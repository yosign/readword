//
//  TranslationResult.swift
//  ReadWord
//
//  翻译结果数据模型
//

import Foundation

/// 翻译结果
struct TranslationResult: Identifiable, Codable {
    var id = UUID() // 必须改为 var 并且 Codable 才能自动处理，或者手动实现。通常 Codable 对 UUID 支持良好。
    let sourceText: String          // 原文（中文）
    let translatedText: String      // 译文（英文）
    let timestamp: Date             // 翻译时间
    
    init(sourceText: String, translatedText: String) {
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.timestamp = Date()
    }
}

