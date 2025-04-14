//
//  coupleapp_WidgetExtensionLiveActivity.swift
//  coupleapp.WidgetExtension
//
//  Created by 박지봉 on 4/9/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct coupleapp_WidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct coupleapp_WidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: coupleapp_WidgetExtensionAttributes.self) { context in
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

extension coupleapp_WidgetExtensionAttributes {
    fileprivate static var preview: coupleapp_WidgetExtensionAttributes {
        coupleapp_WidgetExtensionAttributes(name: "World")
    }
}

extension coupleapp_WidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: coupleapp_WidgetExtensionAttributes.ContentState {
        coupleapp_WidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: coupleapp_WidgetExtensionAttributes.ContentState {
         coupleapp_WidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: coupleapp_WidgetExtensionAttributes.preview) {
   coupleapp_WidgetExtensionLiveActivity()
} contentStates: {
    coupleapp_WidgetExtensionAttributes.ContentState.smiley
    coupleapp_WidgetExtensionAttributes.ContentState.starEyes
}
