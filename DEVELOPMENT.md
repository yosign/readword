# ReadWord 开发文档

## 技术架构详解

### 1. 翻译服务 (TranslationService)

#### 使用的框架
- **Translation Framework** (iOS 17.4+)

#### 核心实现
```swift
// 创建翻译配置
let configuration = TranslationSession.Configuration(
    source: Locale.Language(identifier: "zh-Hans"),  // 简体中文
    target: Locale.Language(identifier: "en")        // 英文
)

// 创建翻译会话
let session = TranslationSession(configuration: configuration)

// 执行翻译
let response = try await session.translate(text)
```

#### 特点
- ✅ 完全离线工作（首次需下载语言包）
- ✅ 隐私保护（数据不离开设备）
- ✅ 免费使用
- ✅ 高质量翻译

#### 注意事项
- 首次使用需要网络下载语言包（约 50-100MB）
- 仅支持 iOS 17.4 及以上版本
- 不支持自定义词典

---

### 2. 文字转语音服务 (TTSService)

#### 使用的框架
- **AVFoundation** - AVSpeechSynthesizer

#### 核心实现
```swift
let utterance = AVSpeechUtterance(string: text)
utterance.voice = AVSpeechSynthesisVoice(language: "en-US")  // 美式英语
utterance.rate = 0.5      // 语速 (0.0-1.0)
utterance.volume = 1.0    // 音量 (0.0-1.0)
utterance.pitchMultiplier = 1.0  // 音调 (0.5-2.0)

synthesizer.speak(utterance)
```

#### 可用语音
- `en-US`: 美式英语
- `en-GB`: 英式英语
- `en-AU`: 澳大利亚英语

#### 控制方法
- `speak()`: 开始朗读
- `stop()`: 立即停止
- `pause()`: 暂停朗读
- `resume()`: 继续朗读

#### 代理方法
```swift
func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance)
func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance)
func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance)
```

---

### 3. 语音识别服务 (SpeechService)

#### 使用的框架
- **Speech Framework** - SFSpeechRecognizer
- **AVFoundation** - AVAudioEngine

#### 核心实现

##### 权限请求
```swift
SFSpeechRecognizer.requestAuthorization { status in
    // 处理权限状态
}
```

##### 配置音频会话
```swift
let audioSession = AVAudioSession.sharedInstance()
try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
```

##### 创建识别请求
```swift
let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
recognitionRequest.shouldReportPartialResults = true  // 实时返回部分结果
```

##### 音频输入配置
```swift
let inputNode = audioEngine.inputNode
let recordingFormat = inputNode.outputFormat(forBus: 0)

inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
    recognitionRequest.append(buffer)
}
```

#### 权限状态
- `notDetermined`: 未请求
- `denied`: 用户拒绝
- `restricted`: 系统限制
- `authorized`: 已授权

#### 最佳实践
1. 在安静环境中使用
2. 靠近麦克风说话
3. 使用标准普通话
4. 避免背景噪音

---

### 4. OCR 文字识别服务 (OCRService)

#### 使用的框架
- **Vision Framework** - VNRecognizeTextRequest

#### 核心实现

##### 创建识别请求
```swift
let request = VNRecognizeTextRequest { request, error in
    guard let observations = request.results as? [VNRecognizedTextObservation] else {
        return
    }
    
    // 提取识别的文字
    let recognizedStrings = observations.compactMap { observation in
        observation.topCandidates(1).first?.string
    }
}
```

##### 配置识别选项
```swift
request.recognitionLevel = .accurate  // 准确模式（还有 .fast 快速模式）
request.recognitionLanguages = ["zh-Hans", "zh-Hant"]  // 支持的语言
request.usesLanguageCorrection = true  // 使用语言校正
```

##### 执行识别
```swift
let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try requestHandler.perform([request])
```

#### 识别级别对比
| 级别 | 速度 | 准确度 | 适用场景 |
|------|------|--------|----------|
| `.fast` | 快 | 中等 | 实时扫描 |
| `.accurate` | 慢 | 高 | 静态图片 |

#### 支持的语言
- 简体中文 (`zh-Hans`)
- 繁体中文 (`zh-Hant`)
- 英文 (`en`)
- 日文 (`ja`)
- 韩文 (`ko`)
- 等 30+ 种语言

#### 优化建议
1. 使用清晰、高分辨率的图片
2. 确保文字清晰可见
3. 避免倾斜或变形的文字
4. 良好的光照条件

---

## MVVM 架构说明

### Model（数据模型）
- `TranslationResult`: 翻译结果
- `InputMode`: 输入模式枚举

### View（视图）
- `ContentView`: 主界面
- `CameraView`: 相机视图

### ViewModel（视图模型）
- `TranslationViewModel`: 主视图模型
  - 协调各个服务
  - 管理应用状态
  - 处理用户交互

### Service（服务层）
- `TranslationService`: 翻译
- `TTSService`: 发音
- `SpeechService`: 语音识别
- `OCRService`: 文字识别

