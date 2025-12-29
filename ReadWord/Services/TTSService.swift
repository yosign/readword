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
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    /// 朗读英文文本
    /// - Parameter text: 英文文本
    func speak(_ text: String) {
        // 如果正在朗读，先停止
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // 创建语音内容
        let utterance = AVSpeechUtterance(string: text)
        
        // 设置语言为英语（美式）
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        // 设置语速（0.0 - 1.0，默认 0.5）
        utterance.rate = 0.5
        
        // 设置音量（0.0 - 1.0）
        utterance.volume = 1.0
        
        // 设置音调（0.5 - 2.0，默认 1.0）
        utterance.pitchMultiplier = 1.0
        
        // 开始朗读
        synthesizer.speak(utterance)
        isSpeaking = true
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

