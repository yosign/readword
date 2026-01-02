//
//  ContentView.swift
//  ReadWord
//
//  主界面 - 极简清爽风格
//

import SwiftUI
import PhotosUI

// MARK: - 主视图（翻译结果页 + 历史列表页）

struct ContentView: View {
    @ObservedObject var viewModel: TranslationViewModel // 使用传入的预加载 ViewModel
    @FocusState private var isInputFocused: Bool
    @State private var selectedWord: WordItem?
    @State private var currentCardIndex: Int = 0
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // 1. 纯白背景
                Color.white
                    .ignoresSafeArea()
                
                // 2. 主内容区域
                ZStack {
                    if !viewModel.translatedText.isEmpty {
                        // 翻译结果页（从下往上弹出动画）
                        translationResultView
                            .padding(.top, 60) // 为顶部栏留出空间
                            .padding(.bottom, 130) // 为底部栏和毛玻璃留出空间
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .zIndex(1) // 确保在最上层
                    } else {
                        // 历史列表页或空状态（淡入淡出动画）
                        if !viewModel.history.isEmpty {
                            // 历史列表页（根据 homeLayoutMode 显示不同布局）
                            Group {
                                switch viewModel.homeLayoutMode {
                                case .waterfall:
                                    // 瀑布流布局
                                    ScrollView {
                                        VStack(spacing: 0) {
                                            Color.clear.frame(height: 60)
                                            
                                            StaggeredGrid(
                                                columns: 2,
                                                spacing: 16,
                                                items: viewModel.allDisplayWords
                                            ) { word in
                                                WordCardStaggered(word: word)
                                                    .onTapGesture {
                                                        selectedWord = word
                                                    }
                                            }
                                            .padding(.top, 16)
                                            .padding(.bottom, 280)
                                        }
                                    }
                                    .scrollIndicators(.hidden)
                                    
                                case .scattered:
                                    // 散布卡片布局（大卡片横滑）
                                    ScatteredGrid(
                                        spacing: 20,
                                        items: viewModel.allDisplayWords
                                    ) { word in
                                        WordCardScattered(word: word)
                                    }
                                    
                                case .list:
                                    // 列表布局
                                    WordListView(items: viewModel.allDisplayWords) { word in
                                        AnyView(
                                            WordCardList(word: word)
                                                .onTapGesture {
                                                    selectedWord = word
                                                }
                                        )
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        } else {
                            // 空状态
                            ScrollView {
                                VStack(spacing: 0) {
                                    Color.clear.frame(height: 60)
                                    emptyStateView
                                        .padding(.top, 100)
                                        .padding(.bottom, 280) // 增加底部内边距，确保内容不会被输入框遮挡
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                }
                // 只在翻译状态改变时动画，键盘弹出时不触发动画
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.translatedText.isEmpty)
                .animation(nil, value: isInputFocused) // 禁用键盘相关动画
                
                // 3. 顶部统计栏（浮动在顶部）
                VStack {
                    HStack {
                        // 左侧：布局切换按钮（仅在首页显示）/ 关闭按钮（翻译结果页）
                        if viewModel.translatedText.isEmpty {
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    // 循环切换布局模式
                                    let allModes = HomeLayoutMode.allCases
                                    if let currentIndex = allModes.firstIndex(of: viewModel.homeLayoutMode) {
                                        let nextIndex = (currentIndex + 1) % allModes.count
                                        viewModel.homeLayoutMode = allModes[nextIndex]
                                    }
                                }
                            } label: {
                                Image(systemName: viewModel.homeLayoutMode.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.orange)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(.white.opacity(0.9))
                                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                                    )
                                    .padding(.leading, 16)
                            }
                            .transition(.opacity.combined(with: .scale))
                        } else {
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    viewModel.clear()
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.gray)
                                    .padding(.leading, 24)
                            }
                            .transition(.opacity.combined(with: .scale))
                        }
                        
                        Spacer()
                        
                        // 中间/右侧：已学数量（仅在非翻译结果页显示）
                        if viewModel.translatedText.isEmpty {
                            Text("已学: \(viewModel.learnedWordsCount)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.orange)
                                .frame(height: 44)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(.white.opacity(0.9))
                                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                                )
                                .padding(.trailing, 16)
                                .transition(.opacity.combined(with: .scale))
                        }
                        
                        // 右侧：全屏按钮（仅在翻译结果页显示）
                        if !viewModel.translatedText.isEmpty, let firstCard = buildCards().first {
                            Button {
                                selectedWord = firstCard
                            } label: {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.orange)
                                    .padding(.trailing, 24)
                            }
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.translatedText.isEmpty)
                    .animation(nil, value: isInputFocused) // 禁用键盘相关动画
                    .background(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .mask(
                                LinearGradient(
                                    colors: [
                                        .black,
                                        .black.opacity(0.8),
                                        .clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .ignoresSafeArea(edges: .top)
                    )
                    Spacer()
                }
                
                // 4. 底部输入区域（浮动在底部）
                VStack(spacing: 12) {
                    // 仿真进度条
                    if viewModel.isTranslating {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 4)
                                
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange, .orange.opacity(0.6)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * viewModel.translationProgress, height: 4)
                            }
                        }
                        .frame(height: 4)
                        .padding(.horizontal, 40)
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .bottom)))
                    }
                    
                    // 输入框
                    HStack(spacing: 12) {
                        TextField("", text: $viewModel.inputText, prompt: Text("输入中文...").foregroundColor(.gray))
                            .font(.system(size: 18))
                            .foregroundStyle(.black)
                            .tint(.black) // 光标颜色设置为黑色
                            .focused($isInputFocused)
                            .submitLabel(.go)
                            .onSubmit {
                                Task { await viewModel.translate() }
                            }
                            .onChange(of: isInputFocused) { _, isFocused in
                                // 延迟执行，避免阻塞键盘动画
                                if isFocused {
                                    Task { @MainActor in
                                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒延迟
                                        viewModel.inputText = ""
                                    }
                                }
                            }
                        
                        // 右侧按钮区域（使用 Group 减少视图重建）
                        Group {
                            if isInputFocused {
                                // 键盘弹出时显示收起键盘按钮
                                Button {
                                    isInputFocused = false
                                } label: {
                                    Image(systemName: "keyboard.chevron.compact.down")
                                        .font(.system(size: 24))
                                        .foregroundStyle(.gray)
                                }
                            } else if viewModel.isTranslating {
                                ProgressView()
                                    .tint(.orange)
                            } else if !viewModel.inputText.isEmpty {
                                Button {
                                    isInputFocused = false
                                    Task { await viewModel.translate() }
                                } label: {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        .animation(nil, value: isInputFocused) // 禁用按钮切换动画
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(0.98)) // 略微透明
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.gray.opacity(0.15), lineWidth: 1) // 更淡的边框
                            )
                            .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4) // 更柔和的阴影
                    )
                    .padding(.horizontal, 24)
                    
                    // 历史记录快捷按钮（只在没有翻译结果时显示）
                    if !viewModel.history.isEmpty && viewModel.translatedText.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.history.prefix(5)) { record in
                                    Button {
                                        viewModel.inputText = record.sourceText
                                        Task { await viewModel.translate() }
                                    } label: {
                                        HStack(spacing: 8) {
                                            // 英文单词
                                            Text(record.mainWord.word)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(.black)
                                            
                                            // 分隔符
                                            Text("·")
                                                .font(.system(size: 14))
                                                .foregroundStyle(.gray.opacity(0.4))
                                            
                                            // 中文翻译
                                            Text(record.sourceText)
                                                .font(.system(size: 14))
                                                .foregroundStyle(.gray)
                                        }
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(.white.opacity(0.95)) // 略微透明，融入背景
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                        .stroke(Color.gray.opacity(0.15), lineWidth: 1) // 更淡的边框
                                                )
                                                // 移除阴影，避免被毛玻璃切割
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 4)
                        }
                        .clipShape(Rectangle())
                    }
                }
                .padding(.bottom, 16)
                .padding(.top, 30) // 增加顶部内边距，让毛玻璃区域向上延伸
                .frame(maxWidth: .infinity) // 确保宽度充满
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .clear,
                                    .black.opacity(0.2),
                                    .black.opacity(0.5),
                                    .black.opacity(0.8),
                                    .black,
                                    .black,
                                    .black  // 底部保持100%不透明
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .ignoresSafeArea()
                )
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isInputFocused = false
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isInputFocused = false
            }
            .sheet(item: $selectedWord) { word in
                WordDetailView(word: word, ttsService: viewModel.ttsService)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(20)
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
        .onReceive(NotificationCenter.default.publisher(for: .focusInput)) { _ in
            // 收到 Widget 打开通知，聚焦输入框
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isInputFocused = true
            }
        }
        .preferredColorScheme(.light)
        }
    }
    
    // MARK: - 翻译结果视图（横滑卡片）
    
    private var translationResultView: some View {
        VStack(spacing: 0) {
            // 横滑卡片轮播（充满剩余空间）
            let cards = buildCards()
            TabView(selection: $currentCardIndex) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, word in
                    TranslationResultCard(
                        word: word,
                        onPlayTap: {
                            viewModel.ttsService.speak(word.word)
                        },
                        onSentenceTap: {
                            if let firstSentence = word.sentences.first {
                                viewModel.ttsService.speak(firstSentence)
                            }
                        },
                        onDetailTap: {
                            selectedWord = word
                        },
                        isSpeaking: viewModel.ttsService.isSpeaking,
                        isInputFocused: isInputFocused
                    )
                    .tag(index)
                    .id("\(word.word)-\(index)") // 添加唯一ID，优化视图重建
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: viewModel.translatedText) { _, newValue in
                if !newValue.isEmpty {
                    // 移除动画，减少性能开销
                    currentCardIndex = 0
                }
            }
            
            // 页面指示器（延迟渲染，避免键盘弹出时重建）
            if cards.count > 1 && !isInputFocused {
                HStack(spacing: 8) {
                    ForEach(0..<cards.count, id: \.self) { index in
                        Circle()
                            .fill(currentCardIndex == index ? Color.orange : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("🐤")
                .font(.system(size: 140))
            
            VStack(spacing: 8) {
                Text("Ready to Learn?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.black)
                
                Text("Type a Chinese word below")
                    .font(.system(size: 16))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
    }
    
    // MARK: - 构建卡片数据
    
    private func buildCards() -> [WordItem] {
        guard let latestResult = viewModel.history.first else {
            return []
        }
        return latestResult.allWords
    }
}

// MARK: - 翻译结果卡片（横滑样式）

struct TranslationResultCard: View {
    let word: WordItem
    let onPlayTap: () -> Void
    let onSentenceTap: () -> Void
    let onDetailTap: () -> Void
    let isSpeaking: Bool
    let isInputFocused: Bool
    
    var body: some View {
        ZStack {
            // 内容区域（移除基于 isInputFocused 的动态样式，减少重建）
            VStack(spacing: 16) {
                // 1. 大号 Emoji
                Text(getValidEmoji())
                    .font(.system(size: 100))
                    .padding(.bottom, 8)
                    .onTapGesture {
                        if !isInputFocused {
                            onDetailTap()
                        }
                    }
                
                // 2. 英文单词
                Text(word.word.capitalized)
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .onTapGesture {
                        if !isInputFocused {
                            onDetailTap()
                        }
                    }
                
                // 3. 发音信息
                HStack(spacing: 12) {
                    Text(word.pronunciation.ipa)
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(.gray)
                    
                    Text(word.pronunciation.hint)
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(.gray)
                }
                .padding(.bottom, 2)
                .onTapGesture {
                    if !isInputFocused {
                        onDetailTap()
                    }
                }
                
                // 4. 中文翻译
                Text(word.cn)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.gray.opacity(0.8))
                    .onTapGesture {
                        if !isInputFocused {
                            onDetailTap()
                        }
                    }
                
                // 5. 第一个例句（点击句子即可播放）
                if !isInputFocused, let firstSentence = word.sentences.first {
                    Text(firstSentence)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.black.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.orange.opacity(0.05))
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSentenceTap()
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 20)
                }
                
                // 6. 播放单词按钮
                if !isInputFocused {
                    Button(action: onPlayTap) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .orange.opacity(0.35), radius: 12, x: 0, y: 6)
                            
                            Image(systemName: isSpeaking ? "pause.fill" : "play.fill")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(.white)
                                .offset(x: isSpeaking ? 0 : 2)
                        }
                        .frame(width: 84, height: 84)
                        .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(isSpeaking ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isSpeaking)
                    .padding(.top, 12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - 辅助方法
    
    /// 获取有效的 Emoji（如果是文字或为空则返回默认 emoji）
    private func getValidEmoji() -> String {
        let emoji = word.emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查是否为空
        if emoji.isEmpty {
            return "✨"
        }
        
        // 检查是否只包含单个 emoji 字符
        // 如果包含多个字符或包含字母数字，则认为是文字
        if emoji.count == 1 {
            let scalar = emoji.unicodeScalars.first!
            // 检查是否在 emoji 的 Unicode 范围内
            if scalar.properties.isEmoji && scalar.properties.isEmojiPresentation {
                return emoji
            }
        }
        
        // 如果是文字或其他内容，返回默认 emoji
        return "✨"
    }
}

// MARK: - 错误提示修饰器

struct ErrorAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String?
    
    func body(content: Content) -> some View {
        content
            .alert("提示", isPresented: $isPresented) {
                Button("确定", role: .cancel) { }
            } message: {
                if let message = message {
                    Text(message)
                }
            }
    }
}

extension View {
    func errorAlert(isPresented: Binding<Bool>, message: String?) -> some View {
        modifier(ErrorAlertModifier(isPresented: isPresented, message: message))
    }
}

// MARK: - 预览

#Preview {
    ContentView(viewModel: TranslationViewModel())
}
