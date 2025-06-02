//
//  IntelligentTyAI.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-06-02.
//


//
//  IntelligentTyAI.swift
//  SwiftCalendar
//
//  New Ty AI focused on schedule optimization as primary purpose
//

import Foundation

class IntelligentTyAI {
    
    private let apiKey: String
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    private let scheduleOptimizer = SmartScheduleOptimizer()
    
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
    
    // MARK: - Response Types
    
    indirect enum TyResponse {
        case scheduleOptimization(task: FlexibleTask, suggestions: [TimeSlot], message: String)
        case calendarAutomation(action: CalendarAction, message: String)
        case requestConfirmation(String, pendingAction: TyResponse)
        case conversational(String)
        case clarifyingQuestion(String, context: String)
    }
    
    enum CalendarAction {
        case addEvents([SimpleEvent])
        case removeEvents([String])
        case removeAllEvents
        case showMessage(String)
    }
    
    struct SimpleEvent {
        let title: String
        let date: Date
        let duration: Int
        let category: String
        let isRecurring: Bool
        let recurrenceDays: [Int]
    }
    
    struct FlexibleTask {
        let title: String
        let duration: Int
        let category: EventCategory
        let preferredTimes: [SmartScheduleOptimizer.TimePreference]?
        let deadline: Date?
        let frequency: SmartScheduleOptimizer.TaskFrequency?
    }
    
    typealias TimeSlot = SmartScheduleOptimizer.TimeSlot
    
    // MARK: - Main Processing Function
    
