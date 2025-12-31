//
//  ContentView.swift
//  ReadWord
//
//  主界面 - 极简清爽风格
//

import SwiftUI
import PhotosUI

// MARK: - 主视图（极简清爽风格）

struct ContentView: View {
    @StateObject private var viewModel = TranslationViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var currentCardIndex: Int = 0
    
    var body: some View {
        ZStack {
            // 1. 纯白背景
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // 2. 主内容区域
                VStack(spacing: 24) {
                    // 顶部大 Emoji 插图 + 卡片轮播
                    if viewModel.translatedText.isEmpty {
                        // 空状态：显示学习小鸟
                        Text("🐤")
                            .font(.system(size: 140))
                            .padding(.bottom, 20)
                    } else {
                        // 有结果：横滑卡片轮播
                        let cards = buildCards()
                        TabView(selection: $currentCardIndex) {
                            ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                                TranslationCard(
                                    chineseText: card.chineseText,
                                    englishText: card.englishText,
                                    emoji: card.emoji,
                                    ipa: card.ipa,
                                    pronunciationHint: card.pronunciationHint,
                                    exampleSentence: card.exampleSentence,
                                    onPlayTap: {
                                        viewModel.ttsService.speak(card.englishText)
                                    },
                                    onSentenceTap: {
                                        viewModel.ttsService.speak(card.exampleSentence)
                                    },
                                    isSpeaking: viewModel.ttsService.isSpeaking,
                                    isInputFocused: isInputFocused
                                )
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: isInputFocused ? 280 : 480) // 键盘弹出时缩小卡片高度
                        .animation(.easeInOut(duration: 0.25), value: isInputFocused)
                        .onChange(of: viewModel.translatedText) { _, newValue in
                            // 翻译完成后自动滑动到最新的词（第一个位置）
                            if !newValue.isEmpty {
                                withAnimation {
                                    currentCardIndex = 0
                                }
                            }
                        }
                        
                        // 页面指示器 - 键盘弹出时隐藏
                        if cards.count > 1 && !isInputFocused {
                            HStack(spacing: 8) {
                                ForEach(0..<cards.count, id: \.self) { index in
                                    Circle()
                                        .fill(currentCardIndex == index ? Color.orange : Color.gray.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.top, -10)
                        }
                    }
                    
                    // 空状态文案
                    if viewModel.translatedText.isEmpty {
                        VStack(spacing: 8) {
                            Text("Ready to Learn?")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.black)
                            
                            Text("Type a Chinese word below")
                                .font(.system(size: 16))
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                    }
                }
                
                Spacer()
                
                // 3. 底部输入区域
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
                            .focused($isInputFocused)
                            .submitLabel(.go)
                            .onSubmit {
                                Task { await viewModel.translate() }
                            }
                            .onChange(of: isInputFocused) { _, isFocused in
                                if isFocused {
                                    viewModel.inputText = ""
                                }
                            }
                        
                        if viewModel.isTranslating {
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
                    .padding(.horizontal, 20)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                    )
                    .padding(.horizontal, 24)
                    
                    // 历史记录快捷按钮
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
                                            Text(record.translatedText)
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
                                                .fill(.white)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                                )
                                                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8) // 防止阴影被裁剪
                        }
                        .clipShape(Rectangle()) // 使用 Rectangle 而不是默认裁剪
                    }
                }
                .padding(.bottom, 24)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isInputFocused = false
            }
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
        .preferredColorScheme(.light)
    }
    
    // MARK: - 构建卡片数据
    
    private func buildCards() -> [CardData] {
        var cards: [CardData] = []
        
        // 当前翻译结果
        if !viewModel.translatedText.isEmpty, let currentRecord = viewModel.history.first {
            print("📊 构建卡片数据:")
            print("   - sourceText: \(currentRecord.sourceText)")
            print("   - translatedText: \(currentRecord.translatedText)")
            print("   - chineseTranslation: \(currentRecord.chineseTranslation ?? "nil")")
            print("   - emoji: \(currentRecord.emoji ?? "nil")")
            print("   - ipa: \(currentRecord.ipa ?? "nil")")
            print("   - hint: \(currentRecord.pronunciationHint ?? "nil")")
            print("   - sentence: \(currentRecord.exampleSentence ?? "nil")")
            
            cards.append(CardData(
                chineseText: currentRecord.chineseTranslation ?? currentRecord.sourceText,  // 优先使用 API 返回的中文
                englishText: currentRecord.translatedText,  // 英文单词
                emoji: currentRecord.emoji,
                exampleSentence: currentRecord.exampleSentence ?? getExampleSentence(for: currentRecord.translatedText),
                ipa: currentRecord.ipa,
                pronunciationHint: currentRecord.pronunciationHint
            ))
        }
        
        // 历史记录（最多5条，跳过第一条因为已显示）
        for record in viewModel.history.dropFirst().prefix(5) {
            cards.append(CardData(
                chineseText: record.chineseTranslation ?? record.sourceText,  // 优先使用 API 返回的中文
                englishText: record.translatedText,  // 英文单词
                emoji: record.emoji,
                exampleSentence: record.exampleSentence ?? getExampleSentence(for: record.translatedText),
                ipa: record.ipa,
                pronunciationHint: record.pronunciationHint
            ))
        }
        
        return cards
    }
    
    // MARK: - 例句生成
    
    private func getExampleSentence(for word: String) -> String {
        let word = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. 优先使用内置高质量例句
        if let sentence = ExampleSentenceDatabase.shared.getSentence(for: word) {
            return sentence
        }
        
        // 2. 智能生成例句（基于词性规则）
        return ExampleSentenceGenerator.generate(for: word)
    }
}

