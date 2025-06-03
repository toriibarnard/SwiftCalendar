//
//  TymoreTheme.swift
//  SwiftCalendar
//
//  ULTRA-MODERN: Sleek, cutting-edge dark theme system
//

import SwiftUI
import Foundation

// MARK: - Ultra-Modern Theme Manager
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
        isDarkMode ? .ultraDark : .light
    }
}

// MARK: - Ultra-Modern Color Schemes
struct ThemeColors {
    // Ultra-dark background layers
    let primaryBackground: Color
    let secondaryBackground: Color
    let tertiaryBackground: Color
    let surfaceBackground: Color
    let elevatedSurface: Color
    
    // Text colors with more contrast
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let accentText: Color
    
    // Neon accent colors
    let tymoreBlue: Color
    let tymoreSteel: Color
    let tymoreAccent: Color
    let tymorePurple: Color      // New: Premium purple
    let tymoreGlow: Color        // New: Glow effects
    
    // Semantic colors with glow
    let success: Color
    let warning: Color
    let error: Color
    let info: Color
    
    // Interactive elements with glassmorphism
    let buttonPrimary: Color
    let buttonSecondary: Color
    let cardBackground: Color
    let glassBackground: Color   // New: Glassmorphism
    let borderColor: Color
    let glowBorder: Color        // New: Glowing borders
    let separatorColor: Color
    
    // Calendar with neon touches
    let workColor: Color
    let fitnessColor: Color
    let personalColor: Color
    let studyColor: Color
    let healthColor: Color
    let socialColor: Color
    let otherColor: Color
    
    static let ultraDark = ThemeColors(
        // ULTRA-DARK backgrounds - deeper than deep
        primaryBackground: Color(hex: "000000"),        // Pure black
        secondaryBackground: Color(hex: "0A0A0F"),      // Ultra-deep navy
        tertiaryBackground: Color(hex: "12121A"),       // Deep charcoal
        surfaceBackground: Color(hex: "1A1A26"),        // Elevated dark
        elevatedSurface: Color(hex: "242430"),          // Floating elements
        
        // High-contrast text with glow potential
        primaryText: Color(hex: "FFFFFF"),              // Pure white
        secondaryText: Color(hex: "E1E5F0"),            // Cool white
        tertiaryText: Color(hex: "9CA3AF"),             // Muted gray
        accentText: Color(hex: "00E5FF"),               // Cyan accent text
        
        // NEON brand colors - electric and modern
        tymoreBlue: Color(hex: "0080FF"),               // Electric blue
        tymoreSteel: Color(hex: "6366F1"),              // Indigo steel
        tymoreAccent: Color(hex: "00E5FF"),             // Neon cyan
        tymorePurple: Color(hex: "8B5CF6"),             // Premium purple
        tymoreGlow: Color(hex: "00E5FF"),               // Glow color
        
        // Vibrant semantic colors
        success: Color(hex: "10B981"),                  // Modern green
        warning: Color(hex: "F59E0B"),                  // Amber warning
        error: Color(hex: "EF4444"),                    // Modern red
        info: Color(hex: "06B6D4"),                     // Cyan info
        
        // Glass and glow interactive elements
        buttonPrimary: Color(hex: "0080FF"),
        buttonSecondary: Color(hex: "6366F1"),
        cardBackground: Color(hex: "1A1A26"),
        glassBackground: Color(hex: "FFFFFF").opacity(0.05), // Glassmorphism
        borderColor: Color(hex: "374151"),
        glowBorder: Color(hex: "00E5FF"),               // Glowing borders
        separatorColor: Color(hex: "374151"),
        
        // NEON calendar categories
        workColor: Color(hex: "EF4444"),                // Electric red
        fitnessColor: Color(hex: "10B981"),             // Neon green
        personalColor: Color(hex: "0080FF"),            // Electric blue
        studyColor: Color(hex: "8B5CF6"),               // Purple
        healthColor: Color(hex: "F59E0B"),              // Amber
        socialColor: Color(hex: "EC4899"),              // Hot pink
        otherColor: Color(hex: "6B7280")                // Cool gray
    )
    