    func processRequest(
        _ input: String,
        existingEvents: [ScheduleEvent],
        userPreferences: UserSchedulePreferences
    ) async throws -> TyResponse {
        
        // Add user message to conversation history
        conversationHistory.append(["role": "user", "content": input])
        
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
        let todayString = formatter.string(from: today)
        
        // Analyze user's current schedule
        let scheduleAnalysis = analyzeUserSchedule(existingEvents, relativeTo: today)
        
        // Build the system message for GPT-4
        let systemPrompt = createSystemPrompt(
            currentTime: todayString,
            scheduleAnalysis: scheduleAnalysis,
            userPreferences: userPreferences
        )
        
        // Build messages array
        var messages: [[String: String]] = []
        
        if conversationHistory.count == 1 { // First message
            messages.append(["role": "system", "content": systemPrompt])
        }
        
        // Add all conversation history
        messages.append(contentsOf: conversationHistory)
        
        let request = [
            "model": "gpt-4-0125-preview",
            "messages": messages,
            "temperature": 0.2,
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
        
        // Parse and handle the response
        return try await parseAndHandleResponse(
            content,
            existingEvents: existingEvents,
            userPreferences: userPreferences
        )
    }
    
    // MARK: - System Prompt Creation
    
    private func createSystemPrompt(
        currentTime: String,
        scheduleAnalysis: String,
        userPreferences: UserSchedulePreferences
    ) -> String {
        return """
        You are Ty, an intelligent schedule optimization assistant. Current time: \(currentTime)
        
        YOUR PRIMARY PURPOSE: Help users find optimal times for FLEXIBLE tasks by analyzing their FIXED commitments.
        YOUR SECONDARY PURPOSE: Automate calendar creation for recurring events.
        
        CURRENT USER SCHEDULE:
        \(scheduleAnalysis)
        
        USER PREFERENCES:
        - Working hours: \(userPreferences.generalPreferences.workingHoursStart):00 - \(userPreferences.generalPreferences.workingHoursEnd):00
        - Sleep time: \(userPreferences.generalPreferences.sleepTime):00
        - Wake time: \(userPreferences.generalPreferences.wakeTime):00
        - Preferred buffer: \(userPreferences.generalPreferences.bufferPreference) minutes
        
        CRITICAL: Understand the difference between:
        
        🎯 SCHEDULE OPTIMIZATION requests (PRIMARY PURPOSE):
        - "When should I go to the gym?"
        - "What's the best time for me to study this week?"
        - "When can I fit in a dentist appointment?"
        - "Find me time for a 2-hour project meeting"
        
        📅 CALENDAR AUTOMATION requests (SECONDARY PURPOSE):
        - "I work 8:30-4 on weekdays" 
        - "Add gym sessions Monday, Wednesday, Friday at 6pm"
        - "I have a dentist appointment tomorrow at 2pm"
        
        RESPONSE FORMATS:
        
        For SCHEDULE OPTIMIZATION (most important):
        OPTIMIZE_START
        task: Go to gym
        duration: 90
        category: fitness
        preferences: evening
        frequency: 3_times_weekly
        deadline: none
        OPTIMIZE_END
        
        For CALENDAR AUTOMATION:
        EVENTS_START
        title: Work
        date: 2025-06-03 08:30
        duration: 450
        category: work
        recurring: false
        ---
        title: Work
        date: 2025-06-04 08:30
        duration: 450
        category: work
        recurring: false
        EVENTS_END
        
        For CLARIFYING QUESTIONS:
        CLARIFY_START
        I need more details to help you optimize your schedule. How long do you typically spend at the gym? Do you prefer morning or evening workouts?
        CLARIFY_END
        
        ALWAYS prioritize helping users find optimal times for flexible tasks. Be descriptive and professional in your suggestions.
        """
    }
    
    // MARK: - Response Parsing and Handling
    
    private func parseAndHandleResponse(
        _ content: String,
        existingEvents: [ScheduleEvent],
        userPreferences: UserSchedulePreferences
    ) async throws -> TyResponse {
        
        print("🤖 Ty AI Response:\n\(content)")
        
        // 1. Check for schedule optimization request (PRIMARY PURPOSE)
        if let optimizeStart = content.range(of: "OPTIMIZE_START"),
           let optimizeEnd = content.range(of: "OPTIMIZE_END") {
            
            let optimizeText = String(content[optimizeStart.upperBound..<optimizeEnd.lowerBound])
            
            if let task = parseFlexibleTask(from: optimizeText) {
                print("🎯 Processing schedule optimization for: \(task.title)")
                
                // Use the schedule optimizer to find best times
                let thisWeek = createWeekInterval(from: Date())
                let suggestions = scheduleOptimizer.findOptimalTimes(
                    for: convertToOptimizerTask(task),
                    in: thisWeek,
                    avoiding: getFixedEvents(from: existingEvents),
                    considering: userPreferences
                )
                
                let message = generateOptimizationMessage(task: task, suggestions: suggestions)
                return .scheduleOptimization(task: task, suggestions: suggestions, message: message)
            }
        }
        
        // 2. Check for clarifying questions
        if let clarifyStart = content.range(of: "CLARIFY_START"),
           let clarifyEnd = content.range(of: "CLARIFY_END") {
            let clarifyText = String(content[clarifyStart.upperBound..<clarifyEnd.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return .clarifyingQuestion(clarifyText, context: content)
        }
        
        // 3. Check for calendar automation (SECONDARY PURPOSE)
        if let eventsStart = content.range(of: "EVENTS_START"),
           let eventsEnd = content.range(of: "EVENTS_END") {
            
            let eventsText = String(content[eventsStart.upperBound..<eventsEnd.lowerBound])
            let events = parseEvents(from: eventsText)
            let message = extractMessageFromContent(content) ?? "I'll add those events to your calendar."
            
            return .calendarAutomation(action: .addEvents(events), message: message)
        }
        
        // 4. Default: conversational response
        let cleanMessage = extractMessageFromContent(content) ?? content
        return .conversational(cleanMessage)
    }
    
    // MARK: - Helper Functions
    
    private func analyzeUserSchedule(_ events: [ScheduleEvent], relativeTo date: Date) -> String {
        let calendar = Calendar.current
        let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let thisWeekEnd = calendar.date(byAdding: .day, value: 7, to: thisWeekStart) ?? date
        
        let thisWeekEvents = events.filter { event in
            event.startTime >= thisWeekStart && event.startTime < thisWeekEnd
        }.sorted { $0.startTime < $1.startTime }
        
        if thisWeekEvents.isEmpty {
            return "User has a completely open schedule this week - excellent for optimization!"
        }
        
        var analysis = "THIS WEEK'S FIXED COMMITMENTS:\n"
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
                analysis += "\n\(eventDay):\n"
                currentDay = eventDay
            }
            
            analysis += "  • \(event.title): \(startTime)-\(endTime)\n"
        }
        
        return analysis
    }
    
    private func parseFlexibleTask(from text: String) -> FlexibleTask? {
        let lines = text.components(separatedBy: .newlines)
        
        var title = ""
        var duration = 60
        var category = EventCategory.personal
        var preferences: [SmartScheduleOptimizer.TimePreference]?
        var deadline: Date?
        var frequency: SmartScheduleOptimizer.TaskFrequency?
        
        for line in lines {
            let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }
            
            switch parts[0] {
            case "task":
                title = parts[1]
            case "duration":
                duration = Int(parts[1]) ?? 60
            case "category":
                category = EventCategory(rawValue: parts[1]) ?? .personal
            case "preferences":
                preferences = parseTimePreferences(parts[1])
            case "frequency":
                frequency = parseTaskFrequency(parts[1])
            default:
                break
            }
        }
        
        if !title.isEmpty {
            return FlexibleTask(
                title: title,
                duration: duration,
                category: category,
                preferredTimes: preferences,
                deadline: deadline,
                frequency: frequency
            )
        }
        
        return nil
    }
    
