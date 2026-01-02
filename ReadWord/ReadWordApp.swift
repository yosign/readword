//
//  ReadWordApp.swift
//  ReadWord
//
//  Created by YoSign on 2025/12/26.
//

import SwiftUI

// MARK: - Notification Extension

extension Notification.Name {
    static let focusInput = Notification.Name("focusInput")
}

@main
struct ReadWordApp: App {
    @State private var splashFinished = false
    @StateObject private var viewModel = TranslationViewModel() // 提前创建 ViewModel，在启动动画期间预加载
    
    init() {
        // 设置全局窗口背景色为白色
        UIWindow.appearance().backgroundColor = .white
    }
    
    var body: some Scene {
        WindowGroup {
            if splashFinished {
                ContentView(viewModel: viewModel) // 传递预加载的 ViewModel
                    .onOpenURL { url in
                        // 处理 Widget 的 Deep Link
                        handleDeepLink(url)
                    }
            } else {
                SplashView(isFinished: $splashFinished, viewModel: viewModel) // 传递 ViewModel 以便在启动期间预加载
            }
        }
    }
    
    // MARK: - Deep Link 处理
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "readword" else { return }
        
        if url.host == "open" {
            // Widget 点击：打开应用
            print("📱 Widget 打开应用")
            // 发送通知，让 ContentView 聚焦输入框
            NotificationCenter.default.post(name: .focusInput, object: nil)
        }
    }
}
