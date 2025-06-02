//
//  ContentView.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-05-24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var scheduleManager = ScheduleManager()
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
                            Label("Ty", systemImage: "message.fill")
                        }
                        .tag(1)
                    
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                        .tag(2)
                }
                .onAppear {
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
            }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                if let user = authViewModel.currentUser {
                    VStack(spacing: 8) {
                        if let displayName = user.displayName, !displayName.isEmpty {
                            Text(displayName)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Text(user.email)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                    .padding(.vertical)
                
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text("Time Zone")
                        Spacer()
                        if let user = authViewModel.currentUser {
                            Text(user.preferences.timeZone)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text("Notifications")
                        Spacer()
                        if let user = authViewModel.currentUser {
                            Toggle("", isOn: .constant(user.preferences.notificationsEnabled))
                                .labelsHidden()
                                .disabled(true) // Make read-only for now
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    authViewModel.signOut()
                }) {
                    Text("Sign Out")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationViewModel())
}