// MARK: - 卡片数据模型

struct CardData {
    let chineseText: String
    let englishText: String
    let emoji: String?
    let exampleSentence: String
    let ipa: String?
    let pronunciationHint: String?
}

// MARK: - 安全数组访问扩展

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - 例句数据库（扩展版）

class ExampleSentenceDatabase {
    static let shared = ExampleSentenceDatabase()
    
    private let sentences: [String: String] = [
        // 动物类 (Animals)
        "cat": "I have a lovely cat at home.",
        "dog": "The dog is my best friend.",
        "bird": "The bird is singing beautifully.",
        "fish": "Fish live in the water.",
        "butterfly": "Look at the colorful butterfly!",
        "bee": "The bee is collecting honey.",
        "bear": "The bear is very strong.",
        "panda": "Pandas love eating bamboo.",
        "elephant": "The elephant has a long nose.",
        "lion": "The lion is the king of animals.",
        "tiger": "The tiger runs very fast.",
        "monkey": "The monkey is climbing the tree.",
        "rabbit": "The rabbit has long ears.",
        "horse": "I can ride a horse.",
        "cow": "The cow gives us milk.",
        "sheep": "Sheep have soft wool.",
        "chicken": "The chicken lays eggs.",
        "duck": "The duck is swimming in the pond.",
        
        // 水果类 (Fruits)
        "apple": "An apple a day keeps the doctor away.",
        "banana": "I eat a banana every morning.",
        "orange": "This orange is very sweet.",
        "grape": "These grapes are delicious.",
        "strawberry": "I love fresh strawberries.",
        "watermelon": "Watermelon is my favorite summer fruit.",
        "peach": "The peach is soft and sweet.",
        "pear": "I had a pear for dessert.",
        
        // 蔬菜类 (Vegetables)
        "carrot": "Rabbits love to eat carrots.",
        "potato": "French fries are made from potatoes.",
        "tomato": "The tomato is red and juicy.",
        "cucumber": "I like cucumber salad.",
        
        // 食物类 (Food)
        "bread": "I have bread for breakfast.",
        "milk": "Milk is good for your health.",
        "egg": "I ate two eggs this morning.",
        "rice": "We eat rice every day.",
        "noodles": "These noodles taste great.",
        "cake": "Happy birthday! Here is your cake.",
        "cookie": "Can I have a cookie, please?",
        "chocolate": "Chocolate is very sweet.",
        
        // 饮料类 (Drinks)
        "water": "Drink more water every day.",
        "juice": "I love orange juice.",
        "tea": "Would you like some tea?",
        "coffee": "My mom drinks coffee in the morning.",
        
        // 日常用语 (Daily Expressions)
        "hello": "Hello! Nice to meet you.",
        "goodbye": "Goodbye! See you tomorrow.",
        "thank you": "Thank you for your help.",
        "sorry": "Sorry, I was late.",
        "please": "Please give me that book.",
        "yes": "Yes, I agree with you.",
        "no": "No, I don't think so.",
        
        // 情感类 (Feelings)
        "happy": "I am very happy today.",
        "sad": "Don't be sad, everything will be fine.",
        "love": "I love my family very much.",
        "like": "I like playing football.",
        
        // 家庭类 (Family)
        "father": "My father works in a hospital.",
        "mother": "My mother cooks very well.",
        "brother": "I have a younger brother.",
        "sister": "My sister is a teacher.",
        "family": "I love my family.",
        
        // 地点类 (Places)
        "home": "There is no place like home.",
        "school": "I go to school by bus.",
        "park": "We play in the park on weekends.",
        "library": "I borrow books from the library.",
        "hospital": "The doctor works in a hospital.",
        "shop": "Let's go to the shop.",
        
        // 交通工具 (Transportation)
        "car": "My father drives a car.",
        "bus": "I take the bus to school.",
        "bike": "I can ride a bike.",
        "train": "The train is very fast.",
        "plane": "We flew to Beijing by plane.",
        
        // 学习用品 (School Supplies)
        "book": "Reading books is fun.",
        "pen": "I write with a pen.",
        "pencil": "My pencil is broken.",
        "bag": "I put my books in the bag.",
        "desk": "My desk is very clean.",
        "chair": "Please sit on the chair.",
        
        // 颜色类 (Colors)
        "red": "My favorite color is red.",
        "blue": "The sky is blue.",
        "green": "Trees are green in spring.",
        "yellow": "The sun is yellow.",
        "black": "I have a black cat.",
        "white": "Snow is white.",
        "pink": "She is wearing a pink dress.",
        
        // 自然类 (Nature)
        "sun": "The sun is shining today.",
        "moon": "The moon is bright tonight.",
        "star": "I can see many stars in the sky.",
        "tree": "The tree is very tall.",
        "flower": "The flower smells wonderful.",
        "grass": "The grass is very green.",
        "rain": "It will rain tomorrow.",
        "snow": "I love playing in the snow.",
        
        // 身体部位 (Body Parts)
        "head": "My head hurts a little.",
        "eye": "I have two eyes.",
        "ear": "Rabbits have long ears.",
        "nose": "The dog has a wet nose.",
        "mouth": "Open your mouth, please.",
        "hand": "Wash your hands before eating.",
        "foot": "My foot is tired.",
        
        // 衣物类 (Clothes)
        "shirt": "I'm wearing a new shirt.",
        "dress": "That dress is very pretty.",
        "shoes": "My shoes are comfortable.",
        "hat": "He is wearing a red hat.",
        
        // 数字类 (Numbers)
        "one": "I have one brother.",
        "two": "Two plus two equals four.",
        "three": "There are three apples.",
        "ten": "I can count to ten.",
        
        // 时间类 (Time)
        "today": "Today is a beautiful day.",
        "tomorrow": "See you tomorrow.",
        "yesterday": "I went shopping yesterday.",
        "morning": "Good morning, everyone!",
        "night": "Good night, sleep well.",
        
        // 其他常用词
        "friend": "He is my best friend.",
        "teacher": "My teacher is very kind.",
        "student": "I am a student.",
        "birthday": "Happy birthday to you!",
        "toy": "I have many toys.",
        "music": "I like listening to music.",
        "game": "Let's play a game together."
    ]
    
