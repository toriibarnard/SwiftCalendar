//
//  AuthenticationView.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-05-24.
//


import SwiftUI
import UIKit

struct CleanSecureField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.isSecureTextEntry = true
        textField.borderStyle = .roundedRect
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.textContentType = .init(rawValue: "") // ← REDDIT SOLUTION!
        textField.passwordRules = nil
        textField.delegate = context.coordinator
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: CleanSecureField
        
        init(_ parent: CleanSecureField) {
            self.parent = parent
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let newText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
            DispatchQueue.main.async {
                self.parent.text = newText
            }
            return true
        }
    }
}

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
                    
                    CleanSecureField(text: $viewModel.password, placeholder: "Password")
                        .frame(height: 36)
                    
                    if viewModel.isSignUpMode {
                        CleanSecureField(text: $viewModel.confirmPassword, placeholder: "Confirm Password")
                            .frame(height: 36)
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
