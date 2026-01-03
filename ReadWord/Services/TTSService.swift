//
//  TTSService.swift
//  ReadWord
//
//  文字转语音服务 - 使用 AVSpeechSynthesizer
//

import Foundation
import AVFoundation
import Combine

/// 文字转语音服务
class TTSService: NSObject, ObservableObject {
    
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    @Published var isReady = false  // 音频是否已准备好
    private var isPrewarming = false  // 是否正在预热（预加载/预热时不改变 isSpeaking 状态）
    private var speechQueue: [(text: String, speaker: String?)] = []  // 待播放的文本队列（包含说话者信息）
    
    // 获取男声和女声
    private var maleVoice: AVSpeechSynthesisVoice? {
        // 查找英语男声
        if #available(iOS 13.0, *) {
            // iOS 13+ 可以使用 gender 属性
            return AVSpeechSynthesisVoice.speechVoices().first { voice in
                voice.language.hasPrefix("en") && voice.gender == .male
            }
        } else {
            // iOS 13 以下，尝试查找标识符中包含 "male" 的声音
            return AVSpeechSynthesisVoice.speechVoices().first { voice in
                voice.language.hasPrefix("en") && (voice.identifier.lowercased().contains("male") || voice.identifier.lowercased().contains("daniel"))
            }
        }
    }
    
    private var femaleVoice: AVSpeechSynthesisVoice? {
        // 默认使用女声（通常是 Samantha 或 Alex）
        if #available(iOS 13.0, *) {
            return AVSpeechSynthesisVoice.speechVoices().first { voice in
                voice.language.hasPrefix("en") && voice.gender == .female
            } ?? AVSpeechSynthesisVoice(language: "en-US")
        } else {
            return AVSpeechSynthesisVoice(language: "en-US")
        }
    }
    
    override init() {
        super.init()
        synthesizer.delegate = self
        
        // 预加载音频会话和语音合成器
        preloadAudio()
    }
    
    /// 预加载音频会话和语音合成器
    private func preloadAudio() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 配置音频会话
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
                try audioSession.setActive(true, options: [])
            } catch {
                // 静默处理错误
            }
            
            // 标记为预热状态
            DispatchQueue.main.async {
            self.isPrewarming = true
            }
            
            // 预热语音合成器（朗读一个短单词）
            let utterance = AVSpeechUtterance(string: "test")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.volume = 0.0  // 静音
            utterance.rate = 0.5
            utterance.preUtteranceDelay = 0.0
            utterance.postUtteranceDelay = 0.0
            
            DispatchQueue.main.async {
            self.synthesizer.speak(utterance)
            }
            
            // 等待预热完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isPrewarming = false
                self.isReady = true
            }
        }
    }
    
    /// 预热特定内容的语音引擎（暂时禁用，避免干扰正常播放）
    func prewarm(_ text: String) {
        // 暂时禁用预热功能，因为它可能干扰正常播放
        // let cleanedText = cleanText(text)
        // guard !cleanedText.isEmpty else { return }
    }
    
    /// 朗读英文文本
    /// - Parameters:
    ///   - text: 英文文本
    ///   - speaker: 说话者（"A" 为女声，"B" 为男声，nil 为默认女声）
    func speak(_ text: String, speaker: String? = nil) {
        // 清理文本（移除提示信息，只保留英文）
        let cleanedText = cleanText(text)
        
        // 如果文本为空，不执行朗读
        guard !cleanedText.isEmpty else {
            return
        }
        
        // 如果正在朗读，先停止
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
        
        // 配置音频会话
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true, options: [])
        } catch {
            return
        }
        
        // 创建语音内容
        let utterance = AVSpeechUtterance(string: cleanedText)
        
        // 根据说话者选择声音
        if speaker == "B" {
            // B角色使用男声
            utterance.voice = maleVoice
        } else {
            // A角色或默认使用女声
            utterance.voice = femaleVoice
        }
        
        // 设置语速（0.0 - 1.0，默认 0.5）
        utterance.rate = 0.45
        
        // 设置音量（0.0 - 1.0）
        utterance.volume = 1.0
        
        // 设置音调（0.5 - 2.0，默认 1.0）
        utterance.pitchMultiplier = 1.0
        
        // 设置延迟（让音频会话准备好）
        utterance.preUtteranceDelay = 0.1
        
        // 开始朗读（不要在这里设置 isSpeaking，等待 delegate 回调）
        synthesizer.speak(utterance)
    }
    
    /// 清理文本，移除提示信息
    private func cleanText(_ text: String) -> String {
        // 如果包含 [Translation] 标记，提取实际内容
        if text.contains("[Translation]") {
            let components = text.components(separatedBy: "\n")
            if let firstLine = components.first {
                return firstLine.replacingOccurrences(of: "[Translation]", with: "").trimmingCharacters(in: .whitespaces)
            }
        }
        
        // 如果包含提示信息，只返回第一行
        if text.contains("\n") {
            let components = text.components(separatedBy: "\n")
            if let firstLine = components.first?.trimmingCharacters(in: .whitespaces), !firstLine.isEmpty {
                return firstLine
            }
        }
        
        return text.trimmingCharacters(in: .whitespaces)
    }
    
    /// 连续播放多个文本（从指定索引开始）
    /// - Parameters:
    ///   - texts: 文本数组
    ///   - startIndex: 开始播放的索引
    ///   - speakers: 说话者数组（可选，与texts对应）
    func speakSequentially(_ texts: [String], from startIndex: Int = 0, speakers: [String]? = nil) {
        guard startIndex < texts.count else { return }
        
        // 清空队列并添加从指定索引开始的所有文本和说话者信息
        let textsToQueue = Array(texts[startIndex...])
        if let speakers = speakers, startIndex < speakers.count {
            let speakersToQueue = Array(speakers[startIndex...])
            speechQueue = zip(textsToQueue, speakersToQueue).map { (text: $0, speaker: $1) }
        } else {
            speechQueue = textsToQueue.map { (text: $0, speaker: nil) }
        }
        
        // 开始播放队列中的第一个文本
        if !speechQueue.isEmpty {
            let first = speechQueue.removeFirst()
            speak(first.text, speaker: first.speaker)
        }
    }
    
    /// 停止朗读
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
        // 清空队列
        speechQueue.removeAll()
    }
    
    /// 暂停朗读
    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
        }
    }
    
    /// 继续朗读
    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension TTSService: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            // 只有在非预热状态下才改变 isSpeaking
            if !self.isPrewarming {
                self.isSpeaking = true
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            // 只有在非预热状态下才改变 isSpeaking
            if !self.isPrewarming {
                self.isSpeaking = false
                
                // 如果队列中还有待播放的文本，继续播放下一个
                if !self.speechQueue.isEmpty {
                    // 添加短暂延迟，让语音更自然
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        let next = self.speechQueue.removeFirst()
                        self.speak(next.text, speaker: next.speaker)
                    }
                }
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            // 只有在非预热状态下才改变 isSpeaking
            if !self.isPrewarming {
                self.isSpeaking = false
                // 取消时清空队列
                self.speechQueue.removeAll()
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // 当开始朗读时的额外确认
        if !self.isPrewarming && !self.isSpeaking {
            DispatchQueue.main.async {
                self.isSpeaking = true
            }
        }
    }
}