    private func parseTimePreferences(_ text: String) -> [SmartScheduleOptimizer.TimePreference]? {
        switch text.lowercased() {
        case "morning":
            return [.morning(before: 12)]
        case "afternoon":
            return [.afternoon(range: 12...17)]
        case "evening":
            return [.evening(after: 17)]
        default:
            return [.anyTime]
        }
    }
    
    private func parseTaskFrequency(_ text: String) -> SmartScheduleOptimizer.TaskFrequency? {
        if text.contains("daily") {
            return .daily
        } else if text.contains("times_weekly") {
            let number = text.components(separatedBy: "_").first
            if let times = Int(number ?? "1") {
                return .weekly(times: times)
            }
        }
        return nil
    }
    
    private func createWeekInterval(from date: Date) -> DateInterval {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? date
        return DateInterval(start: startOfWeek, end: endOfWeek)
    }
    
    private func getFixedEvents(from events: [ScheduleEvent]) -> [ScheduleEvent] {
        // For now, consider all existing events as "fixed"
        // Later we can add logic to determine which are flexible
        return events.filter { $0.isFixed }
    }
    
    private func convertToOptimizerTask(_ task: FlexibleTask) -> SmartScheduleOptimizer.FlexibleTask {
        return SmartScheduleOptimizer.FlexibleTask(
            title: task.title,
            duration: task.duration,
            category: task.category,
            preferredTimes: task.preferredTimes,
            deadline: task.deadline,
            frequency: task.frequency
        )
    }
    
    private func generateOptimizationMessage(task: FlexibleTask, suggestions: [TimeSlot]) -> String {
        guard !suggestions.isEmpty else {
            return "I couldn't find any good times for \(task.title) this week. Your schedule is quite packed! Would you like me to look at next week instead?"
        }
        
        var message = "Here are the best times for \(task.title) this week:\n\n"
        
        for (index, slot) in suggestions.enumerated() {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE h:mm a"
            let timeString = formatter.string(from: slot.startTime)
            
            message += "\(index + 1). \(timeString) - \(slot.reasoning)\n"
        }
        
        message += "\nWould you like me to schedule one of these times?"
        
        return message
    }
    
    private func parseEvents(from text: String) -> [SimpleEvent] {
        // Reuse existing event parsing logic
        var events: [SimpleEvent] = []
        
        // Smart split logic for events without separators
        var eventBlocks = text.components(separatedBy: "---")
        
        if eventBlocks.count == 1 && text.components(separatedBy: "title:").count > 2 {
            let parts = text.components(separatedBy: "title:")
            eventBlocks = []
            for (index, part) in parts.enumerated() {
                if index == 0 && part.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    continue
                }
                eventBlocks.append("title:" + part)
            }
        }
        
        for block in eventBlocks {
            if let event = parseEventFromBlock(block) {
                events.append(event)
            }
        }
        
        return events
    }
    
    private func parseEventFromBlock(_ block: String) -> SimpleEvent? {
        let lines = block.components(separatedBy: .newlines)
        
        var title = ""
        var dateStr = ""
        var duration = 60
        var category = "personal"
        var recurring = false
        var days: [Int] = []
        
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
                // Parse days logic here
                break
            default:
                break
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        if !title.isEmpty, let date = formatter.date(from: dateStr) {
            return SimpleEvent(
                title: title,
                date: date,
                duration: duration,
                category: category,
                isRecurring: recurring,
                recurrenceDays: days
            )
        }
        
        return nil
    }
    
    private func extractMessageFromContent(_ content: String) -> String? {
        // Extract clean message from content
        let lines = content.components(separatedBy: .newlines)
        let filteredLines = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmed.contains("_START") && !trimmed.contains("_END") &&
                   !trimmed.hasPrefix("title:") && !trimmed.hasPrefix("date:")
        }
        
        let result = filteredLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }
    
    func clearConversationHistory() {
        conversationHistory.removeAll()
    }
}