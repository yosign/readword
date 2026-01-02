//
//  WordCard.swift
//  ReadWord
//
//  词汇卡片组件
//

import SwiftUI

/// 词汇卡片（显示在首页网格列表中）
struct WordCard: View {
    let word: WordItem
    @StateObject private var ttsService = TTSService()
    
    var body: some View {
        VStack(spacing: 8) {
            // Emoji 图标
            Text(word.emoji)
                .font(.system(size: 50))
                .padding(.top, 8)
            
            // 英文单词
            Text(word.word.capitalized)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // 中文释义
            Text(word.cn)
                .font(.system(size: 14))
                .foregroundStyle(.gray)
                .lineLimit(1)
            
            Spacer()
            
            // 播放按钮
            Button {
                ttsService.speak(word.word)
            } label: {
                Image(systemName: ttsService.isSpeaking ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.orange)
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - 预览

#Preview {
    WordCard(word: WordItem(
        word: "apple",
        emoji: "🍎",
        cn: "苹果",
        sentences: ["I eat an apple."],
        dialogue: [DialogueLine(speaker: "A", text: "Do you like apples?")],
        pronunciation: PronunciationData(ipa: "/ˈæp.əl/", hint: "A-pul")
    ))
    .padding()
}

