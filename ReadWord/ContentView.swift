//
//  ContentView.swift
//  ReadWord
//
//  主界面 - 沉浸式深色 3D 卡片风格 + 陀螺仪视差
//

import SwiftUI
import PhotosUI
import CoreMotion
import Combine

// MARK: - 主视图

struct ContentView: View {
    @StateObject private var viewModel = TranslationViewModel()
    @StateObject private var motionManager = MotionManager()
    @FocusState private var isInputFocused: Bool
    
    // 控制轮播当前页码
    @State private var currentCardID: String?
    
    var body: some View {
        ZStack {
            // 1. 全局深色背景
            Color.black.ignoresSafeArea()
            
            // 背景光晕
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100 + (isInputFocused ? 0 : motionManager.roll * 20),
                            y: -200 + (isInputFocused ? 0 : motionManager.pitch * 20))
                
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: 100 + (isInputFocused ? 0 : motionManager.roll * 20),
                            y: 200 + (isInputFocused ? 0 : motionManager.pitch * 20))
            }
            .ignoresSafeArea()
            .animation(.interactiveSpring, value: motionManager.roll)
            
            VStack(spacing: 0) {
                // 2. 顶部 Logo (键盘弹起时隐藏)
                if !isInputFocused {
                    Image(systemName: "asterisk")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(isInputFocused ? 90 : 0))
                        .padding(.top, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                // 3. 3D 卡片轮播区域
                GeometryReader { geometry in
                    let size = geometry.size
                    let items = buildCarouselItems()
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        // 修复2：改用 HStack 替代 LazyHStack，解决数据错乱和复用问题
                        HStack(spacing: 0) {
                            ForEach(items) { item in
                                CarouselCard(
                                    item: item,
                                    viewModel: viewModel,
                                    motionManager: motionManager,
                                    isInputFocused: isInputFocused, // 传入焦点状态
                                    // 动态调整卡片尺寸，输入时更小
                                    cardWidth: isInputFocused ? size.width * 0.5 : size.width * 0.75,
                                    cardHeight: size.height * 0.9
                                )
                                .frame(width: size.width, height: size.height)
                                .id(item.id)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $currentCardID)
                    .onChange(of: currentCardID) { _, _ in
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                    .onAppear {
                        if currentCardID == nil, let first = items.first {
                            currentCardID = first.id
                        }
                    }
                }
                // 修复1：键盘弹起时，高度调整 (520 -> 240)，确保不被切割
                .frame(height: isInputFocused ? 240 : 520)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isInputFocused)
                
                // 4. 卡片进度指示器 (键盘弹起时隐藏)
                if !isInputFocused {
                    PageIndicator(
                        currentID: currentCardID,
                        items: buildCarouselItems()
                    )
                    .padding(.vertical, 20)
                    .transition(.opacity)
                }
                
                Spacer()
                
                // 5. 底部文字提示 (键盘弹起时隐藏)
                if !isInputFocused {
                    VStack(spacing: 8) {
                        Text(viewModel.translatedText.isEmpty ? "Start Learning" : "Word of the Moment")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        
                        Text(viewModel.translatedText.isEmpty ? "Type or speak to translate" : "Tap the big button to listen")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .padding(.bottom, 30)
                    .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isInputFocused)
        }
        // 使用 safeAreaInset 修复键盘遮挡
        .safeAreaInset(edge: .bottom) {
            BottomInputCapsule(
                viewModel: viewModel,
                isInputFocused: $isInputFocused
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 10)
        }
        .errorAlert(isPresented: $viewModel.showError, message: viewModel.errorMessage)
        .sheet(isPresented: $viewModel.showCamera) {
            CameraView { image in
                Task { await viewModel.processCameraImage(image) }
            }
        }
        .onChange(of: viewModel.selectedImage) { _, val in
            if val != nil { Task { await viewModel.processSelectedImage() } }
        }
        .preferredColorScheme(.dark)
    }
    
    // 构造显示数据
    private func buildCarouselItems() -> [CarouselItem] {
        var items: [CarouselItem] = []
        
        // 获取当前显示的文本，去除首尾空格，统一小写，用于严格去重
        // 关键修改：使用 currentSourceText 而不是 inputText，切断输入时的实时重绘
        let currentTextCleaned = viewModel.translatedText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let currentSourceCleaned = viewModel.currentSourceText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // 1. 如果有当前翻译结果，作为第一张
        if !viewModel.translatedText.isEmpty {
            items.append(CarouselItem(
                id: "current",
                text: viewModel.translatedText,
                subtext: viewModel.currentSourceText, // 使用稳定的原文
                colorType: .green,
                isInteractive: true
            ))
        } else {
            // 空状态卡片
            items.append(CarouselItem(
                id: "empty",
                text: "Ready?",
                subtext: "输入中文开始翻译",
                colorType: .green,
                isInteractive: false
            ))
        }
        
        // 2. 历史记录 (取前 5 条)
        // 核心修复：增强去重逻辑，防止 ID 或内容重复
        let filteredHistory = viewModel.history.filter { record in
            if !viewModel.translatedText.isEmpty {
                let recordTextCleaned = record.translatedText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let recordSourceCleaned = record.sourceText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
                // 如果翻译结果 OR 原文完全一致，都视为重复，隐藏该历史记录
                if recordTextCleaned == currentTextCleaned || recordSourceCleaned == currentSourceCleaned {
                    return false
                }
            }
            return true
        }
        
        for (index, record) in filteredHistory.prefix(5).enumerated() {
            items.append(CarouselItem(
                id: record.id.uuidString,
                text: record.translatedText,
                subtext: record.sourceText,
                // 交替颜色：粉、蓝、橙...
                colorType: index % 2 == 0 ? .pink : .blue,
                isInteractive: true
            ))
        }
        
        return items
    }
}

// MARK: - 3D 轮播卡片 (含陀螺仪)

struct CarouselCard: View {
    let item: CarouselItem
    @ObservedObject var viewModel: TranslationViewModel
    @ObservedObject var motionManager: MotionManager
    let isInputFocused: Bool
    
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    
    var body: some View {
        GeometryReader { proxy in
            let minX = proxy.frame(in: .global).minX
            let screenWidth = UIScreen.main.bounds.width
            let centerOffset = minX - (screenWidth - cardWidth) / 2
            
            // 基础滚动视差
            let progress = centerOffset / cardWidth
            let rotation = Double(progress) * -10
            let scale = 1.0 - (abs(progress) * 0.15)
            let opacity = 1.0 - (abs(progress) * 0.3)
            
            // 陀螺仪视差
            // 优化：键盘弹起时禁用陀螺仪，减少渲染压力
            let isFocused = abs(progress) < 0.5
            let pitch = (isFocused && !isInputFocused) ? motionManager.pitch : 0
            let roll = (isFocused && !isInputFocused) ? motionManager.roll : 0
            
            ZStack {
                // 1. 卡片背景层
                RoundedRectangle(cornerRadius: isInputFocused ? 24 : 44, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: item.colorType.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: item.colorType.colors.first!.opacity(0.3), radius: isInputFocused ? 10 : 20, x: 0, y: 10)
                
                // 2. 卡片内容层
                VStack(spacing: 0) {
                    
                    // 顶部图标区
                    Spacer()
                    
                    VStack(spacing: isInputFocused ? 4 : 16) {
                        Image(systemName: item.icon)
                            .font(.system(size: isInputFocused ? 24 : 40))
                            .foregroundStyle(.white.opacity(0.8))
                            .shadow(radius: 5)
                        
                        Text(item.subtext)
                            .font(isInputFocused ? .headline : .title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .offset(x: roll * 10, y: pitch * 10)
                    
                    Spacer()
                    
                    // 核心单词
                    Text(item.text)
                        .font(.system(size: isInputFocused ? 32 : 56, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.4)
                        .padding(.horizontal)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
                        .offset(x: roll * 15, y: pitch * 15)
                    
                    Spacer()
                    Spacer()
                    
                    // 播放按钮
                    if item.isInteractive {
                        Button {
                            // 修复：直接播放内容，不再修改 viewModel 的状态，防止 UI 错乱
                            viewModel.ttsService.speak(item.text)
                        } label: {
                            ZStack {
                                // 光晕背景
                                Circle()
                                    .fill(.white.opacity(0.2))
                                    .frame(width: isInputFocused ? 50 : 90, height: isInputFocused ? 50 : 90)
                                    .blur(radius: isInputFocused ? 5 : 10)
                                    // 仅当是当前卡片且正在播放时，才显示光晕动画
                                    .opacity(viewModel.ttsService.isSpeaking && item.id == "current" ? 1.0 : 0.0)
                                
                                // 按钮主体
                                Circle()
                                    .fill(.white)
                                    .frame(width: isInputFocused ? 44 : 80, height: isInputFocused ? 44 : 80)
                                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                                
                                // 图标
                                Image(systemName: "play.fill") // 简化逻辑，统一显示播放图标，避免状态混淆
                                    .font(.system(size: isInputFocused ? 20 : 36))
                                    .foregroundStyle(item.colorType.colors.first!)
                                    .offset(x: 4) // 视觉修正
                            }
                        }
                        .scaleEffect(viewModel.ttsService.isSpeaking && item.id == "current" ? 1.1 : 1.0)
                        .padding(.bottom, isInputFocused ? 20 : 50)
                        .offset(x: roll * 20, y: pitch * 20)
                    } else {
                        Spacer().frame(height: isInputFocused ? 60 : 130)
                    }
                }
            }
            // 3D 变换
            .frame(width: cardWidth, height: cardHeight)
            .scaleEffect(scale)
            .rotation3DEffect(
                .degrees(rotation + (isFocused ? roll * 5 : 0)),
                axis: (x: 0, y: 1, z: 0)
            )
            .rotation3DEffect(
                .degrees(isFocused ? pitch * -5 : 0),
                axis: (x: 1, y: 0, z: 0)
            )
            .opacity(opacity)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }
}

// MARK: - 陀螺仪管理器

class MotionManager: ObservableObject {
    private let manager = CMMotionManager()
    
    @Published var pitch: Double = 0.0 // 前后倾斜
    @Published var roll: Double = 0.0  // 左右倾斜
    
    init() {
        // 检查设备是否支持
        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60Hz 更新
            manager.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
                guard let self = self, let data = data else { return }
                
                // 使用 smooth 动画更新数据，避免抖动
                withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8)) {
                    // 限制最大角度，避免过度旋转 (-1 ~ 1 范围大概是 ±57度)
                    // 我们限制在 ±0.5 左右 (约30度) 即可
                    self.pitch = max(-0.5, min(0.5, data.attitude.pitch))
                    self.roll = max(-0.5, min(0.5, data.attitude.roll))
                }
            }
        } else {
            print("⚠️ Device Motion not available (Simulator?)")
        }
    }
    
    deinit {
        manager.stopDeviceMotionUpdates()
    }
}

// MARK: - 底部胶囊输入栏 (纯键盘模式 - iOS 26 液态玻璃风格)

struct BottomInputCapsule: View {
    @ObservedObject var viewModel: TranslationViewModel
    @FocusState.Binding var isInputFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // 输入图标
            Image(systemName: "keyboard")
                .foregroundStyle(.secondary) // 适配玻璃质感
                .font(.system(size: 20))
            
            // 输入框
            TextField("", text: $viewModel.inputText, prompt: Text("Input word...").foregroundColor(.gray))
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.primary) // 使用主色（深色模式下为白）
                .focused($isInputFocused)
                .submitLabel(.go)
                .onSubmit {
                    Task { await viewModel.translate() }
                }
                // 新增：当输入框获得焦点时，自动清空内容
                .onChange(of: isInputFocused) { _, isFocused in
                    if isFocused {
                        viewModel.inputText = ""
                    }
                }
            
            // 动作按钮
            if isInputFocused {
                // 收起键盘
                Button {
                    isInputFocused = false
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down.fill")
                        .font(.system(size: 28))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.inputText.isEmpty {
                // 占位
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.secondary.opacity(0.5))
            } else if viewModel.isTranslating {
                ProgressView()
                    .tint(.white)
            } else {
                Button {
                    isInputFocused = false
                    Task { await viewModel.translate() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .symbolRenderingMode(.hierarchical) // 层次感渲染
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            ZStack {
                // 1. 液态玻璃基底：超薄材质 + 混合模式
                Capsule()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark) // 强制深色磨砂感
                
                // 2. 流动光泽 (Fluid Sheen)
                Capsule()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.0), location: 0),
                                .init(color: .white.opacity(0.1), location: 0.3), // 高光流动点
                                .init(color: .white.opacity(0.0), location: 0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
            }
        )
        .clipShape(Capsule())
        .overlay(
            // 3. 边缘透镜效果 (Lensing Effect)
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.6), location: 0),   // 左上强反光
                            .init(color: .white.opacity(0.1), location: 0.5),
                            .init(color: .white.opacity(0.4), location: 1)    // 右下次反光
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .blendMode(.screen) // 混合模式增强光感
        )
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10) // 深邃投影
    }
}

