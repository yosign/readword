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
    
    /// 翻译中文到英文
    /// - Parameter text: 中文文本
    /// - Returns: 英文翻译结果
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
    
    /// 使用在线翻译 API（多个接口自动切换，带重试机制）
    private func translateWithOnlineAPI(_ text: String) async throws -> String {
        let maxRetries = 3
        var lastError: Error?
        
        // 尝试重试 3 次
        for attempt in 1...maxRetries {
            do {
                if attempt > 1 {
                    print("🔄 在线翻译重试第 \(attempt) 次...")
                    // 重试前稍微等待一下，避免频繁请求
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                }
                
                // 尝试方案1：百度翻译建议接口
                do {
                    return try await translateWithBaidu(text)
                } catch {
                    print("⚠️ 百度翻译失败 (Attempt \(attempt)): \(error)")
                }
                
                // 尝试方案2：有道翻译
                do {
                    return try await translateWithYoudao(text)
                } catch {
                    print("⚠️ 有道翻译失败 (Attempt \(attempt)): \(error)")
                    lastError = error
                }
                
                // 如果两次都失败，继续下一次循环重试
                
            } catch {
                lastError = error
            }
        }
        
        if let error = lastError {
            throw error
        }
        
        throw TranslationError.networkError
    }
    
    /// 百度翻译建议接口
    private func translateWithBaidu(_ text: String) async throws -> String {
        var components = URLComponents(string: "https://fanyi.baidu.com/sug")!
        components.queryItems = [URLQueryItem(name: "kw", value: text)]
        
        guard let url = components.url else {
            throw TranslationError.networkError
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        
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
        request.timeoutInterval = 5.0
        
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
            "鱼": "Fish",
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

