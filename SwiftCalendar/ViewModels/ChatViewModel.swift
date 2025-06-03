//
//  ChatViewModel.swift
//  SwiftCalendar
//
//  FIXED: Multiple selection support + theme integration
//

import Foundation
import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    let suggestions: [ScheduleSuggestion]? // New: for optimization responses
}

struct ScheduleSuggestion: Identifiable {
    let id = UUID()
    let timeSlot: IntelligentTyAI.TimeSlot
    let taskTitle: String
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showingConfirmation = false
    @Published var confirmationMessage = ""
    @Published var userPreferences = UserSchedulePreferences()
    @Published var selectedSuggestionIds: Set<UUID> = [] // NEW: Track selected suggestions
    
    private let intelligentTy = IntelligentTyAI()
    weak var scheduleManager: ScheduleManager?
    private var pendingOptimization: IntelligentTyAI.FlexibleTask?
    private var pendingSuggestions: [IntelligentTyAI.TimeSlot] = []
    
    init() {
        messages.append(ChatMessage(
            content: """
            Hi! I'm Ty, your intelligent schedule assistant. 
            
            🎯 **My main superpower**: Finding the BEST times for your flexible tasks!
            
            Try asking me:
            • "When should I go to the gym this week?"
            • "Find me time for a 2-hour study session"
            • "What's the best time for a dentist appointment?"
            
            📅 I can also automate your calendar:
            • "I work 8:30-4 on weekdays"
            • "Add gym Monday, Wednesday, Friday at 6pm"
            
            What would you like help optimizing?
            """,
            isUser: false,
            timestamp: Date(),
            suggestions: nil
        ))
        
        // Load user preferences from UserDefaults or Firebase
        loadUserPreferences()
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let scheduleManager = scheduleManager else { return }
        
        let userMessage = inputText
        inputText = ""
        
        // UPDATED: Clear selected suggestions when starting new query
        selectedSuggestionIds.removeAll()
        
        messages.append(ChatMessage(
            content: userMessage,
            isUser: true,
            timestamp: Date(),
            suggestions: nil
        ))
        
        isLoading = true
        
        Task {
            do {
                // Process with the new intelligent Ty AI
                let response = try await intelligentTy.processRequest(
                    userMessage,
                    existingEvents: scheduleManager.events,
                    userPreferences: userPreferences
                )
                
                // Handle different types of responses
                await handleTyResponse(response, scheduleManager: scheduleManager)
                
            } catch {
                print("Error: \(error)")
                messages.append(ChatMessage(
                    content: "I had trouble processing that. Could you try rephrasing your request?",
                    isUser: false,
                    timestamp: Date(),
                    suggestions: nil
                ))
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Response Handling
    
    private func handleTyResponse(_ response: IntelligentTyAI.TyResponse, scheduleManager: ScheduleManager) async {
        switch response {
        case .scheduleOptimization(let task, let suggestions, let message):
            print("🎯 Schedule optimization response for: \(task.title)")
            print("💡 Found \(suggestions.count) suggestions")
            
            // Store for potential scheduling
            pendingOptimization = task
            pendingSuggestions = suggestions
            
            // Convert to UI suggestions
            let uiSuggestions = suggestions.map { timeSlot in
                ScheduleSuggestion(timeSlot: timeSlot, taskTitle: task.title)
            }
            
            messages.append(ChatMessage(
                content: message,
                isUser: false,
                timestamp: Date(),
                suggestions: uiSuggestions
            ))
            
            // Learn from this interaction
            updateUserPreferences(for: task, selectedSlots: suggestions)
            
        case .calendarAutomation(let action, let message):
            print("📅 Calendar automation response")
            await executeCalendarAction(action, scheduleManager: scheduleManager)
            
            messages.append(ChatMessage(
                content: message,
                isUser: false,
                timestamp: Date(),
                suggestions: nil
            ))
            
        case .requestConfirmation(let confirmText, let pendingAction):
            print("❓ Confirmation requested")
            confirmationMessage = confirmText
            showingConfirmation = true
            
            messages.append(ChatMessage(
                content: confirmText,
                isUser: false,
                timestamp: Date(),
                suggestions: nil
            ))
            
        case .conversational(let message):
            print("💬 Conversational response")
            messages.append(ChatMessage(
                content: message,
                isUser: false,
                timestamp: Date(),
                suggestions: nil
            ))
            
        case .clarifyingQuestion(let question, let context):
            print("🤔 Clarifying question")
            messages.append(ChatMessage(
                content: question,
                isUser: false,
                timestamp: Date(),
                suggestions: nil
            ))
        }
    }
    
    // MARK: - UPDATED: Schedule Suggestion Selection
    
    func selectScheduleSuggestion(_ suggestion: ScheduleSuggestion) {
        guard let task = pendingOptimization,
              let scheduleManager = scheduleManager else { return }
        
        // Check if already selected
        if selectedSuggestionIds.contains(suggestion.id) {
            return // Already selected, do nothing
        }
        
        print("✅ User selected suggestion: \(suggestion.taskTitle) at \(suggestion.timeSlot.startTime)")
        
        // Add to selected set
        selectedSuggestionIds.insert(suggestion.id)
        
        // Create the event
        scheduleManager.addAIEvent(
            at: suggestion.timeSlot.startTime,
            title: task.title,
            category: task.category,
            duration: task.duration
        )
        
        // Learn from this selection
        learnFromSelection(task: task, selectedSlot: suggestion.timeSlot)
        
        // NO MESSAGE SENT - just visual feedback via UI update
        print("📅 Event scheduled, UI will show checkmark")
    }
    
    // NEW: Check if suggestion is selected
    func isSuggestionSelected(_ suggestion: ScheduleSuggestion) -> Bool {
        return selectedSuggestionIds.contains(suggestion.id)
    }
    
    // NEW: Clear all selections (could be used with a "Clear" button)
    func clearSelections() {
        selectedSuggestionIds.removeAll()
        pendingOptimization = nil
        pendingSuggestions = []
    }
    
    // MARK: - Calendar Action Execution
    
    private func executeCalendarAction(_ action: IntelligentTyAI.CalendarAction, scheduleManager: ScheduleManager) async {
        switch action {
        case .addEvents(let events):
            print("📅 Adding \(events.count) events")
            for event in events {
                let category = EventCategory(rawValue: event.category) ?? .personal
                scheduleManager.addAIEvent(
                    at: event.date,
                    title: event.title,
                    category: category,
                    duration: event.duration
                )
            }
            
        case .removeEvents(let patterns):
            print("🗑️ Removing events matching: \(patterns)")
            // Implementation for removing events
            
        case .removeAllEvents:
            print("🗑️ Removing all events")
            let allEvents = scheduleManager.events
            for event in allEvents {
                scheduleManager.deleteEvent(event)
            }
            
        case .showMessage(let message):
            print("💬 Show message: \(message)")
            // Already handled in the response
        }
    }
    
    // MARK: - Learning and Preferences
    
    private func updateUserPreferences(for task: IntelligentTyAI.FlexibleTask, selectedSlots: [IntelligentTyAI.TimeSlot]) {
        // Learn from the suggestions provided (even if not selected yet)
        if !selectedSlots.isEmpty {
            var categoryPref = userPreferences.categoryPreferences[task.category] ?? CategoryPreference()
            
            // Record the hours that were suggested as good options
            for slot in selectedSlots.prefix(2) { // Top 2 suggestions
                let hour = Calendar.current.component(.hour, from: slot.startTime)
                categoryPref.preferredHours.insert(hour)
            }
            
            // Update average duration for this category
            let existingAvg = categoryPref.averageDuration
            categoryPref.averageDuration = (existingAvg + task.duration) / 2
            
            userPreferences.categoryPreferences[task.category] = categoryPref
            saveUserPreferences()
        }
    }
    
    private func learnFromSelection(task: IntelligentTyAI.FlexibleTask, selectedSlot: IntelligentTyAI.TimeSlot) {
        // Learn from user's actual selection
        var categoryPref = userPreferences.categoryPreferences[task.category] ?? CategoryPreference()
        
        let selectedHour = Calendar.current.component(.hour, from: selectedSlot.startTime)
        
        // Strongly reinforce the selected hour
        categoryPref.preferredHours.insert(selectedHour)
        
        // Also record adjacent hours as preferred
        categoryPref.preferredHours.insert(max(6, selectedHour - 1))
        categoryPref.preferredHours.insert(min(23, selectedHour + 1))
        
        userPreferences.categoryPreferences[task.category] = categoryPref
        saveUserPreferences()
        
        print("🧠 Learned preference: \(task.category) at \(selectedHour):00")
    }
    
    // MARK: - Persistence
    
    private func loadUserPreferences() {
        if let data = UserDefaults.standard.data(forKey: "TyUserPreferences"),
           let preferences = try? JSONDecoder().decode(UserSchedulePreferences.self, from: data) {
            self.userPreferences = preferences
            print("📱 Loaded user preferences from UserDefaults")
        } else {
            print("📱 Using default user preferences")
        }
    }
    
    private func saveUserPreferences() {
        if let data = try? JSONEncoder().encode(userPreferences) {
            UserDefaults.standard.set(data, forKey: "TyUserPreferences")
            print("💾 Saved user preferences to UserDefaults")
        }
    }
    
    // MARK: - Utility Functions
    
    func clearConversation() {
        intelligentTy.clearConversationHistory()
        selectedSuggestionIds.removeAll() // NEW: Clear selections too
        messages = [
            ChatMessage(
                content: "Conversation cleared! What would you like help optimizing today?",
                isUser: false,
                timestamp: Date(),
                suggestions: nil
            )
        ]
    }
    
    func confirmAction() {
        // Handle confirmations for dangerous actions
        showingConfirmation = false
        // Implementation depends on what was being confirmed
    }
    
    func cancelAction() {
        showingConfirmation = false
        messages.append(ChatMessage(
            content: "Action cancelled. What else can I help you with?",
            isUser: false,
            timestamp: Date(),
            suggestions: nil
        ))
    }
}

extension Date {
    func chatFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
}
