# 首页布局切换功能说明

## ✨ 功能概述

首页支持三种不同的布局样式，用户可以通过左上角的菜单按钮自由切换，每种布局都有独特的视觉效果和动画。

## 🎨 三种布局模式

### 1. 瀑布流布局（Waterfall）

**图标**: `square.grid.2x2`

**特点**:
- 📱 两列自适应瀑布流
- 🎯 卡片高度自适应内容
- ✨ 渐变背景 + 柔和阴影
- 🌊 错落入场动画（随机延迟 0-0.2s）
- 📊 底部显示播放按钮和例句数量

**适用场景**: 
- 浏览大量词汇
- 快速扫视多个单词

**实现文件**: `StaggeredGrid.swift` + `WordCardStaggered`

---

### 2. 散布卡片布局（Scattered）

**图标**: `square.on.square`

**特点**:
- 🎴 卡片随机旋转（-8° 到 8°）
- 📍 随机水平偏移（-20pt 到 20pt）
- 📚 层叠式纵向排列
- 💫 更大的卡片尺寸（85% 宽度）
- 🎭 深度阴影效果（模拟卡片堆叠）
- 🌀 弹性入场动画（随机延迟 0-0.3s）

**适用场景**:
- 趣味性浏览
- 强调随机性和探索感
- 适合少量词汇展示

**实现文件**: `ScatteredGrid.swift` + `WordCardScattered`

**算法细节**:
```swift
// 伪随机旋转角度（使用索引作为种子）
func randomRotation(for index: Int) -> Double {
    let seed = Double(index * 13 + 7)
    let normalized = (seed.truncatingRemainder(dividingBy: 100)) / 100
    return (normalized - 0.5) * 16 // -8 到 8 度
}

// 伪随机X偏移
func randomXOffset(for index: Int) -> CGFloat {
    let seed = Double(index * 17 + 11)
    let normalized = (seed.truncatingRemainder(dividingBy: 100)) / 100
    return CGFloat((normalized - 0.5) * 40) // -20 到 20
}
```

---

### 3. 列表布局（List）

**图标**: `list.bullet`

**特点**:
- 📋 横向长条卡片
- ⭕ 左侧圆形 Emoji 头像（80x80）
- 📝 清晰的层级信息（单词 / 翻译 / 例句数量）
- ▶️ 右侧播放按钮（圆形背景）
- 🎯 紧凑高效的信息展示
- ➡️ 左滑入场动画（随机延迟 0-0.15s）

**适用场景**:
- 快速查找特定单词
- 需要看到更多详细信息
- 一屏展示更多内容

**实现文件**: `WordListView.swift` + `WordCardList`

---

## 🔄 切换机制

### 状态管理

```swift
/// 首页布局模式枚举
enum HomeLayoutMode: String, CaseIterable {
    case waterfall = "瀑布流"
    case scattered = "散布"
    case list = "列表"
    
    var icon: String {
        switch self {
        case .waterfall: return "square.grid.2x2"
        case .scattered: return "square.on.square"
        case .list: return "list.bullet"
        }
    }
}

// ViewModel 中存储当前模式
@Published var homeLayoutMode: HomeLayoutMode = .waterfall
```

### UI 切换按钮

- 📍 **位置**: 首页左上角（仅在非翻译结果页显示）
- 🎯 **样式**: 圆形白色背景按钮 + 阴影
- 📱 **交互**: 点击弹出菜单，显示三种模式选项
- ✅ **反馈**: 当前选中的模式会显示勾选标记

```swift
Menu {
    ForEach(HomeLayoutMode.allCases, id: \.self) { mode in
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                viewModel.homeLayoutMode = mode
            }
        } label: {
            HStack {
                Image(systemName: mode.icon)
                Text(mode.rawValue)
                if viewModel.homeLayoutMode == mode {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
} label: {
    Image(systemName: viewModel.homeLayoutMode.icon)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(.orange)
        .frame(width: 44, height: 44)
        .background(
            Circle()
                .fill(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .padding(.leading, 16)
}
```

---

## 🎬 动画细节

### 1. 布局切换动画

