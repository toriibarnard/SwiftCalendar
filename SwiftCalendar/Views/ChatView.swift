//
//  ChatView.swift
//  SwiftCalendar
//
//  Redesigned to showcase Ty's schedule optimization abilities
//

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @ObservedObject var scheduleManager: ScheduleManager
    @FocusState private var isInputFocused: Bool
    
    init(scheduleManager: ScheduleManager) {
        self.scheduleManager = scheduleManager
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(
                                    message: message,
                                    onSuggestionTap: { suggestion in
                                        viewModel.selectScheduleSuggestion(suggestion)
                                    }
                                )
                                .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                // Error message
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }
                
                Divider()
                
                // Input area
                HStack(spacing: 12) {
                    TextField("Ask when to schedule something...", text: $viewModel.inputText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(1...4)
                        .focused($isInputFocused)
                        .onSubmit {
                            viewModel.sendMessage()
                        }
                    
                    Button(action: viewModel.sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(viewModel.inputText.isEmpty ? .gray : .blue)
                    }
                    .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("Ty - Schedule Optimizer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        viewModel.clearConversation()
                    }
                    .font(.caption)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Calendar") {
                        // Dismiss to go back to calendar
                    }
                }
            }
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

struct MessageBubbleView: View {
    let message: ChatMessage
    let onSuggestionTap: (ScheduleSuggestion) -> Void
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                // Message content
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(message.isUser ? Color.blue : Color(UIColor.secondarySystemBackground))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(20)
                    .frame(maxWidth: 300, alignment: message.isUser ? .trailing : .leading)
                
                // Schedule suggestions (only for Ty's optimization responses)
                if let suggestions = message.suggestions, !suggestions.isEmpty {
                    ScheduleSuggestionsView(
                        suggestions: suggestions,
                        onTap: onSuggestionTap
                    )
                }
                
                // Timestamp
                Text(message.timestamp.chatFormat())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isUser { Spacer() }
        }
    }
}

struct ScheduleSuggestionsView: View {
    let suggestions: [ScheduleSuggestion]
    let onTap: (ScheduleSuggestion) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                ScheduleSuggestionCard(
                    suggestion: suggestion,
                    rank: index + 1,
                    onTap: { onTap(suggestion) }
                )
            }
        }
        .frame(maxWidth: 300)
    }
}

struct ScheduleSuggestionCard: View {
    let suggestion: ScheduleSuggestion
    let rank: Int
    let onTap: () -> Void
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE h:mm a"
        return formatter
    }
    
    private var scoreColor: Color {
        let score = suggestion.timeSlot.score
        if score >= 0.8 { return .green }
        if score >= 0.6 { return .orange }
        return .gray
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                // Header with rank and time
                HStack {
                    Text("#\(rank)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(scoreColor)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    Text(suggestion.timeSlot.startTime, formatter: timeFormatter)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Score indicator
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(index < Int(suggestion.timeSlot.score * 5) ? scoreColor : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                
                // Reasoning
                Text(suggestion.timeSlot.reasoning)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                // Action hint
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("Tap to schedule")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Spacer()
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(scoreColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TypingIndicator: View {
    @State private var animationAmount = 0.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationAmount)
                    .opacity(animationAmount)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: animationAmount
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
        .onAppear {
            animationAmount = 1.0
        }
    }
}

#Preview {
    ChatView(scheduleManager: ScheduleManager())
}
