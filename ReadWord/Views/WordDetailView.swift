//
//  WordDetailView.swift
//  ReadWord
//
//  词汇详情页
//

import SwiftUI

/// 词汇详情页（Sheet 弹出）
struct WordDetailView: View {
    @Environment(\.dismiss) var dismiss
    let word: WordItem
    let ttsService: TTSService
    @State private var currentPlayingText: String? = nil // 跟踪当前正在播放的文本
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 基础信息区
                    basicInfoSection
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // 例句区
                    sentencesSection
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // 对话区
                    dialogueSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: ttsService.isSpeaking) { _, isSpeaking in
                // 当播放结束时，清除当前播放文本
                if !isSpeaking {
                    currentPlayingText = nil
                }
            }
            .toolbar {
                // 左上角：关闭按钮（X 图标）
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
    }
    
    // MARK: - 基础信息区
    
    private var basicInfoSection: some View {
        VStack(spacing: 12) {
            // 大号 Emoji
            Text(word.emoji)
                .font(.system(size: 80))
            
            // 英文单词
            Text(word.word.capitalized)
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(.black)
            
            // 音标
            Text(word.pronunciation.ipa)
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(.gray)
            
            // 发音提示
            Text(word.pronunciation.hint)
                .font(.system(size: 16))
                .foregroundStyle(.gray)
            
            // 中文释义
            Text(word.cn)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.black.opacity(0.8))
                .padding(.top, 4)
            
            // 播放按钮
            Button {
                currentPlayingText = word.word
                ttsService.speak(word.word)
            } label: {
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
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: ttsService.isSpeaking ? 0 : 2)
                }
                .frame(width: 60, height: 60)
            }
            .scaleEffect(ttsService.isSpeaking ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: ttsService.isSpeaking)
            .padding(.top, 8)
        }
    }
    
    // MARK: - 例句区
    
    private var sentencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("例句")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.black)
            
            ForEach(Array(word.sentences.enumerated()), id: \.offset) { index, sentence in
                HStack(alignment: .top, spacing: 12) {
                    // 序号
                    Text("\(index + 1).")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.orange)
                        .frame(width: 24, alignment: .leading)
                    
                    // 例句内容（点击即可播放）
                    Text(sentence)
                        .font(.system(size: 16))
                        .foregroundStyle(.black.opacity(0.8))
                        .lineSpacing(4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            currentPlayingText = sentence
                            ttsService.speak(sentence)
                        }
                    
                    Spacer()
                    
                    // 播放图标（小喇叭）
                    Button {
                        currentPlayingText = sentence
                        ttsService.speak(sentence)
                    } label: {
                        Group {
                            if currentPlayingText == sentence && ttsService.isSpeaking {
                                // 播放时显示波形动画
                                Image(systemName: "waveform")
                                    .font(.system(size: 14, weight: .medium))
                                    .symbolEffect(.variableColor.iterative.reversing, options: .repeating)
                                    .foregroundStyle(.orange)
                            } else {
                                // 未播放时显示静态喇叭
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.gray.opacity(0.6))
                            }
                        }
                        .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 6)
            }
        }
    }
    
    // MARK: - 对话区
    
    private var dialogueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("对话")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.black)
            
            VStack(spacing: 12) {
                ForEach(Array(word.dialogue.enumerated()), id: \.element.id) { index, line in
                    HStack(alignment: .top, spacing: 0) {
                        if line.speaker == "B" {
                            Spacer(minLength: 40)
                        }
                        
                        VStack(alignment: line.speaker == "A" ? .leading : .trailing, spacing: 4) {
                            // 说话者标签
                            Text(line.speaker)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.gray)
                                .padding(.horizontal, 4)
                            
                            // 对话气泡（点击从该行开始播放到结束）
                            HStack(alignment: .center, spacing: 8) {
                                Text(line.text)
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white)
                                    .lineSpacing(4)
                                
                                // 播放图标（小喇叭）
                                Button {
                                    // 从点击的这一行开始，播放到对话结束
                                    currentPlayingText = line.text
                                    let dialogueTexts = word.dialogue.map { $0.text }
                                    let dialogueSpeakers = word.dialogue.map { $0.speaker }
                                    ttsService.speakSequentially(dialogueTexts, from: index, speakers: dialogueSpeakers)
                                } label: {
                                    Group {
                                        if currentPlayingText == line.text && ttsService.isSpeaking {
                                            // 播放时显示波形动画
                                            Image(systemName: "waveform")
                                                .font(.system(size: 12, weight: .medium))
                                                .symbolEffect(.variableColor.iterative.reversing, options: .repeating)
                                                .foregroundStyle(.white.opacity(0.9))
                                        } else {
                                            // 未播放时显示静态喇叭
                                            Image(systemName: "speaker.wave.2.fill")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundStyle(.white.opacity(0.7))
                                        }
                                    }
                                    .frame(width: 16, height: 16)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(line.speaker == "A" ? Color.orange : Color.blue)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // 从点击的这一行开始，播放到对话结束
                                currentPlayingText = line.text
                                let dialogueTexts = word.dialogue.map { $0.text }
                                let dialogueSpeakers = word.dialogue.map { $0.speaker }
                                ttsService.speakSequentially(dialogueTexts, from: index, speakers: dialogueSpeakers)
                            }
                        }
                        
                        if line.speaker == "A" {
                            Spacer(minLength: 40)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 预览

#Preview {
    WordDetailView(
        word: WordItem(
            word: "apple",
            emoji: "🍎",
            cn: "苹果",
            sentences: [
                "I eat a red apple.",
                "The apple is very sweet.",
                "Wash the big apple now.",
                "I like this crunchy apple.",
                "Put the apple in your bag.",
                "The apple falls from the tree.",
                "Give the apple to mommy."
            ],
            dialogue: [
                DialogueLine(speaker: "A", text: "Do you want an apple?"),
                DialogueLine(speaker: "B", text: "Yes, please."),
                DialogueLine(speaker: "A", text: "Here is a red apple."),
                DialogueLine(speaker: "B", text: "Thank you, it is yummy!")
            ],
            pronunciation: PronunciationData(ipa: "/ˈæp.əl/", hint: "A-pul（阿-坡）")
        ),
        ttsService: TTSService()
    )
}

