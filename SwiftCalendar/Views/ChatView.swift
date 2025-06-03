//
//  ChatView.swift
//  SwiftCalendar
//
//  ULTRA-MODERN: Sleek, futuristic chat interface
//

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @ObservedObject var scheduleManager: ScheduleManager
    @EnvironmentObject var theme: TymoreTheme
    @FocusState private var isInputFocused: Bool
    
    init(scheduleManager: ScheduleManager) {
        self.scheduleManager = scheduleManager
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Ultra-dark background with subtle gradient
                LinearGradient(
                    colors: [
                        theme.current.primaryBackground,
                        theme.current.secondaryBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Futuristic Navigation Header
                    UltraModernNavigationHeader(viewModel: viewModel)
                    
                    // Messages with advanced styling
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: TymoreSpacing.lg) {
                                ForEach(viewModel.messages) { message in
                                    FuturisticMessageBubble(
                                        message: message,
                                        viewModel: viewModel,
                                        onSuggestionTap: { suggestion in
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                viewModel.selectScheduleSuggestion(suggestion)
                                            }
                                        }
                                    )
                                    .id(message.id)
                                }
                                
                                if viewModel.isLoading {
                                    UltraModernTypingIndicator()
                                }
                            }
                            .padding(TymoreSpacing.xl)
                        }
                        .onChange(of: viewModel.messages.count) { _ in
                            withAnimation(.easeOut(duration: 0.6)) {
                                proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                            }
                        }
                    }
                    
                    // Error banner with neon styling
                    if !viewModel.errorMessage.isEmpty {
                        NeonErrorBanner(message: viewModel.errorMessage)
                    }
                    
                    // Futuristic input area
                    FuturisticChatInput(
                        inputText: $viewModel.inputText,
                        isLoading: viewModel.isLoading,
                        isInputFocused: $isInputFocused,
                        onSend: viewModel.sendMessage
                    )
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.scheduleManager = scheduleManager
            }
            .alert("Confirmation Required", isPresented: $viewModel.showingConfirmation) {
                Button("Yes", role: .destructive) {
                    viewModel.confirmAction()
                }
                Button("No", role: .cancel) {
                    viewModel.cancelAction()
                }
            } message: {
                Text(viewModel.confirmationMessage)
            }
        }
    }
}

