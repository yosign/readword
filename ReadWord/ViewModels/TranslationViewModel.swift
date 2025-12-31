//
//  TranslationViewModel.swift
//  ReadWord
//

import Foundation
import SwiftUI
import PhotosUI
import Combine
import Speech

@MainActor
class TranslationViewModel: ObservableObject {
    
    @Published var inputText = ""
    @Published var translatedText = ""
    @Published var currentSourceText = ""
    @Published var currentMode: InputMode = .text
    @Published var isTranslating = false
    @Published var translationProgress: Double = 0.0 // 新增：进度条百分比 (0.0 - 1.0)
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var history: [TranslationResult] = []
    @Published var selectedImage: PhotosPickerItem?
    @Published var showCamera = false
    
    private let historyKey = "translationHistory"
    private let translationService = TranslationService()
    let ttsService = TTSService()
    let speechService = SpeechService()
    let ocrService = OCRService()
    
    init() {
        loadHistory()
    }
    
    func translate() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let cleanedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 🔍 先检查缓存：查找历史记录中是否有相同的词
        if let cachedRecord = history.first(where: { $0.sourceText == cleanedInput }) {
            print("💾 使用缓存数据: \(cachedRecord.translatedText)")
            
            // 使用缓存数据，无需请求接口
            isTranslating = true
            translationProgress = 0.0
            
            // 快速进度动画
            withAnimation(.easeOut(duration: 0.3)) { translationProgress = 1.0 }
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            self.translatedText = cachedRecord.translatedText
            self.currentSourceText = cleanedInput
            
            // 预热语音引擎
            ttsService.prewarm(cachedRecord.translatedText)
            
            // 将该记录移到最前面（更新使用时间）
            if let index = history.firstIndex(where: { $0.id == cachedRecord.id }) {
                history.remove(at: index)
                history.insert(cachedRecord, at: 0)
                saveHistory()
            }
            
            isTranslating = false
            try? await Task.sleep(nanoseconds: 200_000_000)
            translationProgress = 0.0
            return
        }
        
        // 📡 缓存未命中，请求接口
        isTranslating = true
        translationProgress = 0.0
        errorMessage = nil
        
        // 开启仿真进度计时任务
        let progressTask = Task {
            // 前 0.5 秒冲到 40%
            withAnimation(.easeOut(duration: 0.5)) { translationProgress = 0.4 }
            if Task.isCancelled { return }
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // 接下来 2 秒慢速涨到 90%
            if Task.isCancelled { return }
            withAnimation(.linear(duration: 2.0)) { translationProgress = 0.9 }
        }
        
        print("\n🚀🚀🚀 >>> 开始翻译流程: \(cleanedInput) <<< 🚀🚀🚀\n")
        
        do {
            let record = try await translationService.translateFull(cleanedInput)
            
            // 接口返回，进度冲刺到 100%
            progressTask.cancel()
            withAnimation(.spring(response: 0.3)) { translationProgress = 1.0 }
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            print("✅ 成功获取记录: \(record.translatedText)")
            
            self.translatedText = record.translatedText
            self.currentSourceText = cleanedInput
            
            // 核心优化：翻译成功后立即预热语音引擎
            ttsService.prewarm(record.translatedText)
            
            history.insert(record, at: 0)
            if history.count > 50 { history.removeLast() }
            saveHistory()
            
        } catch {
            progressTask.cancel()
            print("❌ 翻译流程彻底失败: \(error.localizedDescription)")
            errorMessage = "翻译失败: \(error.localizedDescription)"
            showError = true
        }
        
        isTranslating = false
        // 延迟清空进度，让用户看到 100% 的完成感
        try? await Task.sleep(nanoseconds: 200_000_000)
        translationProgress = 0.0
    }
    
    // MARK: - OCR Methods (补全缺失的方法)
    
    /// 处理选中的图片
    func processSelectedImage() async {
        guard let selectedImage = selectedImage else { return }
        
        do {
            if let imageData = try await selectedImage.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: imageData) {
                let recognizedText = try await ocrService.recognizeText(from: uiImage)
                self.inputText = recognizedText
                await translate() // 识别后自动翻译
            }
        } catch {
            print("❌ 图片识别失败: \(error.localizedDescription)")
        }
    }
    
    /// 处理拍照的图片
    func processCameraImage(_ image: UIImage) async {
        do {
            let recognizedText = try await ocrService.recognizeText(from: image)
            self.inputText = recognizedText
            await translate() // 识别后自动翻译
        } catch {
            print("❌ 相机识别失败: \(error.localizedDescription)")
        }
    }
    
    func speakTranslation() {
        guard !translatedText.isEmpty else { return }
        ttsService.speak(translatedText)
    }
    
    // MARK: - Persistence
    
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("❌ 保存失败")
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return }
        do {
            history = try JSONDecoder().decode([TranslationResult].self, from: data)
        } catch {
            print("❌ 加载失败，清除旧数据")
            UserDefaults.standard.removeObject(forKey: historyKey)
        }
    }
    
    func clear() {
        inputText = ""
        translatedText = ""
        currentSourceText = ""
    }
}
