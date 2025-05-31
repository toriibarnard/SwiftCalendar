//
//  ChatViewModel.swift
//  SwiftCalendar
//
//  View model for managing AI chat interactions
//

import Foundation
import SwiftUI
import Combine

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
    
    private let openAIService = OpenAIService.shared
    private var conversationHistory: [OpenAIService.ChatMessage] = []
    weak var scheduleManager: ScheduleManager?
    
    init() {
        // Add welcome message
        messages.append(ChatMessage(
            content: "Hey! I'm Ty, your AI calendar assistant. I can help you:\n• Add events to your calendar\n• Find the best times for activities\n• Manage your schedule\n\nJust tell me what you need!",
            isUser: false,
            timestamp: Date()
        ))
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = inputText
        inputText = ""
        
        // Add user message to chat
        messages.append(ChatMessage(
            content: userMessage,
            isUser: true,
            timestamp: Date()
        ))
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let (response, functionCall) = try await openAIService.sendMessage(userMessage, conversationHistory: conversationHistory)
                
                // Update conversation history
                conversationHistory.append(OpenAIService.ChatMessage(role: "user", content: userMessage))
                conversationHistory.append(OpenAIService.ChatMessage(role: "assistant", content: response))
                
                // DEBUG: Log function call info
                if let functionCall = functionCall {
                    print("📞 Function call received: \(functionCall.name)")
                    print("📝 Arguments: \(functionCall.arguments)")
                    await handleFunctionCall(functionCall)
                } else {
                    print("❌ No function call in response")
                }
                
                // Add AI response to chat
                messages.append(ChatMessage(
                    content: response,
                    isUser: false,
                    timestamp: Date()
                ))
                
                isLoading = false
            } catch {
                print("❌ Error: \(error)")
                errorMessage = "Failed to get response: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func handleFunctionCall(_ functionCall: OpenAIService.FunctionCall) async {
        guard let scheduleManager = scheduleManager else {
            print("❌ No schedule manager available")
            return
        }
        
        do {
            let arguments = try JSONSerialization.jsonObject(with: Data(functionCall.arguments.utf8)) as? [String: Any] ?? [:]
            
            print("📊 Parsed arguments: \(arguments)")
            
            switch functionCall.name {
            case "add_event":
                await handleAddEvent(arguments: arguments, scheduleManager: scheduleManager)
                
            case "remove_event":
                await handleRemoveEvent(arguments: arguments, scheduleManager: scheduleManager)
                
            case "suggest_time":
                await handleSuggestTime(arguments: arguments, scheduleManager: scheduleManager)
                
            case "get_schedule":
                await handleGetSchedule(arguments: arguments, scheduleManager: scheduleManager)
                
            default:
                print("❌ Unknown function: \(functionCall.name)")
            }
        } catch {
            print("❌ Failed to parse function arguments: \(error)")
        }
    }
    
    private func handleAddEvent(arguments: [String: Any], scheduleManager: ScheduleManager) async {
        print("🎯 Handling add_event function")
        
        guard let title = arguments["title"] as? String,
              let startDateString = arguments["start_date"] as? String,
              let endDateString = arguments["end_date"] as? String,
              let categoryString = arguments["category"] as? String else {
            print("❌ Missing required arguments")
            print("   title: \(arguments["title"] ?? "nil")")
            print("   start_date: \(arguments["start_date"] ?? "nil")")
            print("   end_date: \(arguments["end_date"] ?? "nil")")
            print("   category: \(arguments["category"] ?? "nil")")
            return
        }
        
        // Try multiple date formats
        let iso8601Formatter = ISO8601DateFormatter()
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        localFormatter.timeZone = TimeZone.current
        
        let utcFormatter = DateFormatter()
        utcFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        // Try parsing with different formatters
        var startDate = iso8601Formatter.date(from: startDateString)
        var endDate = iso8601Formatter.date(from: endDateString)
        
        if startDate == nil {
            startDate = localFormatter.date(from: startDateString)
            endDate = localFormatter.date(from: endDateString)
        }
        
        if startDate == nil {
            startDate = utcFormatter.date(from: startDateString)
            endDate = utcFormatter.date(from: endDateString)
        }
        
        guard let validStartDate = startDate, let validEndDate = endDate else {
            print("❌ Failed to parse dates")
            print("   start: \(startDateString)")
            print("   end: \(endDateString)")
            return
        }
        
        print("📅 Parsed dates:")
        print("   Start: \(validStartDate)")
        print("   End: \(validEndDate)")
        
        let category = EventCategory(rawValue: categoryString) ?? .other
        let isRecurring = arguments["is_recurring"] as? Bool ?? false
        let recurrenceDays = arguments["recurrence_days"] as? [Int] ?? []
        
        print("✅ Creating event: \(title)")
        print("   Category: \(category)")
        print("   Start: \(validStartDate)")
        print("   End: \(validEndDate)")
        print("   Recurring: \(isRecurring)")
        print("   Recurrence days: \(recurrenceDays)")
        
        if isRecurring && !recurrenceDays.isEmpty {
            // Create recurring events for the next 4 weeks
            let calendar = Calendar.current
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            
            var eventsCreated = 0
            var currentDate = validStartDate
            
            // Get the hour and minute components from the original times
            let startComponents = calendar.dateComponents([.hour, .minute], from: validStartDate)
            let endComponents = calendar.dateComponents([.hour, .minute], from: validEndDate)
            
            while currentDate <= endOfMonth {
                let weekday = calendar.component(.weekday, from: currentDate) - 1 // Convert to 0-based
                if recurrenceDays.contains(weekday) {
                    // Create events with the same time but different dates
                    var eventStartComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                    eventStartComponents.hour = startComponents.hour
                    eventStartComponents.minute = startComponents.minute
                    
                    var eventEndComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                    eventEndComponents.hour = endComponents.hour
                    eventEndComponents.minute = endComponents.minute
                    
                    if let eventStart = calendar.date(from: eventStartComponents),
                       let eventEnd = calendar.date(from: eventEndComponents) {
                        let duration = Int(eventEnd.timeIntervalSince(eventStart) / 60)
                        scheduleManager.addAIEvent(
                            at: eventStart,
                            title: title,
                            category: category,
                            duration: duration
                        )
                        eventsCreated += 1
                        print("   Created event on \(eventStart)")
                    }
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            print("✅ Created \(eventsCreated) recurring events")
        } else {
            // Single event
            let duration = Int(validEndDate.timeIntervalSince(validStartDate) / 60)
            scheduleManager.addAIEvent(
                at: validStartDate,
                title: title,
                category: category,
                duration: duration
            )
            print("✅ Created single event")
            print("   Duration: \(duration) minutes")
        }
        
        print("📅 Total events in schedule: \(scheduleManager.events.count)")
    }
    
    private func handleRemoveEvent(arguments: [String: Any], scheduleManager: ScheduleManager) async {
        print("🎯 Handling remove_event function")
        
        guard let eventTitle = arguments["event_title"] as? String else {
            print("❌ Missing event title")
            return
        }
        
        let dateString = arguments["date"] as? String
        var targetDate: Date? = nil
        
        if let dateString = dateString {
            let formatter = ISO8601DateFormatter()
            targetDate = formatter.date(from: dateString)
        }
        
        // Find matching events
        let matchingEvents = scheduleManager.events.filter { event in
            let titleMatches = event.title.lowercased().contains(eventTitle.lowercased())
            
            if let targetDate = targetDate {
                let calendar = Calendar.current
                let eventDay = calendar.startOfDay(for: event.startTime)
                let targetDay = calendar.startOfDay(for: targetDate)
                return titleMatches && eventDay == targetDay
            }
            
            return titleMatches
        }
        
        print("📋 Found \(matchingEvents.count) matching events")
        
        // Remove all matching events
        for event in matchingEvents {
            scheduleManager.deleteEvent(event)
            print("🗑️ Removed: \(event.title) at \(event.startTime)")
        }
        
        if matchingEvents.isEmpty {
            print("❌ No events found matching '\(eventTitle)'")
        } else {
            print("✅ Removed \(matchingEvents.count) event(s)")
        }
    }
    
    private func handleSuggestTime(arguments: [String: Any], scheduleManager: ScheduleManager) async {
        print("🎯 Handling suggest_time function")
        // This would analyze the current schedule and suggest optimal times
        // For now, we'll rely on the AI's response text
    }
    
    private func handleGetSchedule(arguments: [String: Any], scheduleManager: ScheduleManager) async {
        print("🎯 Handling get_schedule function")
        // This would fetch and format the current schedule
        // For now, we'll rely on the AI's response text
    }
}

// Extension for Date formatting
extension Date {
    func chatFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
}