struct UltraModernNavigationHeader: View {
    let viewModel: ChatViewModel
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        ZStack {
            // Background with glassmorphism
            Rectangle()
                .fill(theme.current.secondaryBackground)
                .background(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [
                            theme.current.tymoreAccent.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            HStack(spacing: TymoreSpacing.lg) {
                // Futuristic AI Avatar with glow
                ZStack {
                    // Glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [theme.current.tymoreAccent, theme.current.tymorePurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 50, height: 50)
                        .neonGlow(theme.current.tymoreAccent, radius: 12)
                    
                    // Inner avatar
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.current.tymoreBlue,
                                    theme.current.tymorePurple
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 20
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    // AI Icon
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .neonGlow(.white, radius: 4)
                }
                .floating()
                
                // Title with neon effect
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: TymoreSpacing.sm) {
                        Text("TY")
                            .font(TymoreTypography.headlineLarge)
                            .fontWeight(.black)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [theme.current.tymoreAccent, theme.current.tymorePurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .neonGlow(theme.current.tymoreAccent, radius: 8)
                        
                        // Pulsing AI badge
                        Text("AI")
                            .font(TymoreTypography.labelSmall)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(theme.current.tymoreAccent)
                                    .neonGlow(theme.current.tymoreAccent, radius: 6)
                            )
                    }
                    
                    HStack(spacing: 6) {
                        // Animated status dot
                        Circle()
                            .fill(theme.current.success)
                            .frame(width: 8, height: 8)
                            .neonGlow(theme.current.success, radius: 4)
                            .scaleEffect(1.0)
                            .animation(
                                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                value: true
                            )
                        
                        Text("Neural Schedule Optimizer")
                            .font(TymoreTypography.bodySmall)
                            .foregroundColor(theme.current.accentText)
                    }
                }
                
                Spacer()
                
                // Action buttons with neon styling
                HStack(spacing: TymoreSpacing.md) {
                    if !viewModel.selectedSuggestionIds.isEmpty {
                        Button(action: viewModel.clearSelections) {
                            Image(systemName: "clear.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.current.warning)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(theme.current.warning.opacity(0.2))
                                        .overlay(
                                            Circle()
                                                .stroke(theme.current.warning, lineWidth: 1)
                                        )
                                )
                                .neonGlow(theme.current.warning, radius: 8)
                        }
                    }
                    
                    Button(action: viewModel.clearConversation) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.current.tertiaryText)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(theme.current.elevatedSurface)
                                    .overlay(
                                        Circle()
                                            .stroke(theme.current.borderColor, lineWidth: 1)
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, TymoreSpacing.xl)
            .padding(.vertical, TymoreSpacing.lg)
        }
        .frame(height: 80)
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [theme.current.tymoreAccent.opacity(0.3), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

struct FuturisticMessageBubble: View {
    let message: ChatMessage
    let viewModel: ChatViewModel
    let onSuggestionTap: (ScheduleSuggestion) -> Void
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        HStack(alignment: .bottom, spacing: TymoreSpacing.md) {
            if message.isUser { Spacer(minLength: 60) }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: TymoreSpacing.md) {
                // Ultra-modern message bubble
                Text(message.content)
                    .font(TymoreTypography.bodyMedium)
                    .foregroundColor(message.isUser ? .white : theme.current.primaryText)
                    .padding(.horizontal, TymoreSpacing.xl)
                    .padding(.vertical, TymoreSpacing.lg)
                    .background(
                        ZStack {
                            if message.isUser {
                                // User bubble with gradient + glow
                                RoundedRectangle(cornerRadius: TymoreRadius.xl)
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.current.tymoreBlue, theme.current.tymorePurple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .neonGlow(theme.current.tymoreBlue, radius: 12)
                            } else {
                                // AI bubble with glassmorphism
                                RoundedRectangle(cornerRadius: TymoreRadius.xl)
                                    .fill(theme.current.elevatedSurface)
                                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: TymoreRadius.xl))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: TymoreRadius.xl)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        theme.current.tymoreAccent.opacity(0.5),
                                                        theme.current.borderColor.opacity(0.3)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            }
                        }
                    )
                
                // Futuristic schedule suggestions
                if let suggestions = message.suggestions, !suggestions.isEmpty {
                    NeuralScheduleSuggestions(
                        suggestions: suggestions,
                        viewModel: viewModel,
                        onTap: onSuggestionTap
                    )
                }
                
                // Timestamp with glow
                Text(message.timestamp.chatFormat())
                    .font(TymoreTypography.labelSmall)
                    .foregroundColor(theme.current.tertiaryText)
                    .padding(.horizontal, TymoreSpacing.sm)
            }
            
            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

struct NeuralScheduleSuggestions: View {
    let suggestions: [ScheduleSuggestion]
    let viewModel: ChatViewModel
    let onTap: (ScheduleSuggestion) -> Void
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: TymoreSpacing.md) {
            // Futuristic header
            HStack(spacing: TymoreSpacing.sm) {
                Image(systemName: "brain.filled.head.profile")
                    .foregroundColor(theme.current.tymoreAccent)
                    .font(.system(size: 16, weight: .semibold))
                    .neonGlow(theme.current.tymoreAccent, radius: 6)
                
                Text("NEURAL OPTIMIZATION")
                    .font(TymoreTypography.labelMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.current.accentText)
                    .tracking(1.2)
                
                Spacer()
                
                // Suggestion count badge
                Text("\(suggestions.count)")
                    .font(TymoreTypography.labelSmall)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(width: 20, height: 20)
                    .background(
                        Circle()
                            .fill(theme.current.tymoreAccent)
                            .neonGlow(theme.current.tymoreAccent, radius: 4)
                    )
            }
            .padding(.horizontal, TymoreSpacing.sm)
            
            // Ultra-modern suggestion cards
            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                NeuralSuggestionCard(
                    suggestion: suggestion,
                    rank: index + 1,
                    isSelected: viewModel.isSuggestionSelected(suggestion),
                    onTap: { onTap(suggestion) }
                )
            }
        }
        .frame(maxWidth: 340)
    }
}

