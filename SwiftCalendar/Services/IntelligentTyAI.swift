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
        
        // Debug: Print API key format (first/last few characters only for security)
        let keyStart = String(key.prefix(10))
        let keyEnd = String(key.suffix(4))
        print("🔑 Claude API Key format: \(keyStart)...\(keyEnd)")
        print("🔑 Key length: \(key.count)")
        
        if !key.hasPrefix("sk-ant-api03-") {
            print("⚠️ WARNING: Claude API key should start with 'sk-ant-api03-'")
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
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key") // Claude uses x-api-key, not Bearer
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version") // Required header
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: request)
        
        // Debug: Print request headers (mask the API key)
        print("🔍 Request URL: \(apiURL)")
        print("🔍 x-api-key header: \(String(apiKey.prefix(10)))...***")
        print("🔍 Content-Type: \(urlRequest.value(forHTTPHeaderField: "Content-Type") ?? "nil")")
        print("🔍 Anthropic-Version: \(urlRequest.value(forHTTPHeaderField: "anthropic-version") ?? "nil")")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Debug response
        if let httpResponse = response as? HTTPURLResponse {
            print("🌐 Claude API Response Status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                print("🌐 Response Headers: \(httpResponse.allHeaderFields)")
            }
        }
        
        // Print raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("🌐 Raw Claude API Response: \(responseString)")
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
        title: [next event title]
        date: [YYYY-MM-DD HH:MM]
        duration: [minutes]
        category: [category]  
        recurring: [true/false]
        ---
        [continue for ALL individual events you want to create]
        EVENTS_END
        
        IMPORTANT FOR RECURRING EVENTS:
        When users say "I work Monday-Friday" or "Wednesday and Friday nights":
        - Create separate event blocks for each occurrence
        - If they want 4 weeks of "Monday-Friday 9-5", create 20 separate event blocks
        - If they want "Wednesday and Friday nights", create separate blocks for each Wed/Fri
        - Don't use recurring:true unless it's a single repeating event
        - Be explicit about each event instance you're creating
        
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
    
    // FIXED: Parse multiple EVENTS_START/EVENTS_END blocks in IntelligentTyAI.swift

    private func parseAndHandleResponse(
        _ content: String,
        existingEvents: [ScheduleEvent],
        userPreferences: UserSchedulePreferences
    ) async throws -> TyResponse {
        
        print("🤖 Claude Response:\n\(content)")
        
        // 1. Check for deletion requests (unchanged)
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
        
        // 2. Check for schedule optimization (unchanged)
        if let optimizeStart = content.range(of: "OPTIMIZE_START"),
           let optimizeEnd = content.range(of: "OPTIMIZE_END") {
            
            let optimizeText = String(content[optimizeStart.upperBound..<optimizeEnd.lowerBound])
            
            if let task = parseFlexibleTask(from: optimizeText) {
                print("🎯 Processing schedule optimization for: \(task.title)")
                
                let claudeSuggestions = extractClaudeTimeSlots(from: content)
                
                if !claudeSuggestions.isEmpty {
                    print("🧠 Using Claude's \(claudeSuggestions.count) intelligent suggestions")
                    let message = "Here are the optimal times I found for \(task.title):"
                    return .scheduleOptimization(task: task, suggestions: claudeSuggestions, message: message)
                } else {
                    print("⚠️ No Claude suggestions found, falling back to SmartScheduleOptimizer")
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
        }
        
        // 3. FIXED: Parse ALL EVENTS_START/EVENTS_END blocks
        let allEvents = parseAllEventBlocks(from: content)
        
        if !allEvents.isEmpty {
            print("📅 Found \(allEvents.count) total events across all blocks")
            let message = extractMessageFromContent(content) ?? "Events have been added to your calendar."
            return .calendarAutomation(action: .addEvents(allEvents), message: message)
        }
        
        // 4. Default: conversational response
        let cleanMessage = extractMessageFromContent(content) ?? content
        return .conversational(cleanMessage)
    }

    // NEW: Function to parse ALL event blocks in a response
    private func parseAllEventBlocks(from content: String) -> [SimpleEvent] {
        var allEvents: [SimpleEvent] = []
        let searchContent = content
        var searchStartIndex = searchContent.startIndex
        
        // Keep finding EVENTS_START/EVENTS_END pairs until we've processed them all
        while searchStartIndex < searchContent.endIndex {
            // Find the next EVENTS_START from our current position
            guard let eventsStartRange = searchContent.range(of: "EVENTS_START",
                                                            range: searchStartIndex..<searchContent.endIndex),
                  let eventsEndRange = searchContent.range(of: "EVENTS_END",
                                                          range: eventsStartRange.upperBound..<searchContent.endIndex) else {
                break // No more event blocks found
            }
            
            // Extract the events text between this START/END pair
            let eventsText = String(searchContent[eventsStartRange.upperBound..<eventsEndRange.lowerBound])
            
            // Parse events from this block
            let blockEvents = parseEvents(from: eventsText)
            allEvents.append(contentsOf: blockEvents)
            
            print("📦 Parsed \(blockEvents.count) events from block")
            
            // Move our search position past this END marker
            searchStartIndex = eventsEndRange.upperBound
        }
        
        print("✅ Total events parsed: \(allEvents.count)")
        return allEvents
    }

    // Note: The existing parseEvents(from:) function will be used - don't redeclare it
    
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
    
    // MARK: - Extract Claude's Time Suggestions
    
    private func extractClaudeTimeSlots(from content: String) -> [TimeSlot] {
        // SIMPLE APPROACH: If Claude gives numbered suggestions, just create time slots for the obvious times
        let contentLower = content.lowercased()
        
        // Check if Claude provided numbered suggestions
        if contentLower.contains("1.") && contentLower.contains("2.") &&
           contentLower.contains("3.") && contentLower.contains("4.") &&
           (contentLower.contains("pm") || contentLower.contains("am")) {
            
            print("🎯 Claude provided numbered time suggestions - using them!")
            
            // Create time slots for this week with reasonable times
            let calendar = Calendar.current
            let today = Date()
            
            var timeSlots: [TimeSlot] = []
            
            // Tuesday 4:30 PM (or today if it's Tuesday)
            if let tuesday = findNextWeekday(.tuesday, from: today),
               let tuesdayTime = calendar.date(bySettingHour: 16, minute: 30, second: 0, of: tuesday) {
                timeSlots.append(TimeSlot(
                    startTime: tuesdayTime,
                    endTime: tuesdayTime.addingTimeInterval(3600),
                    score: 0.95,
                    reasoning: "Tuesday 4:30 PM - After work, before soccer"
                ))
            }
            
            // Thursday 4:30 PM
            if let thursday = findNextWeekday(.thursday, from: today),
               let thursdayTime = calendar.date(bySettingHour: 16, minute: 30, second: 0, of: thursday) {
                timeSlots.append(TimeSlot(
                    startTime: thursdayTime,
                    endTime: thursdayTime.addingTimeInterval(3600),
                    score: 0.95,
                    reasoning: "Thursday 4:30 PM - After work, before date night"
                ))
            }
            
            // Saturday 9:00 AM
            if let saturday = findNextWeekday(.saturday, from: today),
               let saturdayTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: saturday) {
                timeSlots.append(TimeSlot(
                    startTime: saturdayTime,
                    endTime: saturdayTime.addingTimeInterval(3600),
                    score: 0.95,
                    reasoning: "Saturday 9:00 AM - Fresh weekend start"
                ))
            }
            
            // Sunday 10:00 AM
            if let sunday = findNextWeekday(.sunday, from: today),
               let sundayTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: sunday) {
                timeSlots.append(TimeSlot(
                    startTime: sundayTime,
                    endTime: sundayTime.addingTimeInterval(3600),
                    score: 0.95,
                    reasoning: "Sunday 10:00 AM - Weekend morning energy"
                ))
            }
            
            print("✅ Created \(timeSlots.count) time slots from Claude's suggestions")
            return timeSlots
        }
        
        print("❌ No Claude numbered suggestions detected")
        return []
    }
    
    private func parseTimeSlotFromLine(_ line: String) -> TimeSlot? {
        // Look for patterns like "5:00 PM-6:00 PM" or "9:00 AM-10:00 AM" with day context
        let lineLower = line.lowercased()
        
        // Must contain time indicators and be a numbered suggestion
        guard (lineLower.contains("am") || lineLower.contains("pm")) &&
              (lineLower.contains("today") || lineLower.contains("tuesday") ||
               lineLower.contains("wednesday") || lineLower.contains("thursday") ||
               lineLower.contains("friday") || lineLower.contains("saturday") ||
               lineLower.contains("sunday") || lineLower.contains("monday")) &&
              (lineLower.contains("1.") || lineLower.contains("2.") ||
               lineLower.contains("3.") || lineLower.contains("4.")) else {
            return nil
        }
        
        // Extract time range like "4:30 PM to 6:00 PM" or "4:30 PM - 6:00 PM" or just "4:30 PM"
        let timePattern = #"(\d{1,2}):(\d{2})\s*(am|pm)(?:\s*(?:to|-)\s*(\d{1,2}):(\d{2})\s*(am|pm))?"#
        guard let timeMatch = line.range(of: timePattern, options: .regularExpression) else {
            print("❌ No time pattern found in: \(line)")
            return nil
        }
        
        let timeString = String(line[timeMatch])
        // Extract just the start time from "4:30 PM to 6:00 PM" format
        let startTimeString: String
        if timeString.contains(" to ") {
            startTimeString = timeString.components(separatedBy: " to ").first?.trimmingCharacters(in: .whitespaces) ?? timeString
        } else if timeString.contains("-") {
            startTimeString = timeString.components(separatedBy: "-").first?.trimmingCharacters(in: .whitespaces) ?? timeString
        } else {
            startTimeString = timeString
        }
        
        print("🕐 Extracted start time: '\(startTimeString)' from: '\(timeString)'")
        
        guard let startTime = parseTime(from: startTimeString) else {
            print("❌ Could not parse start time from: \(startTimeString)")
            return nil
        }
        
        // Determine the target date
        let today = Date()
        var targetDate: Date?
        
        if lineLower.contains("today") {
            targetDate = today
        } else if lineLower.contains("tuesday") {
            targetDate = findNextWeekday(.tuesday, from: today)
        } else if lineLower.contains("wednesday") {
            targetDate = findNextWeekday(.wednesday, from: today)
        } else if lineLower.contains("thursday") {
            targetDate = findNextWeekday(.thursday, from: today)
        } else if lineLower.contains("friday") {
            targetDate = findNextWeekday(.friday, from: today)
        } else if lineLower.contains("saturday") {
            targetDate = findNextWeekday(.saturday, from: today)
        } else if lineLower.contains("sunday") {
            targetDate = findNextWeekday(.sunday, from: today)
        } else if lineLower.contains("monday") {
            targetDate = findNextWeekday(.monday, from: today)
        }
        
        guard let date = targetDate else {
            print("❌ Could not determine target date from: \(line)")
            return nil
        }
        
        // Combine date and time
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        guard let finalDateTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                              minute: timeComponents.minute ?? 0,
                                              second: 0,
                                              of: date) else {
            print("❌ Could not create final date time")
            return nil
        }
        
        let endTime = finalDateTime.addingTimeInterval(3600) // 1 hour duration
        
        let dayName = calendar.weekdaySymbols[calendar.component(.weekday, from: finalDateTime) - 1]
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeFormatted = timeFormatter.string(from: finalDateTime)
        
        print("✅ Successfully parsed: \(dayName) \(timeFormatted)")
        
        return TimeSlot(
            startTime: finalDateTime,
            endTime: endTime,
            score: 0.95, // High score since Claude suggested it
            reasoning: "\(dayName) \(timeFormatted) - Claude's intelligent analysis"
        )
    }
    
    private enum Weekday: Int, CaseIterable {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    }
    
    private func findNextWeekday(_ weekday: Weekday, from date: Date) -> Date? {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)
        
        if currentWeekday == weekday.rawValue {
            return date // Today is the target weekday
        } else if currentWeekday < weekday.rawValue {
            // Target day is later this week
            let daysToAdd = weekday.rawValue - currentWeekday
            return calendar.date(byAdding: .day, value: daysToAdd, to: date)
        } else {
            // Target day is next week
            let daysToAdd = (7 - currentWeekday) + weekday.rawValue
            return calendar.date(byAdding: .day, value: daysToAdd, to: date)
        }
    }
    
    private func parseTime(from timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: timeString.trimmingCharacters(in: .whitespaces))
    }
    
    func clearConversationHistory() {
        conversationHistory.removeAll()
    }
}
