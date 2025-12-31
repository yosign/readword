//
//  SplashView.swift
//  ReadWord
//

import SwiftUI
import AVKit

struct SplashView: View {
    @Binding var isFinished: Bool
    
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
