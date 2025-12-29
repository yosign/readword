# ReadWord 快速开始指南

## 🎯 5分钟快速上手

### 第一步：打开项目
```bash
cd /path/to/ReadWord
open ReadWord.xcodeproj
```

### 第二步：选择目标设备
- 点击 Xcode 顶部的设备选择器
- 选择 iPhone 15 Pro 或更高版本的模拟器
- 或连接真机（需要 iOS 17.4+）

### 第三步：运行项目
- 按 `⌘ + R` 或点击运行按钮
- 等待编译完成
- 应用将自动启动

### 第四步：体验功能

#### 📝 测试文字输入
1. 默认已选中"文字"模式
2. 在输入框输入：`你好世界`
3. 点击"翻译"按钮
4. 查看结果：`Hello World`
5. 点击喇叭图标听发音

#### 🎤 测试语音输入
1. 点击顶部"语音"按钮
2. 点击"开始录音"
3. 对着麦克风说：`你好世界`
4. 点击"停止录音"
5. 点击"翻译"按钮
6. 查看翻译结果

#### 📷 测试拍照输入
1. 点击顶部"拍照"按钮
2. 点击"相册"按钮
3. 选择一张包含中文的图片
4. 等待识别完成
5. 点击"翻译"按钮
6. 查看翻译结果

---

## ⚠️ 常见问题

### 问题1：编译错误 "Translation is only available in iOS 17.4 or newer"
**解决方案**：
1. 打开 `ReadWord.xcodeproj`
2. 选择项目 → Target → ReadWord
3. General → Deployment Info
4. 将 Minimum Deployments 改为 iOS 17.4

### 问题2：模拟器没有 iOS 17.4+
**解决方案**：
1. Xcode → Settings → Platforms
2. 点击 "+" 下载 iOS 17.4+ 模拟器
3. 或使用真机测试

### 问题3：语音识别不工作
**解决方案**：
1. 确保已授予麦克风权限
2. 确保已授予语音识别权限
3. 模拟器可能不支持，建议使用真机

### 问题4：拍照功能不可用
**解决方案**：
1. 模拟器不支持相机
2. 请使用真机测试拍照功能
3. 相册功能在模拟器可用

### 问题5：首次翻译很慢
**解决方案**：
1. 首次使用需要下载语言包（需要网络）
2. 大约需要 1-2 分钟
3. 下载后支持离线翻译

---

## 📱 真机测试步骤

### 1. 连接设备
- 使用 USB 线连接 iPhone
- 信任此电脑

### 2. 配置签名
1. 选择项目 → Target → ReadWord
2. Signing & Capabilities
3. Team: 选择你的开发者账号
4. 如果没有，点击 "Add Account" 添加 Apple ID

### 3. 运行到真机
- 选择你的设备
- 按 `⌘ + R` 运行
- 首次运行需要在设备上信任开发者

### 4. 授予权限
应用首次运行时会请求以下权限：
- ✅ 麦克风权限（语音输入）
- ✅ 语音识别权限（语音转文字）
- ✅ 相机权限（拍照识别）
- ✅ 相册权限（选择图片）

**建议全部允许以体验完整功能**

---

## 🧪 测试用例

### 测试用例 1：简单翻译
- **输入**：你好
- **预期输出**：Hello

### 测试用例 2：长句翻译
- **输入**：今天天气真好，我们一起去公园玩吧
- **预期输出**：The weather is really nice today, let's go to the park together

### 测试用例 3：专业术语
- **输入**：人工智能正在改变世界
- **预期输出**：Artificial intelligence is changing the world

### 测试用例 4：语音识别
- **说话内容**：苹果手机
- **预期识别**：苹果手机
- **预期翻译**：Apple phone / iPhone

### 测试用例 5：OCR 识别
- **图片内容**：包含"欢迎使用"的图片
- **预期识别**：欢迎使用
- **预期翻译**：Welcome to use

---

## 🎨 UI 预览

### 主界面
```
┌─────────────────────────────┐
│      ReadWord               │
├─────────────────────────────┤
│  [文字] [语音] [拍照]       │
├─────────────────────────────┤
│  输入中文              [×]  │
│  ┌───────────────────────┐  │
│  │ 请输入要翻译的中文... │  │
│  │                       │  │
│  │                       │  │
│  └───────────────────────┘  │
├─────────────────────────────┤
│      [翻译]                 │
├─────────────────────────────┤
│  翻译结果            [🔊]   │
│  ┌───────────────────────┐  │
│  │  Hello World          │  │
│  └───────────────────────┘  │
├─────────────────────────────┤
│  历史记录                   │
│  • 你好 → Hello            │
│  • 谢谢 → Thank you        │
└─────────────────────────────┘
```

---

## 🔧 开发环境配置

### 必需工具
- ✅ macOS 14.0+
- ✅ Xcode 15.0+
- ✅ iOS 17.4+ 设备或模拟器

### 可选工具
- SwiftLint（代码规范检查）
- Instruments（性能分析）
- SF Symbols（图标资源）

---

## 📚 学习资源

### Apple 官方文档
- [Translation Framework](https://developer.apple.com/documentation/translation)
- [Speech Framework](https://developer.apple.com/documentation/speech)
- [Vision Framework](https://developer.apple.com/documentation/vision)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)

### 推荐阅读
- [Swift 编程语言](https://docs.swift.org/swift-book/)
- [iOS App 开发教程](https://developer.apple.com/tutorials/app-dev-training)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

## 🎯 下一步

完成快速开始后，你可以：

1. **查看详细文档**
   - 阅读 `README.md` 了解项目概况
   - 阅读 `DEVELOPMENT.md` 了解技术细节

2. **自定义功能**
   - 修改 UI 样式
   - 添加新的翻译语言
   - 实现单词本功能

3. **性能优化**
   - 添加缓存机制
   - 优化图片处理
   - 改进错误处理

4. **发布应用**
   - 准备 App Store 资源
   - 配置证书和描述文件
   - 提交审核

---

## 💡 小贴士

### 提高翻译质量
- 输入完整的句子而非单词
- 使用标准的中文表达
- 避免网络用语和缩写

### 提高语音识别准确度
- 在安静的环境中使用
- 清晰地发音
- 使用标准普通话
- 避免说话太快

### 提高 OCR 识别率
- 使用清晰的图片
- 确保光线充足
- 文字应该水平放置
- 避免反光和阴影

---

## 🆘 获取帮助

遇到问题？

1. 查看 [README.md](README.md) 的常见问题部分
2. 查看 [DEVELOPMENT.md](DEVELOPMENT.md) 的技术细节
3. 提交 Issue 到 GitHub
4. 发送邮件到 your-email@example.com

---

**祝你使用愉快！** 🎉

如果觉得项目有帮助，请给个 ⭐️ Star！

