//
//  TranslationResult.swift
//  ReadWord
//
//  翻译结果数据模型
//

import Foundation

// MARK: - 发音数据

/// 发音数据（音标 + 发音提示）
struct PronunciationData: Codable, Equatable {
    let ipa: String      // 音标 (IPA)
    let hint: String     // 发音提示
}

// MARK: - 对话行

/// 对话的一行
struct DialogueLine: Identifiable, Codable, Equatable {
    var id = UUID()
    let speaker: String  // 说话者（"A" 或 "B"）
    let text: String     // 对话内容
}

// MARK: - 词条

/// 单个词条（包含完整信息）
struct WordItem: Identifiable, Codable, Equatable {
    var id = UUID()
    let word: String                    // 英文单词
    let emoji: String                   // Emoji 图标
    let cn: String                      // 中文翻译
    let sentences: [String]             // 例句数组
    let dialogue: [DialogueLine]       // 对话数组
    let pronunciation: PronunciationData // 发音数据
}

// MARK: - 翻译结果

/// 翻译结果
struct TranslationResult: Identifiable, Codable {
    var id = UUID()
    let sourceText: String          // 原文（用户输入）
    let translatedText: String      // 英文单词（兼容旧版本）
    let chineseTranslation: String? // 中文翻译（兼容旧版本）
    let timestamp: Date             // 翻译时间
    
    // 兼容旧版本：Dify API 扩展字段
    let emoji: String?              // Emoji 图标（兼容旧版本）
    let exampleSentence: String?    // 例句（兼容旧版本）
    let ipa: String?                // 音标 (IPA)（兼容旧版本）
    let pronunciationHint: String?  // 发音提示（兼容旧版本）
    
    // 新版本：多词返回
    let mainWord: WordItem?         // 主词
    let similarWords: [WordItem]?   // 相似词数组
    
    /// 获取所有词条（主词 + 相似词）
    var allWords: [WordItem] {
        var words: [WordItem] = []
        if let mainWord = mainWord {
            words.append(mainWord)
        }
        if let similarWords = similarWords {
            words.append(contentsOf: similarWords)
        }
        return words
    }
    
    // 兼容旧版本的初始化方法
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
        self.mainWord = nil
        self.similarWords = nil
    }
    
    // 新版本的初始化方法（多词返回）
    init(sourceText: String,
         mainWord: WordItem,
         similarWords: [WordItem] = []) {
        self.sourceText = sourceText
        self.translatedText = mainWord.word
        self.chineseTranslation = mainWord.cn
        self.timestamp = Date()
        self.emoji = mainWord.emoji
        self.exampleSentence = mainWord.sentences.first
        self.ipa = mainWord.pronunciation.ipa
        self.pronunciationHint = mainWord.pronunciation.hint
        self.mainWord = mainWord
        self.similarWords = similarWords
    }
}

