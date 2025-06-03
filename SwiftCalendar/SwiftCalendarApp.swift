//
//  SwiftCalendarApp.swift
//  SwiftCalendar
//
//  FIXED: Removed redeclaration conflicts
//

import SwiftUI
import FirebaseCore

@main
struct SwiftCalendarApp: App {
    @StateObject private var theme = TymoreTheme.shared
    
    init() {
        FirebaseApp.configure()
        setupGlobalAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthenticationViewModel())
                .environmentObject(theme)
        }
    }
    
    private func setupGlobalAppearance() {
        // Set up global navigation appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(TymoreTheme.shared.current.secondaryBackground)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(TymoreTheme.shared.current.primaryText)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(TymoreTheme.shared.current.primaryText)
        ]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }
}
