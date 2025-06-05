//
//  ChatViewModel.swift
//  SwiftCalendar
//
//  UPDATED: ChatViewModel with intelligent scheduling integration
//

import Foundation
import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    let suggestions: [ScheduleSuggestion]? // Time slot suggestions
}

struct ScheduleSuggestion: Identifiable {
    let id = UUID()
    let timeSlot: TimeSlotSuggestion
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
    @Published var selectedSuggestionIds: Set<UUID> = []
    
    private let intelligentTy = IntelligentTyAI()
    weak var scheduleManager: ScheduleManager?
    private var pendingOptimization: FlexibleTask?
    private var pendingSuggestions: [TimeSlotSuggestion] = []
    
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
        
        loadUserPreferences()
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let scheduleManager = scheduleManager else { return }
        
        let userMessage = inputText
        inputText = ""
        
        // Clear selected suggestions when starting new query
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
                // Get current events and user preferences
                let currentEvents = scheduleManager.events
                let userPreferences = getUserPreferences()
                
                print("🧠 Sending request with \(currentEvents.count) existing events for context")
                
                // Process with the intelligent Ty AI using new architecture
                let response = try await intelligentTy.processRequest(
                    userMessage,
                    existingEvents: currentEvents,
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
    
    private func handleTyResponse(_ response: TyResponse, scheduleManager: ScheduleManager) async {
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
            
        case .requestConfirmation(let confirmText, _):
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
            
        case .clarifyingQuestion(let question, _):
            print("🤔 Clarifying question")
            messages.append(ChatMessage(
                content: question,
                isUser: false,
                timestamp: Date(),
                suggestions: nil
            ))
        }
    }
    
    // MARK: - Schedule Suggestion Selection
    
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
        
        // Create the event using the new event category
        scheduleManager.addAIEvent(
            at: suggestion.timeSlot.startTime,
            title: task.title,
            category: task.category.eventCategory, // Convert to EventCategory
            duration: task.duration
        )
        
        // Learn from this selection
        learnFromSelection(task: task, selectedSlot: suggestion.timeSlot)
        
        print("📅 Event scheduled, UI will show checkmark")
    }
    
    // Check if suggestion is selected
    func isSuggestionSelected(_ suggestion: ScheduleSuggestion) -> Bool {
        return selectedSuggestionIds.contains(suggestion.id)
    }
    
    // Clear all selections
    func clearSelections() {
        selectedSuggestionIds.removeAll()
        pendingOptimization = nil
        pendingSuggestions = []
    }
    
    // MARK: - Calendar Action Execution
    
    private func executeCalendarAction(_ action: CalendarAction, scheduleManager: ScheduleManager) async {
        switch action {
        case .addEvents(let events):
            print("📅 Adding \(events.count) events")
            for event in events {
                let category = EventCategory(rawValue: event.category) ?? .personal
                scheduleManager.addAIEvent(
                    at: event.startDate,
                    title: event.title,
                    category: category,
                    duration: event.duration
                )
            }
            
        case .removeEvents(let patterns):
            print("🗑️ Removing events matching: \(patterns)")
            // Implementation for removing events based on patterns
            let allEvents = scheduleManager.events
            for pattern in patterns {
                let matchingEvents = allEvents.filter { event in
                    event.title.lowercased().contains(pattern.lowercased())
                }
                for event in matchingEvents {
                    scheduleManager.deleteEvent(event)
                }
            }
            
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
    
    private func updateUserPreferences(for task: FlexibleTask, selectedSlots: [TimeSlotSuggestion]) {
        // Learn from the suggestions provided (even if not selected yet)
        if !selectedSlots.isEmpty {
            let preferences = getUserPreferences()
            
            // Record the hours that were suggested as good options
            for slot in selectedSlots.prefix(2) { // Top 2 suggestions
                let hour = Calendar.current.component(.hour, from: slot.startTime)
                // Update preferences based on category and hour
                // This is a simplified version - you might want to expand this
                print("🧠 Learning: \(task.category) works well at \(hour):00")
            }
            
            saveUserPreferences(preferences)
        }
    }
    
    private func learnFromSelection(task: FlexibleTask, selectedSlot: TimeSlotSuggestion) {
        let selectedHour = Calendar.current.component(.hour, from: selectedSlot.startTime)
        
        var preferences = getUserPreferences()
        
        // Create mutable copy of time preferences
        var mutableTimePreferences = preferences.timePreferences
        
        // Update time preference for this category based on selection
        if selectedHour <= 12 {
            mutableTimePreferences[task.category] = .morning
        } else if selectedHour <= 17 {
            mutableTimePreferences[task.category] = .afternoon
        } else {
            mutableTimePreferences[task.category] = .evening
        }
        
        // Create new preferences with updated time preferences
        let updatedPreferences = UserSchedulePreferences(
            workingHours: preferences.workingHours,
            preferredMorningStart: preferences.preferredMorningStart,
            preferredEveningEnd: preferences.preferredEveningEnd,
            timePreferences: mutableTimePreferences,
            bufferTime: preferences.bufferTime
        )
        
        saveUserPreferences(updatedPreferences)
        
        print("🧠 Learned preference: \(task.category) at \(selectedHour):00")
    }
    
    // MARK: - User Preferences Management
    
    private func getUserPreferences() -> UserSchedulePreferences {
        if let data = UserDefaults.standard.data(forKey: "TyUserPreferences") {
            do {
                let preferences = try JSONDecoder().decode(UserSchedulePreferences.self, from: data)
                return preferences
            } catch {
                print("❌ Failed to decode user preferences: \(error)")
                return UserSchedulePreferences()
            }
        } else {
            return UserSchedulePreferences()
        }
    }
    
    private func saveUserPreferences(_ preferences: UserSchedulePreferences) {
        do {
            let data = try JSONEncoder().encode(preferences)
            UserDefaults.standard.set(data, forKey: "TyUserPreferences")
            print("💾 Saved user preferences")
        } catch {
            print("❌ Failed to save user preferences: \(error)")
        }
    }
    
    private func loadUserPreferences() {
        // Load preferences from UserDefaults
        _ = getUserPreferences()
        print("📱 Loaded user preferences")
    }
    
    // MARK: - Utility Functions
    
    func clearConversation() {
        intelligentTy.clearConversationHistory()
        selectedSuggestionIds.removeAll()
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
        showingConfirmation = false
        // Handle confirmations for dangerous actions
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

// MARK: - Extensions

extension Date {
    func chatFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
}
