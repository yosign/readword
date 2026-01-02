//
//  WordListView.swift
//  ReadWord
//
//  列表式卡片布局
//

import SwiftUI

/// 列表式卡片布局
struct WordListView<T: Identifiable>: View {
    let items: [T]
    let content: (T) -> AnyView
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(items) { item in
                    content(item)
                }
            }
            .padding(.top, 76) // 为顶部毛玻璃预留空间
            .padding(.horizontal, 16)
            .padding(.bottom, 280)
        }
        .scrollIndicators(.hidden)
    }
}

/// 列表卡片样式的词汇展示
struct WordCardList: View {
    let word: WordItem
    @StateObject private var ttsService = TTSService()
    @State private var appeared = false
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧圆形 Emoji
            ZStack {
                Circle()
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
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(
                        color: .black.opacity(0.06),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                Text(getValidEmoji())
                    .font(.system(size: 40))
            }
            .frame(width: 80, height: 80)
            
            // 中间文字信息
            VStack(alignment: .leading, spacing: 6) {
                Text(word.word.capitalized)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                
                Text(word.cn)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
                
                // 例句数量
                if !word.sentences.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 11))
                        Text("\(word.sentences.count) 个例句")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.gray.opacity(0.6))
                    .padding(.top, 2)
                }
            }
            
            Spacer(minLength: 12)
            
            // 右侧播放按钮
            Button {
                ttsService.speak(word.word)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: ttsService.isSpeaking ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.orange)
                        .offset(x: ttsService.isSpeaking ? 0 : 1)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.99, green: 0.99, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.gray.opacity(0.08), lineWidth: 1)
                )
                .shadow(
                    color: .black.opacity(0.04),
                    radius: 12,
                    x: 0,
                    y: 4
                )
        )
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -20)
        .onAppear {
            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.75)
                .delay(Double.random(in: 0...0.15))
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
    WordListView(
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
            )
        ]
    ) { word in
        AnyView(
            WordCardList(word: word)
        )
    }
}

