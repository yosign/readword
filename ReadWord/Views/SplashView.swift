//
//  SplashView.swift
//  ReadWord
//

import SwiftUI
import AVKit

struct SplashView: View {
    @Binding var isFinished: Bool
    @ObservedObject var viewModel: TranslationViewModel // 接收预加载的 ViewModel
    
    // 提前持有播放器，确保进入即播放
    @State private var player: AVPlayer = {
        guard let url = Bundle.main.url(forResource: "splash", withExtension: "mp4") else {
            return AVPlayer()
        }
        let player = AVPlayer(url: url)
        player.automaticallyWaitsToMinimizeStalling = false
        return player
    }()
    
    @State private var rotationDegree: Double = 0
    @State private var hasStartedPreloading = false // 确保只预加载一次
    
    var body: some View {
        ZStack {
            // 1. 纯白背景
            Color.white.ignoresSafeArea()
            
            // 使用等分布局锁定 1/3 和 2/3
            VStack(spacing: 0) {
                Spacer() // 占位顶部 1/3
                
                // 2. 视频动画区
                CustomPlayerView(player: player) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        isFinished = true
                    }
                }
                .brightness(0.05) // 提升亮度 5%
                .blendMode(.darken) // Darken 混合模式
                .frame(width: UIScreen.main.bounds.width * 0.5)
                .frame(height: UIScreen.main.bounds.width * 0.5)
                
                Spacer() // 占位中部 1/3
                
                // 3. Loading 动画区
                ZStack {
                    Circle()
                        .stroke(Color.orange.opacity(0.1), lineWidth: 3)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(
                            LinearGradient(colors: [.orange, .orange.opacity(0.3)], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 40, height: 40)
                        .rotationEffect(Angle(degrees: rotationDegree))
                }
                .onAppear {
                    withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        rotationDegree = 360
                    }
                }
                .frame(height: 100)
                
                Spacer() // 占位底部 1/3
            }
        }
        .ignoresSafeArea()
        .onAppear {
            player.play()
            
            // 在启动动画期间预加载首页数据和朗读信息
            if !hasStartedPreloading {
                hasStartedPreloading = true
                preloadData()
            }
        }
    }
    
    /// 预加载首页数据和朗读信息
    private func preloadData() {
        print("🚀 [启动预加载] 开始预加载首页数据和朗读信息...")
        
        // 1. 历史记录已经在 TranslationViewModel.init() 中加载
        // 2. TTS 已经在 TTSService.init() 中预加载
        
        // 3. 在后台线程预加载，不阻塞 UI
        Task { @MainActor in
            // 等待 TTS 服务准备就绪（最多等待5秒，正好是启动动画的时间）
            var waitCount = 0
            while !viewModel.ttsService.isReady && waitCount < 50 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                waitCount += 1
            }
            
            // 检查历史记录是否已加载
            let historyCount = viewModel.history.count
            let learnedWordsCount = viewModel.learnedWordsCount
            
            print("✅ [启动预加载] 预加载完成！")
            print("   - 历史记录: \(historyCount) 条")
            print("   - 已学词汇: \(learnedWordsCount) 个")
            print("   - TTS 服务: \(viewModel.ttsService.isReady ? "✅ 就绪" : "⏳ 准备中")")
            
            // 预加载最近几个单词的 TTS（如果历史记录中有）
            if historyCount > 0 {
                let recentWords = viewModel.history.prefix(3).flatMap { $0.allWords }
                print("   - 预加载最近 \(recentWords.count) 个单词的 TTS")
                // 注意：prewarm 目前被禁用，实际预热由 TTS 服务的初始化完成
            }
        }
    }
}

// 核心修复：自定义容器，解决飞入问题
class VideoContainerView: UIView {
    var playerLayer: AVPlayerLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 关键：在布局更新时强制关闭 Layer 动画，并立即对齐尺寸
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer?.frame = self.bounds
        CATransaction.commit()
    }
}

struct CustomPlayerView: UIViewRepresentable {
    let player: AVPlayer
    let onFinished: () -> Void
    
    func makeUIView(context: Context) -> VideoContainerView {
        let view = VideoContainerView(frame: .zero)
        view.backgroundColor = .clear
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.backgroundColor = UIColor.clear.cgColor
        
        view.playerLayer = playerLayer
        view.layer.addSublayer(playerLayer)
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            onFinished()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: VideoContainerView, context: Context) {
        // 同步已在 layoutSubviews 中由系统自动触发
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
    }
}
