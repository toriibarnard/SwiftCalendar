//
//  AuthenticationService.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-05-24.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthenticationService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    init() {
        // Listen for authentication changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.fetchUserData(uid: user.uid)
            } else {
                self?.user = nil
                self?.isAuthenticated = false
            }
        }
    }
    
    func signUp(email: String, password: String, displayName: String?) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // Create user document in Firestore
        let newUser = User(email: email, displayName: displayName)
        try await db.collection("users").document(result.user.uid).setData(from: newUser)
        
        await MainActor.run {
            self.user = newUser
            self.isAuthenticated = true
        }
    }
    
    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        user = nil
        isAuthenticated = false
    }
    
    private func fetchUserData(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching user: \(error)")
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                do {
                    let user = try snapshot.data(as: User.self)
                    DispatchQueue.main.async {
                        self?.user = user
                        self?.isAuthenticated = true
                    }
                } catch {
                    print("Error decoding user: \(error)")
                }
            }
        }
    }
}
