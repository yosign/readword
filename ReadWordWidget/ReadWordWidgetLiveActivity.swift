//
//  ReadWordWidgetLiveActivity.swift
//  ReadWordWidget
//
//  Created by YoSign on 2025/12/31.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ReadWordWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ReadWordWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReadWordWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ReadWordWidgetAttributes {
    fileprivate static var preview: ReadWordWidgetAttributes {
        ReadWordWidgetAttributes(name: "World")
    }
}

extension ReadWordWidgetAttributes.ContentState {
    fileprivate static var smiley: ReadWordWidgetAttributes.ContentState {
        ReadWordWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ReadWordWidgetAttributes.ContentState {
         ReadWordWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ReadWordWidgetAttributes.preview) {
   ReadWordWidgetLiveActivity()
} contentStates: {
    ReadWordWidgetAttributes.ContentState.smiley
    ReadWordWidgetAttributes.ContentState.starEyes
}
