//
//  ContentView.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-05-24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // Main app content (for now, just a simple logged-in view)
                VStack(spacing: 20) {
                    Text("🎉 Welcome to Swift Calendar!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("You're successfully logged in!")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    if let user = authViewModel.currentUser {
                        Text("Email: \(user.email)")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                    
                    Button("Sign Out") {
                        authViewModel.signOut()
                    }
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding()
            } else {
                // Show authentication view when not logged in
                AuthenticationView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationViewModel())
}
