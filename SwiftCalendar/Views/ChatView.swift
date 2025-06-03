//
//  ChatView.swift
//  SwiftCalendar
//
//  ELEGANT: Sophisticated chat interface - Black Butler aesthetic
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
                // Elegant navigation header
                ElegantNavigationHeader(viewModel: viewModel)
                
                // Messages with refined styling
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: TymoreSpacing.lg) {
                            ForEach(viewModel.messages) { message in
                                RefinedMessageBubble(
                                    message: message,
                                    viewModel: viewModel,
                                    onSuggestionTap: { suggestion in
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            viewModel.selectScheduleSuggestion(suggestion)
                                        }
                                    }
                                )
                                .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                ElegantTypingIndicator()
                            }
                        }
                        .padding(TymoreSpacing.xl)
                    }
                    .background(theme.current.primaryBackground)
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation(.easeOut(duration: 0.4)) {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                // Error banner with elegant styling
                if !viewModel.errorMessage.isEmpty {
                    ElegantErrorBanner(message: viewModel.errorMessage)
                }
                
                // Refined input area
                ElegantChatInput(
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

struct ElegantNavigationHeader: View {
    let viewModel: ChatViewModel
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        HStack(spacing: TymoreSpacing.lg) {
            // Refined AI avatar
            ZStack {
                Circle()
                    .fill(theme.current.elevatedSurface)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(theme.current.borderColor, lineWidth: 0.5)
                    )
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(theme.current.tymoreBlue)
            }
            .tymoreShadow(TymoreShadow.subtle)
            
            // Clean title
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: TymoreSpacing.sm) {
                    Text("Ty")
                        .font(TymoreTypography.headlineMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.current.primaryText)
                    
                    // Minimal AI indicator
                    Text("AI")
                        .font(TymoreTypography.labelSmall)
                        .fontWeight(.medium)
                        .foregroundColor(theme.current.tymoreBlue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(theme.current.tymoreBlue.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(theme.current.tymoreBlue.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(theme.current.success)
                        .frame(width: 6, height: 6)
                    
                    Text("Schedule Assistant")
                        .font(TymoreTypography.bodySmall)
                        .foregroundColor(theme.current.secondaryText)
                }
            }
            
            Spacer()
            
            // Minimal action buttons
            HStack(spacing: TymoreSpacing.md) {
                if !viewModel.selectedSuggestionIds.isEmpty {
                    Button(action: viewModel.clearSelections) {
                        Image(systemName: "clear")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.current.warning)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(theme.current.warning.opacity(0.1))
                                    .overlay(
                                        Circle()
                                            .stroke(theme.current.warning.opacity(0.3), lineWidth: 0.5)
                                    )
                            )
                    }
                }
                
                Button(action: viewModel.clearConversation) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.current.tertiaryText)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(theme.current.elevatedSurface)
                                .overlay(
                                    Circle()
                                        .stroke(theme.current.borderColor, lineWidth: 0.5)
                                )
                        )
                }
            }
        }
        .padding(.horizontal, TymoreSpacing.xl)
        .padding(.vertical, TymoreSpacing.lg)
        .background(
            Rectangle()
                .fill(theme.current.secondaryBackground)
                .overlay(
                    Rectangle()
                        .fill(theme.current.separatorColor)
                        .frame(height: 0.5),
                    alignment: .bottom
                )
        )
    }
}

