//
//  TymoreTheme.swift
//  SwiftCalendar
//
//  Dark, sleek theme system inspired by the Tymore logo
//

import SwiftUI
import Foundation

// MARK: - Theme Manager
class TymoreTheme: ObservableObject {
    @Published var isDarkMode: Bool = true
    
    static let shared = TymoreTheme()
    
    private init() {
        // Load saved theme preference
        self.isDarkMode = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool ?? true
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
    
    var current: ThemeColors {
        isDarkMode ? .dark : .light
    }
}

// MARK: - Color Schemes
struct ThemeColors {
    // Background layers
    let primaryBackground: Color
    let secondaryBackground: Color
    let tertiaryBackground: Color
    let surfaceBackground: Color
    
    // Text colors
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    
    // Accent colors (inspired by logo)
    let tymoreBlue: Color        // Primary brand color
    let tymoreSteel: Color       // Secondary metallic tone
    let tymoreAccent: Color      // Bright accent
    
    // Semantic colors
    let success: Color
    let warning: Color
    let error: Color
    let info: Color
    
    // Interactive elements
    let buttonPrimary: Color
    let buttonSecondary: Color
    let cardBackground: Color
    let borderColor: Color
    let separatorColor: Color
    
    // Calendar specific
    let workColor: Color
    let fitnessColor: Color
    let personalColor: Color
    let studyColor: Color
    let healthColor: Color
    let socialColor: Color
    let otherColor: Color
    
    static let dark = ThemeColors(
        // Backgrounds - inspired by logo's dark sophistication
        primaryBackground: Color(hex: "0A0E14"),      // Deep charcoal
        secondaryBackground: Color(hex: "1A1F26"),    // Slightly lighter
        tertiaryBackground: Color(hex: "252B33"),     // Card backgrounds
        surfaceBackground: Color(hex: "2D3440"),      // Elevated surfaces
        
        // Text colors
        primaryText: Color(hex: "F5F7FA"),            // Clean white
        secondaryText: Color(hex: "B8C5D1"),          // Muted text
        tertiaryText: Color(hex: "8A9BA8"),           // Subtle text
        
        // Brand colors from logo
        tymoreBlue: Color(hex: "4A90E2"),             // Primary blue
        tymoreSteel: Color(hex: "6B7C93"),            // Steel blue-gray
        tymoreAccent: Color(hex: "00D4FF"),           // Bright cyan accent
        
        // Semantic colors
        success: Color(hex: "00C851"),
        warning: Color(hex: "FF8F00"),
        error: Color(hex: "FF4444"),
        info: Color(hex: "33B5E5"),
        
        // Interactive elements
        buttonPrimary: Color(hex: "4A90E2"),
        buttonSecondary: Color(hex: "6B7C93"),
        cardBackground: Color(hex: "2D3440"),
        borderColor: Color(hex: "3D4753"),
        separatorColor: Color(hex: "3D4753"),
        
        // Calendar category colors - sophisticated palette
        workColor: Color(hex: "E74C3C"),       // Refined red
        fitnessColor: Color(hex: "27AE60"),     // Energetic green
        personalColor: Color(hex: "4A90E2"),    // Brand blue
        studyColor: Color(hex: "9B59B6"),       // Deep purple
        healthColor: Color(hex: "F39C12"),      // Warm orange
        socialColor: Color(hex: "E91E63"),      // Vibrant pink
        otherColor: Color(hex: "6B7C93")        // Steel gray
    )
    
