//
//  TranslationResult.swift
//  ReadWord
//
//  翻译结果数据模型
//

import Foundation

// MARK: - 发音数据

/// 发音数据
struct PronunciationData: Codable, Equatable {
    let ipa: String         // 音标 (IPA)
    let hint: String        // 发音提示
}

// MARK: - 对话行

/// 对话的一行
struct DialogueLine: Identifiable, Codable, Equatable {
    var id = UUID()
    let speaker: String     // "A" or "B"
    let text: String        // 对话内容
    
    enum CodingKeys: String, CodingKey {
        case speaker, text
    }
    
    init(speaker: String, text: String) {
        self.speaker = speaker
        self.text = text
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.speaker = try container.decode(String.self, forKey: .speaker)
        self.text = try container.decode(String.self, forKey: .text)
    }
}

// MARK: - 单词项

/// 单个词条（主词或相似词）
struct WordItem: Identifiable, Codable, Equatable {
    var id = UUID()
    let word: String                // 英文单词
    let emoji: String               // Emoji 图标
    let cn: String                  // 中文释义
    let sentences: [String]         // 例句列表（7个）
    let dialogue: [DialogueLine]    // 对话
    let pronunciation: PronunciationData  // 发音数据
    
    enum CodingKeys: String, CodingKey {
        case word, emoji, cn, sentences, dialogue, pronunciation
    }
    
    init(word: String,
         emoji: String,
         cn: String,
         sentences: [String],
         dialogue: [DialogueLine],
         pronunciation: PronunciationData) {
        self.word = word
        self.emoji = emoji
        self.cn = cn
        self.sentences = sentences
        self.dialogue = dialogue
        self.pronunciation = pronunciation
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.word = try container.decode(String.self, forKey: .word)
        self.emoji = try container.decode(String.self, forKey: .emoji)
        self.cn = try container.decode(String.self, forKey: .cn)
        self.sentences = try container.decode([String].self, forKey: .sentences)
        self.dialogue = try container.decode([DialogueLine].self, forKey: .dialogue)
        self.pronunciation = try container.decode(PronunciationData.self, forKey: .pronunciation)
    }
}

// MARK: - 翻译结果

/// 翻译结果（包含主词和相似词）
struct TranslationResult: Identifiable, Codable {
    var id = UUID()
    let sourceText: String          // 用户输入的中文
    let mainWord: WordItem          // 主词（words[0]）
    let similarWords: [WordItem]    // 相似词（words[1...n]）
    let timestamp: Date             // 翻译时间
    
    enum CodingKeys: String, CodingKey {
        case sourceText, mainWord, similarWords, timestamp
    }
    
    init(sourceText: String,
         mainWord: WordItem,
         similarWords: [WordItem] = []) {
        self.sourceText = sourceText
        self.mainWord = mainWord
        self.similarWords = similarWords
        self.timestamp = Date()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sourceText = try container.decode(String.self, forKey: .sourceText)
        self.mainWord = try container.decode(WordItem.self, forKey: .mainWord)
        self.similarWords = try container.decode([WordItem].self, forKey: .similarWords)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    /// 便捷访问所有词（主词 + 相似词）
    var allWords: [WordItem] {
        [mainWord] + similarWords
    }
}

