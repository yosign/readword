# Widget 配置指南

## 📱 已完成的代码

✅ Widget UI 代码已创建：`ReadWordWidget/ReadWordWidget.swift`
✅ Deep Link 处理已添加到主应用
✅ 输入框自动聚焦功能已实现

## 🔧 Xcode 配置步骤

### 1. 添加 Widget Extension Target

1. 打开 Xcode 项目
2. 点击菜单：**File** → **New** → **Target**
3. 选择 **Widget Extension**
4. 配置：
   - Product Name: `ReadWordWidget`
   - Include Configuration Intent: **不勾选**
   - 点击 **Finish**
5. 如果提示激活 scheme，点击 **Activate**

### 2. Widget 代码已更新

✅ `ReadWordWidget/ReadWordWidget.swift` 已经更新为正确的代码
- 显示 🐤 emoji 和 ReadWord 标题
- 点击后通过 `readword://open` 打开应用
- 支持小尺寸和中尺寸

### 3. 配置 URL Scheme

✅ **已自动配置完成！**

URL Scheme `readword://` 已经添加到项目配置中，无需手动操作。

如果你想验证配置，可以在 Xcode 中查看：
1. 选择项目 → ReadWord Target → Info 标签
2. 找到 **URL Types** 部分
3. 应该能看到 `readword` scheme

### 4. 运行和测试 Widget

现在可以直接运行测试了：

1. **运行 Widget**
   - 在 Xcode 顶部，点击 Scheme 选择器（默认显示 ReadWord）
   - 切换到 **ReadWordWidget**
   - 选择目标设备（模拟器或真机）
   - 点击 **Run** 按钮（▶️）

2. **添加 Widget 到主屏幕**
   - 应用运行后会自动打开 Widget 预览
   - 或者在主屏幕长按空白处
   - 点击左上角 **+** 按钮
   - 搜索 **ReadWord**
   - 选择小尺寸或中尺寸
   - 点击 **添加 Widget**

3. **测试点击**
   - 点击 Widget
   - 应该会打开 ReadWord 应用
   - 输入框自动聚焦
   - 可以立即开始输入单词

### 5. 配置 App Groups（可选 - 用于显示历史记录）

如果以后需要 Widget 显示最近翻译的单词：

**步骤：**
1. 选择 **ReadWord** Target → **Signing & Capabilities**
2. 点击 **+ Capability** → 添加 **App Groups**
3. 勾选或创建：`group.com.readword.shared`
4. 对 **ReadWordWidget** Target 重复相同操作

### 5. 运行测试

1. 选择 ReadWordWidget Scheme
2. 选择目标设备（模拟器或真机）
3. 点击 Run
4. 在主屏幕长按添加 Widget
5. 点击 Widget 测试是否能打开应用并聚焦输入框

## 🎨 Widget 设计

- **小尺寸（systemSmall）**：显示 🐤 emoji + 标题
- **中尺寸（systemMedium）**：显示更大的 emoji + 标题 + 提示文字
- **背景**：纯白色，与应用风格一致
- **点击行为**：打开应用并自动聚焦到输入框

## 🔗 Deep Link 说明

- **URL Scheme**: `readword://open`
- **触发时机**：用户点击 Widget
- **应用行为**：
  1. 打开应用（如果未运行）
  2. 发送通知到 ContentView
  3. 延迟 0.3 秒后聚焦输入框
  4. 用户可以立即开始输入

## 📝 注意事项

1. Widget Extension 需要单独的 Bundle ID（通常是主应用 + `.widget`）
2. Widget 不能直接访问主应用的数据，需要通过 App Groups 共享
3. Widget 的刷新策略设置为 `.never`，因为它是静态的快捷方式
4. 如果需要显示动态内容（如最近翻译的词），需要配置 App Groups 并修改 Widget 代码

## 🚀 后续优化建议

1. **显示历史记录**：在中等尺寸 Widget 中显示最近翻译的 3 个单词
2. **多种样式**：提供不同颜色主题的 Widget
3. **快捷操作**：添加 Widget 配置选项（如显示的历史数量）
4. **动态更新**：根据用户使用情况更新 Widget 显示内容

