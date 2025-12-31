//
//  TranslationResult.swift
//  ReadWord
//
//  翻译结果数据模型
//

import Foundation

/// 翻译结果
struct TranslationResult: Identifiable, Codable {
    var id = UUID()
    let sourceText: String          // 原文（用户输入）
    let translatedText: String      // 英文单词
    let chineseTranslation: String? // 中文翻译（新增）
    let timestamp: Date             // 翻译时间
    
    // 新增：Dify API 扩展字段
    let emoji: String?              // Emoji 图标
    let exampleSentence: String?    // 例句
    let ipa: String?                // 音标 (IPA)
    let pronunciationHint: String?  // 发音提示
    
    init(sourceText: String, 
         translatedText: String,
         chineseTranslation: String? = nil,
         emoji: String? = nil,
         exampleSentence: String? = nil,
         ipa: String? = nil,
         pronunciationHint: String? = nil) {
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.chineseTranslation = chineseTranslation
        self.emoji = emoji
        self.exampleSentence = exampleSentence
        self.ipa = ipa
        self.pronunciationHint = pronunciationHint
        self.timestamp = Date()
    }
}

