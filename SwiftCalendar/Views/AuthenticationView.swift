//
//  AuthenticationView.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-05-24.
//


import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var viewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App Logo/Title
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Swift Calendar")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Smart scheduling for busy people")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 30)
                
                // Form Fields
                VStack(spacing: 15) {
                    if viewModel.isSignUpMode {
                        TextField("Display Name (Optional)", text: $viewModel.displayName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if viewModel.isSignUpMode {
                        SecureField("Confirm Password", text: $viewModel.confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                // Error Message
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                // Action Button
                Button(action: {
                    if viewModel.isSignUpMode {
                        viewModel.signUp()
                    } else {
                        viewModel.signIn()
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(viewModel.isSignUpMode ? "Sign Up" : "Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(viewModel.isLoading)
                
                // Toggle Mode
                Button(action: {
                    viewModel.isSignUpMode.toggle()
                    viewModel.errorMessage = ""
                }) {
                    HStack {
                        Text(viewModel.isSignUpMode ? "Already have an account?" : "Don't have an account?")
                            .foregroundColor(.secondary)
                        Text(viewModel.isSignUpMode ? "Sign In" : "Sign Up")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.top, 50)
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationViewModel())
}