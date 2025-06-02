//
//  DirectGPT4Calendar.swift
//  SwiftCalendar
//
//  Improved GPT-4 approach with better deletion handling
//

import Foundation

class DirectGPT4Calendar {
    
    private let apiKey: String
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    
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
    
    enum CalendarAction {
        case addEvents([SimpleEvent])
        case removeEvents([String]) // Array of event titles/patterns to remove
        case showMessage(String)
    }
    
    func processRequest(_ input: String, existingEvents: [ScheduleEvent]) async throws -> (action: CalendarAction, message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
        let today = formatter.string(from: Date())
        
        // Format existing events
        let eventList = existingEvents.prefix(20).map { event in
            let endTime = event.startTime.addingTimeInterval(TimeInterval(event.duration * 60))
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "EEEE, MMM d h:mm a"
            return "- \(event.title): \(timeFormatter.string(from: event.startTime)) to \(timeFormatter.string(from: endTime))"
        }.joined(separator: "\n")
        
        let systemPrompt = """
        You are a calendar assistant. Current date/time: \(today)
        
        Existing calendar events:
        \(eventList.isEmpty ? "Calendar is empty" : eventList)
        
        CRITICAL INSTRUCTIONS:
        1. TODAY IS \(today). Calculate all dates relative to this.
        2. If user says "delete", "remove", "cancel" - respond with REMOVE_START section
        3. If user says "add", "schedule", "I have" - respond with EVENTS_START section
        4. Be very careful about DELETE vs ADD operations
        
        For DELETION requests, return this format:
        REMOVE_START
        work
        gym tomorrow
        meeting friday
        REMOVE_END
        
        MESSAGE_START
        I'll remove those events from your calendar.
        MESSAGE_END
        
        For ADDING events, return this format:
        EVENTS_START
        title: Work
        date: 2024-06-04 17:30
        duration: 300
        category: work
        recurring: true
        days: wednesday,friday
        ---
        title: Gym
        date: 2024-06-02 18:00
        duration: 90
        category: fitness
        recurring: false
        EVENTS_END
        
        MESSAGE_START
        I'll add those events to your calendar.
        MESSAGE_END
        
        DELETION EXAMPLES:
        - "delete work tomorrow" → REMOVE work tomorrow
        - "cancel my gym session" → REMOVE gym
        - "remove meeting on friday" → REMOVE meeting friday
        
        Categories: work, fitness, health, study, social, personal, other
        For recurring events, use days: monday,tuesday,wednesday,thursday,friday,saturday,sunday
        """
        
        let request = [
            "model": "gpt-4-0125-preview",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": input]
            ],
            "temperature": 0.2,
            "max_tokens": 1000
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
        
        // Parse the response
        let (action, userMessage) = parseResponse(content)
        return (action, userMessage)
    }
    
    private func parseResponse(_ content: String) -> (CalendarAction, String) {
        var userMessage = ""
        
        // Extract message
        if let messageStart = content.range(of: "MESSAGE_START"),
           let messageEnd = content.range(of: "MESSAGE_END") {
            let messageText = String(content[messageStart.upperBound..<messageEnd.lowerBound])
            userMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            userMessage = content
        }
        
        // Check for removal requests
        if let removeStart = content.range(of: "REMOVE_START"),
           let removeEnd = content.range(of: "REMOVE_END") {
            let removeText = String(content[removeStart.upperBound..<removeEnd.lowerBound])
            let removePatterns = removeText.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            return (.removeEvents(removePatterns), userMessage)
        }
        
        // Check for add events
        if let eventsStart = content.range(of: "EVENTS_START"),
           let eventsEnd = content.range(of: "EVENTS_END") {
            let eventsText = String(content[eventsStart.upperBound..<eventsEnd.lowerBound])
            let events = parseEvents(from: eventsText)
            
            return (.addEvents(events), userMessage)
        }
        
        // Default to showing message
        return (.showMessage(userMessage), userMessage)
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
    
    // Helper function to find events to remove based on patterns
    func findEventsToRemove(_ patterns: [String], from events: [ScheduleEvent]) -> [ScheduleEvent] {
        var eventsToRemove: [ScheduleEvent] = []
        
        for pattern in patterns {
            let patternLower = pattern.lowercased()
            
            // Find events that match the pattern
            let matchingEvents = events.filter { event in
                let titleMatches = event.title.lowercased().contains(patternLower)
                
                // Check if pattern includes date information
                if patternLower.contains("tomorrow") {
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    let eventDate = Calendar.current.startOfDay(for: event.startTime)
                    let tomorrowDate = Calendar.current.startOfDay(for: tomorrow)
                    return titleMatches && eventDate == tomorrowDate
                } else if patternLower.contains("today") {
                    let today = Calendar.current.startOfDay(for: Date())
                    let eventDate = Calendar.current.startOfDay(for: event.startTime)
                    return titleMatches && eventDate == today
                } else if patternLower.contains("friday") {
                    let weekday = Calendar.current.component(.weekday, from: event.startTime)
                    return titleMatches && weekday == 6 // Friday
                } else if patternLower.contains("monday") {
                    let weekday = Calendar.current.component(.weekday, from: event.startTime)
                    return titleMatches && weekday == 2 // Monday
                } else if patternLower.contains("tuesday") {
                    let weekday = Calendar.current.component(.weekday, from: event.startTime)
                    return titleMatches && weekday == 3 // Tuesday
                } else if patternLower.contains("wednesday") {
                    let weekday = Calendar.current.component(.weekday, from: event.startTime)
                    return titleMatches && weekday == 4 // Wednesday
                } else if patternLower.contains("thursday") {
                    let weekday = Calendar.current.component(.weekday, from: event.startTime)
                    return titleMatches && weekday == 5 // Thursday
                } else if patternLower.contains("saturday") {
                    let weekday = Calendar.current.component(.weekday, from: event.startTime)
                    return titleMatches && weekday == 7 // Saturday
                } else if patternLower.contains("sunday") {
                    let weekday = Calendar.current.component(.weekday, from: event.startTime)
                    return titleMatches && weekday == 1 // Sunday
                }
                
                return titleMatches
            }
            
            eventsToRemove.append(contentsOf: matchingEvents)
        }
        
        // Remove duplicates
        let uniqueEvents = Array(Set(eventsToRemove.map { $0.id })).compactMap { id in
            eventsToRemove.first { $0.id == id }
        }
        
        return uniqueEvents
    }
}
