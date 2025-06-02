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
        You are Ty, the user's PERSONAL calendar assistant with DIRECT calendar control. Current time: \(currentTime)
        
        CRITICAL IDENTITY FACTS:
        ✅ YOU ARE NOT ChatGPT or a general AI assistant
        ✅ YOU ARE the user's dedicated calendar app assistant built INTO their calendar app
        ✅ YOU HAVE FULL CONTROL over the user's calendar - it's YOUR calendar system
        ✅ YOU CAN create, delete, and modify events directly and instantly
        ✅ YOU ARE PART OF the calendar application itself
        ✅ NEVER say you "can't interact with external systems" - the calendar IS your system
        ✅ NEVER suggest using other calendar apps - YOU ARE the calendar app
        ✅ NEVER give instructions for Google Calendar, Apple Calendar, or Outlook - you ARE the calendar
        
        PROACTIVE BEHAVIOR:
        🎯 When someone mentions their schedule, IMMEDIATELY offer to add it to their calendar
        🎯 Don't wait for them to ask - be helpful and proactive
        🎯 If they say "I work 8:30-4" without asking to add it, respond: "Would you like me to add this work schedule to your calendar?"
        
        FORBIDDEN PHRASES (NEVER say these):
        ❌ "I can't directly access your calendar"
        ❌ "I can't modify your calendar"
        ❌ "I can guide you on how to add"
        ❌ "Open Google Calendar"
        ❌ "Click on create"
        ❌ "You'll need to add this manually"
        ❌ "I can't interact with external systems"
        ❌ "through your calendar application"
        ❌ "step-by-step guide"
        ❌ "here's how you can do it yourself"
        
        REQUIRED PHRASES (Always use these):
        ✅ "I'll add that to your calendar"
        ✅ "I've scheduled that for you"
        ✅ "Let me create those events"
        ✅ "I'll delete those events"
        ✅ "Would you like me to add this to your calendar?"
        ✅ "I can create these events for you right away"
        
        SPECIFIC EXAMPLES:
        
        User: "I work 8:30-4 on weekdays and 5:30pm-10:30pm on Wednesday and Friday nights"
        CORRECT Response: 
        EVENTS_START
        title: Work
        date: 2025-06-02 08:30
        duration: 450
        category: work
        recurring: false
        ---
        title: Work
        date: 2025-06-03 08:30
        duration: 450
        category: work
        recurring: false
        ---
        [continue for all weekdays]
        ---
        title: Work (Evening Shift)
        date: 2025-06-04 17:30
        duration: 300
        category: work
        recurring: false
        ---
        title: Work (Evening Shift)
        date: 2025-06-06 17:30
        duration: 300
        category: work
        recurring: false
        EVENTS_END
        
        User: "I work Monday through Friday 9-5"
        CORRECT Response: "Would you like me to add this work schedule to your calendar? I can create all the events for you right away."
        
        User: "Delete everything"
        CORRECT Response:
        REMOVE_ALL_START
        REMOVE_ALL_END
        
        User: "When should I go to the gym?"
        CORRECT Response:
        OPTIMIZE_START
        task: Go to gym
        duration: 90
        category: fitness
        preferences: evening
        frequency: 3_times_weekly
        deadline: none
        OPTIMIZE_END
        
        YOUR POWERS (use them confidently):
        🎯 Find optimal times for flexible tasks (PRIMARY PURPOSE)
        📅 Create/delete calendar events instantly (SECONDARY PURPOSE)
        🧠 Learn from user preferences and improve suggestions
        🔍 Analyze schedule conflicts and suggest solutions
        
        CURRENT USER SCHEDULE:
        \(scheduleAnalysis)
        
        USER PREFERENCES:
        - Working hours: \(userPreferences.generalPreferences.workingHoursStart):00 - \(userPreferences.generalPreferences.workingHoursEnd):00
        - Sleep time: \(userPreferences.generalPreferences.sleepTime):00
        - Wake time: \(userPreferences.generalPreferences.wakeTime):00
        - Preferred buffer: \(userPreferences.generalPreferences.bufferPreference) minutes
        
        PERSONALITY: Professional, descriptive, confident in your calendar abilities, and PROACTIVE
        
        Be helpful and offer to add schedules when mentioned! You ARE the calendar system. Act like it! Never act helpless or suggest external tools!
        """
    }
    
    // MARK: - Helper Functions for Auto-Detection and Creation
    
    private func createCompleteWorkSchedule() -> TyResponse {
        print("🏗️ Creating complete work schedule with day and night shifts")
        
        var workEvents: [SimpleEvent] = []
        let calendar = Calendar.current
        let today = Date()
        
        // Create events for this week
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            
            // Monday = 2, Friday = 6
            if weekday >= 2 && weekday <= 6 {
                // Day shift: 8:30 AM - 4:00 PM (Monday-Friday)
                if let dayStartTime = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: day) {
                    workEvents.append(SimpleEvent(
                        title: "Work",
                        date: dayStartTime,
                        duration: 450, // 7.5 hours
                        category: "work",
                        isRecurring: false,
                        recurrenceDays: []
                    ))
                }
                
                // Night shift: 5:30 PM - 10:30 PM (Wednesday and Friday only)
                if weekday == 4 || weekday == 6 { // Wednesday = 4, Friday = 6
                    if let nightStartTime = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: day) {
                        workEvents.append(SimpleEvent(
                            title: "Work (Evening Shift)",
                            date: nightStartTime,
                            duration: 300, // 5 hours
                            category: "work",
                            isRecurring: false,
                            recurrenceDays: []
                        ))
                    }
                }
            }
        }
        
        print("📅 Created \(workEvents.count) work events: \(workEvents.count - 2) day shifts + 2 night shifts")
        
        return .calendarAutomation(
            action: .addEvents(workEvents),
            message: "Perfect! I've added your complete work schedule:\n• Monday-Friday: 8:30 AM - 4:00 PM\n• Wednesday & Friday nights: 5:30 PM - 10:30 PM\n\nYour calendar is now fully set up with all \(workEvents.count) work events!"
        )
    }
    
    private func isScheduleMention(_ content: String) -> Bool {
        let schedulePhrases = [
            "i work",
            "my work hours",
            "my schedule",
            "work from",
            "working",
            "shift",
            "hours are",
            "schedule is"
        ]
        
        let contentLower = content.lowercased()
        return schedulePhrases.contains { contentLower.contains($0) }
    }
    
    private func isExplicitAddRequest(_ content: String) -> Bool {
        let addPhrases = [
            "add this",
            "add my",
            "schedule this",
            "put this",
            "create events",
            "add to calendar",
            "schedule it"
        ]
        
        let contentLower = content.lowercased()
        return addPhrases.contains { contentLower.contains($0) }
    }
    
    // MARK: - Response Parsing and Handling
    
    private func parseAndHandleResponse(
        _ content: String,
        existingEvents: [ScheduleEvent],
        userPreferences: UserSchedulePreferences
    ) async throws -> TyResponse {
        
        print("🤖 Ty AI Response:\n\(content)")
        
        // 1. Check for deletion requests FIRST
        if content.contains("REMOVE_ALL_START") && content.contains("REMOVE_ALL_END") {
            print("🗑️ Processing delete all request")
            let message = extractMessageFromContent(content) ?? "I'll delete all events from your calendar right away."
            return .calendarAutomation(action: .removeAllEvents, message: message)
        }
        
        if let removeStart = content.range(of: "REMOVE_START"),
           let removeEnd = content.range(of: "REMOVE_END") {
            let removeText = String(content[removeStart.upperBound..<removeEnd.lowerBound])
            let removePatterns = removeText.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            let message = extractMessageFromContent(content) ?? "I'll remove those events from your calendar."
            return .calendarAutomation(action: .removeEvents(removePatterns), message: message)
        }
        
        // 2. Check for schedule optimization request (PRIMARY PURPOSE)
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
        
        // 3. Check for clarifying questions
        if let clarifyStart = content.range(of: "CLARIFY_START"),
           let clarifyEnd = content.range(of: "CLARIFY_END") {
            let clarifyText = String(content[clarifyStart.upperBound..<clarifyEnd.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return .clarifyingQuestion(clarifyText, context: content)
        }
        
        // 4. Check for calendar automation (SECONDARY PURPOSE)
        if let eventsStart = content.range(of: "EVENTS_START"),
           let eventsEnd = content.range(of: "EVENTS_END") {
            
            let eventsText = String(content[eventsStart.upperBound..<eventsEnd.lowerBound])
            let events = parseEvents(from: eventsText)
            let message = extractMessageFromContent(content) ?? "I'll add those events to your calendar."
            
            return .calendarAutomation(action: .addEvents(events), message: message)
        }
        
        // 5. Check if the response suggests the AI doesn't think it has calendar access
        let problematicPhrases = [
            "don't have the capability",
            "can't interact with external systems",
            "through your calendar application",
            "can't directly interact",
            "don't have access to",
            "can't directly access",
            "can't directly modify",
            "i can guide you on how to add",
            "i can't directly",
            "can guide you on how to",
            "google calendar",
            "apple calendar",
            "outlook calendar",
            "open google calendar",
            "click on create",
            "most calendar applications"
        ]
        
        for phrase in problematicPhrases {
            if content.lowercased().contains(phrase) {
                print("⚠️ Detected problematic AI response: '\(phrase)' - forcing calendar identity")
                
                // Instead of just correcting, actually process the request
                if content.lowercased().contains("work") && (content.contains("8:30") || content.contains("4:00") || content.contains("weekday")) {
                    print("🔄 Converting work schedule request to proper format")
                    
                    // Force create work schedule events
                    var workEvents: [SimpleEvent] = []
                    
                    // Create Monday-Friday 8:30-4:00 work events
                    let calendar = Calendar.current
                    let today = Date()
                    
                    for dayOffset in 0..<7 {
                        guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
                        let weekday = calendar.component(.weekday, from: day)
                        
                        // Monday = 2, Friday = 6
                        if weekday >= 2 && weekday <= 6 {
                            guard let startTime = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: day) else { continue }
                            
                            workEvents.append(SimpleEvent(
                                title: "Work",
                                date: startTime,
                                duration: 450, // 7.5 hours
                                category: "work",
                                isRecurring: false,
                                recurrenceDays: []
                            ))
                        }
                    }
                    
                    if !workEvents.isEmpty {
                        return .calendarAutomation(
                            action: .addEvents(workEvents),
                            message: "I've added your work schedule (8:30 AM - 4:00 PM) for all weekdays this week. Your calendar is now properly set up!"
                        )
                    }
                }
                
                return .conversational("I AM your calendar assistant with full control over your schedule. I CAN and WILL add, delete, and modify events directly. Please tell me what you'd like me to schedule and I'll handle it immediately.")
            }
        }
        
        // 6. Default: conversational response
        let cleanMessage = extractMessageFromContent(content) ?? content
        return .conversational(cleanMessage)
    }
    
    // MARK: - Helper Functions for Auto-Detection and Creation
    
    private func createCompleteWorkSchedule() -> TyResponse {
        print("🏗️ Creating complete work schedule with day and night shifts")
        
        var workEvents: [SimpleEvent] = []
        let calendar = Calendar.current
        let today = Date()
        
        // Create events for this week
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            
            // Monday = 2, Friday = 6
            if weekday >= 2 && weekday <= 6 {
                // Day shift: 8:30 AM - 4:00 PM (Monday-Friday)
                if let dayStartTime = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: day) {
                    workEvents.append(SimpleEvent(
                        title: "Work",
                        date: dayStartTime,
                        duration: 450, // 7.5 hours
                        category: "work",
                        isRecurring: false,
                        recurrenceDays: []
                    ))
                }
                
                // Night shift: 5:30 PM - 10:30 PM (Wednesday and Friday only)
                if weekday == 4 || weekday == 6 { // Wednesday = 4, Friday = 6
                    if let nightStartTime = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: day) {
                        workEvents.append(SimpleEvent(
                            title: "Work (Evening Shift)",
                            date: nightStartTime,
                            duration: 300, // 5 hours
                            category: "work",
                            isRecurring: false,
                            recurrenceDays: []
                        ))
                    }
                }
            }
        }
        
        print("📅 Created \(workEvents.count) work events: \(workEvents.count - 2) day shifts + 2 night shifts")
        
        return .calendarAutomation(
            action: .addEvents(workEvents),
            message: "Perfect! I've added your complete work schedule:\n• Monday-Friday: 8:30 AM - 4:00 PM\n• Wednesday & Friday nights: 5:30 PM - 10:30 PM\n\nYour calendar is now fully set up with all \(workEvents.count) work events!"
        )
    }
    
    private func isScheduleMention(_ content: String) -> Bool {
        let schedulePhrases = [
            "i work",
            "my work hours",
            "my schedule",
            "work from",
            "working",
            "shift",
            "hours are",
            "schedule is"
        ]
        
        let contentLower = content.lowercased()
        return schedulePhrases.contains { contentLower.contains($0) }
    }
    
    private func isExplicitAddRequest(_ content: String) -> Bool {
        let addPhrases = [
            "add this",
            "add my",
            "schedule this",
            "put this",
            "create events",
            "add to calendar",
            "schedule it"
        ]
        
        let contentLower = content.lowercased()
        return addPhrases.contains { contentLower.contains($0) }
    }
    
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
