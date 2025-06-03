//
//  AuthenticationView.swift
//  SwiftCalendar
//
//  ULTRA-MODERN: Futuristic authentication interface
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

// MARK: - Ultra-Modern Authentication View
struct AuthenticationView: View {
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @EnvironmentObject var theme: TymoreTheme
    @FocusState private var focusedField: Field?
    
    enum Field {
        case displayName, email, password, confirmPassword
    }
    
    var body: some View {
        ZStack {
            // Ultra-dark background with animated gradients
            LinearGradient(
                colors: [
                    theme.current.primaryBackground,
                    theme.current.secondaryBackground,
                    theme.current.primaryBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating particles effect
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(theme.current.tymoreAccent.opacity(0.1))
                    .frame(width: CGFloat.random(in: 20...40))
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 100...700)
                    )
                    .floating()
                    .neonGlow(theme.current.tymoreAccent, radius: 4)
            }
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: TymoreSpacing.xxxl) {
                        Spacer(minLength: geometry.size.height * 0.08)
                        
                        // Futuristic App Logo and Branding
                        VStack(spacing: TymoreSpacing.xl) {
                            // Ultra-modern logo with multiple glow layers
                            ZStack {
                                // Outer glow ring
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                theme.current.tymoreAccent.opacity(0.6),
                                                theme.current.tymorePurple.opacity(0.4),
                                                theme.current.tymoreBlue.opacity(0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                                    .frame(width: 140, height: 140)
                                    .neonGlow(theme.current.tymoreAccent, radius: 20)
                                    .floating()
                                
                                // Middle ring
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [theme.current.tymoreBlue, theme.current.tymorePurple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                                    .frame(width: 100, height: 100)
                                    .neonGlow(theme.current.tymoreBlue, radius: 12)
                                
                                // Inner core
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [
                                                    theme.current.tymoreBlue,
                                                    theme.current.tymorePurple,
                                                    theme.current.primaryBackground
                                                ],
                                                center: .center,
                                                startRadius: 5,
                                                endRadius: 40
                                            )
                                        )
                                        .frame(width: 80, height: 80)
                                    
                                    // Neural T logo
                                    Text("T")
                                        .font(.system(size: 42, weight: .black, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.white, theme.current.tymoreAccent],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .neonGlow(.white, radius: 8)
                                }
                            }
                            
                            // Ultra-modern branding
                            VStack(spacing: TymoreSpacing.md) {
                                HStack(spacing: TymoreSpacing.sm) {
                                    Text("TYMORE")
                                        .font(TymoreTypography.displayLarge)
                                        .fontWeight(.black)
                                        .tracking(3)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [
                                                    theme.current.tymoreAccent,
                                                    theme.current.tymorePurple,
                                                    theme.current.tymoreBlue
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .neonGlow(theme.current.tymoreAccent, radius: 12)
                                    
                                    // Version badge
                                    Text("4.0")
                                        .font(TymoreTypography.labelSmall)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(theme.current.tymoreAccent)
                                                .neonGlow(theme.current.tymoreAccent, radius: 6)
                                        )
                                }
                                
                                Text("NEURAL SCHEDULING INTELLIGENCE")
                                    .font(TymoreTypography.bodyMedium)
                                    .fontWeight(.medium)
                                    .tracking(1.5)
                                    .foregroundColor(theme.current.accentText)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.bottom, TymoreSpacing.xl)
                        
                        // Ultra-modern form fields
                        VStack(spacing: TymoreSpacing.xl) {
                            if viewModel.isSignUpMode {
                                FuturisticTextField(
                                    text: $viewModel.displayName,
                                    placeholder: "Neural Identity (Optional)",
                                    icon: "person.crop.circle.fill",
                                    isSecure: false,
                                    focusedField: $focusedField,
                                    field: .displayName
                                )
                            }
                            
                            FuturisticTextField(
                                text: $viewModel.email,
                                placeholder: "Neural Interface ID",
                                icon: "envelope.circle.fill",
                                isSecure: false,
                                focusedField: $focusedField,
                                field: .email
                            )
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            
                            FuturisticTextField(
                                text: $viewModel.password,
                                placeholder: "Security Protocol",
                                icon: "lock.circle.fill",
                                isSecure: true,
                                focusedField: $focusedField,
                                field: .password
                            )
                            
                            if viewModel.isSignUpMode {
                                FuturisticTextField(
                                    text: $viewModel.confirmPassword,
                                    placeholder: "Confirm Security Protocol",
                                    icon: "checkmark.shield.fill",
                                    isSecure: true,
                                    focusedField: $focusedField,
                                    field: .confirmPassword
                                )
                            }
                        }
                        .padding(.horizontal, TymoreSpacing.xl)
                        
                        // Neural error display
                        if !viewModel.errorMessage.isEmpty {
                            HStack(spacing: TymoreSpacing.md) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(theme.current.error)
                                    .font(.system(size: 18, weight: .bold))
                                    .neonGlow(theme.current.error, radius: 6)
                                
                                Text(viewModel.errorMessage)
                                    .font(TymoreTypography.bodyMedium)
                                    .foregroundColor(theme.current.primaryText)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(TymoreSpacing.lg)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: TymoreRadius.md)
                                        .fill(theme.current.error.opacity(0.1))
                                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: TymoreRadius.md))
                                    
