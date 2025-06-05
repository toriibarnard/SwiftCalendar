//
//  CompatibilityExtensions.swift
//  SwiftCalendar
//
//  FIXED: Extensions to ensure the compatibility between old and new architecture
//

import Foundation

// MARK: - ScheduleEvent Extensions

extension ScheduleEvent {
    /// Convert to SmartScheduleOptimizer.FixedEvent for compatibility
    func toSmartScheduleOptimizerFixedEvent() -> SmartScheduleOptimizer.FixedEvent {
        let endTime = self.startTime.addingTimeInterval(TimeInterval(self.duration * 60))
        return SmartScheduleOptimizer.FixedEvent(
            title: self.title,
            startDate: self.startTime,
            endDate: endTime
        )
    }
}

// MARK: - EventCategory Extensions

extension EventCategory {
    /// Convert to FlexibleTask.TaskCategory
    var flexibleTaskCategory: FlexibleTask.TaskCategory {
        switch self {
        case .work: return .work
        case .fitness: return .fitness
        case .personal: return .personal
        case .study: return .study
        case .health: return .health
        case .social: return .social
        case .other: return .other
        }
    }
    
    /// Convert to SmartScheduleOptimizer.TaskCategory
    var smartScheduleOptimizerCategory: SmartScheduleOptimizer.TaskCategory {
        switch self {
        case .work: return .work
        case .fitness: return .fitness
        case .personal: return .personal
        case .study: return .study
        case .health: return .health
        case .social: return .social
        case .other: return .other
        }
    }
}

// MARK: - FlexibleTask.TaskCategory Extensions

extension FlexibleTask.TaskCategory {
    /// Convert to SmartScheduleOptimizer.TaskCategory
    var smartScheduleOptimizerCategory: SmartScheduleOptimizer.TaskCategory {
        switch self {
        case .work: return .work
        case .fitness: return .fitness
        case .personal: return .personal
        case .study: return .study
        case .health: return .health
        case .social: return .social
        case .other: return .other
        }
    }
}

// MARK: - SmartScheduleOptimizer.TaskCategory Extensions

extension SmartScheduleOptimizer.TaskCategory {
    /// Convert to FlexibleTask.TaskCategory
    var flexibleTaskCategory: FlexibleTask.TaskCategory {
        switch self {
        case .work: return .work
        case .fitness: return .fitness
        case .personal: return .personal
        case .study: return .study
        case .health: return .health
        case .social: return .social
        case .other: return .other
        }
    }
    
    /// Convert to EventCategory
    func toEventCategory() -> EventCategory {
        switch self {
        case .work: return .work
        case .fitness: return .fitness
        case .personal: return .personal
        case .study: return .study
        case .health: return .health
        case .social: return .social
        case .other: return .other
        }
    }
}

// MARK: - TimeSlotSuggestion Extensions

extension TimeSlotSuggestion {
    /// Convert to SmartScheduleOptimizer.TimeSlot for compatibility
    var smartScheduleOptimizerTimeSlot: SmartScheduleOptimizer.TimeSlot {
        return SmartScheduleOptimizer.TimeSlot(
            startTime: self.startTime,
            endTime: self.endTime,
            score: self.score,
            reasoning: self.reasoning ?? ""
        )
    }
}

// MARK: - SmartScheduleOptimizer.TimeSlot Extensions

extension SmartScheduleOptimizer.TimeSlot {
    /// Convert to TimeSlotSuggestion
    func toTimeSlotSuggestion(category: FlexibleTask.TaskCategory) -> TimeSlotSuggestion {
        return TimeSlotSuggestion(
            startTime: self.startTime,
            endTime: self.endTime,
            score: self.score,
            reasoning: self.reasoning,
            category: category
        )
    }
}

// MARK: - Date Extensions

extension Date {
    /// Format for chat messages
    func chatTimeFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
    
    /// Format for schedule suggestions
    func suggestionFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d 'at' h:mm a"
        return formatter.string(from: self)
    }
    
    /// Format for day display
    func dayFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: self)
    }
}

// MARK: - SimpleEvent Extensions

extension SimpleEvent {
    /// Convert to CalendarEvent for storage
    func toCalendarEvent(userId: String) -> CalendarEvent {
        return CalendarEvent(
            userId: userId,
            title: self.title,
            startDate: self.startDate,
            endDate: self.endDate,
            isFixed: true,
            category: EventCategory(rawValue: self.category) ?? .personal
        )
    }
}