```swift
Group {
    switch viewModel.homeLayoutMode {
    case .waterfall:
        // 瀑布流视图
    case .scattered:
        // 散布视图
    case .list:
        // 列表视图
    }
}
.transition(.opacity.combined(with: .scale(scale: 0.95)))
```

- **过渡效果**: 淡入淡出 + 轻微缩放（0.95x）
- **动画曲线**: `spring(response: 0.4, dampingFraction: 0.8)`
- **持续时间**: 约 0.4 秒

### 2. 卡片入场动画

#### 瀑布流：
```swift
.scaleEffect(appeared ? 1 : 0.8)
.opacity(appeared ? 1 : 0)
.offset(y: appeared ? 0 : 20)
.onAppear {
    let delay = Double.random(in: 0...0.2)
    withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(delay)) {
        appeared = true
    }
}
```

#### 散布卡片：
```swift
.scaleEffect(appeared ? 1 : 0.8)
.opacity(appeared ? 1 : 0)
.onAppear {
    withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double.random(in: 0...0.3))) {
        appeared = true
    }
}
```

#### 列表：
```swift
.scaleEffect(appeared ? 1 : 0.95)
.opacity(appeared ? 1 : 0)
.offset(x: appeared ? 0 : -20)
.onAppear {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double.random(in: 0...0.15))) {
        appeared = true
    }
}
```

---

## 🎯 设计原则

### 1. 一致性
- ✅ 所有布局共享相同的点击行为（进入详情页）
- ✅ 统一的颜色方案（橙色强调色）
- ✅ 相同的 Emoji 验证逻辑

### 2. 性能优化
- ✅ 使用 `LazyVStack` 和 `LazyVGrid` 延迟加载
- ✅ 伪随机算法避免每次计算（基于索引）
- ✅ 底部留白 280pt，避免被输入框遮挡

### 3. 用户体验
- ✅ 平滑的布局切换动画
- ✅ 错落有致的入场动画
- ✅ 明确的当前模式指示
- ✅ 易于访问的切换按钮

---

## 📱 响应式布局

所有布局模式都支持：
- ✅ 自动适应不同屏幕尺寸
- ✅ 安全区域处理
- ✅ 滚动到底部时保留 280pt 留白
- ✅ 顶部 60pt 占位符（避免被统计栏遮挡）

---

## 🔧 技术实现

### 文件结构

```
ReadWord/
├── Views/
│   ├── StaggeredGrid.swift       # 瀑布流布局
│   │   └── WordCardStaggered     # 瀑布流卡片
│   ├── ScatteredGrid.swift       # 散布布局
│   │   └── WordCardScattered     # 散布卡片
│   ├── WordListView.swift        # 列表布局
│   │   └── WordCardList          # 列表卡片
│   └── ContentView.swift         # 主视图（包含切换逻辑）
├── ViewModels/
│   └── TranslationViewModel.swift # 包含 HomeLayoutMode 枚举
```

### 依赖关系

- `ContentView` → 根据 `viewModel.homeLayoutMode` 渲染对应布局
- `TranslationViewModel` → 存储和管理布局模式状态
- 各布局组件 → 独立实现，无相互依赖

---

## 🎉 效果展示

### 瀑布流
- 紧凑高效
- 适合浏览大量内容
- 卡片从下往上、从透明到不透明渐入

### 散布卡片
- 趣味性强
- 模拟真实卡片堆叠
- 每张卡片轻微旋转，营造随意感

### 列表
- 信息密集
- 快速扫描
- 从左侧滑入，营造流畅感

---

## 🚀 使用建议

1. **首次使用**: 默认瀑布流布局，平衡美观与实用
2. **大量词汇**: 使用列表布局，提高信息密度
3. **娱乐浏览**: 使用散布卡片，增加趣味性
4. **快速切换**: 随时通过左上角按钮切换，状态会保存

---

## ⚙️ 后续优化方向

1. ✨ 将布局模式偏好保存到 UserDefaults
2. 🎨 支持更多自定义选项（卡片大小、间距等）
3. 📊 统计用户最常用的布局模式
4. 🌈 为不同布局添加主题色变化

---

**最后更新**: 2026-01-02  
**版本**: v2.0  
**作者**: AI Assistant