// MARK: - 页面指示器

struct PageIndicator: View {
    let currentID: String?
    let items: [CarouselItem]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(items) { item in
                Capsule()
                    .fill(currentID == item.id ? Color.white : Color.white.opacity(0.3))
                    .frame(width: currentID == item.id ? 20 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentID)
            }
        }
        .padding(8)
        .background(.black.opacity(0.3))
        .clipShape(Capsule())
    }
}

// MARK: - 数据模型与扩展

struct CarouselItem: Identifiable, Hashable {
    let id: String
    let text: String
    let subtext: String
    let colorType: CardColor
    let isInteractive: Bool
    
    // Hashable 实现
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CarouselItem, rhs: CarouselItem) -> Bool {
        lhs.id == rhs.id
    }
    
    var icon: String {
        switch colorType {
        case .green: return "text.book.closed.fill"
        case .pink: return "clock.fill"
        case .blue: return "star.fill"
        }
    }
}

enum CardColor {
    case green, pink, blue
    
    var colors: [Color] {
        switch self {
        case .green:
            return [Color(red: 0.18, green: 0.49, blue: 0.20), Color(red: 0.40, green: 0.73, blue: 0.42)]
        case .pink:
            return [Color(red: 0.76, green: 0.09, blue: 0.36), Color(red: 0.96, green: 0.56, blue: 0.69)]
        case .blue:
            return [Color(red: 0.08, green: 0.40, blue: 0.75), Color(red: 0.26, green: 0.65, blue: 0.96)]
        }
    }
}

extension View {
    func errorAlert(isPresented: Binding<Bool>, message: String?) -> some View {
        alert("Error", isPresented: isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            if let message { Text(message) }
        }
    }
}

#Preview {
    ContentView()
}
