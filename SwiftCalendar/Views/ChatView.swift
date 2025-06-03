//
//  ChatView.swift
//  SwiftCalendar
//
//  FINAL: Complete theme integration with multiple selection
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
            VStack(spacing: 0) {
                // Custom Navigation Header
                TymoreNavigationHeader(viewModel: viewModel)
                
                // Messages list with custom styling
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: TymoreSpacing.md) {
                            ForEach(viewModel.messages) { message in
                                TymoreMessageBubble(
                                    message: message,
                                    viewModel: viewModel,
                                    onSuggestionTap: { suggestion in
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                            viewModel.selectScheduleSuggestion(suggestion)
                                        }
                                    }
                                )
                                .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                TymoreTypingIndicator()
                            }
                        }
                        .padding(TymoreSpacing.lg)
                    }
                    .background(theme.current.primaryBackground)
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation(.easeOut(duration: 0.5)) {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                // Error banner
                if !viewModel.errorMessage.isEmpty {
                    TymoreErrorBanner(message: viewModel.errorMessage)
                }
                
                // Custom input area
                TymoreChatInput(
                    inputText: $viewModel.inputText,
                    isLoading: viewModel.isLoading,
                    isInputFocused: $isInputFocused,
                    onSend: viewModel.sendMessage
                )
            }
            .background(theme.current.primaryBackground)
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

struct TymoreNavigationHeader: View {
    let viewModel: ChatViewModel
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        HStack(spacing: TymoreSpacing.md) {
            // Ty AI Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.current.tymoreBlue, theme.current.tymoreSteel],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            .tymoreShadow(TymoreShadow.subtle)
            
            // Title and status
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: TymoreSpacing.xs) {
                    Text("Ty")
                        .font(TymoreTypography.headlineMedium)
                        .foregroundColor(theme.current.primaryText)
                    
                    // AI indicator
                    Text("AI")
                        .font(TymoreTypography.labelSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(theme.current.tymoreAccent)
                        .cornerRadius(TymoreRadius.xs)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(theme.current.success)
                        .frame(width: 6, height: 6)
                    
                    Text("Schedule Optimizer")
                        .font(TymoreTypography.bodySmall)
                        .foregroundColor(theme.current.secondaryText)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: TymoreSpacing.sm) {
                // Clear selections button
                if !viewModel.selectedSuggestionIds.isEmpty {
                    Button(action: viewModel.clearSelections) {
                        Image(systemName: "clear")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.current.warning)
                    }
                }
                
                // Clear conversation button
                Button(action: viewModel.clearConversation) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.current.tertiaryText)
                }
            }
        }
        .padding(.horizontal, TymoreSpacing.lg)
        .padding(.vertical, TymoreSpacing.md)
        .background(theme.current.secondaryBackground)
        .overlay(
            Rectangle()
                .fill(theme.current.separatorColor)
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

struct TymoreMessageBubble: View {
    let message: ChatMessage
    let viewModel: ChatViewModel
    let onSuggestionTap: (ScheduleSuggestion) -> Void
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        HStack(alignment: .bottom, spacing: TymoreSpacing.sm) {
            if message.isUser { Spacer(minLength: 50) }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: TymoreSpacing.sm) {
                // Message bubble
                Text(message.content)
                    .font(TymoreTypography.bodyMedium)
                    .foregroundColor(message.isUser ? .white : theme.current.primaryText)
                    .padding(.horizontal, TymoreSpacing.lg)
                    .padding(.vertical, TymoreSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: TymoreRadius.lg)
                            .fill(
                                message.isUser
                                ? LinearGradient(
                                    colors: [theme.current.tymoreBlue, theme.current.tymoreSteel],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [theme.current.cardBackground, theme.current.cardBackground],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: TymoreRadius.lg)
                            .stroke(
                                message.isUser ? Color.clear : theme.current.borderColor,
                                lineWidth: 1
                            )
                    )
                    .tymoreShadow(message.isUser ? TymoreShadow.soft : TymoreShadow.subtle)
                
                // Schedule suggestions with enhanced styling
                if let suggestions = message.suggestions, !suggestions.isEmpty {
                    TymoreScheduleSuggestions(
                        suggestions: suggestions,
                        viewModel: viewModel,
                        onTap: onSuggestionTap
                    )
                }
                
                // Timestamp
                Text(message.timestamp.chatFormat())
                    .font(TymoreTypography.labelSmall)
                    .foregroundColor(theme.current.tertiaryText)
                    .padding(.horizontal, TymoreSpacing.sm)
            }
            
            if !message.isUser { Spacer(minLength: 50) }
        }
    }
}

struct TymoreScheduleSuggestions: View {
    let suggestions: [ScheduleSuggestion]
    let viewModel: ChatViewModel
    let onTap: (ScheduleSuggestion) -> Void
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: TymoreSpacing.sm) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(theme.current.tymoreAccent)
                    .font(.system(size: 14))
                
                Text("Optimal Time Suggestions")
                    .font(TymoreTypography.labelMedium)
                    .foregroundColor(theme.current.secondaryText)
                
                Spacer()
            }
            .padding(.horizontal, TymoreSpacing.sm)
            
            // Suggestions
            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                TymoreSuggestionCard(
                    suggestion: suggestion,
                    rank: index + 1,
                    isSelected: viewModel.isSuggestionSelected(suggestion),
                    onTap: { onTap(suggestion) }
                )
            }
        }
        .frame(maxWidth: 320)
    }
}