// MARK: - CalendarEvent Extensions

extension CalendarEvent {
    /// Convert to SimpleEvent for UI display
    var simpleEvent: SimpleEvent {
        return SimpleEvent(
            title: self.title,
            startDate: self.startDate,
            endDate: self.endDate,
            category: self.category.rawValue,
            isRecurring: false,
            recurrenceDays: []
        )
    }
    
    /// Convert to ScheduleEvent for schedule management
    var scheduleEvent: ScheduleEvent {
        let duration = Int(self.endDate.timeIntervalSince(self.startDate) / 60)
        let isAIGenerated = self.description?.contains("AI-generated") == true
        
        return ScheduleEvent(
            title: self.title,
            startTime: self.startDate,
            duration: duration,
            category: self.category,
            isFixed: self.isFixed,
            isAIGenerated: isAIGenerated
        )
    }
}

// MARK: - Array Extensions

extension Array where Element == ScheduleEvent {
    /// Convert all ScheduleEvents to SmartScheduleOptimizer.FixedEvent
    var asFixedEvents: [SmartScheduleOptimizer.FixedEvent] {
        return self.map { $0.toSmartScheduleOptimizerFixedEvent() }
    }
    
    /// Filter to only fixed (non-flexible) events
    var fixedOnly: [ScheduleEvent] {
        return self.filter { $0.isFixed }
    }
    
    /// Filter to only AI-generated events
    var aiGeneratedOnly: [ScheduleEvent] {
        return self.filter { $0.isAIGenerated }
    }
}

extension Array where Element == TimeSlotSuggestion {
    /// Convert to SmartScheduleOptimizer.TimeSlot array
    var asSmartScheduleOptimizerTimeSlots: [SmartScheduleOptimizer.TimeSlot] {
        return self.map { $0.smartScheduleOptimizerTimeSlot }
    }
}

extension Array where Element == SmartScheduleOptimizer.TimeSlot {
    /// Convert to TimeSlotSuggestion array
    func asTimeSlotSuggestions(category: FlexibleTask.TaskCategory) -> [TimeSlotSuggestion] {
        return self.map { $0.toTimeSlotSuggestion(category: category) }
    }
}

// MARK: - Error Handling Extensions

extension APIError {
    /// User-friendly error message
    var userFriendlyMessage: String {
        switch self {
        case .claudeError(let message):
            return "AI service error: \(message)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Debugging Extensions

extension TyResponse {
    /// Debug description for logging
    var debugDescription: String {
        switch self {
        case .scheduleOptimization(let task, let suggestions, let message):
            return "Schedule Optimization: \(task.title) with \(suggestions.count) suggestions"
        case .calendarAutomation(let action, let message):
            return "Calendar Automation: \(action)"
        case .requestConfirmation(let text, _):
            return "Request Confirmation: \(text)"
        case .conversational(let message):
            return "Conversational: \(message.prefix(50))..."
        case .clarifyingQuestion(let question, let context):
            return "Clarifying Question: \(question)"
        }
    }
}

extension CalendarAction {
    /// Debug description for logging
    var debugDescription: String {
        switch self {
        case .addEvents(let events):
            return "Add \(events.count) events"
        case .removeEvents(let patterns):
            return "Remove events matching: \(patterns.joined(separator: ", "))"
        case .removeAllEvents:
            return "Remove all events"
        case .showMessage(let message):
            return "Show message: \(message)"
        }
    }
}

// MARK: - Utility Extensions

extension UserDefaults {
    /// Save any Codable object
    func setCodable<T: Codable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            set(data, forKey: key)
        }
    }
    
    /// Load any Codable object
    func getCodable<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

// MARK: - JSON Serialization Extensions

extension JSONSerialization {
    /// Safe JSON serialization with error handling
    static func safeJSONObject(with data: Data) -> [String: Any]? {
        do {
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch {
            print("❌ JSON Serialization Error: \(error)")
            return nil
        }
    }
    
    /// Safe JSON data creation with error handling
    static func safeData(withJSONObject obj: Any) -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: obj)
        } catch {
            print("❌ JSON Data Creation Error: \(error)")
            return nil
        }
    }
}
