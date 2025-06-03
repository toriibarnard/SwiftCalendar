//
//  TymoreTheme.swift
//  SwiftCalendar
//
//  ELEGANT: Sophisticated dark theme - Black Butler aesthetic
//

import SwiftUI
import Foundation

// MARK: - Elegant Theme Manager
class TymoreTheme: ObservableObject {
    @Published var isDarkMode: Bool = true
    
    static let shared = TymoreTheme()
    
    private init() {
        self.isDarkMode = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool ?? true
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
    
    var current: ThemeColors {
        isDarkMode ? .elegantDark : .light
    }
}

// MARK: - Sophisticated Color Schemes
struct ThemeColors {
    // Elegant dark backgrounds
    let primaryBackground: Color
    let secondaryBackground: Color
    let tertiaryBackground: Color
    let surfaceBackground: Color
    let elevatedSurface: Color
    
    // Refined text colors
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let accentText: Color
    
    // Minimal accent colors - very subtle
    let tymoreBlue: Color
    let tymoreSteel: Color
    let tymoreAccent: Color
    let tymorePurple: Color
    let tymoreGlow: Color
    
    // Subtle semantic colors
    let success: Color
    let warning: Color
    let error: Color
    let info: Color
    
    // Clean interactive elements
    let buttonPrimary: Color
    let buttonSecondary: Color
    let cardBackground: Color
    let glassBackground: Color
    let borderColor: Color
    let glowBorder: Color
    let separatorColor: Color
    
    // Refined calendar colors
    let workColor: Color
    let fitnessColor: Color
    let personalColor: Color
    let studyColor: Color
    let healthColor: Color
    let socialColor: Color
    let otherColor: Color
    
    static let elegantDark = ThemeColors(
        // ELEGANT DARK - Pure sophistication
        primaryBackground: Color(hex: "000000"),        // Pure black
        secondaryBackground: Color(hex: "0F0F0F"),      // Barely lighter black
        tertiaryBackground: Color(hex: "1A1A1A"),       // Subtle gray
        surfaceBackground: Color(hex: "242424"),        // Elevated surface
        elevatedSurface: Color(hex: "2D2D2D"),          // Floating elements
        
        // Refined text with perfect contrast
        primaryText: Color(hex: "FFFFFF"),              // Pure white
        secondaryText: Color(hex: "E5E5E5"),            // Soft white
        tertiaryText: Color(hex: "999999"),             // Refined gray
        accentText: Color(hex: "CCCCCC"),               // Subtle accent
        
        // MINIMAL brand colors - very refined
        tymoreBlue: Color(hex: "4A90E2"),               // Refined blue
        tymoreSteel: Color(hex: "6B7280"),              // Subtle steel
        tymoreAccent: Color(hex: "3B82F6"),             // Clean blue accent
        tymorePurple: Color(hex: "8B5CF6"),             // Elegant purple
        tymoreGlow: Color(hex: "4A90E2"),               // Subtle glow
        
        // Understated semantic colors
        success: Color(hex: "10B981"),                  // Clean green
        warning: Color(hex: "F59E0B"),                  // Refined amber
        error: Color(hex: "EF4444"),                    // Clean red
        info: Color(hex: "3B82F6"),                     // Refined blue
        
        // Clean interactive elements
        buttonPrimary: Color(hex: "4A90E2"),
        buttonSecondary: Color(hex: "6B7280"),
        cardBackground: Color(hex: "1A1A1A"),
        glassBackground: Color(hex: "FFFFFF").opacity(0.02), // Very subtle glass
        borderColor: Color(hex: "333333"),              // Subtle borders
        glowBorder: Color(hex: "4A90E2"),               // Minimal glow
        separatorColor: Color(hex: "333333"),
        
        // REFINED calendar categories - muted elegance
        workColor: Color(hex: "DC2626"),                // Refined red
        fitnessColor: Color(hex: "059669"),             // Elegant green
        personalColor: Color(hex: "2563EB"),            // Clean blue
        studyColor: Color(hex: "7C3AED"),               // Refined purple
        healthColor: Color(hex: "D97706"),              // Elegant orange
        socialColor: Color(hex: "DB2777"),              // Refined pink
        otherColor: Color(hex: "6B7280")                // Subtle gray
    )
    
