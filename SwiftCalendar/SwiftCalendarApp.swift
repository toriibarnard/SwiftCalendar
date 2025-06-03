//
//  SwiftCalendarApp.swift
//  SwiftCalendar
//
//  ELEGANT: Sophisticated app entry point
//

import SwiftUI
import FirebaseCore

@main
struct SwiftCalendarApp: App {
    @StateObject private var theme = TymoreTheme.shared
    
    init() {
        FirebaseApp.configure()
        setupElegantGlobalAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthenticationViewModel())
                .environmentObject(theme)
        }
    }
    
    private func setupElegantGlobalAppearance() {
        // Set up sophisticated navigation appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(TymoreTheme.shared.current.secondaryBackground)
        navAppearance.shadowColor = UIColor(TymoreTheme.shared.current.separatorColor)
        
        // Refined title styling
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(TymoreTheme.shared.current.primaryText),
            .font: UIFont.systemFont(ofSize: 18, weight: .medium)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(TymoreTheme.shared.current.primaryText),
            .font: UIFont.systemFont(ofSize: 32, weight: .light)
        ]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        
        // Elegant form styling
        UITextField.appearance().tintColor = UIColor(TymoreTheme.shared.current.tymoreBlue)
        UITextView.appearance().tintColor = UIColor(TymoreTheme.shared.current.tymoreBlue)
    }
}
