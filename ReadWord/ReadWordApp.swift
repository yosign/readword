//
//  ReadWordApp.swift
//  ReadWord
//
//  Created by YoSign on 2025/12/26.
//

import SwiftUI

@main
struct ReadWordApp: App {
    @State private var splashFinished = false
    
    init() {
        // 设置全局窗口背景色为白色
        UIWindow.appearance().backgroundColor = .white
    }
    
    var body: some Scene {
        WindowGroup {
            if splashFinished {
                ContentView()
            } else {
                SplashView(isFinished: $splashFinished)
            }
        }
    }
}
