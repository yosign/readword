//
//  TranslationResult.swift
//  ReadWord
//
//  翻译结果数据模型
//

import Foundation

/// 翻译结果
struct TranslationResult: Identifiable {
    let id = UUID()
    let sourceText: String          // 原文（中文）
    let translatedText: String      // 译文（英文）
    let timestamp: Date             // 翻译时间
    
    init(sourceText: String, translatedText: String) {
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.timestamp = Date()
    }
}