struct NeuralSuggestionCard: View {
    let suggestion: ScheduleSuggestion
    let rank: Int
    let isSelected: Bool
    let onTap: () -> Void
    @EnvironmentObject var theme: TymoreTheme
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE h:mm a"
        return formatter
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: TymoreSpacing.md) {
                // Futuristic rank indicator
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                            ? LinearGradient(
                                colors: [theme.current.success, theme.current.success.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [theme.current.tymoreSteel, theme.current.tymorePurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.white)
                    } else {
                        Text("\(rank)")
                            .font(TymoreTypography.labelSmall)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                    }
                }
                .neonGlow(
                    isSelected ? theme.current.success : theme.current.tymoreSteel,
                    radius: isSelected ? 8 : 6
                )
                
                // Content with advanced styling
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(suggestion.timeSlot.startTime, formatter: timeFormatter)
                            .font(TymoreTypography.headlineSmall)
                            .fontWeight(.bold)
                            .foregroundColor(
                                isSelected ? theme.current.success : theme.current.primaryText
                            )
                        
                        Spacer()
                        
                        // Neural score visualization
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(theme.current.success)
                                .font(.system(size: 22))
                                .neonGlow(theme.current.success, radius: 6)
                        } else {
                            HStack(spacing: 3) {
                                ForEach(0..<5) { index in
                                    Circle()
                                        .fill(
                                            index < Int(suggestion.timeSlot.score * 5)
                                            ? theme.current.tymoreAccent
                                            : theme.current.tertiaryBackground
                                        )
                                        .frame(width: 6, height: 6)
                                        .neonGlow(
                                            index < Int(suggestion.timeSlot.score * 5)
                                            ? theme.current.tymoreAccent : Color.clear,
                                            radius: 2
                                        )
                                }
                            }
                        }
                    }
                    
                    Text(suggestion.timeSlot.reasoning)
                        .font(TymoreTypography.bodySmall)
                        .foregroundColor(theme.current.secondaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    // Action indicator with neon styling
                    HStack(spacing: 6) {
                        Image(systemName: isSelected ? "calendar.badge.checkmark" : "plus.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(
                                isSelected ? theme.current.success : theme.current.tymoreAccent
                            )
                        
                        Text(isSelected ? "SCHEDULED" : "TAP TO SCHEDULE")
                            .font(TymoreTypography.labelSmall)
                            .fontWeight(.bold)
                            .tracking(0.5)
                            .foregroundColor(
                                isSelected ? theme.current.success : theme.current.tymoreAccent
                            )
                    }
                }
                
                Spacer()
            }
            .padding(TymoreSpacing.lg)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: TymoreRadius.lg)
                        .fill(
                            isSelected
                            ? theme.current.success.opacity(0.1)
                            : theme.current.elevatedSurface
                        )
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: TymoreRadius.lg))
                    
                    RoundedRectangle(cornerRadius: TymoreRadius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    isSelected ? theme.current.success : theme.current.tymoreAccent,
                                    isSelected ? theme.current.success.opacity(0.3) : theme.current.borderColor
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isSelected ? 2 : 1
                        )
                        .neonGlow(
                            isSelected ? theme.current.success : theme.current.tymoreAccent,
                            radius: isSelected ? 8 : 4
                        )
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isSelected)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}

struct FuturisticChatInput: View {
    @Binding var inputText: String
    let isLoading: Bool
    @FocusState.Binding var isInputFocused: Bool
    let onSend: () -> Void
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Neon separator
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.current.tymoreAccent.opacity(0.6),
                            Color.clear,
                            theme.current.tymorePurple.opacity(0.6)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .neonGlow(theme.current.tymoreAccent, radius: 4)
            
