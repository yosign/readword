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
                try audioSession.setCategory(.playback, mode: .default, options: [])
                try audioSession.setActive(true, options: [])
                print("✅ 音频会话预加载成功")
            } catch {
                print("❌ 音频会话预加载失败: \(error)")
            }
            
            // 预热语音合成器（朗读一个空字符串）
            let utterance = AVSpeechUtterance(string: " ")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.volume = 0.0  // 静音
            utterance.rate = 0.5
            
            self.synthesizer.speak(utterance)
            
            // 等待预热完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isReady = true
                print("✅ 语音合成器预热完成，准备就绪")
            }
        }
    }
    
    /// 朗读英文文本
    /// - Parameter text: 英文文本
    func speak(_ text: String) {
        // 如果正在朗读，先停止
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // 配置音频会话
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true, options: [])
        } catch {
            print("❌ 音频会话配置失败: \(error)")
        }
        
        // 清理文本（移除提示信息，只保留英文）
        let cleanedText = cleanText(text)
        
        print("🔊 准备朗读: \(cleanedText)")
        
        // 创建语音内容
        let utterance = AVSpeechUtterance(string: cleanedText)
        
        // 设置语言为英语（美式）
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        // 设置语速（0.0 - 1.0，默认 0.5）
        utterance.rate = 0.45
        
        // 设置音量（0.0 - 1.0）
        utterance.volume = 1.0
        
        // 设置音调（0.5 - 2.0，默认 1.0）
        utterance.pitchMultiplier = 1.0
        
        // 开始朗读
        synthesizer.speak(utterance)
        isSpeaking = true
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
    
    /// 停止朗读
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
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
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}

