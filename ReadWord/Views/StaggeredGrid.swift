//
//  StaggeredGrid.swift
//  ReadWord
//
//  瀑布流布局视图
//

import SwiftUI

/// 瀑布流布局（Pinterest风格）
struct StaggeredGrid<Content: View, T: Identifiable>: View {
    let columns: Int
    let spacing: CGFloat
    let items: [T]
    let content: (T) -> Content
    
    init(
        columns: Int = 2,
        spacing: CGFloat = 16,
        items: [T],
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.columns = columns
        self.spacing = spacing
        self.items = items
        self.content = content
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { columnIndex in
                LazyVStack(spacing: spacing) {
                    ForEach(itemsForColumn(columnIndex)) { item in
                        content(item)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, spacing)
    }
    
    private func itemsForColumn(_ columnIndex: Int) -> [T] {
        items.enumerated()
            .filter { $0.offset % columns == columnIndex }
            .map { $0.element }
    }
}

/// 卡片样式的词汇展示（用于首页瀑布流）
struct WordCardStaggered: View {
    let word: WordItem
    @StateObject private var ttsService = TTSService()
    @State private var appeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 主内容区
            VStack(spacing: 16) {
                // Emoji
                Text(getValidEmoji())
                    .font(.system(size: 70))
                    .padding(.top, 24)
                
                // 英文单词
                Text(word.word.capitalized)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // 中文翻译
                Text(word.cn)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(red: 0.98, green: 0.98, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.gray.opacity(0.08), lineWidth: 1)
            )
            .shadow(
                color: .black.opacity(0.06),
                radius: 16,
                x: 0,
                y: 8
            )
            
            // 底部信息栏
            HStack(spacing: 12) {
                // 播放按钮
                Button {
                    ttsService.speak(word.word)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: ttsService.isSpeaking ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 18))
                        Text(ttsService.isSpeaking ? "播放中" : "发音")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // 例句数量
                if !word.sentences.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 12))
                        Text("\(word.sentences.count)")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.gray.opacity(0.6))
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 12)
        }
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            // 随机延迟，创建错落有致的入场效果
            let delay = Double.random(in: 0...0.2)
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.75)
                .delay(delay)
            ) {
                appeared = true
            }
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
    ScrollView {
        StaggeredGrid(
            columns: 2,
            spacing: 16,
            items: [
                WordItem(
                    word: "apple",
                    emoji: "🍎",
                    cn: "苹果",
                    sentences: ["I eat an apple.", "The apple is red."],
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
                ),
                WordItem(
                    word: "cat",
                    emoji: "🐱",
                    cn: "猫",
                    sentences: ["The cat is cute."],
                    dialogue: [],
                    pronunciation: PronunciationData(ipa: "/kæt/", hint: "Cat")
                ),
                WordItem(
                    word: "dog",
                    emoji: "🐶",
                    cn: "狗",
                    sentences: ["The dog is friendly."],
                    dialogue: [],
                    pronunciation: PronunciationData(ipa: "/dɒɡ/", hint: "Dog")
                )
            ]
        ) { word in
            WordCardStaggered(word: word)
        }
        .padding(.top, 20)
        .padding(.bottom, 100)
    }
}

