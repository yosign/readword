//
//  TranslationService.swift
//  ReadWord
//
//  翻译服务 - 使用内置词典
//

import Foundation
import Combine

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
        
        // 当前使用内置词典方案
        // Translation Framework 在 Xcode 26.2 中的 API 还在调整
        // 未来版本会更新为使用官方 Translation Framework
        return try translateWithDictionary(text)
    }
    
    /// 使用内置词典翻译
    private func translateWithDictionary(_ text: String) throws -> String {
        // 简单的中英对照词典
        let dictionary: [String: String] = [
            "你好": "Hello",
            "世界": "World",
            "你好世界": "Hello World",
            "谢谢": "Thank you",
            "再见": "Goodbye",
            "早上好": "Good morning",
            "晚上好": "Good evening",
            "晚安": "Good night",
            "是": "Yes",
            "不是": "No",
            "苹果": "Apple",
            "手机": "Phone",
            "电脑": "Computer",
            "学习": "Study",
            "工作": "Work",
            "吃饭": "Eat",
            "喝水": "Drink water",
            "睡觉": "Sleep",
            "今天": "Today",
            "明天": "Tomorrow",
            "昨天": "Yesterday",
            "天气": "Weather",
            "好的": "OK",
            "对不起": "Sorry",
            "请": "Please",
            "欢迎": "Welcome",
            "爱": "Love",
            "朋友": "Friend",
            "家": "Home",
            "学校": "School"
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

