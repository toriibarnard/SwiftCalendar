//
//  AuthenticationView.swift
//  SwiftCalendar
//
//  FIXED: Removed naming conflicts and ambiguous inits
//

import SwiftUI
import UIKit

// MARK: - Keep Original Clean Secure Field
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
        textField.textContentType = .init(rawValue: "")
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

// MARK: - Updated AuthenticationView with Tymore Theme
struct AuthenticationView: View {
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @EnvironmentObject var theme: TymoreTheme
    @FocusState private var focusedField: Field?
    
    enum Field {
        case displayName, email, password, confirmPassword
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: TymoreSpacing.xl) {
                    Spacer(minLength: geometry.size.height * 0.1)
                    
                    // App Logo and Branding
                    VStack(spacing: TymoreSpacing.lg) {
                        // Logo with gradient background inspired by your logo
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            theme.current.tymoreBlue.opacity(0.3),
                                            theme.current.tymoreSteel.opacity(0.1)
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            ZStack {
                                // Clock element
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [theme.current.tymoreBlue, theme.current.tymoreSteel],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                                    .frame(width: 50, height: 50)
                                
                                // T letter
                                Text("T")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [theme.current.tymoreBlue, theme.current.tymoreSteel],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        }
                        .tymoreShadow(TymoreShadow.medium)
                        
                        VStack(spacing: TymoreSpacing.sm) {
                            Text("Tymore")
                                .font(TymoreTypography.displayLarge)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [theme.current.tymoreBlue, theme.current.tymoreSteel],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("Intelligent scheduling for busy people")
                                .font(TymoreTypography.bodyLarge)
                                .foregroundColor(theme.current.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.bottom, TymoreSpacing.xl)
                    
                    // Form Fields with sophisticated styling
                    VStack(spacing: TymoreSpacing.lg) {
                        if viewModel.isSignUpMode {
                            TymoreTextField(
                                text: $viewModel.displayName,
                                placeholder: "Display Name (Optional)",
                                icon: "person.circle",
                                isSecure: false,
                                focusedField: $focusedField,
                                field: .displayName
                            )
                        }
                        
                        TymoreTextField(
                            text: $viewModel.email,
                            placeholder: "Email Address",
                            icon: "envelope",
                            isSecure: false,
                            focusedField: $focusedField,
                            field: .email
                        )
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        
                        TymoreTextField(
                            text: $viewModel.password,
                            placeholder: "Password",
                            icon: "lock",
                            isSecure: true,
                            focusedField: $focusedField,
                            field: .password
                        )
                        
                        if viewModel.isSignUpMode {
                            TymoreTextField(
                                text: $viewModel.confirmPassword,
                                placeholder: "Confirm Password",
                                icon: "lock.fill",
                                isSecure: true,
                                focusedField: $focusedField,
                                field: .confirmPassword
                            )
                        }
                    }
                    .padding(.horizontal, TymoreSpacing.lg)
                    
                    // Error Message
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(TymoreTypography.bodySmall)
                            .foregroundColor(theme.current.error)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, TymoreSpacing.lg)
                            .padding(.vertical, TymoreSpacing.sm)
                            .background(theme.current.error.opacity(0.1))
                            .cornerRadius(TymoreRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: TymoreRadius.sm)
                                    .stroke(theme.current.error.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal, TymoreSpacing.lg)
                    }
                    
                    // Action Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if viewModel.isSignUpMode {
                                viewModel.signUp()
                            } else {
                                viewModel.signIn()
                            }
                        }
                    }) {
                        HStack(spacing: TymoreSpacing.sm) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: viewModel.isSignUpMode ? "person.badge.plus" : "person.badge.key")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text(viewModel.isSignUpMode ? "Create Account" : "Sign In")
                                    .font(TymoreTypography.labelLarge)
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [theme.current.tymoreBlue, theme.current.tymoreSteel],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(TymoreRadius.lg)
                        .tymoreShadow(TymoreShadow.medium)
                    }
                    .disabled(viewModel.isLoading)
                    .scaleEffect(viewModel.isLoading ? 0.98 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isLoading)
                    .padding(.horizontal, TymoreSpacing.lg)
                    
                    // Toggle Mode
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.isSignUpMode.toggle()
                            viewModel.errorMessage = ""
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(viewModel.isSignUpMode ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(theme.current.secondaryText)
                            
                            Text(viewModel.isSignUpMode ? "Sign In" : "Sign Up")
                                .foregroundColor(theme.current.tymoreBlue)
                                .fontWeight(.semibold)
                        }
                        .font(TymoreTypography.bodyMedium)
                    }
                    
                    Spacer(minLength: TymoreSpacing.xl)
                }
            }
        }
        .background(theme.current.primaryBackground)
        .preferredColorScheme(theme.isDarkMode ? .dark : .light)
    }
}

struct TymoreTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    let isSecure: Bool
    @FocusState.Binding var focusedField: AuthenticationView.Field?
    let field: AuthenticationView.Field
    @EnvironmentObject var theme: TymoreTheme
    @State private var isPasswordVisible = false
    
    var body: some View {
        HStack(spacing: TymoreSpacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(focusedField == field ? theme.current.tymoreBlue : theme.current.tertiaryText)
                .frame(width: 24)
                .animation(.easeInOut(duration: 0.2), value: focusedField == field)
            
            // Text field
            Group {
                if isSecure && !isPasswordVisible {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(TymoreTypography.bodyMedium)
            .foregroundColor(theme.current.primaryText)
            .focused($focusedField, equals: field)
            
            // Password visibility toggle
            if isSecure {
                Button(action: { isPasswordVisible.toggle() }) {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.current.tertiaryText)
                }
            }
        }
        .padding(.horizontal, TymoreSpacing.lg)
        .padding(.vertical, TymoreSpacing.md)
        .background(theme.current.tertiaryBackground)
        .cornerRadius(TymoreRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: TymoreRadius.md)
                .stroke(
                    focusedField == field ? theme.current.tymoreBlue : theme.current.borderColor,
                    lineWidth: focusedField == field ? 2 : 1
                )
        )
        .tymoreShadow(focusedField == field ? TymoreShadow.soft : TymoreShadow.subtle)
        .animation(.easeInOut(duration: 0.2), value: focusedField == field)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(TymoreTheme.shared)
}
