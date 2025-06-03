//
//  ContentView.swift
//  SwiftCalendar
//
//  FIXED: Removed ambiguous init issues
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
                // Main app content with tab view
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
                    
                    TymoreProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                        .tag(2)
                }
                .tint(theme.current.tymoreBlue) // Custom tint color
                .background(theme.current.primaryBackground)
                .preferredColorScheme(theme.isDarkMode ? .dark : .light)
                .onAppear {
                    setupTabBarAppearance()
                    
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
                // Show authentication view when not logged in
                AuthenticationView()
                    .preferredColorScheme(theme.isDarkMode ? .dark : .light)
            }
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        
        if theme.isDarkMode {
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(theme.current.secondaryBackground)
            
            // Selected item
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(theme.current.tymoreBlue)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(theme.current.tymoreBlue)
            ]
            
            // Normal item
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(theme.current.tertiaryText)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(theme.current.tertiaryText)
            ]
        } else {
            appearance.configureWithDefaultBackground()
        }
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

struct TymoreProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: TymoreSpacing.xl) {
                    // Profile Header
                    VStack(spacing: TymoreSpacing.lg) {
                        // Profile Picture with Tymore styling
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [theme.current.tymoreBlue, theme.current.tymoreSteel],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .tymoreShadow(TymoreShadow.medium)
                        
                        // User Info
                        if let user = authViewModel.currentUser {
                            VStack(spacing: TymoreSpacing.sm) {
                                if let displayName = user.displayName, !displayName.isEmpty {
                                    Text(displayName)
                                        .font(TymoreTypography.displaySmall)
                                        .foregroundColor(theme.current.primaryText)
                                }
                                
                                Text(user.email)
                                    .font(TymoreTypography.bodyMedium)
                                    .foregroundColor(theme.current.secondaryText)
                            }
                        }
                    }
                    .padding(.top, TymoreSpacing.lg)
                    
                    // Settings Section
                    VStack(spacing: TymoreSpacing.md) {
                        // Theme Toggle - Featured prominently
                        ProfileSettingCard(
                            icon: theme.isDarkMode ? "moon.fill" : "sun.max.fill",
                            title: "Appearance",
                            subtitle: theme.isDarkMode ? "Dark Mode" : "Light Mode",
                            iconColor: theme.current.tymoreAccent
                        ) {
                            HStack {
                                Text(theme.isDarkMode ? "🌙" : "☀️")
                                    .font(.title2)
                                
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
                        }
                        
                        // Time Zone Setting
                        if let user = authViewModel.currentUser {
                            ProfileSettingCard(
                                icon: "globe",
                                title: "Time Zone",
                                subtitle: user.preferences.timeZone,
                                iconColor: theme.current.tymoreBlue
                            ) {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(theme.current.tertiaryText)
                            }
                            
                            // Notifications Setting
                            ProfileSettingCard(
                                icon: "bell.fill",
                                title: "Notifications",
                                subtitle: user.preferences.notificationsEnabled ? "Enabled" : "Disabled",
                                iconColor: theme.current.success
                            ) {
                                Toggle("", isOn: .constant(user.preferences.notificationsEnabled))
                                    .tint(theme.current.tymoreBlue)
                                    .disabled(true) // Make read-only for now
                            }
                        }
                        
                        // AI Assistant Info
                        ProfileSettingCard(
                            icon: "brain.head.profile",
                            title: "AI Assistant",
                            subtitle: "Ty is ready to optimize your schedule",
                            iconColor: theme.current.tymoreSteel
                        ) {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(theme.current.tertiaryText)
                        }
                    }
                    
                    Spacer(minLength: TymoreSpacing.xl)
                    
                    // Sign Out Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            authViewModel.signOut()
                        }
                    }) {
                        HStack(spacing: TymoreSpacing.sm) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(TymoreTypography.labelLarge)
                            Text("Sign Out")
                                .font(TymoreTypography.labelLarge)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [theme.current.error, theme.current.error.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(TymoreRadius.md)
                        .tymoreShadow(TymoreShadow.soft)
                    }
                    .padding(.horizontal, TymoreSpacing.lg)
                }
                .padding(.horizontal, TymoreSpacing.lg)
            }
            .background(theme.current.primaryBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.current.secondaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

struct ProfileSettingCard<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    @ViewBuilder let trailing: Content
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        HStack(spacing: TymoreSpacing.md) {
            // Icon with background
            ZStack {
                RoundedRectangle(cornerRadius: TymoreRadius.sm)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TymoreTypography.bodyLarge)
                    .foregroundColor(theme.current.primaryText)
                
                Text(subtitle)
                    .font(TymoreTypography.bodySmall)
                    .foregroundColor(theme.current.secondaryText)
            }
            
            Spacer()
            
            // Trailing content
            trailing
        }
        .padding(TymoreSpacing.md)
        .tymoreCard()
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(TymoreTheme.shared)
}