    static let light = ThemeColors(
        // Clean light mode
        primaryBackground: Color(hex: "FFFFFF"),
        secondaryBackground: Color(hex: "F9FAFB"),
        tertiaryBackground: Color(hex: "F3F4F6"),
        surfaceBackground: Color(hex: "FFFFFF"),
        elevatedSurface: Color(hex: "FFFFFF"),
        
        primaryText: Color(hex: "111827"),
        secondaryText: Color(hex: "4B5563"),
        tertiaryText: Color(hex: "6B7280"),
        accentText: Color(hex: "0080FF"),
        
        tymoreBlue: Color(hex: "0080FF"),
        tymoreSteel: Color(hex: "6366F1"),
        tymoreAccent: Color(hex: "00E5FF"),
        tymorePurple: Color(hex: "8B5CF6"),
        tymoreGlow: Color(hex: "00E5FF"),
        
        success: Color(hex: "10B981"),
        warning: Color(hex: "F59E0B"),
        error: Color(hex: "EF4444"),
        info: Color(hex: "06B6D4"),
        
        buttonPrimary: Color(hex: "0080FF"),
        buttonSecondary: Color(hex: "6B7280"),
        cardBackground: Color(hex: "FFFFFF"),
        glassBackground: Color(hex: "FFFFFF"),
        borderColor: Color(hex: "E5E7EB"),
        glowBorder: Color(hex: "0080FF"),
        separatorColor: Color(hex: "F3F4F6"),
        
        workColor: Color(hex: "EF4444"),
        fitnessColor: Color(hex: "10B981"),
        personalColor: Color(hex: "0080FF"),
        studyColor: Color(hex: "8B5CF6"),
        healthColor: Color(hex: "F59E0B"),
        socialColor: Color(hex: "EC4899"),
        otherColor: Color(hex: "6B7280")
    )
}

// MARK: - Ultra-Modern Typography
struct TymoreTypography {
    // Display fonts - more futuristic
    static let displayLarge = Font.system(size: 36, weight: .black, design: .rounded)
    static let displayMedium = Font.system(size: 30, weight: .heavy, design: .rounded)
    static let displaySmall = Font.system(size: 26, weight: .bold, design: .rounded)
    
    // Headlines - sharper, more modern
    static let headlineLarge = Font.system(size: 24, weight: .bold, design: .default)
    static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .default)
    static let headlineSmall = Font.system(size: 17, weight: .semibold, design: .default)
    
    // Body text - optimized for dark reading
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
    
    // Labels - more pronounced
    static let labelLarge = Font.system(size: 15, weight: .semibold, design: .default)
    static let labelMedium = Font.system(size: 13, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
}

// MARK: - Ultra-Modern Spacing
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

// MARK: - Modern Radius System
struct TymoreRadius {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 18
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let round: CGFloat = 50
}

// MARK: - Advanced Shadow & Glow System
struct TymoreShadow {
    static let none = Shadow(color: Color.clear, radius: 0, x: 0, y: 0)
    
    static let subtle = Shadow(
        color: Color.black.opacity(0.15),
        radius: 4,
        x: 0,
        y: 2
    )
    
    static let soft = Shadow(
        color: Color.black.opacity(0.25),
        radius: 12,
        x: 0,
        y: 4
    )
    
    static let medium = Shadow(
        color: Color.black.opacity(0.35),
        radius: 20,
        x: 0,
        y: 8
    )
    
    static let strong = Shadow(
        color: Color.black.opacity(0.5),
        radius: 30,
        x: 0,
        y: 12
    )
    
    // NEW: Glow effects
    static let glow = Shadow(
        color: Color(hex: "00E5FF").opacity(0.4),
        radius: 16,
        x: 0,
        y: 0
    )
    
    static let strongGlow = Shadow(
        color: Color(hex: "00E5FF").opacity(0.6),
        radius: 24,
        x: 0,
        y: 0
    )
    