    static let light = ThemeColors(
        // Clean light mode
        primaryBackground: Color(hex: "FFFFFF"),
        secondaryBackground: Color(hex: "FAFAFA"),
        tertiaryBackground: Color(hex: "F5F5F5"),
        surfaceBackground: Color(hex: "FFFFFF"),
        elevatedSurface: Color(hex: "FFFFFF"),
        
        primaryText: Color(hex: "000000"),
        secondaryText: Color(hex: "666666"),
        tertiaryText: Color(hex: "999999"),
        accentText: Color(hex: "333333"),
        
        tymoreBlue: Color(hex: "4A90E2"),
        tymoreSteel: Color(hex: "6B7280"),
        tymoreAccent: Color(hex: "3B82F6"),
        tymorePurple: Color(hex: "8B5CF6"),
        tymoreGlow: Color(hex: "4A90E2"),
        
        success: Color(hex: "10B981"),
        warning: Color(hex: "F59E0B"),
        error: Color(hex: "EF4444"),
        info: Color(hex: "3B82F6"),
        
        buttonPrimary: Color(hex: "4A90E2"),
        buttonSecondary: Color(hex: "6B7280"),
        cardBackground: Color(hex: "FFFFFF"),
        glassBackground: Color(hex: "FFFFFF"),
        borderColor: Color(hex: "E5E5E5"),
        glowBorder: Color(hex: "4A90E2"),
        separatorColor: Color(hex: "F0F0F0"),
        
        workColor: Color(hex: "DC2626"),
        fitnessColor: Color(hex: "059669"),
        personalColor: Color(hex: "2563EB"),
        studyColor: Color(hex: "7C3AED"),
        healthColor: Color(hex: "D97706"),
        socialColor: Color(hex: "DB2777"),
        otherColor: Color(hex: "6B7280")
    )
}

// MARK: - Elegant Typography
struct TymoreTypography {
    // Display fonts - clean and sophisticated
    static let displayLarge = Font.system(size: 32, weight: .thin, design: .default)
    static let displayMedium = Font.system(size: 28, weight: .ultraLight, design: .default)
    static let displaySmall = Font.system(size: 24, weight: .light, design: .default)
    
    // Headlines - refined weight
    static let headlineLarge = Font.system(size: 22, weight: .medium, design: .default)
    static let headlineMedium = Font.system(size: 18, weight: .medium, design: .default)
    static let headlineSmall = Font.system(size: 16, weight: .medium, design: .default)
    
    // Body text - optimized for elegance
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
    
    // Labels - subtle emphasis
    static let labelLarge = Font.system(size: 15, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 13, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
}

// MARK: - Refined Spacing
struct TymoreSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Clean Radius System
struct TymoreRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let round: CGFloat = 50
}

// MARK: - Subtle Shadow System
struct TymoreShadow {
    static let none = Shadow(color: Color.clear, radius: 0, x: 0, y: 0)
    
    static let subtle = Shadow(
        color: Color.black.opacity(0.1),
        radius: 4,
        x: 0,
        y: 2
    )
    
    static let soft = Shadow(
        color: Color.black.opacity(0.15),
        radius: 8,
        x: 0,
        y: 4
    )
    
    static let medium = Shadow(
        color: Color.black.opacity(0.2),
        radius: 12,
        x: 0,
        y: 6
    )
    
    static let strong = Shadow(
        color: Color.black.opacity(0.25),
        radius: 16,
        x: 0,
        y: 8
    )
    
    // Minimal glow for focus states only
    static let focus = Shadow(
        color: Color(hex: "4A90E2").opacity(0.3),
        radius: 8,
        x: 0,
        y: 0
    )
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Elegant View Modifiers

struct ElegantCard: ViewModifier {
    @EnvironmentObject var theme: TymoreTheme
    let isElevated: Bool
    
    init(isElevated: Bool = false) {
        self.isElevated = isElevated
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: TymoreRadius.lg)
                    .fill(isElevated ? theme.current.elevatedSurface : theme.current.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: TymoreRadius.lg)
                            .stroke(theme.current.borderColor, lineWidth: 0.5)
                    )
            )
            .shadow(
                color: Color.black.opacity(isElevated ? 0.3 : 0.1),
                radius: isElevated ? 12 : 6,
                x: 0,
                y: isElevated ? 8 : 3
            )
    }
}

struct ElegantButton: ButtonStyle {
    let variant: ButtonVariant
    @EnvironmentObject var theme: TymoreTheme
    
    enum ButtonVariant {
        case primary, secondary, ghost, destructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TymoreTypography.labelMedium)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, TymoreSpacing.lg)
            .padding(.vertical, TymoreSpacing.md)
            .background(backgroundColor)
            .cornerRadius(TymoreRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: TymoreRadius.md)
                    .stroke(borderColor, lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return theme.current.buttonPrimary
        case .secondary:
            return theme.current.elevatedSurface
        case .ghost:
            return Color.clear
        case .destructive:
            return theme.current.error
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive:
            return Color.white
        case .secondary:
            return theme.current.primaryText
        case .ghost:
            return theme.current.tymoreBlue
        }
    }
    
    private var borderColor: Color {
        switch variant {
        case .primary, .destructive:
            return Color.clear
        case .secondary, .ghost:
            return theme.current.borderColor
        }
    }
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

// MARK: - Elegant View Extensions
extension View {
    func elegantCard(elevated: Bool = false) -> some View {
        self.modifier(ElegantCard(isElevated: elevated))
    }
    
    func elegantButton(_ variant: ElegantButton.ButtonVariant = .primary) -> some View {
        self.buttonStyle(ElegantButton(variant: variant))
    }
    
    func tymoreShadow(_ shadow: Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    func subtleGlow(_ color: Color = Color(hex: "4A90E2"), radius: CGFloat = 8) -> some View {
        self.shadow(color: color.opacity(0.2), radius: radius, x: 0, y: 0)
    }
}

// MARK: - Legacy Support
struct TymoreCardStyle: ViewModifier {
    @EnvironmentObject var theme: TymoreTheme
    
    func body(content: Content) -> some View {
        content.elegantCard()
    }
}

extension View {
    func tymoreCard() -> some View {
        self.elegantCard()
    }
}
