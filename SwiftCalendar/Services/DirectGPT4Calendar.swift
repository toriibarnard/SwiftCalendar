//
//  DirectGPT4Calendar.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-06-01.
//


//
//  DirectGPT4Calendar.swift
//  SwiftCalendar
//
//  Direct GPT-4 approach - works like ChatGPT web
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
    
    func processRequest(_ input: String, existingEvents: [ScheduleEvent]) async throws -> (events: [SimpleEvent], message: String) {
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
        
        Instructions:
        1. Parse the user's request
        2. Check for conflicts with existing events
        3. Return a response in this EXACT format:
        
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
        I'll add work on Wednesday and Friday nights from 5:30 PM to 10:30 PM. I notice you already have [any conflicts]. 
        MESSAGE_END
        
        Categories: work, fitness, health, study, social, personal, other
        For recurring events, use days: monday,tuesday,wednesday,thursday,friday,saturday,sunday
        
        BE SMART: 
        - If user says "I work Friday and Wednesday nights too" - that means ADD to existing work schedule
        - Calculate actual dates correctly
        - Suggest optimal times when asked
        - Handle "6 gym sessions this week" by finding 6 good time slots
        """
        
        let request = [
            "model": "gpt-4-0125-preview",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": input]
            ],
            "temperature": 0.3,
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
        var events: [SimpleEvent] = []
        var userMessage = ""
        
        // Extract events
        if let eventsStart = content.range(of: "EVENTS_START"),
           let eventsEnd = content.range(of: "EVENTS_END") {
            let eventsText = String(content[eventsStart.upperBound..<eventsEnd.lowerBound])
            events = parseEvents(from: eventsText)
        }
        
        // Extract message
        if let messageStart = content.range(of: "MESSAGE_START"),
           let messageEnd = content.range(of: "MESSAGE_END") {
            let messageText = String(content[messageStart.upperBound..<messageEnd.lowerBound])
            userMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            userMessage = content
        }
        
        return (events, userMessage)
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
}