struct RefinedMessageBubble: View {
    let message: ChatMessage
    let viewModel: ChatViewModel
    let onSuggestionTap: (ScheduleSuggestion) -> Void
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        HStack(alignment: .bottom, spacing: TymoreSpacing.md) {
            if message.isUser { Spacer(minLength: 60) }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: TymoreSpacing.md) {
                // Elegant message bubble
                Text(message.content)
                    .font(TymoreTypography.bodyMedium)
                    .foregroundColor(message.isUser ? .white : theme.current.primaryText)
                    .padding(.horizontal, TymoreSpacing.xl)
                    .padding(.vertical, TymoreSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: TymoreRadius.lg)
                            .fill(
                                message.isUser
                                ? theme.current.tymoreBlue
                                : theme.current.elevatedSurface
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: TymoreRadius.lg)
                                    .stroke(
                                        message.isUser ? Color.clear : theme.current.borderColor,
                                        lineWidth: 0.5
                                    )
                            )
                    )
                    .tymoreShadow(TymoreShadow.soft)
                
                // Refined schedule suggestions
                if let suggestions = message.suggestions, !suggestions.isEmpty {
                    ElegantScheduleSuggestions(
                        suggestions: suggestions,
                        viewModel: viewModel,
                        onTap: onSuggestionTap
                    )
                }
                
                // Subtle timestamp
                Text(message.timestamp.chatFormat())
                    .font(TymoreTypography.labelSmall)
                    .foregroundColor(theme.current.tertiaryText)
                    .padding(.horizontal, TymoreSpacing.sm)
            }
            
            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

struct ElegantScheduleSuggestions: View {
    let suggestions: [ScheduleSuggestion]
    let viewModel: ChatViewModel
    let onTap: (ScheduleSuggestion) -> Void
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: TymoreSpacing.md) {
            // Clean header
            HStack(spacing: TymoreSpacing.sm) {
                Image(systemName: "lightbulb")
                    .foregroundColor(theme.current.tymoreBlue)
                    .font(.system(size: 14, weight: .medium))
                
                Text("Optimal Times")
                    .font(TymoreTypography.labelMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.current.secondaryText)
                
                Spacer()
                
                Text("\(suggestions.count)")
                    .font(TymoreTypography.labelSmall)
                    .fontWeight(.medium)
                    .foregroundColor(theme.current.tertiaryText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(theme.current.tertiaryBackground)
                    )
            }
            .padding(.horizontal, TymoreSpacing.sm)
            
            // Elegant suggestion cards
            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                RefinedSuggestionCard(
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

struct RefinedSuggestionCard: View {
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
                // Elegant rank indicator
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                            ? theme.current.success
                            : theme.current.tertiaryBackground
                        )
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color.clear : theme.current.borderColor,
                                    lineWidth: 0.5
                                )
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(rank)")
                            .font(TymoreTypography.labelSmall)
                            .fontWeight(.medium)
                            .foregroundColor(theme.current.secondaryText)
                    }
                }
                
                // Clean content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(suggestion.timeSlot.startTime, formatter: timeFormatter)
                            .font(TymoreTypography.headlineSmall)
                            .fontWeight(.medium)
                            .foregroundColor(
                                isSelected ? theme.current.success : theme.current.primaryText
                            )
                        
                        Spacer()
                        
                        // Subtle score indicator
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(theme.current.success)
                                .font(.system(size: 18))
                        } else {
                            HStack(spacing: 2) {
                                ForEach(0..<5) { index in
                                    Circle()
                                        .fill(
                                            index < Int(suggestion.timeSlot.score * 5)
                                            ? theme.current.tymoreBlue
                                            : theme.current.tertiaryBackground
                                        )
                                        .frame(width: 4, height: 4)
                                }
                            }
                        }
                    }
                    
                    Text(suggestion.timeSlot.reasoning)
                        .font(TymoreTypography.bodySmall)
                        .foregroundColor(theme.current.secondaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    // Clean action indicator
                    HStack(spacing: 4) {
                        Image(systemName: isSelected ? "calendar.badge.checkmark" : "plus.circle")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(
                                isSelected ? theme.current.success : theme.current.tymoreBlue
                            )
                        
                        Text(isSelected ? "Scheduled" : "Tap to schedule")
                            .font(TymoreTypography.labelSmall)
                            .fontWeight(.medium)
                            .foregroundColor(
                                isSelected ? theme.current.success : theme.current.tymoreBlue
                            )
                    }
                }
                
                Spacer()
            }
            .padding(TymoreSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: TymoreRadius.md)
                    .fill(
                        isSelected
                        ? theme.current.success.opacity(0.05)
                        : theme.current.elevatedSurface
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: TymoreRadius.md)
                            .stroke(
                                isSelected ? theme.current.success.opacity(0.3) : theme.current.borderColor,
                                lineWidth: isSelected ? 1 : 0.5
                            )
                    )
            )
            .tymoreShadow(isSelected ? TymoreShadow.medium : TymoreShadow.subtle)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isSelected)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct ElegantChatInput: View {
    @Binding var inputText: String
    let isLoading: Bool
    @FocusState.Binding var isInputFocused: Bool
    let onSend: () -> Void
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(theme.current.separatorColor)
                .frame(height: 0.5)
            
            HStack(spacing: TymoreSpacing.lg) {
                // Refined input field
                HStack(spacing: TymoreSpacing.md) {
                    TextField("Ask Ty to optimize your schedule", text: $inputText, axis: .vertical)
                        .font(TymoreTypography.bodyMedium)
                        .foregroundColor(theme.current.primaryText)
                        .lineLimit(1...4)
                        .focused($isInputFocused)
                        .onSubmit(onSend)
                    
                    if !inputText.isEmpty {
                        Button(action: { inputText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(theme.current.tertiaryText)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, TymoreSpacing.lg)
                .padding(.vertical, TymoreSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: TymoreRadius.lg)
                        .fill(theme.current.elevatedSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: TymoreRadius.lg)
                                .stroke(
                                    isInputFocused ? theme.current.tymoreBlue.opacity(0.5) : theme.current.borderColor,
                                    lineWidth: isInputFocused ? 1 : 0.5
                                )
                        )
                )
                .tymoreShadow(isInputFocused ? TymoreShadow.focus : TymoreShadow.subtle)
                
                // Elegant send button
                Button(action: onSend) {
                    ZStack {
                        Circle()
                            .fill(
                                inputText.isEmpty || isLoading
                                ? theme.current.tertiaryBackground
                                : theme.current.tymoreBlue
                            )
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(
                                        inputText.isEmpty ? theme.current.borderColor : Color.clear,
                                        lineWidth: 0.5
                                    )
                            )
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(
                                    inputText.isEmpty ? theme.current.tertiaryText : .white
                                )
                        }
                    }
                }
                .disabled(inputText.isEmpty || isLoading)
                .scaleEffect(inputText.isEmpty ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: inputText.isEmpty)
            }
            .padding(TymoreSpacing.xl)
            .background(theme.current.secondaryBackground)
        }
    }
}

