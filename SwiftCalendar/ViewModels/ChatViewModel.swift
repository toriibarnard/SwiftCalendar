//
//  ChatViewModel.swift
//  SwiftCalendar
//
//  Direct GPT-4 approach - works like ChatGPT web
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
    
    private let gpt4 = DirectGPT4Calendar()
    weak var scheduleManager: ScheduleManager?
    
    init() {
        messages.append(ChatMessage(
            content: "Hey! I'm Ty. I can manage your calendar just like ChatGPT. Try:\n• \"I work Friday and Wednesday nights at 5:30pm until 10:30pm\"\n• \"I need to go to the gym 6 times this week\"\n• \"Add dentist June 4th at noon\"",
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
                // Get GPT-4 to process the request
                let (events, message) = try await gpt4.processRequest(userMessage, existingEvents: scheduleManager.events)
                
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
                
                // Show response
                messages.append(ChatMessage(
                    content: message,
                    isUser: false,
                    timestamp: Date()
                ))
                
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
