//
//  AuthenticationView.swift
//  SwiftCalendar
//
//  ELEGANT: Sophisticated authentication - Black Butler aesthetic
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

// MARK: - Elegant Authentication View
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
                VStack(spacing: TymoreSpacing.xxxl) {
                    Spacer(minLength: geometry.size.height * 0.12)
                    
                    // Sophisticated App Logo and Branding
                    VStack(spacing: TymoreSpacing.xl) {
                        // Minimal, elegant logo
                        ZStack {
                            Circle()
                                .stroke(theme.current.borderColor, lineWidth: 1)
                                .frame(width: 100, height: 100)
                            
                            Circle()
                                .stroke(theme.current.tymoreBlue.opacity(0.3), lineWidth: 0.5)
                                .frame(width: 80, height: 80)
                            
                            ZStack {
                                Circle()
                                    .fill(theme.current.elevatedSurface)
                                    .frame(width: 60, height: 60)
                                
                                Text("T")
                                    .font(.system(size: 28, weight: .thin, design: .serif))
                                    .foregroundColor(theme.current.tymoreBlue)
                            }
                        }
                        .tymoreShadow(TymoreShadow.soft)
                        
                        // Refined branding
                        VStack(spacing: TymoreSpacing.md) {
                            Text("Tymore")
                                .font(TymoreTypography.displayLarge)
                                .fontWeight(.thin)
                                .foregroundColor(theme.current.primaryText)
                                .tracking(2)
                            
                            Text("Intelligent Scheduling Assistant")
                                .font(TymoreTypography.bodyMedium)
                                .foregroundColor(theme.current.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.bottom, TymoreSpacing.xl)
                    
                    // Elegant form fields
                    VStack(spacing: TymoreSpacing.xl) {
                        if viewModel.isSignUpMode {
                            ElegantTextField(
                                text: $viewModel.displayName,
                                placeholder: "Display Name (Optional)",
                                icon: "person",
                                isSecure: false,
                                focusedField: $focusedField,
                                field: .displayName
                            )
                        }
                        
                        ElegantTextField(
                            text: $viewModel.email,
                            placeholder: "Email Address",
                            icon: "envelope",
                            isSecure: false,
                            focusedField: $focusedField,
                            field: .email
                        )
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        
                        ElegantTextField(
                            text: $viewModel.password,
                            placeholder: "Password",
                            icon: "lock",
                            isSecure: true,
                            focusedField: $focusedField,
                            field: .password
                        )
                        
                        if viewModel.isSignUpMode {
                            ElegantTextField(
                                text: $viewModel.confirmPassword,
                                placeholder: "Confirm Password",
                                icon: "checkmark.shield",
                                isSecure: true,
                                focusedField: $focusedField,
                                field: .confirmPassword
                            )
                        }
                    }
                    .padding(.horizontal, TymoreSpacing.xl)
                    
                    // Refined error display
                    if !viewModel.errorMessage.isEmpty {
                        HStack(spacing: TymoreSpacing.md) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(theme.current.error)
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(viewModel.errorMessage)
                                .font(TymoreTypography.bodyMedium)
                                .foregroundColor(theme.current.primaryText)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(TymoreSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: TymoreRadius.md)
                                .fill(theme.current.error.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: TymoreRadius.md)
                                        .stroke(theme.current.error.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                        .padding(.horizontal, TymoreSpacing.xl)
                    }
                    
                    // Elegant action button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if viewModel.isSignUpMode {
                                viewModel.signUp()
                            } else {
                                viewModel.signIn()
                            }
                        }
                    }) {
                        HStack(spacing: TymoreSpacing.md) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: viewModel.isSignUpMode ? "person.badge.plus" : "key")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text(viewModel.isSignUpMode ? "Create Account" : "Sign In")
                                    .font(TymoreTypography.labelLarge)
                                    .fontWeight(.medium)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: TymoreRadius.md)
                                .fill(theme.current.tymoreBlue)
                        )
                        .tymoreShadow(TymoreShadow.medium)
                    }
                    .disabled(viewModel.isLoading)
                    .scaleEffect(viewModel.isLoading ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: viewModel.isLoading)
                    .padding(.horizontal, TymoreSpacing.xl)
                    
                    // Subtle mode toggle
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.isSignUpMode.toggle()
                            viewModel.errorMessage = ""
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(viewModel.isSignUpMode ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(theme.current.secondaryText)
                            
                            Text(viewModel.isSignUpMode ? "Sign In" : "Sign Up")
                                .foregroundColor(theme.current.tymoreBlue)
                                .fontWeight(.medium)
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

struct ElegantTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    let isSecure: Bool
    @FocusState.Binding var focusedField: AuthenticationView.Field?
    let field: AuthenticationView.Field
    @EnvironmentObject var theme: TymoreTheme
    @State private var isPasswordVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: TymoreSpacing.sm) {
            HStack(spacing: TymoreSpacing.md) {
                // Refined icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(
                        focusedField == field ? theme.current.tymoreBlue : theme.current.tertiaryText
                    )
                    .frame(width: 20)
                
                // Clean text field
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
                
                // Minimal visibility toggle
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
            .background(
                RoundedRectangle(cornerRadius: TymoreRadius.md)
                    .fill(theme.current.elevatedSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: TymoreRadius.md)
                            .stroke(
                                focusedField == field
                                ? theme.current.tymoreBlue.opacity(0.5)
                                : theme.current.borderColor,
                                lineWidth: focusedField == field ? 1 : 0.5
                            )
                    )
            )
            .tymoreShadow(focusedField == field ? TymoreShadow.focus : TymoreShadow.subtle)
            .animation(.easeInOut(duration: 0.2), value: focusedField == field)
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(TymoreTheme.shared)
}
