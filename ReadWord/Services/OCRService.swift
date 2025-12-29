//
//  OCRService.swift
//  ReadWord
//
//  OCR文字识别服务 - 使用 Vision Framework
//

import Foundation
import Vision
import UIKit
import Combine

/// OCR文字识别服务
class OCRService: ObservableObject {
    
    @Published var recognizedText = ""
    @Published var isProcessing = false
    
    /// 识别图片中的文字
    /// - Parameter image: 输入图片
    /// - Returns: 识别出的文字
    func recognizeText(from image: UIImage) async throws -> String {
        await MainActor.run {
            isProcessing = true
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }
        
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // 创建文字识别请求
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                // 提取识别出的文字
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let result = recognizedStrings.joined(separator: "\n")
                
                if result.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    continuation.resume(returning: result)
                }
            }
            
            // 配置识别选项
            request.recognitionLevel = .accurate  // 使用准确模式
            request.recognitionLanguages = ["zh-Hans", "zh-Hant"]  // 支持简体和繁体中文
            request.usesLanguageCorrection = true  // 使用语言校正
            
            // 创建请求处理器
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            // 执行识别
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 识别图片中的文字（带进度回调）
    /// - Parameters:
    ///   - image: 输入图片
    ///   - progressHandler: 进度回调
    /// - Returns: 识别出的文字
    func recognizeText(from image: UIImage, progressHandler: @escaping (Double) -> Void) async throws -> String {
        progressHandler(0.3)
        let result = try await recognizeText(from: image)
        progressHandler(1.0)
        return result
    }
}

/// OCR错误类型
enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无效的图片"
        case .noTextFound:
            return "未识别到文字"
        case .processingFailed:
            return "处理失败"
        }
    }
}