    static let light = ThemeColors(
        // Light mode backgrounds
        primaryBackground: Color(hex: "FFFFFF"),
        secondaryBackground: Color(hex: "F8F9FA"),
        tertiaryBackground: Color(hex: "F1F3F5"),
        surfaceBackground: Color(hex: "FFFFFF"),
        
        // Light mode text
        primaryText: Color(hex: "1A1F26"),
        secondaryText: Color(hex: "495057"),
        tertiaryText: Color(hex: "6C757D"),
        
        // Brand colors (same as dark)
        tymoreBlue: Color(hex: "4A90E2"),
        tymoreSteel: Color(hex: "6B7C93"),
        tymoreAccent: Color(hex: "00D4FF"),
        
        // Light semantic colors
        success: Color(hex: "28A745"),
        warning: Color(hex: "FFC107"),
        error: Color(hex: "DC3545"),
        info: Color(hex: "17A2B8"),
        
        // Light interactive
        buttonPrimary: Color(hex: "4A90E2"),
        buttonSecondary: Color(hex: "6C757D"),
        cardBackground: Color(hex: "FFFFFF"),
        borderColor: Color(hex: "DEE2E6"),
        separatorColor: Color(hex: "E9ECEF"),
        
        // Light calendar colors
        workColor: Color(hex: "DC3545"),
        fitnessColor: Color(hex: "28A745"),
        personalColor: Color(hex: "4A90E2"),
        studyColor: Color(hex: "6F42C1"),
        healthColor: Color(hex: "FD7E14"),
        socialColor: Color(hex: "E83E8C"),
        otherColor: Color(hex: "6C757D")
    )
}

// MARK: - Typography System
struct TymoreTypography {
    // Display fonts
    static let displayLarge = Font.system(size: 32, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    static let displaySmall = Font.system(size: 24, weight: .semibold, design: .rounded)
    
    // Headlines
    static let headlineLarge = Font.system(size: 22, weight: .semibold, design: .default)
    static let headlineMedium = Font.system(size: 18, weight: .semibold, design: .default)
    static let headlineSmall = Font.system(size: 16, weight: .medium, design: .default)
    
    // Body text
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
    
    // Labels
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 10, weight: .medium, design: .default)
}

// MARK: - Spacing System
struct TymoreSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius System
struct TymoreRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let round: CGFloat = 50
}

// MARK: - Shadow System
struct TymoreShadow {
    static let subtle = Shadow(
        color: Color.black.opacity(0.1),
        radius: 2,
        x: 0,
        y: 1
    )
    
    static let soft = Shadow(
        color: Color.black.opacity(0.15),
        radius: 8,
        x: 0,
        y: 2
    )
    
    static let medium = Shadow(
        color: Color.black.opacity(0.2),
        radius: 16,
        x: 0,
        y: 4
    )
    
    static let strong = Shadow(
        color: Color.black.opacity(0.3),
        radius: 24,
        x: 0,
        y: 8
    )
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Utility Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
struct TymoreCardStyle: ViewModifier {
    @EnvironmentObject var theme: TymoreTheme
    
    func body(content: Content) -> some View {
        content
            .background(theme.current.cardBackground)
            .cornerRadius(TymoreRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: TymoreRadius.md)
                    .stroke(theme.current.borderColor, lineWidth: 1)
            )
            .shadow(
                color: theme.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                radius: 8,
                x: 0,
                y: 2
            )
    }
}

struct TymoreButtonStyle: ButtonStyle {
    let variant: ButtonVariant
    @EnvironmentObject var theme: TymoreTheme
    
    enum ButtonVariant {
        case primary, secondary, ghost, destructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TymoreTypography.labelLarge)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, TymoreSpacing.lg)
            .padding(.vertical, TymoreSpacing.md)
            .background(backgroundColor)
            .cornerRadius(TymoreRadius.md)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return theme.current.buttonPrimary
        case .secondary:
            return theme.current.buttonSecondary
        case .ghost:
            return Color.clear
        case .destructive:
            return theme.current.error
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary, .secondary, .destructive:
            return Color.white
        case .ghost:
            return theme.current.tymoreBlue
        }
    }
}

// MARK: - View Extensions
extension View {
    func tymoreCard() -> some View {
        self.modifier(TymoreCardStyle())
    }
    
    func tymoreButton(_ variant: TymoreButtonStyle.ButtonVariant = .primary) -> some View {
        self.buttonStyle(TymoreButtonStyle(variant: variant))
    }
    
    func tymoreShadow(_ shadow: Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}