### 数据流
```
User Input → View → ViewModel → Service → API/Framework
                ↑                    ↓
                └────── Result ──────┘
```

---

## 状态管理

### Published 属性
使用 `@Published` 属性包装器实现响应式更新：

```swift
@Published var inputText = ""
@Published var translatedText = ""
@Published var isTranslating = false
```

### ObservableObject
服务类遵循 `ObservableObject` 协议：

```swift
class TranslationService: ObservableObject {
    @Published var isLoading = false
}
```

### StateObject vs ObservedObject
- `@StateObject`: 视图拥有对象的生命周期
- `@ObservedObject`: 视图观察外部对象

---

## 错误处理

### 自定义错误类型
```swift
enum TranslationError: LocalizedError {
    case emptyText
    case unsupportedVersion
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "输入文本不能为空"
        // ...
        }
    }
}
```

### 错误处理流程
1. Service 层抛出错误
2. ViewModel 捕获错误
3. 更新 UI 状态
4. 显示错误提示

---

## 异步编程

### Async/Await
```swift
func translate() async {
    do {
        let result = try await translationService.translate(inputText)
        translatedText = result
    } catch {
        showError(message: error.localizedDescription)
    }
}
```

### Task
在 SwiftUI 中调用异步方法：
```swift
Button("翻译") {
    Task {
        await viewModel.translate()
    }
}
```

### MainActor
确保 UI 更新在主线程：
```swift
@MainActor
class TranslationViewModel: ObservableObject {
    // 所有方法都在主线程执行
}
```

---

## 性能优化

### 1. 懒加载
服务类在首次使用时才初始化：
```swift
private lazy var translationService = TranslationService()
```

### 2. 防抖动
避免频繁的翻译请求：
```swift
.onChange(of: inputText) { _, newValue in
    // 延迟执行
    Task {
        try? await Task.sleep(nanoseconds: 500_000_000)
        await translate()
    }
}
```

### 3. 图片压缩
OCR 前压缩图片：
```swift
let maxSize: CGFloat = 1920
if image.size.width > maxSize || image.size.height > maxSize {
    image = image.resized(to: maxSize)
}
```

### 4. 历史记录限制
```swift
if history.count > 50 {
    history.removeLast()
}
```

---

## 测试建议

### 单元测试
```swift
func testTranslation() async throws {
    let service = TranslationService()
    let result = try await service.translate("你好")
    XCTAssertFalse(result.isEmpty)
}
```

### UI 测试
```swift
func testTranslationFlow() throws {
    let app = XCUIApplication()
    app.launch()
    
    let textField = app.textViews.firstMatch
    textField.tap()
    textField.typeText("你好")
    
    app.buttons["翻译"].tap()
    
    XCTAssertTrue(app.staticTexts["Hello"].exists)
}
```

---

## 调试技巧

### 1. 打印日志
```swift
print("🔍 [Translation] Input: \(inputText)")
print("✅ [Translation] Result: \(result)")
```

### 2. 断点调试
在关键位置设置断点：
- 服务调用前
- 错误处理处
- 状态更新处

### 3. Instruments
使用 Xcode Instruments 分析：
- Time Profiler: 性能分析
- Allocations: 内存分析
- Leaks: 内存泄漏检测

---

## 常见问题

### Q1: Translation Framework 不可用？
**A**: 确保 iOS 版本 >= 17.4，并且已下载语言包。

### Q2: 语音识别不准确？
**A**: 
- 检查麦克风权限
- 确保环境安静
- 使用标准普通话
- 靠近麦克风说话

### Q3: OCR 识别失败？
**A**:
- 使用清晰的图片
- 确保文字清晰可见
- 避免倾斜或模糊
- 检查光照条件

### Q4: 应用崩溃？
**A**:
- 检查权限是否授予
- 查看 Console 日志
- 确保异步操作正确处理

---

## 版本兼容性

| 功能 | 最低 iOS 版本 | 说明 |
|------|--------------|------|
| Translation | iOS 17.4 | 核心功能 |
| Speech | iOS 10.0 | 语音识别 |
| Vision | iOS 13.0 | OCR |
| AVSpeechSynthesizer | iOS 7.0 | TTS |
| PhotosPicker | iOS 16.0 | 相册选择 |

**推荐最低版本**: iOS 17.4

---

## 贡献指南

1. Fork 项目
2. 创建特性分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

### 代码规范
- 使用 SwiftLint
- 遵循 Swift API 设计指南
- 添加必要的注释
- 编写单元测试

---

## 资源链接

- [Apple Translation Framework](https://developer.apple.com/documentation/translation)
- [Speech Framework](https://developer.apple.com/documentation/speech)
- [Vision Framework](https://developer.apple.com/documentation/vision)
- [AVFoundation](https://developer.apple.com/documentation/avfoundation)
- [SwiftUI](https://developer.apple.com/documentation/swiftui)

---

**Happy Coding!** 🚀