    static let purpleGlow = Shadow(
        color: Color(hex: "8B5CF6").opacity(0.5),
        radius: 20,
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

// MARK: - Advanced View Modifiers

struct UltraModernCard: ViewModifier {
    @EnvironmentObject var theme: TymoreTheme
    let hasGlow: Bool
    
    init(hasGlow: Bool = false) {
        self.hasGlow = hasGlow
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Main card background
                    RoundedRectangle(cornerRadius: TymoreRadius.lg)
                        .fill(theme.current.cardBackground)
                    
                    // Glassmorphism overlay
                    RoundedRectangle(cornerRadius: TymoreRadius.lg)
                        .fill(theme.current.glassBackground)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TymoreRadius.lg))
                    
                    // Subtle border
                    RoundedRectangle(cornerRadius: TymoreRadius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    theme.current.borderColor.opacity(0.8),
                                    theme.current.borderColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(
                color: hasGlow ? theme.current.tymoreGlow.opacity(0.3) : Color.black.opacity(0.3),
                radius: hasGlow ? 16 : 12,
                x: 0,
                y: hasGlow ? 0 : 6
            )
    }
}

struct NeonButton: ViewModifier {
    let variant: ButtonVariant
    @EnvironmentObject var theme: TymoreTheme
    @State private var isPressed = false
    
    enum ButtonVariant {
        case primary, secondary, ghost, destructive, neon
    }
    
    func body(content: Content) -> some View {
        content
            .font(TymoreTypography.labelLarge)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, TymoreSpacing.lg)
            .padding(.vertical, TymoreSpacing.md)
            .background(backgroundView)
            .cornerRadius(TymoreRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: TymoreRadius.md)
                    .stroke(borderColor, lineWidth: variant == .neon ? 2 : 1)
            )
            .shadow(
                color: shadowColor,
                radius: isPressed ? 8 : 12,
                x: 0,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
    
    private var backgroundView: some View {
        Group {
            switch variant {
            case .primary:
                LinearGradient(
                    colors: [theme.current.tymoreBlue, theme.current.tymoreSteel],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .neon:
                ZStack {
                    RoundedRectangle(cornerRadius: TymoreRadius.md)
                        .fill(theme.current.cardBackground)
                    
                    LinearGradient(
                        colors: [
                            theme.current.tymoreAccent.opacity(0.3),
                            theme.current.tymorePurple.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            case .secondary:
                LinearGradient(
                    colors: [theme.current.tertiaryBackground, theme.current.surfaceBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .ghost:
                Color.clear
            case .destructive:
                LinearGradient(
                    colors: [theme.current.error, theme.current.error.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive, .neon:
            return .white
        case .secondary:
            return theme.current.primaryText
        case .ghost:
            return theme.current.tymoreBlue
        }
    }
    
    private var borderColor: Color {
        switch variant {
        case .neon:
            return theme.current.tymoreAccent
        case .primary, .secondary, .destructive, .ghost:
            return Color.clear
        }
    }
    
    private var shadowColor: Color {
        switch variant {
        case .neon:
            return theme.current.tymoreAccent.opacity(0.5)
        case .primary:
            return theme.current.tymoreBlue.opacity(0.4)
        case .destructive:
            return theme.current.error.opacity(0.4)
        default:
            return Color.black.opacity(0.3)
        }
    }
}

struct FloatingElement: ViewModifier {
    @State private var isFloating = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -2 : 0)
            .animation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                isFloating = true
            }
    }
}

// MARK: - Ultra-Modern Extensions
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

// MARK: - Ultra-Modern View Extensions
extension View {
    func ultraModernCard(hasGlow: Bool = false) -> some View {
        self.modifier(UltraModernCard(hasGlow: hasGlow))
    }
    
    func neonButton(_ variant: NeonButton.ButtonVariant = .primary) -> some View {
        self.modifier(NeonButton(variant: variant))
    }
    
    func tymoreShadow(_ shadow: Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    func floating() -> some View {
        self.modifier(FloatingElement())
    }
    
    func neonGlow(_ color: Color = Color(hex: "00E5FF"), radius: CGFloat = 16) -> some View {
        self.shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
    }
    
    func glassmorphism() -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TymoreRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: TymoreRadius.lg)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Legacy Support
struct TymoreCardStyle: ViewModifier {
    @EnvironmentObject var theme: TymoreTheme
    
    func body(content: Content) -> some View {
        content.ultraModernCard()
    }
}

extension View {
    func tymoreCard() -> some View {
        self.ultraModernCard()
    }
}