struct ElegantTypingIndicator: View {
    @State private var animationPhase = 0.0
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(theme.current.tertiaryText)
                        .frame(width: 6, height: 6)
                        .scaleEffect(1.0 + 0.3 * sin(animationPhase + Double(index) * 0.7))
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: false),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, TymoreSpacing.lg)
            .padding(.vertical, TymoreSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: TymoreRadius.lg)
                    .fill(theme.current.elevatedSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: TymoreRadius.lg)
                            .stroke(theme.current.borderColor, lineWidth: 0.5)
                    )
            )
            .tymoreShadow(TymoreShadow.subtle)
            
            Spacer()
        }
        .onAppear {
            animationPhase = 2 * .pi
        }
    }
}

struct ElegantErrorBanner: View {
    let message: String
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        HStack(spacing: TymoreSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(theme.current.warning)
                .font(.system(size: 16, weight: .medium))
            
            Text(message)
                .font(TymoreTypography.bodySmall)
                .foregroundColor(theme.current.primaryText)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.horizontal, TymoreSpacing.xl)
        .padding(.vertical, TymoreSpacing.md)
        .background(
            Rectangle()
                .fill(theme.current.warning.opacity(0.1))
                .overlay(
                    Rectangle()
                        .fill(theme.current.warning.opacity(0.3))
                        .frame(height: 2),
                    alignment: .bottom
                )
        )
    }
}

#Preview {
    ChatView(scheduleManager: ScheduleManager())
        .environmentObject(TymoreTheme.shared)
}
