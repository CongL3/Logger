//
//  LoggerSpikeApp.swift
//  LoggerSpike
//
//  Created by Cong Le on 20/08/2024.
//

import SwiftUI

@main
struct LoggerSpikeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
