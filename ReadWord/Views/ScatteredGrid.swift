//
//  ScatteredGrid.swift
//  ReadWord
//
//  散布式卡片布局（大卡片横滑）
//

import SwiftUI

/// 散布式卡片布局 - 大卡片横滑样式
struct ScatteredGrid<Content: View, T: Identifiable>: View {
    let spacing: CGFloat
    let items: [T]
    let content: (T) -> Content
    
    @State private var currentCardIndex: Int = 0
    
    init(
        spacing: CGFloat = 20,
        items: [T],
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.spacing = spacing
        self.items = items
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            if items.isEmpty {
                EmptyView()
            } else {
                VStack(spacing: 0) {
                    // 横滑卡片轮播（充满可用空间）
                    TabView(selection: $currentCardIndex) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            content(item)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: geometry.size.height - (items.count > 1 ? 50 : 0)) // 为页面指示器留出空间
                    
                    // 页面指示器（显示 当前页/总页数）
                    if items.count > 1 {
                        Text("\(currentCardIndex + 1)/\(items.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.gray)
                            .padding(.bottom, 16)
                            .frame(height: 50)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .padding(.top, 76) // 为顶部栏留出空间
        .padding(.bottom, 130) // 为底部栏留出空间
    }
}

// MARK: - 散布卡片组件（使用翻译结果页样式）

/// 散布卡片样式的词汇展示（大卡片横滑）
struct WordCardScattered: View {
    let word: WordItem
    let ttsService: TTSService
    @State private var selectedWord: WordItem?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 内容区域（参考 TranslationResultCard）
                VStack(spacing: 16) {
                    // 1. 大号 Emoji
                    Text(getValidEmoji())
                        .font(.system(size: 100))
                        .padding(.bottom, 8)
                        .onTapGesture {
                            selectedWord = word
                        }
                    
                    // 2. 英文单词
                    Text(word.word.capitalized)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .onTapGesture {
                            selectedWord = word
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
                        selectedWord = word
                    }
                    
                    // 4. 中文翻译
                    Text(word.cn)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.gray.opacity(0.8))
                        .onTapGesture {
                            selectedWord = word
                        }
                    
                    // 5. 第一个例句（点击句子即可播放）
                    if let firstSentence = word.sentences.first {
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
                                ttsService.speak(firstSentence)
                            }
                            .padding(.top, 8)
                            .padding(.horizontal, 20)
                    }
                    
                    // 6. 播放单词按钮（使用多层手势处理，确保滑动后仍可点击）
                    ZStack {
                        // 按钮视觉层
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
                            
                            Image(systemName: ttsService.isSpeaking ? "pause.fill" : "play.fill")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(.white)
                                .offset(x: ttsService.isSpeaking ? 0 : 2)
                        }
                        .frame(width: 84, height: 84)
                        .scaleEffect(ttsService.isSpeaking ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: ttsService.isSpeaking)
                        .allowsHitTesting(false) // 视觉层不接收手势
                        
                        // 透明覆盖层（完全拦截手势，优先于 TabView）
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 100, height: 100) // 更大的点击区域
                            .contentShape(Circle())
                            .allowsHitTesting(true) // 确保可以接收手势
                            .highPriorityGesture(
                                // 高优先级手势：处理点击和拖动
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        // 计算拖动距离
                                        let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                                        // 如果拖动距离很小（小于10pt），视为点击
                                        if distance < 10 {
                                            ttsService.speak(word.word)
                                        }
                                        // 如果拖动距离较大，不触发播放，但已拦截手势，TabView 不会滑动
                                    }
                            )
                    }
                    .padding(.top, 12)
                    
                    Spacer() // 填充剩余空间
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .sheet(item: $selectedWord) { word in
            WordDetailView(word: word, ttsService: ttsService)
        }
    }
    
    /// 获取有效的 Emoji
    private func getValidEmoji() -> String {
        let emoji = word.emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if emoji.isEmpty {
            return "✨"
        }
        
        if emoji.count == 1 {
            let scalar = emoji.unicodeScalars.first!
            if scalar.properties.isEmoji && scalar.properties.isEmojiPresentation {
                return emoji
            }
        }
        
        return "✨"
    }
}

// MARK: - 预览
#Preview {
    ScatteredGrid(
        items: [
            WordItem(
                word: "apple",
                emoji: "🍎",
                cn: "苹果",
                sentences: ["I eat an apple."],
                dialogue: [],
                pronunciation: PronunciationData(ipa: "/ˈæp.əl/", hint: "A-pul")
            ),
            WordItem(
                word: "banana",
                emoji: "🍌",
                cn: "香蕉",
                sentences: ["I like bananas."],
                dialogue: [],
                pronunciation: PronunciationData(ipa: "/bəˈnæn.ə/", hint: "Ba-na-na")
            )
        ]
    ) { word in
        WordCardScattered(word: word, ttsService: TTSService())
    }
}