            HStack(spacing: TymoreSpacing.lg) {
                // Ultra-modern input field
                HStack(spacing: TymoreSpacing.md) {
                    TextField("Interface with Ty's neural network...", text: $inputText, axis: .vertical)
                        .font(TymoreTypography.bodyMedium)
                        .foregroundColor(theme.current.primaryText)
                        .lineLimit(1...4)
                        .focused($isInputFocused)
                        .onSubmit(onSend)
                    
                    if !inputText.isEmpty {
                        Button(action: { inputText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(theme.current.tertiaryText)
                                .font(.system(size: 18))
                        }
                    }
                }
                .padding(.horizontal, TymoreSpacing.lg)
                .padding(.vertical, TymoreSpacing.md)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: TymoreRadius.xl)
                            .fill(theme.current.elevatedSurface)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: TymoreRadius.xl))
                        
                        RoundedRectangle(cornerRadius: TymoreRadius.xl)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        isInputFocused ? theme.current.tymoreAccent : theme.current.borderColor,
                                        isInputFocused ? theme.current.tymorePurple : theme.current.borderColor.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isInputFocused ? 2 : 1
                            )
                            .neonGlow(
                                isInputFocused ? theme.current.tymoreAccent : Color.clear,
                                radius: isInputFocused ? 8 : 0
                            )
                    }
                )
                
                // Futuristic send button
                Button(action: onSend) {
                    ZStack {
                        Circle()
                            .fill(
                                inputText.isEmpty || isLoading
                                ? LinearGradient(
                                    colors: [theme.current.tertiaryBackground],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                : LinearGradient(
                                    colors: [theme.current.tymoreBlue, theme.current.tymorePurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .neonGlow(.white, radius: inputText.isEmpty ? 0 : 4)
                        }
                    }
                    .neonGlow(
                        inputText.isEmpty ? Color.clear : theme.current.tymoreBlue,
                        radius: inputText.isEmpty ? 0 : 12
                    )
                }
                .disabled(inputText.isEmpty || isLoading)
                .scaleEffect(inputText.isEmpty ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: inputText.isEmpty)
            }
            .padding(TymoreSpacing.xl)
            .background(
                LinearGradient(
                    colors: [
                        theme.current.secondaryBackground,
                        theme.current.primaryBackground
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .background(.ultraThinMaterial)
            )
        }
    }
}

struct UltraModernTypingIndicator: View {
    @State private var animationPhase = 0.0
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.current.tymoreAccent, theme.current.tymorePurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 10, height: 10)
                        .scaleEffect(1.0 + 0.5 * sin(animationPhase + Double(index) * 0.8))
                        .neonGlow(theme.current.tymoreAccent, radius: 6)
                        .animation(
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: false),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, TymoreSpacing.xl)
            .padding(.vertical, TymoreSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: TymoreRadius.xl)
                    .fill(theme.current.elevatedSurface)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: TymoreRadius.xl))
                    .overlay(
                        RoundedRectangle(cornerRadius: TymoreRadius.xl)
                            .stroke(theme.current.tymoreAccent.opacity(0.3), lineWidth: 1)
                    )
            )
            
            Spacer()
        }
        .onAppear {
            animationPhase = 2 * .pi
        }
    }
}

struct NeonErrorBanner: View {
    let message: String
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        HStack(spacing: TymoreSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(theme.current.warning)
                .font(.system(size: 18, weight: .semibold))
                .neonGlow(theme.current.warning, radius: 6)
            
            Text(message)
                .font(TymoreTypography.bodySmall)
                .foregroundColor(theme.current.primaryText)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.horizontal, TymoreSpacing.xl)
        .padding(.vertical, TymoreSpacing.md)
        .background(
            ZStack {
                Rectangle()
                    .fill(theme.current.warning.opacity(0.1))
                    .background(.thinMaterial)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [theme.current.warning, theme.current.warning.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 3)
                    .neonGlow(theme.current.warning, radius: 4)
            },
            alignment: .bottom
        )
    }
}

#Preview {
    ChatView(scheduleManager: ScheduleManager())
        .environmentObject(TymoreTheme.shared)
}
