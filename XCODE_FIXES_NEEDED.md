# Xcode 手动修复清单

## ⚠️ 需要在 Xcode 中手动修复的问题

### 1. Widget 版本号不匹配 ⚠️

**错误信息**:
```
The CFBundleVersion of an app extension ('1') must match that of its containing parent app ('2').
```

**修复步骤**:
1. 在 Xcode 中打开项目
2. 选择 `ReadWordWidget` target
3. 在 General 选项卡中，找到 Version 和 Build
4. 确保与主应用 `ReadWord` 的版本号一致
   - Version: 1.0
   - Build: 2（或与主应用相同）

**或者使用命令行修复**:
```bash
# 在项目根目录执行
cd ReadWord
agvtool new-version -all 2
```

### 2. 新文件添加到 Xcode 项目 ⚠️

**需要添加的文件**:
- ✅ `ReadWord/Views/WordCard.swift`
- ✅ `ReadWord/Views/WordDetailView.swift`
- ✅ `ReadWord/Views/StaggeredGrid.swift`
- 🆕 `ReadWord/Views/ScatteredGrid.swift`
- 🆕 `ReadWord/Views/WordListView.swift`

**添加步骤**:
1. 在 Xcode 中右键点击 `Views` 文件夹
2. 选择 "Add Files to ReadWord..."
3. 选择上述新增的文件（ScatteredGrid.swift 和 WordListView.swift）
4. 确保勾选 "Copy items if needed"
5. 确保 Target Membership 选中 `ReadWord`

**注意**: 如果文件已存在但不在项目中，可以直接拖拽到 Xcode 的 Views 文件夹中

## ✅ 已修复的问题

### 1. ContentView 布局问题 ✓
- 翻译结果页充满全屏
- Emoji 验证和默认值
- 查看详情改为全屏图标

### 2. AccentColor 资源问题 ✓
- 移除了重复的 unassigned 颜色定义

### 3. 代码语法错误 ✓
- 修复了负数运算符的使用

## 🔍 验证步骤

1. **清理项目**
   ```
   Product → Clean Build Folder (⇧⌘K)
   ```

2. **重新构建**
   ```
   Product → Build (⌘B)
   ```

3. **运行测试**
   - 选择模拟器或真机
   - 点击运行 (⌘R)

4. **检查 Widget**
   - 确保 Widget 可以正常添加到主屏幕
   - 测试 Widget 的交互功能

## 📝 注意事项

- Widget 和主应用必须保持相同的版本号和构建号
- 如果使用自动版本管理，确保所有 target 都启用
- 新添加的 Swift 文件必须在 Xcode 中正确添加到项目

## 🚀 完成后

所有问题修复后，项目应该可以正常编译和运行。如果还有其他错误，请查看 Xcode 的 Issue Navigator (⌘5) 获取详细信息。

