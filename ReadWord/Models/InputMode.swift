//
//  InputMode.swift
//  ReadWord
//
//  输入模式枚举
//

import Foundation

/// 输入模式
enum InputMode {
    case text       // 文字输入
    case voice      // 语音输入
    case camera     // 拍照输入
    
    var title: String {
        switch self {
        case .text:
            return "文字"
        case .voice:
            return "语音"
        case .camera:
            return "拍照"
        }
    }
    
    var icon: String {
        switch self {
        case .text:
            return "keyboard"
        case .voice:
            return "mic.fill"
        case .camera:
            return "camera.fill"
        }
    }
}

