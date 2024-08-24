//
//  AnalyticsLogger.swift
//  LoggerSpike
//
//  Created by Cong Le on 24/08/2024.
//

import Foundation
import SwiftUI

class AnalyticsLogger: ObservableObject {
    static let shared = AnalyticsLogger()

    struct AnalyticsEvent: Identifiable {
        let id = UUID()
        let name: String
        let timestamp: Date
    }

    @Published private(set) var events: [AnalyticsEvent] = []

    func logEvent(_ event: String) {
        let newEvent = AnalyticsEvent(name: event, timestamp: Date())
        events.append(newEvent)
        
        // Limit the number of stored events
        if events.count > 100 {
            events.removeFirst()
        }
    }

    func clearEvents() {
        events.removeAll()
    }
}

class AnalyticsService {
    public static func logEvent(_ event: String) {
        let sanitisedEvent = sanitised(event)
        debugPrint("🙉 Analytics: \(sanitisedEvent)")
        AnalyticsLogger.shared.logEvent(sanitisedEvent)
        // Analytics.logEvent(sanitisedEvent, parameters: nil)
    }

    public static func logScreenEvent(_ screenName: String, className: String) {
        let sanitisedScreenName = sanitised(screenName)
        debugPrint("🙉 Analytics: \(sanitisedScreenName)")
        AnalyticsLogger.shared.logEvent(sanitisedScreenName)
        // Analytics.logEvent(AnalyticsEventScreenView,
        //                    parameters: [
        //                        AnalyticsParameterScreenName: sanitisedScreenName,
        //                        AnalyticsParameterScreenClass: sanitised(className)
        //                    ])
    }

    static func sanitised(_ event: String) -> String {
        var tag = event
        if event.count > 39 {
            tag = String(event.prefix(40))
        }
        return tag.replacingOccurrences(of: " ", with: "_")
    }
}
