//
//  TranslationService.swift
//  ReadWord
//
//  翻译服务 - 使用 Apple Translation API
//

import Foundation
import Combine
import NaturalLanguage

/// 翻译服务
@MainActor
class TranslationService: ObservableObject {
    
    // MARK: - Dify API Models
    
    struct DifyWrapper: Codable {
        let text: String?
        let data: DifyData?
    }
    
    struct DifyData: Codable {
        let outputs: DifyOutputs?
    }
    
    struct DifyOutputs: Codable {
        let text: String?     // 真正的 JSON 字符串在这里
    }
    
    // 新版 API 响应结构（多词返回）
    struct DifyWordsResponse: Codable {
        let words: [WordData]
    }
    
    struct WordData: Codable {
        let word: String
        let emoji: String
        let cn: String
        let sentences: [String]
        let dialogue: [DialogueData]
        let pronunciation: PronunciationData
    }
    
    struct DialogueData: Codable {
        let speaker: String
        let text: String
    }
    
    /// 翻译中文到英文（增强版，返回完整数据）
    func translateFull(_ text: String) async throws -> TranslationResult {
        guard !text.isEmpty else {
            throw TranslationError.emptyText
        }
        
        print("📡 [DEBUG] 正在请求 Dify API...")
        
        do {
            let result = try await translateWithDify(text)
            return result
        } catch {
            print("❌ [DEBUG] Dify API 彻底失败: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 翻译中文到英文（兼容旧版本）
    func translate(_ text: String) async throws -> String {
        guard !text.isEmpty else {
            throw TranslationError.emptyText
        }
        
        // 1. 先尝试内置词典（最快，离线）
        let dictionary = getDictionary()
        if let directTranslation = dictionary[text] {
            print("✅ 词典匹配: \(text) -> \(directTranslation)")
            return directTranslation
        }
        
        // 2. 使用在线翻译 API（主力方案）
        do {
            let onlineResult = try await translateWithOnlineAPI(text)
            print("✅ 在线翻译: \(text) -> \(onlineResult)")
            return onlineResult
        } catch {
            print("⚠️ 在线翻译失败: \(error)")
            throw TranslationError.networkError
        }
    }
    
    /// 使用 Dify AI API（最优先方案）
    private func translateWithDify(_ text: String) async throws -> TranslationResult {
        let maxRetries = 3
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                if attempt > 1 {
                    let delay = UInt64(pow(2.0, Double(attempt - 2))) * 1_000_000_000
                    print("🔄 [DEBUG] Dify 重试第 \(attempt) 次，等待 \(pow(2.0, Double(attempt - 2))) 秒...")
                    try await Task.sleep(nanoseconds: delay)
                }
                
                return try await performDifyRequest(text)
            } catch {
                lastError = error
                let nsError = error as NSError
                
                // 只有特定错误才重试：网络断开(-1005)、超时(-1001)、503错误
                let retryableCodes = [-1005, -1001, -1003, -1009]
                let isRetryable = retryableCodes.contains(nsError.code) || nsError.localizedDescription.contains("503")
                
                if isRetryable && attempt < maxRetries {
                    print("⚠️ [DEBUG] 第 \(attempt) 次尝试失败（\(nsError.code)），准备重试...")
                    continue
                }
                break // 不可重试或达到上限，直接跳出
            }
        }
        throw lastError ?? TranslationError.networkError
    }
    
    /// 实际执行 Dify 网络请求的方法
    private func performDifyRequest(_ text: String) async throws -> TranslationResult {
        let urlString = "https://api.dify.ai/v1/workflows/run"
        
        guard let url = URL(string: urlString) else {
            throw TranslationError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20.0 // 稍微增加超时到 20 秒
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer app-CUISU4O47Vp1ZPn5Odkxgnwi", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "inputs": ["word": text],
            "response_mode": "blocking",
            "user": "readword-app"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.networkError
        }
        
        print("📡 Dify API 状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 503 {
            throw NSError(domain: "DifyError", code: 503, userInfo: [NSLocalizedDescriptionKey: "Server 503"])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw TranslationError.networkError
        }
        
        do {
            let wrapper = try JSONDecoder().decode(DifyWrapper.self, from: data)
            
            // 策略 1: 检查 data.outputs.text (新版多词返回)
            if let jsonString = wrapper.data?.outputs?.text, !jsonString.isEmpty {
                if let result = tryParseWordsResponse(jsonString, original: text) {
                    print("✅ Dify 解析成功: Data.Outputs.Text 多词模式")
                    return result
                }
            }
            
            // 策略 2: 检查根部的 text (兼容模式)
            if let jsonString = wrapper.text, !jsonString.isEmpty {
                if let result = tryParseWordsResponse(jsonString, original: text) {
                    print("✅ Dify 解析成功: Root.Text 多词模式")
                    return result
                }
            }
            
            throw TranslationError.unknownError
        } catch {
            print("❌ Dify 解析彻底失败: \(error.localizedDescription)")
            throw error
        }
    }
    
    // 辅助解析多词响应
    private func tryParseWordsResponse(_ jsonString: String, original: String) -> TranslationResult? {
        var cleanedJson = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 清理 markdown 代码块标记
        if cleanedJson.hasPrefix("```") {
            cleanedJson = cleanedJson.components(separatedBy: "\n")
                .filter { !$0.hasPrefix("```") }
                .joined(separator: "\n")
        }
        
        guard let innerData = cleanedJson.data(using: .utf8) else {
            return nil
        }
        
        // 尝试解析为多词响应
        if let wordsResponse = try? JSONDecoder().decode(DifyWordsResponse.self, from: innerData),
           !wordsResponse.words.isEmpty {
            return createResultFromWords(wordsResponse.words, original: original)
        }
        
        return nil
    }
    
    // 辅助方法：从 WordData 数组构建 TranslationResult
    private func createResultFromWords(_ words: [WordData], original: String) -> TranslationResult {
        // 第一个词是主词
        let mainWordData = words[0]
        let mainWord = WordItem(
            word: mainWordData.word,
            emoji: mainWordData.emoji,
            cn: mainWordData.cn,
            sentences: mainWordData.sentences,
            dialogue: mainWordData.dialogue.map { DialogueLine(speaker: $0.speaker, text: $0.text) },
            pronunciation: mainWordData.pronunciation
        )
        
        // 其余是相似词
        let similarWords = words.dropFirst().map { wordData in
            WordItem(
                word: wordData.word,
                emoji: wordData.emoji,
                cn: wordData.cn,
                sentences: wordData.sentences,
                dialogue: wordData.dialogue.map { DialogueLine(speaker: $0.speaker, text: $0.text) },
                pronunciation: wordData.pronunciation
            )
        }
        
        return TranslationResult(
            sourceText: original,
            mainWord: mainWord,
            similarWords: Array(similarWords)
        )
    }
    
    /// 使用在线翻译 API（多个接口自动切换，带重试机制）
    private func translateWithOnlineAPI(_ text: String) async throws -> String {
        let maxRetries = 3
        var lastError: Error?
        
        // 尝试重试 3 次（指数退避策略）
        for attempt in 1...maxRetries {
            do {
                if attempt > 1 {
                    // 指数退避：第1次重试等1秒，第2次等2秒，第3次等3秒
                    let waitTime = UInt64(attempt - 1) * 1_000_000_000 // 转换为纳秒
                    print("🔄 在线翻译重试第 \(attempt) 次（等待 \(attempt - 1) 秒）...")
                    try await Task.sleep(nanoseconds: waitTime)
                }
                
                // 尝试方案1：百度翻译建议接口
                do {
                    let result = try await translateWithBaidu(text)
                    print("✅ 百度翻译成功 (Attempt \(attempt))")
                    return result
                } catch let baiduError {
                    print("⚠️ 百度翻译失败 (Attempt \(attempt)): \(baiduError.localizedDescription)")
                    lastError = baiduError
                    
                    // 短暂等待后尝试备用接口
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
                }
                
                // 尝试方案2：有道翻译
                do {
                    let result = try await translateWithYoudao(text)
                    print("✅ 有道翻译成功 (Attempt \(attempt))")
                    return result
                } catch let youdaoError {
                    print("⚠️ 有道翻译失败 (Attempt \(attempt)): \(youdaoError.localizedDescription)")
                    lastError = youdaoError
                }
                
                // 两个接口都失败，如果还有重试次数，继续下一轮
                if attempt < maxRetries {
                    print("⚠️ 第 \(attempt) 次尝试失败，准备重试...")
                }
                
            } catch {
                lastError = error
                print("❌ 意外错误: \(error.localizedDescription)")
            }
        }
        
        // 所有重试都失败
        print("❌ 所有翻译尝试均失败（共 \(maxRetries) 次）")
        throw lastError ?? TranslationError.networkError
    }
    
    /// 百度翻译建议接口
    private func translateWithBaidu(_ text: String) async throws -> String {
        var components = URLComponents(string: "https://fanyi.baidu.com/sug")!
        components.queryItems = [URLQueryItem(name: "kw", value: text)]
        
        guard let url = components.url else {
            throw TranslationError.networkError
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0 // 增加到10秒
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TranslationError.networkError
        }
        
        struct BaiduResponse: Codable {
            let data: [BaiduItem]?
        }
        struct BaiduItem: Codable {
            let v: String
        }
        
        let result = try JSONDecoder().decode(BaiduResponse.self, from: data)
        
        if let firstItem = result.data?.first {
            // 提取英文单词（格式可能是："n. 蝴蝶 Web Butterfly; butterfly;"）
            return extractEnglishWord(from: firstItem.v, original: text)
        }
        
        throw TranslationError.unknownError
    }
    
    /// 有道翻译接口
    private func translateWithYoudao(_ text: String) async throws -> String {
        let urlString = "https://dict.youdao.com/suggest?num=1&doctype=json&q=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text)"
        
        guard let url = URL(string: urlString) else {
            throw TranslationError.networkError
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0 // 增加到10秒
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        struct YoudaoResponse: Codable {
            let result: YoudaoResult?
        }
        struct YoudaoResult: Codable {
            let entries: [YoudaoEntry]?
        }
        struct YoudaoEntry: Codable {
            let explain: String?
        }
        
        let result = try JSONDecoder().decode(YoudaoResponse.self, from: data)
        
        if let explain = result.result?.entries?.first?.explain {
            return extractEnglishWord(from: explain, original: text)
        }
        
        throw TranslationError.unknownError
    }
    
    /// 从翻译结果中提取纯英文单词
    private func extractEnglishWord(from translation: String, original: String) -> String {
        print("🔍 原始翻译结果: \(translation)")
        
        // 方法1: 正则匹配纯英文单词（大写开头）
        let pattern = "\\b[A-Z][a-z]+(?:[- ][A-Z]?[a-z]+)*\\b"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: translation, range: NSRange(translation.startIndex..., in: translation)),
           let range = Range(match.range, in: translation) {
            let word = String(translation[range])
            print("✅ 提取单词: \(word)")
            return word
        }
        
        // 方法2: 查找 "Web" 后面的单词
        if let webRange = translation.range(of: "Web "),
           webRange.upperBound < translation.endIndex {
            let afterWeb = String(translation[webRange.upperBound...])
            let words = afterWeb.components(separatedBy: CharacterSet(charactersIn: ";, "))
            if let firstWord = words.first(where: { !$0.isEmpty && $0.first?.isLetter == true }) {
                print("✅ Web后单词: \(firstWord)")
                return firstWord.capitalized
            }
        }
        
        // 方法3: 分割字符串，找第一个纯英文单词
        let components = translation.components(separatedBy: CharacterSet(charactersIn: " ;,.\n"))
        for component in components {
            let trimmed = component.trimmingCharacters(in: .whitespaces)
            // 检查是否是纯英文（不含中文）
            let hasOnlyEnglish = trimmed.allSatisfy { char in
                char.isLetter || char == "-" || char == "'"
            }
            if hasOnlyEnglish && trimmed.count > 1 {
                print("✅ 分词提取: \(trimmed)")
                return trimmed.capitalized
            }
        }
        
        // 如果都失败，返回首字母大写的第一个词
        if let firstWord = translation.components(separatedBy: " ").first {
            return firstWord.capitalized
        }
        
        return translation
    }
    
    /// 从内置词典获取翻译
    private func getTranslation(for word: String) -> String? {
        // 使用扩展的词典
        let dictionary = getDictionary()
        return dictionary[word]
    }
    
    /// 获取完整词典
    private func getDictionary() -> [String: String] {
        return [
            // 问候语
            "你好": "Hello",
            "谢谢": "Thank you",
            "再见": "Goodbye",
            "早上好": "Good morning",
            "晚上好": "Good evening",
            "晚安": "Good night",
            "对不起": "Sorry",
            "请": "Please",
            "欢迎": "Welcome",
            
            // 常用词
            "是": "Yes",
            "不是": "No",
            "好的": "OK",
            "爱": "Love",
            
            // 时间
            "今天": "Today",
            "明天": "Tomorrow",
            "昨天": "Yesterday",
            
            // 物品
            "苹果": "Apple",
            "手机": "Phone",
            "电脑": "Computer",
            "世界": "World",
            "你好世界": "Hello World",
            
            // 动作
            "学习": "Study",
            "工作": "Work",
            "吃饭": "Eat",
            "喝水": "Drink",
            "睡觉": "Sleep",
            
            // 地点
            "家": "Home",
            "学校": "School",
            
            // 其他
            "天气": "Weather",
            "朋友": "Friend",
            
            // 动物
            "猫": "Cat",
            "狗": "Dog",
            "鸟": "Bird",
            "鱼": "Fish",
            "马": "Horse",
            "牛": "Cow",
            "羊": "Sheep",
            "猪": "Pig",
            "鸡": "Chicken",
            "鸭": "Duck",
            "兔子": "Rabbit",
            "老虎": "Tiger",
            "狮子": "Lion",
            "大象": "Elephant",
            "猴子": "Monkey",
            "熊猫": "Panda",
            "熊": "Bear",
            "长颈鹿": "Giraffe",
            "斑马": "Zebra",
            "袋鼠": "Kangaroo",
            
            // 食物
            "米饭": "Rice",
            "面条": "Noodles",
            "面包": "Bread",
            "牛奶": "Milk",
            "水": "Water",
            "茶": "Tea",
            "咖啡": "Coffee",
            "鸡蛋": "Egg",
            "肉": "Meat",
            "蔬菜": "Vegetable",
            "水果": "Fruit",
            "香蕉": "Banana",
            "橙子": "Orange",
            "葡萄": "Grape",
            
            // 颜色
            "红色": "Red",
            "蓝色": "Blue",
            "绿色": "Green",
            "黄色": "Yellow",
            "黑色": "Black",
            "白色": "White",
            "粉色": "Pink",
            "紫色": "Purple",
            "橙色": "Orange",
            "灰色": "Gray"
        ]
    }
    
    /// 使用内置词典翻译
    private func translateWithDictionary(_ text: String) throws -> String {
        // 简单的中英对照词典
        let dictionary: [String: String] = [
            // 问候语
            "你好": "Hello",
            "谢谢": "Thank you",
            "再见": "Goodbye",
            "早上好": "Good morning",
            "晚上好": "Good evening",
            "晚安": "Good night",
            "对不起": "Sorry",
            "请": "Please",
            "欢迎": "Welcome",
            
            // 常用词
            "是": "Yes",
            "不是": "No",
            "好的": "OK",
            "爱": "Love",
            
            // 时间
            "今天": "Today",
            "明天": "Tomorrow",
            "昨天": "Yesterday",
            
            // 物品
            "苹果": "Apple",
            "手机": "Phone",
            "电脑": "Computer",
            "世界": "World",
            "你好世界": "Hello World",
            
            // 动作
            "学习": "Study",
            "工作": "Work",
            "吃饭": "Eat",
            "喝水": "Drink water",
            "睡觉": "Sleep",
            
            // 地点
            "家": "Home",
            "学校": "School",
            
            // 其他
            "天气": "Weather",
            "朋友": "Friend",
            
            // 动物
            "猫": "Cat",
            "狗": "Dog",
            "鸟": "Bird",
            "鱼": "Fish",
            "马": "Horse",
            "牛": "Cow",
            "羊": "Sheep",
            "猪": "Pig",
            "鸡": "Chicken",
            "鸭": "Duck",
            "兔子": "Rabbit",
            "老虎": "Tiger",
            "狮子": "Lion",
            "大象": "Elephant",
            "猴子": "Monkey",
            "熊猫": "Panda",
            "熊": "Bear",
            "长颈鹿": "Giraffe",
            "斑马": "Zebra",
            "袋鼠": "Kangaroo",
            
            // 食物
            "米饭": "Rice",
            "面条": "Noodles",
            "面包": "Bread",
            "牛奶": "Milk",
            "水": "Water",
            "茶": "Tea",
            "咖啡": "Coffee",
            "鸡蛋": "Egg",
            "肉": "Meat",
            "蔬菜": "Vegetable",
            "水果": "Fruit",
            "香蕉": "Banana",
            "橙子": "Orange",
            "葡萄": "Grape",
            
            // 颜色
            "红色": "Red",
            "蓝色": "Blue",
            "绿色": "Green",
            "黄色": "Yellow",
            "黑色": "Black",
            "白色": "White",
            "粉色": "Pink",
            "紫色": "Purple",
            "橙色": "Orange",
            "灰色": "Gray",
            
            // 数字
            "一": "One",
            "二": "Two",
            "三": "Three",
            "四": "Four",
            "五": "Five",
            "六": "Six",
            "七": "Seven",
            "八": "Eight",
            "九": "Nine",
            "十": "Ten",
            
            // 家庭
            "爸爸": "Father",
            "妈妈": "Mother",
            "哥哥": "Brother",
            "姐姐": "Sister",
            "爷爷": "Grandfather",
            "奶奶": "Grandmother",
            "儿子": "Son",
            "女儿": "Daughter",
            
            // 身体部位
            "头": "Head",
            "眼睛": "Eye",
            "耳朵": "Ear",
            "鼻子": "Nose",
            "嘴": "Mouth",
            "手": "Hand",
            "脚": "Foot",
            "腿": "Leg",
            "胳膊": "Arm"
        ]
        
        // 先尝试直接匹配
        if let translation = dictionary[text] {
            return translation
        }
        
        // 尝试分词匹配（简单实现）
        var result = ""
        for char in text {
            let charStr = String(char)
            if let trans = dictionary[charStr] {
                result += trans + " "
            }
        }
        
        if !result.isEmpty {
            return result.trimmingCharacters(in: .whitespaces)
        }
        
        // 如果都没有匹配，返回友好提示
        return "[Translation] \(text)\n\n💡 提示：当前使用内置词典。支持常用词汇翻译。\n\n已支持词汇：你好、谢谢、再见、早上好、晚上好、苹果、手机、电脑等。"
    }
    
    /// 批量翻译
    /// - Parameter texts: 中文文本数组
    /// - Returns: 英文翻译结果数组
    func translateBatch(_ texts: [String]) async throws -> [String] {
        var results: [String] = []
        
        for text in texts {
            let translated = try await translate(text)
            results.append(translated)
        }
        
        return results
    }
}

/// 翻译错误类型
enum TranslationError: LocalizedError {
    case emptyText
    case unsupportedVersion
    case networkError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "输入文本不能为空"
        case .unsupportedVersion:
            return "需要 iOS 18.0 或更高版本"
        case .networkError:
            return "网络连接失败"
        case .unknownError:
            return "翻译失败，请重试"
        }
    }
}