                                    RoundedRectangle(cornerRadius: TymoreRadius.md)
                                        .stroke(theme.current.error, lineWidth: 1)
                                        .neonGlow(theme.current.error, radius: 8)
                                }
                            )
                            .padding(.horizontal, TymoreSpacing.xl)
                        }
                        
                        // Ultra-futuristic action button
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                if viewModel.isSignUpMode {
                                    viewModel.signUp()
                                } else {
                                    viewModel.signIn()
                                }
                            }
                        }) {
                            HStack(spacing: TymoreSpacing.md) {
                                if viewModel.isLoading {
                                    // Futuristic loading indicator
                                    ZStack {
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                            .frame(width: 20, height: 20)
                                        
                                        Circle()
                                            .trim(from: 0, to: 0.7)
                                            .stroke(Color.white, lineWidth: 2)
                                            .frame(width: 20, height: 20)
                                            .rotationEffect(.degrees(-90))
                                            .animation(
                                                .linear(duration: 1).repeatForever(autoreverses: false),
                                                value: viewModel.isLoading
                                            )
                                    }
                                } else {
                                    Image(systemName: viewModel.isSignUpMode ? "person.badge.plus.fill" : "key.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .neonGlow(.white, radius: 4)
                                    
                                    Text(viewModel.isSignUpMode ? "INITIALIZE NEURAL LINK" : "ESTABLISH CONNECTION")
                                        .font(TymoreTypography.labelLarge)
                                        .fontWeight(.black)
                                        .tracking(1)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: TymoreRadius.lg)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    theme.current.tymoreBlue,
                                                    theme.current.tymorePurple,
                                                    theme.current.tymoreAccent
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    // Animated border
                                    RoundedRectangle(cornerRadius: TymoreRadius.lg)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.6), Color.clear],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                }
                            )
                            .neonGlow(theme.current.tymoreBlue, radius: 16)
                        }
                        .disabled(viewModel.isLoading)
                        .scaleEffect(viewModel.isLoading ? 0.97 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isLoading)
                        .padding(.horizontal, TymoreSpacing.xl)
                        
                        // Neural mode toggle
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.isSignUpMode.toggle()
                                viewModel.errorMessage = ""
                            }
                        }) {
                            HStack(spacing: TymoreSpacing.sm) {
                                Text(viewModel.isSignUpMode ? "EXISTING NEURAL PROFILE?" : "NEW TO THE NETWORK?")
                                    .foregroundColor(theme.current.secondaryText)
                                    .tracking(0.5)
                                
                                Text(viewModel.isSignUpMode ? "CONNECT" : "INITIALIZE")
                                    .foregroundColor(theme.current.tymoreAccent)
                                    .fontWeight(.bold)
                                    .tracking(0.5)
                                    .neonGlow(theme.current.tymoreAccent, radius: 4)
                            }
                            .font(TymoreTypography.bodyMedium)
                        }
                        
                        Spacer(minLength: TymoreSpacing.xl)
                    }
                }
            }
        }
        .preferredColorScheme(theme.isDarkMode ? .dark : .light)
    }
}

struct FuturisticTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    let isSecure: Bool
    @FocusState.Binding var focusedField: AuthenticationView.Field?
    let field: AuthenticationView.Field
    @EnvironmentObject var theme: TymoreTheme
    @State private var isPasswordVisible = false
    
    var body: some View {
        HStack(spacing: TymoreSpacing.lg) {
            // Futuristic icon with glow
            ZStack {
                Circle()
                    .fill(
                        focusedField == field
                        ? LinearGradient(
                            colors: [theme.current.tymoreAccent, theme.current.tymorePurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [theme.current.elevatedSurface],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 44, height: 44)
                    .neonGlow(
                        focusedField == field ? theme.current.tymoreAccent : Color.clear,
                        radius: focusedField == field ? 8 : 0
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(
                        focusedField == field ? .white : theme.current.tertiaryText
                    )
            }
            
            // Neural text field
            VStack(alignment: .leading, spacing: 6) {
                Group {
                    if isSecure && !isPasswordVisible {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
                .font(TymoreTypography.bodyLarge)
                .foregroundColor(theme.current.primaryText)
                .focused($focusedField, equals: field)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .font(TymoreTypography.bodyLarge)
                        .foregroundColor(theme.current.tertiaryText)
                }
                
                // Neural scanning line
                Rectangle()
                    .fill(
                        focusedField == field
                        ? LinearGradient(
                            colors: [
                                theme.current.tymoreAccent,
                                theme.current.tymorePurple,
                                theme.current.tymoreAccent
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [theme.current.borderColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: focusedField == field ? 2 : 1)
                    .neonGlow(
                        focusedField == field ? theme.current.tymoreAccent : Color.clear,
                        radius: focusedField == field ? 4 : 0
                    )
                    .animation(.easeInOut(duration: 0.3), value: focusedField == field)
            }
            
            // Neural visibility toggle
            if isSecure {
                Button(action: { isPasswordVisible.toggle() }) {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(theme.current.tertiaryText)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(theme.current.elevatedSurface)
                        )
                }
            }
        }
        .padding(TymoreSpacing.lg)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: TymoreRadius.lg)
                    .fill(theme.current.elevatedSurface)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: TymoreRadius.lg))
                
                RoundedRectangle(cornerRadius: TymoreRadius.lg)
                    .stroke(
                        focusedField == field
                        ? LinearGradient(
                            colors: [theme.current.tymoreAccent, theme.current.tymorePurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [theme.current.borderColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: focusedField == field ? 2 : 1
                    )
                    .neonGlow(
                        focusedField == field ? theme.current.tymoreAccent : Color.clear,
                        radius: focusedField == field ? 6 : 0
                    )
            }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focusedField == field)
    }
}

// MARK: - Placeholder Helper
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(TymoreTheme.shared)
}
