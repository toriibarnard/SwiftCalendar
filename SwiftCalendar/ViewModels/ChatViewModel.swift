//
//  ChatViewModel.swift
//  SwiftCalendar
//
//  Updated with conversation memory and confirmation handling
//

import Foundation
import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showingConfirmation = false
    @Published var confirmationMessage = ""
    
    private let gpt4 = DirectGPT4Calendar()
    weak var scheduleManager: ScheduleManager?
    private var pendingAction: DirectGPT4Calendar.CalendarAction?
    
    init() {
        messages.append(ChatMessage(
            content: "Hey! I'm Ty, your smart calendar assistant. I remember our entire conversation and understand context. Try:\n\n• \"I work Friday and Wednesday nights at 5:30pm until 10:30pm\"\n• \"Delete everything\" (I'll ask for confirmation)\n• \"Yes\" or \"No\" to answer my questions\n• \"Find me 4 gym sessions this week, avoid my work hours\"",
            isUser: false,
            timestamp: Date()
        ))
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let scheduleManager = scheduleManager else { return }
        
        let userMessage = inputText
        inputText = ""
        
        messages.append(ChatMessage(
            content: userMessage,
            isUser: true,
            timestamp: Date()
        ))
        
        isLoading = true
        
        Task {
            do {
                // Get GPT-4 to process the request with conversation memory
                let (action, message) = try await gpt4.processRequest(userMessage, existingEvents: scheduleManager.events)
                
                // Handle the action
                await handleCalendarAction(action, message: message, scheduleManager: scheduleManager)
                
            } catch {
                print("Error: \(error)")
                messages.append(ChatMessage(
                    content: "I had trouble processing that. Try rephrasing your request.",
                    isUser: false,
                    timestamp: Date()
                ))
            }
            
            isLoading = false
        }
    }
    
    func confirmAction() {
        guard let action = pendingAction, let scheduleManager = scheduleManager else { return }
        
        Task {
            await executeAction(action, scheduleManager: scheduleManager)
            pendingAction = nil
            showingConfirmation = false
        }
    }
    
    func cancelAction() {
        pendingAction = nil
        showingConfirmation = false
        
        messages.append(ChatMessage(
            content: "Action cancelled. How else can I help you?",
            isUser: false,
            timestamp: Date()
        ))
    }
    
    private func handleCalendarAction(_ action: DirectGPT4Calendar.CalendarAction, message: String, scheduleManager: ScheduleManager) async {
        switch action {
        case .requestConfirmation(let confirmText, let pendingAction):
            // Store pending action and show confirmation dialog
            self.pendingAction = pendingAction
            self.confirmationMessage = confirmText
            
            messages.append(ChatMessage(
                content: confirmText,
                isUser: false,
                timestamp: Date()
            ))
            
            showingConfirmation = true
            
        case .removeAllEvents:
            // Execute immediately if no confirmation needed
            await executeAction(action, scheduleManager: scheduleManager)
            
            messages.append(ChatMessage(
                content: message.isEmpty ? "All events have been removed from your calendar." : message,
                isUser: false,
                timestamp: Date()
            ))
            
        default:
            // Handle other actions immediately
            await executeAction(action, scheduleManager: scheduleManager)
            
            messages.append(ChatMessage(
                content: message,
                isUser: false,
                timestamp: Date()
            ))
        }
    }
    
    private func executeAction(_ action: DirectGPT4Calendar.CalendarAction, scheduleManager: ScheduleManager) async {
        switch action {
        case .addEvents(let events):
            // Add events to calendar
            for event in events {
                if event.isRecurring && !event.recurrenceDays.isEmpty {
                    // Create recurring events
                    await createRecurringEvents(event, scheduleManager: scheduleManager)
                } else {
                    // Single event
                    let category = EventCategory(rawValue: event.category) ?? .personal
                    scheduleManager.addAIEvent(
                        at: event.date,
                        title: event.title,
                        category: category,
                        duration: event.duration
                    )
                }
            }
            
        case .removeEvents(let patterns):
            // Find and remove matching events
            let eventsToRemove = gpt4.findEventsToRemove(patterns, from: scheduleManager.events)
            
            print("🗑️ Found \(eventsToRemove.count) events to remove for patterns: \(patterns)")
            
            for event in eventsToRemove {
                scheduleManager.deleteEvent(event)
                print("🗑️ Deleted: \(event.title) on \(event.startTime)")
            }
            
            if eventsToRemove.isEmpty {
                messages.append(ChatMessage(
                    content: "I couldn't find any events matching '\(patterns.joined(separator: ", "))'. Try being more specific about what you want to remove.",
                    isUser: false,
                    timestamp: Date()
                ))
            }
            
        case .removeAllEvents:
            // Remove all events
            let allEvents = scheduleManager.events
            for event in allEvents {
                scheduleManager.deleteEvent(event)
            }
            
            print("🗑️ Deleted all \(allEvents.count) events")
            
        case .requestConfirmation(_, _):
            // Already handled in handleCalendarAction
            break
            
        case .showMessage(_):
            // Just show the message, no action needed
            break
        }
    }
    
    // Reset conversation (useful for testing)
    func clearConversation() {
        gpt4.clearConversationHistory()
        messages = [
            ChatMessage(
                content: "Conversation cleared! I'm ready to help you with your calendar.",
                isUser: false,
                timestamp: Date()
            )
        ]
    }
    
    private func createRecurringEvents(_ event: DirectGPT4Calendar.SimpleEvent, scheduleManager: ScheduleManager) async {
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .weekOfYear, value: 4, to: Date()) ?? Date()
        
        var currentDate = event.date
        let baseComponents = calendar.dateComponents([.hour, .minute], from: event.date)
        
        while currentDate <= endDate {
            let weekday = calendar.component(.weekday, from: currentDate) - 1 // 0-based
            
            if event.recurrenceDays.contains(weekday) {
                var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
                components.hour = baseComponents.hour
                components.minute = baseComponents.minute
                
                if let eventDate = calendar.date(from: components) {
                    let category = EventCategory(rawValue: event.category) ?? .personal
                    scheduleManager.addAIEvent(
                        at: eventDate,
                        title: event.title,
                        category: category,
                        duration: event.duration
                    )
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
    }
}

extension Date {
    func chatFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
}
