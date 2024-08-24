//
//  AnalyticsLogScreen.swift
//  LoggerSpike
//
//  Created by Cong Le on 24/08/2024.
//

import SwiftUI

struct AnalyticsLogScreen: View {
    @ObservedObject private var logger = AnalyticsLogger.shared
    @State private var isReversed = false

    var body: some View {
        NavigationView {
            List(isReversed ? logger.events.reversed() : logger.events) { event in
                VStack(alignment: .leading) {
                    Text(event.name)
                        .font(.headline)
                    Text(event.timestamp, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Analytics Events")
            .navigationBarItems(trailing: HStack {
                Button("Reverse") {
                    isReversed.toggle()
                }
                Button("Clear") {
                    logger.clearEvents()
                }
            })
        }
    }
}
