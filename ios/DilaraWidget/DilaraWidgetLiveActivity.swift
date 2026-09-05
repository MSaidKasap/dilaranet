//
//  DilaraWidgetLiveActivity.swift
//  DilaraWidget
//
//  Created by Macbook on 21.02.2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct DilaraWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct DilaraWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DilaraWidgetAttributes.self) { context in
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

extension DilaraWidgetAttributes {
    fileprivate static var preview: DilaraWidgetAttributes {
        DilaraWidgetAttributes(name: "World")
    }
}

extension DilaraWidgetAttributes.ContentState {
    fileprivate static var smiley: DilaraWidgetAttributes.ContentState {
        DilaraWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: DilaraWidgetAttributes.ContentState {
         DilaraWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: DilaraWidgetAttributes.preview) {
   DilaraWidgetLiveActivity()
} contentStates: {
    DilaraWidgetAttributes.ContentState.smiley
    DilaraWidgetAttributes.ContentState.starEyes
}
