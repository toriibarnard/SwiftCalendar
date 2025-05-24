//
//  AuthenticationViewModel.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-05-24.
//


import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var displayName = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isSignUpMode = false
    @Published var isAuthenticated = false
    
    private let authService = AuthenticationService()
    private var cancellables = Set<AnyCancellable>()
    
    var currentUser: User? {
        authService.user
    }
    
    init() {
        // Bind to auth service
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
    }
    
    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    func signUp() {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await authService.signUp(
                    email: email,
                    password: password,
                    displayName: displayName.isEmpty ? nil : displayName
                )
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}