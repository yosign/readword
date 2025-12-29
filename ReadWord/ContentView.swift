//
//  ContentView.swift
//  ReadWord
//
//  主界面
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    
    @StateObject private var viewModel = TranslationViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 输入模式选择器
                        inputModeSelector
                        
                        // 输入区域
                        inputSection
                        
                        // 翻译按钮
                        translateButton
                        
                        // 结果显示区域
                        if !viewModel.translatedText.isEmpty {
                            resultSection
                        }
                        
                        // 历史记录
                        if !viewModel.history.isEmpty {
                            historySection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("ReadWord")
            .navigationBarTitleDisplayMode(.large)
            .alert("错误", isPresented: $viewModel.showError) {
                Button("确定", role: .cancel) {}
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $viewModel.showCamera) {
                CameraView { image in
                    Task {
                        await viewModel.processCameraImage(image)
                    }
                }
            }
            .onChange(of: viewModel.selectedImage) { _, newValue in
                if newValue != nil {
                    Task {
                        await viewModel.processSelectedImage()
                    }
                }
            }
        }
    }
    
    // MARK: - 输入模式选择器
    private var inputModeSelector: some View {
        HStack(spacing: 12) {
            ForEach([InputMode.text, InputMode.voice, InputMode.camera], id: \.self) { mode in
                Button {
                    viewModel.switchMode(to: mode)
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: mode.icon)
                            .font(.title2)
                        Text(mode.title)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        viewModel.currentMode == mode ?
                        Color.blue : Color.gray.opacity(0.2)
                    )
                    .foregroundColor(
                        viewModel.currentMode == mode ? .white : .primary
                    )
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - 输入区域
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("输入中文")
                    .font(.headline)
                
                Spacer()
                
                if !viewModel.inputText.isEmpty {
                    Button {
                        viewModel.clear()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // 根据不同模式显示不同的输入界面
            switch viewModel.currentMode {
            case .text:
                textInputView
                
            case .voice:
                voiceInputView
                
            case .camera:
                cameraInputView
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - 文字输入视图
    private var textInputView: some View {
        TextEditor(text: $viewModel.inputText)
            .frame(minHeight: 120)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .focused($isInputFocused)
            .overlay(
                Group {
                    if viewModel.inputText.isEmpty {
                        Text("请输入要翻译的中文...")
                            .foregroundColor(.gray)
                            .padding(.leading, 12)
                            .padding(.top, 16)
                            .allowsHitTesting(false)
                    }
                },
                alignment: .topLeading
            )
    }
    
    // MARK: - 语音输入视图
    private var voiceInputView: some View {
        VStack(spacing: 16) {
            // 显示识别的文字
            if !viewModel.speechService.recognizedText.isEmpty {
                Text(viewModel.speechService.recognizedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // 录音按钮
            Button {
                if viewModel.speechService.isRecording {
                    viewModel.stopVoiceRecognition()
                } else {
                    Task {
                        await viewModel.startVoiceRecognition()
                    }
                }
            } label: {
                HStack {
                    Image(systemName: viewModel.speechService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title)
                    Text(viewModel.speechService.isRecording ? "停止录音" : "开始录音")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.speechService.isRecording ? Color.red : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            if viewModel.speechService.isRecording {
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue)
                            .frame(width: 4, height: 20)
                            .animation(
                                Animation.easeInOut(duration: 0.5)
                                    .repeatForever()
                                    .delay(Double(index) * 0.1),
                                value: viewModel.speechService.isRecording
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - 拍照输入视图
    private var cameraInputView: some View {
        VStack(spacing: 16) {
            // 显示识别的文字
            if !viewModel.inputText.isEmpty {
                Text(viewModel.inputText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            HStack(spacing: 12) {
                // 拍照按钮
                Button {
                    viewModel.showCamera = true
                } label: {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.title)
                        Text("拍照")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // 相册选择按钮
                PhotosPicker(selection: $viewModel.selectedImage, matching: .images) {
                    VStack {
                        Image(systemName: "photo.fill")
                            .font(.title)
                        Text("相册")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            if viewModel.ocrService.isProcessing {
                ProgressView("识别中...")
            }
        }
    }
    
    // MARK: - 翻译按钮
    private var translateButton: some View {
        Button {
            isInputFocused = false
            Task {
                await viewModel.translate()
            }
        } label: {
            HStack {
                if viewModel.isTranslating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                }
                Text(viewModel.isTranslating ? "翻译中..." : "翻译")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                viewModel.inputText.isEmpty ? Color.gray : Color.blue
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.inputText.isEmpty || viewModel.isTranslating)
    }
    
    // MARK: - 结果显示区域
    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("翻译结果")
                    .font(.headline)
                
                Spacer()
                
                // 朗读按钮
                Button {
                    viewModel.speakTranslation()
                } label: {
                    Image(systemName: viewModel.ttsService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            Text(viewModel.translatedText)
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - 历史记录
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("历史记录")
                .font(.headline)
            
            ForEach(viewModel.history.prefix(5)) { record in
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.sourceText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(record.translatedText)
                        .font(.body)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .onTapGesture {
                    viewModel.inputText = record.sourceText
                    viewModel.translatedText = record.translatedText
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ContentView()
}
