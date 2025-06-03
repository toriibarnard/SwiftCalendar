//
//  ContentView.swift
//  SwiftCalendar
//
//  ELEGANT: Sophisticated main interface - Black Butler aesthetic
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var scheduleManager = ScheduleManager()
    @EnvironmentObject var theme: TymoreTheme
    @State private var selectedTab = 0
    @State private var showingError = false
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // Elegant main app with sophisticated tab view
                TabView(selection: $selectedTab) {
                    CalendarView(scheduleManager: scheduleManager)
                        .tabItem {
                            Label("Calendar", systemImage: "calendar")
                        }
                        .tag(0)
                    
                    ChatView(scheduleManager: scheduleManager)
                        .tabItem {
                            Label("Ty", systemImage: "brain.head.profile")
                        }
                        .tag(1)
                    
                    ElegantProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person")
                        }
                        .tag(2)
                }
                .tint(theme.current.tymoreBlue)
                .background(theme.current.primaryBackground)
                .preferredColorScheme(theme.isDarkMode ? .dark : .light)
                .onAppear {
                    setupElegantTabBarAppearance()
                    
                    // Run migration once when app loads
                    Task {
                        let migration = MigrationHelper()
                        await migration.removeWorkingHoursFromUsers()
                    }
                }
                .onChange(of: scheduleManager.errorMessage) { errorMessage in
                    showingError = !errorMessage.isEmpty
                }
                .alert("Error", isPresented: $showingError) {
                    Button("OK") {
                        scheduleManager.errorMessage = ""
                    }
                } message: {
                    Text(scheduleManager.errorMessage)
                }
            } else {
                // Elegant authentication view
                AuthenticationView()
                    .preferredColorScheme(theme.isDarkMode ? .dark : .light)
            }
        }
    }
    
    private func setupElegantTabBarAppearance() {
        let appearance = UITabBarAppearance()
        
        if theme.isDarkMode {
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(theme.current.secondaryBackground)
            
            // Refined tab appearance
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(theme.current.tymoreBlue)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(theme.current.tymoreBlue),
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]
            
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(theme.current.tertiaryText)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(theme.current.tertiaryText),
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]
        } else {
            appearance.configureWithDefaultBackground()
        }
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

struct ElegantProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: TymoreSpacing.xxxl) {
                    // Elegant profile header
                    VStack(spacing: TymoreSpacing.xl) {
                        // Refined profile picture
                        ZStack {
                            Circle()
                                .fill(theme.current.elevatedSurface)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Circle()
                                        .stroke(theme.current.borderColor, lineWidth: 1)
                                )
                            
                            Circle()
                                .fill(theme.current.tymoreBlue.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(theme.current.tymoreBlue)
                        }
                        .tymoreShadow(TymoreShadow.medium)
                        
                        // User information
                        if let user = authViewModel.currentUser {
                            VStack(spacing: TymoreSpacing.sm) {
                                if let displayName = user.displayName, !displayName.isEmpty {
                                    Text(displayName)
                                        .font(TymoreTypography.displaySmall)
                                        .fontWeight(.light)
                                        .foregroundColor(theme.current.primaryText)
                                }
                                
                                Text(user.email)
                                    .font(TymoreTypography.bodyMedium)
                                    .foregroundColor(theme.current.secondaryText)
                            }
                        }
                    }
                    .padding(.top, TymoreSpacing.xl)
                    
                    // Elegant settings section
                    VStack(spacing: TymoreSpacing.lg) {
                        // Theme toggle - prominently featured
                        ElegantSettingCard(
                            icon: theme.isDarkMode ? "moon" : "sun.max",
                            title: "Appearance",
                            subtitle: theme.isDarkMode ? "Dark Mode" : "Light Mode",
                            iconColor: theme.current.tymoreBlue
                        ) {
                            Toggle("", isOn: Binding(
                                get: { theme.isDarkMode },
                                set: { _ in
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        theme.toggleTheme()
                                    }
                                }
                            ))
                            .tint(theme.current.tymoreBlue)
                        }
                        
                        // Time zone setting
                        if let user = authViewModel.currentUser {
                            ElegantSettingCard(
                                icon: "globe",
                                title: "Time Zone",
                                subtitle: user.preferences.timeZone,
                                iconColor: theme.current.tymoreSteel
                            ) {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(theme.current.tertiaryText)
                            }
                            
                            // Notifications setting
                            ElegantSettingCard(
                                icon: "bell",
                                title: "Notifications",
                                subtitle: user.preferences.notificationsEnabled ? "Enabled" : "Disabled",
                                iconColor: theme.current.success
                            ) {
                                Toggle("", isOn: .constant(user.preferences.notificationsEnabled))
                                    .tint(theme.current.tymoreBlue)
                                    .disabled(true)
                            }
                        }
                        
                        // AI assistant info
                        ElegantSettingCard(
                            icon: "brain.head.profile",
                            title: "AI Assistant",
                            subtitle: "Ty is ready to help",
                            iconColor: theme.current.tymorePurple
                        ) {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(theme.current.tertiaryText)
                        }
                    }
                    
                    Spacer(minLength: TymoreSpacing.xxxl)
                    
                    // Elegant sign out button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            authViewModel.signOut()
                        }
                    }) {
                        HStack(spacing: TymoreSpacing.md) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .medium))
                            Text("Sign Out")
                                .font(TymoreTypography.labelLarge)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: TymoreRadius.md)
                                .fill(theme.current.error)
                        )
                        .tymoreShadow(TymoreShadow.soft)
                    }
                    .padding(.horizontal, TymoreSpacing.xl)
                }
                .padding(.horizontal, TymoreSpacing.xl)
            }
            .background(theme.current.primaryBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ElegantSettingCard<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    @ViewBuilder let trailing: Content
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        HStack(spacing: TymoreSpacing.lg) {
            // Refined icon background
            ZStack {
                RoundedRectangle(cornerRadius: TymoreRadius.sm)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: TymoreRadius.sm)
                            .stroke(iconColor.opacity(0.2), lineWidth: 0.5)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TymoreTypography.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(theme.current.primaryText)
                
                Text(subtitle)
                    .font(TymoreTypography.bodySmall)
                    .foregroundColor(theme.current.secondaryText)
            }
            
            Spacer()
            
            // Trailing content
            trailing
        }
        .padding(TymoreSpacing.lg)
        .elegantCard()
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(TymoreTheme.shared)
}
