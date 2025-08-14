//
//  shift_schedulerApp.swift
//  shift scheduler
//
//  Created by ああ on 2025/08/13.
//

import SwiftUI

@main
struct shift_schedulerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
