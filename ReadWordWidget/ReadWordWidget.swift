//
//  ReadWordWidget.swift
//  ReadWordWidget
//
//  桌面组件 - 快速开始翻译
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Widget 是静态的，不需要更新
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
}

// MARK: - Widget View

struct ReadWordWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            // 白色背景
            Color.white
            
            VStack(spacing: family == .systemSmall ? 8 : 12) {
                // 大号 Emoji
                Text("🐤")
                    .font(.system(size: family == .systemSmall ? 40 : 50))
                
                // 标题
                Text("ReadWord")
                    .font(.system(size: family == .systemSmall ? 14 : 16, weight: .bold))
                    .foregroundColor(.black)
                
                // 提示文字
                if family != .systemSmall {
                    Text("点击开始学习")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
        .widgetURL(URL(string: "readword://open"))
    }
}

// MARK: - Widget Configuration

struct ReadWordWidget: Widget {
    let kind: String = "ReadWordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                ReadWordWidgetEntryView(entry: entry)
                    .containerBackground(.white, for: .widget)
            } else {
                ReadWordWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color.white)
            }
        }
        .configurationDisplayName("ReadWord")
        .description("快速开始翻译单词")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    ReadWordWidget()
} timeline: {
    SimpleEntry(date: .now)
}

#Preview(as: .systemMedium) {
    ReadWordWidget()
} timeline: {
    SimpleEntry(date: .now)
}
