//
//  DirectGPT4Calendar.swift
//  SwiftCalendar
//
//  Conversational AI with memory - maintains chat history
//

import Foundation

class DirectGPT4Calendar {
    
    private let apiKey: String
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    
    // Conversation history storage
    private var conversationHistory: [[String: String]] = []
    
    init() {
        // Load API key from Config.plist
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["OPENAI_API_KEY"] as? String else {
            fatalError("OpenAI API key not found")
        }
        self.apiKey = key
    }
    
    struct SimpleEvent {
        let title: String
        let date: Date
        let duration: Int
        let category: String
        let isRecurring: Bool
        let recurrenceDays: [Int]
    }
    
    indirect enum CalendarAction {
        case addEvents([SimpleEvent])
        case removeEvents([String])
        case removeAllEvents // New: handle "delete everything"
        case requestConfirmation(String, pendingAction: CalendarAction) // New: for confirmations
        case showMessage(String)
    }
    
    func processRequest(_ input: String, existingEvents: [ScheduleEvent]) async throws -> (action: CalendarAction, message: String) {
        
        // Add user message to conversation history
        conversationHistory.append(["role": "user", "content": input])
        
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
        let todayString = formatter.string(from: today)
        
        // Create detailed schedule analysis
        let scheduleAnalysis = analyzeSchedule(existingEvents, relativeTo: today)
        
        // Build the system message only for the first message
        var messages: [[String: String]] = []
        
        if conversationHistory.count == 1 { // First message
            let systemPrompt = """
            You are Ty, a smart calendar assistant. Current date/time: \(todayString)
            
            CURRENT SCHEDULE ANALYSIS:
            \(scheduleAnalysis.detailedSchedule)
            
            AVAILABLE TIME SLOTS (conflict-free):
            \(scheduleAnalysis.availableSlots)
            
            WORK PATTERN DETECTED:
            \(scheduleAnalysis.workPattern)
            
            CONVERSATION RULES:
            1. REMEMBER the entire conversation context
            2. When user says "yes" or "no", refer to what they're responding to
            3. For destructive actions like "delete everything", ask for confirmation first
            4. NEVER say you don't have context - you have the full conversation above
            
            CALENDAR OPERATION RULES:
            1. NEVER schedule events that conflict with existing events
            2. When finding "best times", ONLY use the available time slots listed above
            3. For deletion, be specific about time of day (morning/afternoon/evening)
            
            RESPONSE FORMATS:
            
            For CONFIRMATION requests:
            CONFIRM_START
            Are you sure you want to delete all events? This includes all work shifts and appointments.
            CONFIRM_END
            
            For DELETION of everything:
            REMOVE_ALL_START
            REMOVE_ALL_END
            
            For DELETION of specific events:
            REMOVE_START
            work friday evening
            REMOVE_END
            
            For SCHEDULING:
            EVENTS_START
            title: Gym
            date: 2024-06-04 17:30
            duration: 60
            category: fitness
            recurring: false
            EVENTS_END
            
            Categories: work, fitness, health, study, social, personal, other
            """
            
            messages.append(["role": "system", "content": systemPrompt])
        }
        
        // Add all conversation history
        messages.append(contentsOf: conversationHistory)
        
        let request = [
            "model": "gpt-4-0125-preview",
            "messages": messages,
            "temperature": 0.1,
            "max_tokens": 1500
        ] as [String : Any]
        
        var urlRequest = URLRequest(url: URL(string: apiURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: request)
        
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let choices = response?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "Parse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        // Add AI response to conversation history
        conversationHistory.append(["role": "assistant", "content": content])
        
        // Parse the response
        let (action, userMessage) = parseResponse(content)
        return (action, userMessage)
    }
    
    // Clear conversation history (useful for new sessions)
    func clearConversationHistory() {
        conversationHistory.removeAll()
    }
    
    private func analyzeSchedule(_ events: [ScheduleEvent], relativeTo today: Date) -> ScheduleAnalysis {
        let calendar = Calendar.current
        let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let thisWeekEnd = calendar.date(byAdding: .day, value: 7, to: thisWeekStart) ?? today
        
        // Get this week's events
        let thisWeekEvents = events.filter { event in
            event.startTime >= thisWeekStart && event.startTime < thisWeekEnd
        }.sorted { $0.startTime < $1.startTime }
        
        // Create detailed schedule
        var detailedSchedule = "THIS WEEK'S SCHEDULE:\n"
        if thisWeekEvents.isEmpty {
            detailedSchedule += "No events scheduled this week.\n"
        } else {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            
            var currentDay: String? = nil
            for event in thisWeekEvents {
                let eventDay = dayFormatter.string(from: event.startTime)
                let startTime = timeFormatter.string(from: event.startTime)
                let endTime = timeFormatter.string(from: event.startTime.addingTimeInterval(TimeInterval(event.duration * 60)))
                
                if currentDay != eventDay {
                    detailedSchedule += "\n\(eventDay):\n"
                    currentDay = eventDay
                }
                
                let timeOfDay = getTimeOfDay(from: event.startTime)
                detailedSchedule += "  • \(event.title): \(startTime)-\(endTime) (\(timeOfDay))\n"
            }
        }
        
        // Analyze work pattern
        let workEvents = thisWeekEvents.filter { $0.title.lowercased().contains("work") }
        var workPattern = "WORK PATTERN:\n"
        if workEvents.isEmpty {
            workPattern += "No work events detected.\n"
        } else {
            let workByDay = Dictionary(grouping: workEvents) { event in
                calendar.component(.weekday, from: event.startTime)
            }
            
            for (weekday, dayEvents) in workByDay.sorted(by: { $0.key < $1.key }) {
                let dayName = calendar.weekdaySymbols[weekday - 1]
                workPattern += "\n\(dayName):\n"
                for event in dayEvents.sorted(by: { $0.startTime < $1.startTime }) {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "h:mm a"
                    let start = timeFormatter.string(from: event.startTime)
                    let end = timeFormatter.string(from: event.startTime.addingTimeInterval(TimeInterval(event.duration * 60)))
                    let timeOfDay = getTimeOfDay(from: event.startTime)
                    workPattern += "  • \(start)-\(end) (\(timeOfDay) shift)\n"
                }
            }
        }
        
        // Find available time slots
        let availableSlots = findDetailedAvailableSlots(events: thisWeekEvents, weekStart: thisWeekStart)
        
        return ScheduleAnalysis(
            detailedSchedule: detailedSchedule,
            availableSlots: availableSlots,
            workPattern: workPattern
        )
    }
    
    private func getTimeOfDay(from date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 0..<6:
            return "early morning"
        case 6..<12:
            return "morning"
        case 12..<17:
            return "afternoon"
        case 17..<21:
            return "evening"
        case 21..<24:
            return "night"
        default:
            return "unknown"
        }
    }
    