struct TymoreSuggestionCard: View {
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
                // Rank badge
                Text("#\(rank)")
                    .font(TymoreTypography.labelSmall)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isSelected ? theme.current.success : theme.current.tymoreSteel)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(suggestion.timeSlot.startTime, formatter: timeFormatter)
                            .font(TymoreTypography.headlineSmall)
                            .foregroundColor(isSelected ? theme.current.success : theme.current.primaryText)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        // Status indicator
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(theme.current.success)
                                .font(.system(size: 20))
                        } else {
                            // Score visualization
                            HStack(spacing: 2) {
                                ForEach(0..<5) { index in
                                    Circle()
                                        .fill(
                                            index < Int(suggestion.timeSlot.score * 5)
                                            ? theme.current.tymoreBlue
                                            : theme.current.tertiaryBackground
                                        )
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }
                    }
                    
                    Text(suggestion.timeSlot.reasoning)
                        .font(TymoreTypography.bodySmall)
                        .foregroundColor(theme.current.secondaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    // Action indicator
                    HStack(spacing: 4) {
                        Image(systemName: isSelected ? "calendar.badge.checkmark" : "plus.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(isSelected ? theme.current.success : theme.current.tymoreBlue)
                        
                        Text(isSelected ? "Scheduled" : "Tap to schedule")
                            .font(TymoreTypography.labelSmall)
                            .foregroundColor(isSelected ? theme.current.success : theme.current.tymoreBlue)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
            }
            .padding(TymoreSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: TymoreRadius.md)
                    .fill(
                        isSelected
                        ? theme.current.success.opacity(0.1)
                        : theme.current.cardBackground
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: TymoreRadius.md)
                    .stroke(
                        isSelected ? theme.current.success : theme.current.borderColor,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .tymoreShadow(isSelected ? TymoreShadow.medium : TymoreShadow.subtle)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isSelected)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
}

struct TymoreChatInput: View {
    @Binding var inputText: String
    let isLoading: Bool
    @FocusState.Binding var isInputFocused: Bool
    let onSend: () -> Void
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(theme.current.separatorColor)
                .frame(height: 1)
            
            HStack(spacing: TymoreSpacing.md) {
                // Input field with sophisticated styling
                HStack(spacing: TymoreSpacing.sm) {
                    TextField("Ask Ty to optimize your schedule...", text: $inputText, axis: .vertical)
                        .font(TymoreTypography.bodyMedium)
                        .foregroundColor(theme.current.primaryText)
                        .lineLimit(1...4)
                        .focused($isInputFocused)
                        .onSubmit(onSend)
                    
                    if !inputText.isEmpty {
                        Button(action: { inputText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(theme.current.tertiaryText)
                        }
                    }
                }
                .padding(.horizontal, TymoreSpacing.md)
                .padding(.vertical, TymoreSpacing.sm)
                .background(theme.current.tertiaryBackground)
                .cornerRadius(TymoreRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: TymoreRadius.lg)
                        .stroke(
                            isInputFocused ? theme.current.tymoreBlue : theme.current.borderColor,
                            lineWidth: isInputFocused ? 2 : 1
                        )
                )
                
                // Send button with gradient
                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(
                                    inputText.isEmpty || isLoading
                                    ? LinearGradient(colors: [theme.current.tertiaryText], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(
                                        colors: [theme.current.tymoreBlue, theme.current.tymoreSteel],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .tymoreShadow(inputText.isEmpty ? TymoreShadow.subtle : TymoreShadow.soft)
                }
                .disabled(inputText.isEmpty || isLoading)
                .scaleEffect(inputText.isEmpty ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: inputText.isEmpty)
            }
            .padding(TymoreSpacing.lg)
            .background(theme.current.secondaryBackground)
        }
    }
}

struct TymoreTypingIndicator: View {
    @State private var animationPhase = 0.0
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(theme.current.tymoreBlue)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0 + 0.3 * sin(animationPhase + Double(index) * 0.7))
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: false),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, TymoreSpacing.lg)
            .padding(.vertical, TymoreSpacing.md)
            .background(theme.current.cardBackground)
            .cornerRadius(TymoreRadius.lg)
            .tymoreShadow(TymoreShadow.subtle)
            
            Spacer()
        }
        .onAppear {
            animationPhase = 2 * .pi
        }
    }
}

struct TymoreErrorBanner: View {
    let message: String
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        HStack(spacing: TymoreSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(theme.current.warning)
            
            Text(message)
                .font(TymoreTypography.bodySmall)
                .foregroundColor(theme.current.primaryText)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.horizontal, TymoreSpacing.lg)
        .padding(.vertical, TymoreSpacing.sm)
        .background(theme.current.warning.opacity(0.1))
        .overlay(
            Rectangle()
                .fill(theme.current.warning)
                .frame(height: 2),
            alignment: .bottom
        )
    }
}

#Preview {
    ChatView(scheduleManager: ScheduleManager())
        .environmentObject(TymoreTheme.shared)
}
