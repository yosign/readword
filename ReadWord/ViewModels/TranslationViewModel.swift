//
//  TranslationViewModel.swift
//  ReadWord
//
//  主视图模型 - 协调各个服务
//

import Foundation
import SwiftUI
import PhotosUI
import Combine
import Speech

/// 翻译视图模型
@MainActor
class TranslationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var inputText = ""
    @Published var translatedText = ""
    @Published var currentMode: InputMode = .text
    @Published var isTranslating = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var history: [TranslationResult] = []
    @Published var selectedImage: PhotosPickerItem?
    @Published var showCamera = false
    
    // MARK: - Services
    private let translationService = TranslationService()
    let ttsService = TTSService()
    let speechService = SpeechService()
    let ocrService = OCRService()
    
    // MARK: - Translation Methods
    
    /// 执行翻译
    func translate() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError(message: "请输入要翻译的文字")
            return
        }
        
        isTranslating = true
        errorMessage = nil
        
        do {
            let result = try await translationService.translate(inputText)
            translatedText = result
            
            // 添加到历史记录
            let record = TranslationResult(sourceText: inputText, translatedText: result)
            history.insert(record, at: 0)
            
            // 限制历史记录数量
            if history.count > 50 {
                history.removeLast()
            }
            
        } catch {
            showError(message: error.localizedDescription)
        }
        
        isTranslating = false
    }
    
    /// 清空输入和结果
    func clear() {
        inputText = ""
        translatedText = ""
        errorMessage = nil
    }
    
    /// 朗读翻译结果
    func speakTranslation() {
        guard !translatedText.isEmpty else {
            showError(message: "没有可朗读的内容")
            return
        }
        
        ttsService.speak(translatedText)
    }
    
    // MARK: - Voice Input Methods
    
    /// 开始语音识别
    func startVoiceRecognition() async {
        // 检查权限
        if speechService.authorizationStatus == .notDetermined {
            let granted = await speechService.requestAuthorization()
            if !granted {
                showError(message: "需要语音识别权限")
                return
            }
        }
        
        guard speechService.authorizationStatus == .authorized else {
            showError(message: "未授权语音识别权限，请在设置中开启")
            return
        }
        
        // 开始录音
        do {
            try speechService.startRecording()
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    /// 停止语音识别
    func stopVoiceRecognition() {
        speechService.stopRecording()
        
        // 将识别的文字填入输入框
        if !speechService.recognizedText.isEmpty {
            inputText = speechService.recognizedText
        }
    }
    
    // MARK: - Camera/Photo Methods
    
    /// 处理选中的图片
    func processSelectedImage() async {
        guard let selectedImage = selectedImage else { return }
        
        do {
            // 加载图片数据
            guard let imageData = try await selectedImage.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: imageData) else {
                showError(message: "无法加载图片")
                return
            }
            
            // 执行OCR识别
            let recognizedText = try await ocrService.recognizeText(from: uiImage)
            inputText = recognizedText
            
        } catch {
            showError(message: "图片识别失败: \(error.localizedDescription)")
        }
    }
    
    /// 处理拍照的图片
    func processCameraImage(_ image: UIImage) async {
        do {
            let recognizedText = try await ocrService.recognizeText(from: image)
            inputText = recognizedText
        } catch {
            showError(message: "图片识别失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// 显示错误信息
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    /// 切换输入模式
    func switchMode(to mode: InputMode) {
        currentMode = mode
        
        // 切换模式时停止当前操作
        if speechService.isRecording {
            speechService.stopRecording()
        }
        if ttsService.isSpeaking {
            ttsService.stop()
        }
    }
}