    private func findDetailedAvailableSlots(events: [ScheduleEvent], weekStart: Date) -> String {
        let calendar = Calendar.current
        var availableSlots = "AVAILABLE TIME SLOTS (1-hour windows):\n"
        
        // Check each day of the week
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            let dayName = calendar.component(.weekday, from: day)
            let dayString = calendar.weekdaySymbols[dayName - 1]
            
            let dayEvents = events.filter { event in
                calendar.isDate(event.startTime, inSameDayAs: day)
            }
            
            availableSlots += "\n\(dayString):\n"
            
            // Check hourly slots from 6 AM to 10 PM
            var hasAvailableSlots = false
            for hour in 6...22 {
                guard let timeSlot = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) else { continue }
                
                // Check if this hour conflicts with any event
                let hasConflict = dayEvents.contains { event in
                    let eventStart = event.startTime
                    let eventEnd = event.startTime.addingTimeInterval(TimeInterval(event.duration * 60))
                    let slotEnd = timeSlot.addingTimeInterval(3600) // 1 hour slot
                    
                    return (timeSlot < eventEnd && slotEnd > eventStart)
                }
                
                if !hasConflict {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "h:mm a"
                    let timeString = timeFormatter.string(from: timeSlot)
                    let endTimeString = timeFormatter.string(from: timeSlot.addingTimeInterval(3600))
                    let timeOfDay = getTimeOfDay(from: timeSlot)
                    availableSlots += "  ✅ \(timeString)-\(endTimeString) (\(timeOfDay))\n"
                    hasAvailableSlots = true
                }
            }
            
