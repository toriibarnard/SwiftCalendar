//
//  HybridCalendarAI.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-06-01.
//


//
//  HybridCalendarAI.swift
//  SwiftCalendar
//
//  Combines deterministic parsing with AI validation for reliable calendar management
//

import Foundation

class HybridCalendarAI {
    private let parser = SimpleCalendarParser()
    private let openAI = OpenAIService.shared
    
    enum CalendarResult {
        case success(action: CalendarAction, message: String)
        case needsInfo(missingInfo: String, parsedSoFar: SimpleCalendarParser.ParsedEvent?)
        case conflict(conflicts: [ScheduleEvent], suggestion: String)
        case error(String)
    }
    
    enum CalendarAction {
        case addEvent(event: ScheduleEvent)
        case addRecurringEvents(events: [ScheduleEvent])
        case removeEvents(events: [ScheduleEvent])
        case showSchedule(events: [ScheduleEvent], dateRange: String)
    }
    
    @MainActor
    func processRequest(_ input: String, scheduleManager: ScheduleManager) async -> CalendarResult {
        // Step 1: Parse the request
        let parsed = parser.parse(input)
        
        switch parsed {
        case .add(let event):
            return await handleAddEvent(event, originalRequest: input, scheduleManager: scheduleManager)
            
        case .remove(let title, let date):
            return handleRemoveEvent(title: title, date: date, scheduleManager: scheduleManager)
            
        case .query(let start, let end):
            return handleQuery(start: start, end: end, scheduleManager: scheduleManager)
            
        case .unknown(let text):
            // Fall back to AI for complex requests
            return await handleComplexRequest(text, scheduleManager: scheduleManager)
        }
    }
    
    func handleAddEvent(_ event: SimpleCalendarParser.ParsedEvent, originalRequest: String, scheduleManager: ScheduleManager) async -> CalendarResult {
        // Check if we have all required information
        guard event.isComplete else {
            var missingInfo = ""
            if event.startTime == nil {
                missingInfo = "What time should \(event.title) start?"
            } else if event.endTime == nil {
                missingInfo = "How long should \(event.title) last?"
            }
            return .needsInfo(missingInfo: missingInfo, parsedSoFar: event)
        }
        
        guard let startTime = event.startTime, let endTime = event.endTime else {
            return .error("Unable to determine event times")
        }
        
        // Check for conflicts
        let conflicts = findConflicts(start: startTime, end: endTime, in: scheduleManager.events)
        
        if !conflicts.isEmpty && !event.isRecurring {
            let conflictTitles = conflicts.map { $0.title }.joined(separator: ", ")
            return .conflict(
                conflicts: conflicts,
                suggestion: "You have '\(conflictTitles)' scheduled at that time. Would you like to:\n1. Replace it\n2. Choose a different time\n3. Cancel"
            )
        }
        
        // Create the event(s)
        if event.isRecurring {
            let events = createRecurringEvents(from: event, scheduleManager: scheduleManager)
            let message = formatRecurringEventMessage(event, eventCount: events.count)
            return .success(action: .addRecurringEvents(events: events), message: message)
        } else {
            let scheduleEvent = ScheduleEvent(
                title: event.title,
                startTime: startTime,
                duration: event.duration ?? 60,
                category: event.category,
                isFixed: true,
                isAIGenerated: true
            )
            let message = formatSingleEventMessage(scheduleEvent)
            return .success(action: .addEvent(event: scheduleEvent), message: message)
        }
    }
    
    private func handleRemoveEvent(title: String, date: Date?, scheduleManager: ScheduleManager) -> CalendarResult {
        let matchingEvents = scheduleManager.events.filter { event in
            let titleMatches = event.title.lowercased().contains(title.lowercased())
            
            if let date = date {
                let calendar = Calendar.current
                return titleMatches && calendar.isDate(event.startTime, inSameDayAs: date)
            }
            
            return titleMatches
        }
        
        if matchingEvents.isEmpty {
            return .error("I couldn't find any events matching '\(title)'. Try being more specific.")
        }
        
        let message: String
        if matchingEvents.count == 1 {
            message = "I've removed '\(matchingEvents[0].title)' from your calendar."
        } else {
            message = "I've removed \(matchingEvents.count) events matching '\(title)'."
        }
        
        return .success(action: .removeEvents(events: matchingEvents), message: message)
    }
    
