//
//  IntelligentTyAI.swift
//  SwiftCalendar
//
//  Updated to use Claude API (Anthropic) for better conversation flow
//

import Foundation

class IntelligentTyAI {
    
    private let apiKey: String
    private let apiURL = "https://api.anthropic.com/v1/messages" // Claude API endpoint
    private let scheduleOptimizer = SmartScheduleOptimizer()
    
    // Conversation history storage
    private var conversationHistory: [[String: Any]] = []
    
    init() {
        // Load API key from Config.plist - update to use CLAUDE_API_KEY
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["CLAUDE_API_KEY"] as? String else {
            fatalError("Claude API key not found in Config.plist - add CLAUDE_API_KEY")
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
        conversationHistory.append([
            "role": "user",
            "content": input
        ])
        
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
        let todayString = formatter.string(from: today)
        
        // Analyze user's current schedule
        let scheduleAnalysis = analyzeUserSchedule(existingEvents, relativeTo: today)
        
        // Build the system message for Claude
        let systemPrompt = createClaudeSystemPrompt(
            currentTime: todayString,
            scheduleAnalysis: scheduleAnalysis,
            userPreferences: userPreferences
        )
        
        // Claude API request format
        let request = [
            "model": "claude-3-5-sonnet-20241022", // Latest Claude Sonnet model
            "max_tokens": 1500,
            "temperature": 0.1, // Low temperature for consistent behavior
            "system": systemPrompt,
            "messages": conversationHistory
        ] as [String : Any]
        
        var urlRequest = URLRequest(url: URL(string: apiURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version") // Required header
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Debug response
        if let httpResponse = response as? HTTPURLResponse {
            print("🌐 Claude API Response Status: \(httpResponse.statusCode)")
        }
        
        let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Handle API errors
        if let error = jsonResponse?["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw NSError(domain: "ClaudeAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Claude API Error: \(message)"])
        }
        
        // Parse Claude response format
        guard let content = jsonResponse?["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw NSError(domain: "Parse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Claude response format"])
        }
        
        // Add AI response to conversation history
        conversationHistory.append([
            "role": "assistant",
            "content": text
        ])
        
        // Parse and handle the response
        return try await parseAndHandleResponse(
            text,
            existingEvents: existingEvents,
            userPreferences: userPreferences
        )
    }
    
    // MARK: - Claude-Optimized System Prompt
    
    private func createClaudeSystemPrompt(
        currentTime: String,
        scheduleAnalysis: String,
        userPreferences: UserSchedulePreferences
    ) -> String {
        return """
        You are Ty, a calendar AI assistant built directly into the user's calendar application. Current time: \(currentTime)
        
        CORE IDENTITY & CAPABILITIES:
        • You ARE the calendar system itself - not an external tool
        • You have DIRECT, immediate control over all calendar operations
        • You can instantly create, modify, delete, and analyze events
        • You maintain full conversation context and follow through on requests consistently
        • Never suggest external calendar apps - you ARE the calendar
        
        PRIMARY PURPOSE: Schedule Optimization
        When users ask "when should I..." or "best time for...":
        1. Analyze their fixed commitments (work, meetings, appointments)
        2. Consider user preferences, energy levels, buffer times
        3. Suggest 3-4 optimal time slots with clear reasoning
        4. Use the OPTIMIZE_START/OPTIMIZE_END format below
        
        SECONDARY PURPOSE: Calendar Automation  
        When users describe schedules like "I work 9-5 on weekdays":
        1. Proactively create all necessary events
        2. Use EVENTS_START/EVENTS_END format
        3. Be confident: "I'll add your work schedule right away!"
        
        CONVERSATION FLOW (CRITICAL):
        • Maintain full awareness of the conversation history
        • When you ask for confirmation and the user agrees, execute the action immediately
        • Never respond with confusion after receiving confirmation
        • If you asked about deleting events and user confirms, delete them
        • Follow logical conversation progression consistently
        
        RESPONSE FORMATS:
        
        For Schedule Optimization:
        OPTIMIZE_START
        task: [task name]
        duration: [minutes]
        category: [fitness/work/personal/health/study]
        preferences: [morning/afternoon/evening/any]
        frequency: [daily/weekly/specific/none]
        deadline: [date or none]
        OPTIMIZE_END
        
        For Calendar Events:
        EVENTS_START
        title: [event title]
        date: [YYYY-MM-DD HH:MM]
        duration: [minutes]
        category: [category]
        recurring: [true/false]
        ---
        [additional events separated by ---]
        EVENTS_END
        
        For Deleting All Events:
        REMOVE_ALL_START
        REMOVE_ALL_END
        
        For Deleting Specific Events:
        REMOVE_START
        [search pattern or description]
        REMOVE_END
        
        BEHAVIORAL GUIDELINES:
        • Be professional but conversational
        • Ask clarifying questions only when genuinely unclear
        • When conflicts exist, always suggest alternatives
        • Be proactive about adding recurring schedules
        • Never claim you "can't access" or "can't modify" the calendar
        • Follow through on conversation logic without confusion
        
        CURRENT USER SCHEDULE:
        \(scheduleAnalysis)
        
        USER PREFERENCES:
        • Working hours: \(userPreferences.generalPreferences.workingHoursStart):00 to \(userPreferences.generalPreferences.workingHoursEnd):00
        • Sleep schedule: \(userPreferences.generalPreferences.sleepTime):00 to \(userPreferences.generalPreferences.wakeTime):00
        • Preferred buffer time: \(userPreferences.generalPreferences.bufferPreference) minutes between events
        
        Remember: You have complete calendar control. Maintain conversation context and follow through on requests consistently.
        """
    }
    
    // MARK: - Response Parsing and Handling
    
    private func parseAndHandleResponse(
        _ content: String,
        existingEvents: [ScheduleEvent],
        userPreferences: UserSchedulePreferences
    ) async throws -> TyResponse {
        
        print("🤖 Claude Response:\n\(content)")
        
        // 1. Check for deletion requests
        if content.contains("REMOVE_ALL_START") && content.contains("REMOVE_ALL_END") {
            print("🗑️ Processing delete all request")
            let message = extractMessageFromContent(content) ?? "All events have been deleted from your calendar."
            return .calendarAutomation(action: .removeAllEvents, message: message)
        }
        
        if let removeStart = content.range(of: "REMOVE_START"),
           let removeEnd = content.range(of: "REMOVE_END") {
            let removeText = String(content[removeStart.upperBound..<removeEnd.lowerBound])
            let removePatterns = removeText.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            let message = extractMessageFromContent(content) ?? "Selected events have been removed from your calendar."
            return .calendarAutomation(action: .removeEvents(removePatterns), message: message)
        }
        
        // 2. Check for schedule optimization (PRIMARY PURPOSE)
        if let optimizeStart = content.range(of: "OPTIMIZE_START"),
           let optimizeEnd = content.range(of: "OPTIMIZE_END") {
            
            let optimizeText = String(content[optimizeStart.upperBound..<optimizeEnd.lowerBound])
            
            if let task = parseFlexibleTask(from: optimizeText) {
                print("🎯 Processing schedule optimization for: \(task.title)")
                
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
        
        // 3. Check for calendar automation (SECONDARY PURPOSE)
        if let eventsStart = content.range(of: "EVENTS_START"),
           let eventsEnd = content.range(of: "EVENTS_END") {
            
            let eventsText = String(content[eventsStart.upperBound..<eventsEnd.lowerBound])
            let events = parseEvents(from: eventsText)
            let message = extractMessageFromContent(content) ?? "Events have been added to your calendar."
            
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
            return "User has a completely open schedule this week - perfect for optimization!"
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
        let deadline: Date? = nil
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
        var events: [SimpleEvent] = []
        
        let eventBlocks = text.components(separatedBy: "---")
        
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
        let days: [Int] = []
        
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