    func getSentence(for word: String) -> String? {
        return sentences[word.lowercased()]
    }
}

// MARK: - 智能例句生成器

struct ExampleSentenceGenerator {
    static func generate(for word: String) -> String {
        let word = word.lowercased()
        
        // 更智能的判断：根据单词长度和特征选择合适的模板
        if word.count <= 4 {
            // 短单词通常是基础词，用简单句型
            return "Look! This is \(word)."
        } else if word.hasSuffix("ing") {
            // -ing 结尾，可能是动名词
            return "I enjoy \(word)."
        } else if word.hasSuffix("ly") {
            // 副词
            return "He speaks \(word)."
        } else {
            // 默认名词句型
            return "This is a \(word)."
        }
    }
}

// MARK: - 翻译卡片（简洁版）

struct TranslationCard: View {
    let chineseText: String
    let englishText: String
    let emoji: String?
    let ipa: String?
    let pronunciationHint: String?
    let exampleSentence: String?
    let onPlayTap: () -> Void
    let onSentenceTap: () -> Void
    let isSpeaking: Bool
    let isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: isInputFocused ? 10 : 16) {
            // 1. 大号 Emoji（视觉焦点）
            Text(emoji ?? getEmoji(for: englishText))
                .font(.system(size: isInputFocused ? 60 : 100))
                .padding(.bottom, isInputFocused ? 4 : 8)
                .animation(.easeInOut(duration: 0.2), value: isInputFocused)
            
            // 2. 英文单词（主要内容）
            Text(englishText.capitalized)
                .font(.system(size: isInputFocused ? 28 : 42, weight: .black, design: .rounded))
                .foregroundStyle(.black)
                .animation(.easeInOut(duration: 0.2), value: isInputFocused)
            
            // 3. 发音信息行（音标 + 中文提示 统一灰色样式）
            HStack(spacing: 12) {
                if let ipa = ipa, !ipa.isEmpty {
                    Text(ipa)
                        .font(.system(size: isInputFocused ? 14 : 16, design: .serif))
                        .foregroundStyle(.gray)
                }
                
                if let hint = pronunciationHint, !hint.isEmpty {
                    Text(hint)
                        .font(.system(size: isInputFocused ? 14 : 16, design: .serif))
                        .foregroundStyle(.gray)
                }
            }
            .padding(.bottom, 2)
            
            // 4. 中文翻译
            Text(chineseText)
                .font(.system(size: isInputFocused ? 14 : 16, weight: .medium))
                .foregroundStyle(.gray.opacity(0.8))
            
            // 5. 例句区域（去掉标题和分割线，采用卡片包裹）
            if !isInputFocused, let sentence = exampleSentence {
                Button(action: onSentenceTap) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.orange)
                        
                        Text(sentence)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.orange.opacity(0.05))
                    )
                }
                .padding(.top, 8)
                .padding(.horizontal, 20)
            }
            
            // 6. 播放单词按钮（升级为大圆按钮）
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
                            .offset(x: isSpeaking ? 0 : 2) // 播放图标视觉对齐修正
                    }
                    .frame(width: 84, height: 84)
                }
                .scaleEffect(isSpeaking ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSpeaking)
                .padding(.top, 12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, isInputFocused ? 12 : 20)
    }
    
    // 根据单词返回对应的 Emoji
    private func getEmoji(for word: String) -> String {
        let word = word.lowercased()
        let emojiMap: [String: String] = [
            "cat": "🐱", "dog": "🐶", "bird": "🐦", "fish": "🐟",
            "butterfly": "🦋", "bee": "🐝", "bear": "🐻", "panda": "🐼",
            "apple": "🍎", "banana": "🍌", "orange": "🍊", "grape": "🍇",
            "hello": "👋", "love": "❤️", "star": "⭐", "sun": "☀️",
            "moon": "🌙", "tree": "🌳", "flower": "🌸", "book": "📚",
            "home": "🏠", "school": "🏫", "car": "🚗", "phone": "📱"
        ]
        return emojiMap[word] ?? "✨"
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
    ContentView()
}