            if !hasAvailableSlots {
                availableSlots += "  ❌ No available slots\n"
            }
        }
        
        return availableSlots
    }
    
    private func parseResponse(_ content: String) -> (CalendarAction, String) {
        // Default message is the content with special blocks removed manually
        var userMessage = content
        
        // Extract and return specific actions without modifying the original string
        
        // 1. Check for confirmation requests
        if let confirmStart = content.range(of: "CONFIRM_START"),
           let confirmEnd = content.range(of: "CONFIRM_END") {
            let confirmText = String(content[confirmStart.upperBound..<confirmEnd.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (.requestConfirmation(confirmText, pendingAction: .removeAllEvents), confirmText)
        }
        
        // 2. Check for remove all events
        if content.contains("REMOVE_ALL_START") && content.contains("REMOVE_ALL_END") {
            let message = extractMessageFromContent(content) ?? "All events have been removed from your calendar."
            return (.removeAllEvents, message)
        }
        
        // 3. Check for specific event removal
        if let removeStart = content.range(of: "REMOVE_START"),
           let removeEnd = content.range(of: "REMOVE_END") {
            let removeText = String(content[removeStart.upperBound..<removeEnd.lowerBound])
            let removePatterns = removeText.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            let message = extractMessageFromContent(content) ?? "I'll remove those events."
            return (.removeEvents(removePatterns), message)
        }
        
        // 4. Check for add events
        if let eventsStart = content.range(of: "EVENTS_START"),
           let eventsEnd = content.range(of: "EVENTS_END") {
            let eventsText = String(content[eventsStart.upperBound..<eventsEnd.lowerBound])
            let events = parseEvents(from: eventsText)
            
            let message = extractMessageFromContent(content) ?? "I'll add those events."
            return (.addEvents(events), message)
        }
        
        // 5. Default - just show the message
        let cleanMessage = extractMessageFromContent(content) ?? content.trimmingCharacters(in: .whitespacesAndNewlines)
        return (.showMessage(cleanMessage), cleanMessage)
    }
    
    // Helper method to safely extract message without crashing
    private func extractMessageFromContent(_ content: String) -> String? {
        // Try to extract from MESSAGE_START/MESSAGE_END blocks
        if let messageStart = content.range(of: "MESSAGE_START"),
           let messageEnd = content.range(of: "MESSAGE_END") {
            let extracted = String(content[messageStart.upperBound..<messageEnd.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !extracted.isEmpty {
                return extracted
            }
        }
        
        // Fallback: return content with known blocks manually filtered out
        var lines = content.components(separatedBy: .newlines)
        
        // Remove lines that are part of special blocks
        let blockMarkers = [
            "CONFIRM_START", "CONFIRM_END",
            "REMOVE_ALL_START", "REMOVE_ALL_END",
            "REMOVE_START", "REMOVE_END",
            "EVENTS_START", "EVENTS_END",
            "MESSAGE_START", "MESSAGE_END"
        ]
        
        lines = lines.filter { line in
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return !blockMarkers.contains(trimmedLine)
        }
        
        // Also filter out event definition lines
        lines = lines.filter { line in
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmedLine.hasPrefix("title:") &&
                   !trimmedLine.hasPrefix("date:") &&
                   !trimmedLine.hasPrefix("duration:") &&
                   !trimmedLine.hasPrefix("category:") &&
                   !trimmedLine.hasPrefix("recurring:") &&
                   !trimmedLine.hasPrefix("days:") &&
                   !trimmedLine.hasPrefix("---")
        }
        
        let result = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }
    
    private func parseEvents(from text: String) -> [SimpleEvent] {
        var events: [SimpleEvent] = []
        let eventBlocks = text.components(separatedBy: "---")
        
        for block in eventBlocks {
            var title = ""
            var dateStr = ""
            var duration = 60
            var category = "personal"
            var recurring = false
            var days: [Int] = []
            
            let lines = block.components(separatedBy: .newlines)
            for line in lines {
                let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                guard parts.count == 2 else { continue }
                
                switch parts[0] {
                case "title":
                    title = parts[1]
                case "date":
                    dateStr = parts[1]
                case "duration":
                    duration = Int(parts[1]) ?? 60
                case "category":
                    category = parts[1]
                case "recurring":
                    recurring = parts[1] == "true"
                case "days":
                    let dayNames = parts[1].split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    let dayMap = ["sunday": 0, "monday": 1, "tuesday": 2, "wednesday": 3,
                                  "thursday": 4, "friday": 5, "saturday": 6]
                    days = dayNames.compactMap { dayMap[$0] }
                default:
                    break
                }
            }
            
            // Parse date
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            
            if !title.isEmpty, let date = formatter.date(from: dateStr) {
                events.append(SimpleEvent(
                    title: title,
                    date: date,
                    duration: duration,
                    category: category,
                    isRecurring: recurring,
                    recurrenceDays: days
                ))
            }
        }
        
        return events
    }
    
    // Improved deletion matching with time-of-day awareness
    func findEventsToRemove(_ patterns: [String], from events: [ScheduleEvent]) -> [ScheduleEvent] {
        var eventsToRemove: [ScheduleEvent] = []
        
        for pattern in patterns {
            let patternLower = pattern.lowercased()
            print("🔍 Looking for events matching pattern: '\(pattern)'")
            
            // Find events that match the pattern
            let matchingEvents = events.filter { event in
                let titleMatches = event.title.lowercased().contains(extractKeyword(from: patternLower))
                
                if !titleMatches {
                    return false
                }
                
                // Check time-of-day specificity
                if patternLower.contains("evening") || patternLower.contains("night") {
                    let hour = Calendar.current.component(.hour, from: event.startTime)
                    let isEvening = hour >= 17 && hour <= 23
                    print("  🌅 Checking evening event: \(event.title) at \(hour):xx - isEvening: \(isEvening)")
                    return isEvening
                } else if patternLower.contains("morning") {
                    let hour = Calendar.current.component(.hour, from: event.startTime)
                    let isMorning = hour >= 6 && hour < 12
                    print("  🌅 Checking morning event: \(event.title) at \(hour):xx - isMorning: \(isMorning)")
                    return isMorning
                } else if patternLower.contains("afternoon") {
                    let hour = Calendar.current.component(.hour, from: event.startTime)
                    let isAfternoon = hour >= 12 && hour < 17
                    print("  🌅 Checking afternoon event: \(event.title) at \(hour):xx - isAfternoon: \(isAfternoon)")
                    return isAfternoon
                }
                
                // Check day-specific patterns
                if let dayMatch = extractDayPattern(from: patternLower) {
                    let eventWeekday = Calendar.current.component(.weekday, from: event.startTime)
                    let matches = eventWeekday == dayMatch
                    print("  📅 Checking day pattern: \(event.title) - event weekday: \(eventWeekday), target: \(dayMatch), matches: \(matches)")
                    return matches
                }
                
                print("  ✅ Title matches pattern: \(event.title)")
                return true
            }
            
            print("  📋 Found \(matchingEvents.count) matching events for pattern '\(pattern)'")
            eventsToRemove.append(contentsOf: matchingEvents)
        }
        
        // Remove duplicates
        let uniqueEvents = Array(Set(eventsToRemove.map { $0.id })).compactMap { id in
            eventsToRemove.first { $0.id == id }
        }
        
        print("🗑️ Total unique events to remove: \(uniqueEvents.count)")
        return uniqueEvents
    }
    
    private func extractKeyword(from pattern: String) -> String {
        let keywords = ["work", "gym", "meeting", "appointment", "dentist", "doctor", "lunch", "dinner"]
        for keyword in keywords {
            if pattern.contains(keyword) {
                return keyword
            }
        }
        return pattern
    }
    
    private func extractDayPattern(from pattern: String) -> Int? {
        let dayMap = [
            "sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4,
            "thursday": 5, "friday": 6, "saturday": 7,
            "tomorrow": Calendar.current.component(.weekday, from: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()),
            "today": Calendar.current.component(.weekday, from: Date())
        ]
        
        for (dayName, weekday) in dayMap {
            if pattern.contains(dayName) {
                return weekday
            }
        }
        return nil
    }
}

struct ScheduleAnalysis {
    let detailedSchedule: String
    let availableSlots: String
    let workPattern: String
}
