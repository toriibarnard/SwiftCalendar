//
//  SwiftCalendarApp.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-05-24.
//

import SwiftUI
import FirebaseCore

@main
struct SwiftCalendarApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthenticationViewModel())
        }
    }
}