    private func handleQuery(start: Date, end: Date, scheduleManager: ScheduleManager) -> CalendarResult {
        let events = scheduleManager.events.filter { event in
            event.startTime >= start && event.startTime < end
        }.sorted { $0.startTime < $1.startTime }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        let dateRange = formatter.string(from: start)
        
        if events.isEmpty {
            return .success(
                action: .showSchedule(events: [], dateRange: dateRange),
                message: "You have no events scheduled for \(dateRange)."
            )
        }
        
        return .success(
            action: .showSchedule(events: events, dateRange: dateRange),
            message: formatScheduleMessage(events, dateRange: dateRange)
        )
    }
    
    private func handleComplexRequest(_ text: String, scheduleManager: ScheduleManager) async -> CalendarResult {
        // Use AI for complex requests that the parser couldn't handle
        do {
            let prompt = """
            Parse this calendar request: "\(text)"
            Today is \(Date()).
            
            Return a simple action like:
            - "add event: [title] at [time] for [duration]"
            - "remove: [title]"
            - "show schedule for: [date]"
            """
            
            // This is where you'd call OpenAI with a simpler prompt
            // For now, return an error
            return .error("I couldn't understand that request. Try saying something like 'Add meeting tomorrow at 2pm for 1 hour'")
        }
    }
    
    // MARK: - Helper Methods
    
    private func findConflicts(start: Date, end: Date, in events: [ScheduleEvent]) -> [ScheduleEvent] {
        return events.filter { event in
            let eventEnd = event.startTime.addingTimeInterval(TimeInterval(event.duration * 60))
            // Check if times overlap
            return (start < eventEnd && end > event.startTime)
        }
    }
    
    private func createRecurringEvents(from parsed: SimpleCalendarParser.ParsedEvent, scheduleManager: ScheduleManager) -> [ScheduleEvent] {
        guard let startTime = parsed.startTime, let endTime = parsed.endTime else { return [] }
        
        var events: [ScheduleEvent] = []
        let calendar = Calendar.current
        let duration = parsed.duration ?? 60
        
        // Create events for the next 4 weeks
        let endDate = calendar.date(byAdding: .weekOfYear, value: 4, to: startTime) ?? startTime
        var currentDate = startTime
        
        while currentDate <= endDate {
            let weekday = calendar.component(.weekday, from: currentDate) - 1 // 0-based
            
            if parsed.recurrenceDays.contains(weekday) {
                // Set the time components
                var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
                components.hour = calendar.component(.hour, from: startTime)
                components.minute = calendar.component(.minute, from: startTime)
                
                if let eventDate = calendar.date(from: components) {
                    // Check for conflicts
                    let eventEnd = eventDate.addingTimeInterval(TimeInterval(duration * 60))
                    let conflicts = findConflicts(start: eventDate, end: eventEnd, in: scheduleManager.events)
                    
                    // Only add if no conflicts
                    if conflicts.isEmpty {
                        let event = ScheduleEvent(
                            title: parsed.title,
                            startTime: eventDate,
                            duration: duration,
                            category: parsed.category,
                            isFixed: true,
                            isAIGenerated: true
                        )
                        events.append(event)
                    }
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return events
    }
    
    private func formatSingleEventMessage(_ event: ScheduleEvent) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        let date = dateFormatter.string(from: event.startTime)
        let startTime = timeFormatter.string(from: event.startTime)
        let endTime = timeFormatter.string(from: event.startTime.addingTimeInterval(TimeInterval(event.duration * 60)))
        
        return "Perfect! I've added '\(event.title)' to your calendar on \(date) from \(startTime) to \(endTime)."
    }
    
    private func formatRecurringEventMessage(_ event: SimpleCalendarParser.ParsedEvent, eventCount: Int) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        let startTime = event.startTime.map { timeFormatter.string(from: $0) } ?? ""
        let endTime = event.endTime.map { timeFormatter.string(from: $0) } ?? ""
        
        let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let scheduledDays = event.recurrenceDays.sorted().map { dayNames[$0] }.joined(separator: ", ")
        
        return "Great! I've scheduled '\(event.title)' every \(scheduledDays) from \(startTime) to \(endTime). Created \(eventCount) events for the next 4 weeks."
    }
    
    private func formatScheduleMessage(_ events: [ScheduleEvent], dateRange: String) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        var message = "Here's your schedule for \(dateRange):\n\n"
        
        for event in events {
            let startTime = timeFormatter.string(from: event.startTime)
            let endTime = timeFormatter.string(from: event.startTime.addingTimeInterval(TimeInterval(event.duration * 60)))
            message += "• \(event.title): \(startTime) - \(endTime)\n"
        }
        
        return message
    }
}