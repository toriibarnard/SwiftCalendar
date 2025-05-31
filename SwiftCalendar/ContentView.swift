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
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text("Working Hours")
                        Spacer()
                        Text("9:00 AM - 5:00 PM")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text("Notifications")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .labelsHidden()
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
