//
//  ResponseParser.swift
//  SwiftCalendar
//
//  FIXED: Service for parsing Claude responses - ensures only AI suggestions are used
//

import Foundation

class ResponseParser {
    
    // MARK: - Public API
    
    func parseResponse(_ content: String) -> ParseResult {
        print("🤖 Parsing Claude Response:")
        print("📝 Full Content: \(content)")
        print("📏 Content Length: \(content.count)")
        
        // 1. Check for deletion requests
        if content.contains("REMOVE_ALL_START") && content.contains("REMOVE_ALL_END") {
            print("🗑️ Processing delete all request")
            let message = extractMessageFromContent(content) ?? "All events have been deleted from your calendar."
            return ParseResult(
                responseType: .removal,
                content: CalendarAction.removeAllEvents,
                message: message
            )
        }
        
        if let removeStart = content.range(of: "REMOVE_START"),
           let removeEnd = content.range(of: "REMOVE_END") {
            let removeText = String(content[removeStart.upperBound..<removeEnd.lowerBound])
            let removePatterns = removeText.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            let message = extractMessageFromContent(content) ?? "Selected events have been removed from your calendar."
            return ParseResult(
                responseType: .removal,
                content: CalendarAction.removeEvents(removePatterns),
                message: message
            )
        }
        
        // 2. Check for schedule optimization - EXTRACT CLAUDE'S ACTUAL SUGGESTIONS
        if let optimizeStart = content.range(of: "OPTIMIZE_START"),
           let optimizeEnd = content.range(of: "OPTIMIZE_END") {
            
            let optimizeText = String(content[optimizeStart.upperBound..<optimizeEnd.lowerBound])
            print("🎯 Found OPTIMIZE block:")
            print("📋 Optimize Text: '\(optimizeText)'")
            
            if let task = parseFlexibleTask(from: optimizeText) {
                print("✅ Successfully parsed task: \(task.title)")
                print("⏱️ Duration: \(task.duration) minutes")
                print("📂 Category: \(task.category)")
                print("🔢 Count: \(task.count)")
                
                // CRITICAL: Extract Claude's actual suggestions from the response text
                let claudeSuggestions = extractClaudeSuggestions(from: content, for: task)
                
                if !claudeSuggestions.isEmpty {
                    print("🤖 Using Claude's \(claudeSuggestions.count) suggestions instead of generating new ones")
                    for (index, suggestion) in claudeSuggestions.enumerated() {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "EEEE MMM d h:mm a"
                        print("  \(index + 1). \(formatter.string(from: suggestion.startTime))")
                    }
                    
                    let message = extractMessageFromContent(content) ?? "Here are the optimal times I found for \(task.title):"
                    return ParseResult(
                        responseType: .optimization,
                        content: (task: task, suggestions: claudeSuggestions),
                        message: message
                    )
                } else {
                    print("❌ CRITICAL ERROR: No Claude suggestions found")
                    // Return with empty suggestions - IntelligentTyAI will handle the error
                    let message = extractMessageFromContent(content) ?? "Failed to extract time suggestions"
                    return ParseResult(
                        responseType: .optimization,
                        content: (task: task, suggestions: []),
                        message: message
                    )
                }
            } else {
                print("❌ Failed to parse task from optimize block")
            }
        }
        
        // 3. Check for calendar automation (multiple event blocks)
        let allEvents = parseAllEventBlocks(from: content)
        
        if !allEvents.isEmpty {
            print("📅 Found \(allEvents.count) total events across all blocks")
            let message = extractMessageFromContent(content) ?? "Events have been added to your calendar."
            return ParseResult(
                responseType: .automation,
                content: CalendarAction.addEvents(allEvents),
                message: message
            )
        }
        
        // 5. Default: conversational response
        print("💬 Defaulting to conversational response")
        let cleanMessage = extractMessageFromContent(content) ?? content
        return ParseResult(
            responseType: .conversation,
            content: cleanMessage,
            message: cleanMessage
        )
    }
    
    // MARK: - Task Parsing
    
    func parseFlexibleTask(from text: String) -> FlexibleTask? {
        print("🔍 Parsing flexible task from text:")
        print("📝 Input text: '\(text)'")
        
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        print("📄 Lines to parse: \(lines)")
        
        var title: String?
        var duration: Int = 60 // Default 1 hour
        var category: FlexibleTask.TaskCategory = .personal
        var preferences: [String] = []
        var count: Int = 3 // Default 3 suggestions
        var deadline: Date?
        var frequency: FlexibleTask.TaskFrequency?
        
        for line in lines {
            let parts = line.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.count >= 2 {
                let key = parts[0].lowercased()
                let value = parts[1]
                
                print("🔑 Parsing key: '\(key)' = '\(value)'")
                
                switch key {
                case "task":
                    title = value
                    // Extract duration hints from task title
                    duration = extractDurationFromTitle(value)
                    category = categorizeTask(value)
                    print("  📝 Set title: \(value)")
                    print("  ⏱️ Extracted duration: \(duration)")
                    print("  📂 Extracted category: \(category)")
                case "duration":
                    if let durationValue = Int(value) {
                        duration = durationValue
                        print("  ⏱️ Set duration: \(durationValue)")
                    }
                case "category":
                    if let taskCategory = FlexibleTask.TaskCategory(rawValue: value.lowercased()) {
                        category = taskCategory
                        print("  📂 Set category: \(taskCategory)")
                    }
                case "preferences":
                    preferences = value.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    print("  🎯 Set preferences: \(preferences)")
                case "count":
                    if let countValue = Int(value) {
                        count = countValue
                        print("  🔢 Set count: \(countValue)")
                    }
                case "deadline":
                    deadline = parseDateFromString(value)
                    print("  📅 Set deadline: \(deadline?.description ?? "nil")")
                case "frequency":
                    frequency = parseTaskFrequency(value)
                    print("  🔄 Set frequency: \(frequency?.description ?? "nil")")
                default:
                    print("  ❓ Unrecognized key: \(key)")
                }
            }
        }
        
        guard let taskTitle = title else {
            print("❌ No task title found, cannot create task")
            return nil
        }
        
        let task = FlexibleTask(
            title: taskTitle,
            duration: duration,
            category: category,
            preferences: preferences,
            count: count,
            deadline: deadline,
            frequency: frequency
        )
        
        print("✅ Created FlexibleTask:")
        print("  📝 Title: \(task.title)")
        print("  ⏱️ Duration: \(task.duration)")
        print("  📂 Category: \(task.category)")
        print("  🔢 Count: \(task.count)")
        
        return task
    }
    
    // MARK: - Event Parsing
    
    func parseAllEventBlocks(from content: String) -> [SimpleEvent] {
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
                break // Handle any unrecognized keys
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        if !title.isEmpty, let startDate = formatter.date(from: dateStr) {
            let endDate = startDate.addingTimeInterval(TimeInterval(duration * 60))
            return SimpleEvent(
                title: title,
                startDate: startDate,
                endDate: endDate,
                category: category,
                isRecurring: recurring,
                recurrenceDays: days
            )
        }
        
        return nil
    }
    
    // MARK: - Extract Claude's Actual Suggestions
    
    private func extractClaudeSuggestions(from content: String, for task: FlexibleTask) -> [TimeSlotSuggestion] {
        print("🔍 Extracting Claude's suggestions from response text")
        
        var suggestions: [TimeSlotSuggestion] = []
        let lines = content.components(separatedBy: .newlines)
        
        // Look for numbered suggestions in Claude's response
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Look for patterns like "1. Today (Thursday) at 5:00 PM - 6:00 PM"
            // or "2. Saturday at 10:00 AM - 11:00 AM"
            if let match = extractTimeFromLine(trimmed) {
                let (startTime, reasoning) = match
                let endTime = startTime.addingTimeInterval(TimeInterval(task.duration * 60))
                
                let suggestion = TimeSlotSuggestion(
                    startTime: startTime,
                    endTime: endTime,
                    score: 1.0, // Claude's suggestions are perfect
                    reasoning: reasoning,
                    category: task.category
                )
                
                suggestions.append(suggestion)
                
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE MMM d h:mm a"
                print("  ✅ Extracted: \(formatter.string(from: startTime)) - \(reasoning)")
            }
        }
        
        print("🎯 Extracted \(suggestions.count) suggestions from Claude's response")
        return suggestions
    }
    
    private func extractTimeFromLine(_ line: String) -> (Date, String)? {
        // FIXED: Patterns to match Claude's actual format with " - " instead of " at "
        let patterns = [
            // "1. Today (Thursday) - 5:00 PM to 6:00 PM"
            "\\d+\\.\\s*(Today|Tomorrow)\\s*\\([^)]+\\)\\s*-\\s*(\\d{1,2}:\\d{2}\\s*[AP]M)",
            // "2. Saturday - 10:00 AM to 11:00 AM"
            "\\d+\\.\\s*(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\\s*-\\s*(\\d{1,2}:\\d{2}\\s*[AP]M)",
            // "Today (Thursday) - 5:00 PM"
            "(Today|Tomorrow)\\s*\\([^)]+\\)\\s*-\\s*(\\d{1,2}:\\d{2}\\s*[AP]M)",
            // "Saturday - 10:00 AM"
            "(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\\s*-\\s*(\\d{1,2}:\\d{2}\\s*[AP]M)"
        ]
        
        for pattern in patterns {
            print("    🧪 Testing pattern: \(pattern)")
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) {
                
                // Extract the day and time
                let fullMatch = String(line[Range(match.range, in: line)!])
                print("    ✅ MATCHED pattern with: '\(fullMatch)'")
                
                if let parsedDate = parseClaudeTimeString(fullMatch) {
                    let reasoning = extractReasoningFromLine(line)
                    return (parsedDate, reasoning)
                } else {
                    print("    ❌ Failed to parse date from: '\(fullMatch)'")
                }
            } else {
                print("    ❌ Pattern failed")
            }
        }
        
        return nil
    }
    
    private func parseClaudeTimeString(_ timeString: String) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        // Extract day and time components
        let dayPattern = "(Today|Tomorrow|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)"
        let timePattern = "(\\d{1,2}:\\d{2}\\s*[AP]M)"
        
        guard let dayRegex = try? NSRegularExpression(pattern: dayPattern, options: .caseInsensitive),
              let timeRegex = try? NSRegularExpression(pattern: timePattern, options: .caseInsensitive),
              let dayMatch = dayRegex.firstMatch(in: timeString, options: [], range: NSRange(timeString.startIndex..., in: timeString)),
              let timeMatch = timeRegex.firstMatch(in: timeString, options: [], range: NSRange(timeString.startIndex..., in: timeString)) else {
            return nil
        }
        
        let dayString = String(timeString[Range(dayMatch.range, in: timeString)!])
        let timeStringPart = String(timeString[Range(timeMatch.range, in: timeString)!])
        
        print("    📅 Day: \(dayString), Time: \(timeStringPart)")
        
        // Parse the time
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let time = timeFormatter.date(from: timeStringPart) else {
            print("    ❌ Could not parse time: \(timeStringPart)")
            return nil
        }
        
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        // Calculate the target date
        var targetDate: Date?
        
        switch dayString.lowercased() {
        case "today":
            targetDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now)
        case "tomorrow":
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
                targetDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: tomorrow)
            }
        default:
            // Find the next occurrence of this weekday
            let weekdays = ["sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4, "thursday": 5, "friday": 6, "saturday": 7]
            if let targetWeekday = weekdays[dayString.lowercased()] {
                let currentWeekday = calendar.component(.weekday, from: now)
                var daysToAdd = targetWeekday - currentWeekday
                if daysToAdd <= 0 {
                    daysToAdd += 7 // Next week
                }
                
                if let futureDate = calendar.date(byAdding: .day, value: daysToAdd, to: now) {
                    targetDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: futureDate)
                }
            }
        }
        
        if let finalDate = targetDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE MMM d h:mm a"
            print("    ✅ Parsed to: \(formatter.string(from: finalDate))")
        }
        
        return targetDate
    }
    private func extractReasoningFromLine(_ line: String) -> String {
        // Look for text after "Reasoning:" or similar
        if let reasoningRange = line.range(of: "Reasoning:", options: .caseInsensitive) {
            let reasoning = String(line[reasoningRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return reasoning.isEmpty ? "Claude's optimal suggestion" : reasoning
        }
        
        return "Claude's optimal suggestion"
    }
    
    // MARK: - Helper Functions
    
    private func extractMessageFromContent(_ content: String) -> String? {
        let lines = content.components(separatedBy: .newlines)
        let filteredLines = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmed.contains("_START") && !trimmed.contains("_END") &&
                   !trimmed.hasPrefix("task:") && !trimmed.hasPrefix("duration:") &&
                   !trimmed.hasPrefix("category:") && !trimmed.hasPrefix("preferences:") &&
                   !trimmed.hasPrefix("count:") && !trimmed.hasPrefix("deadline:") &&
                   !trimmed.hasPrefix("frequency:") && !trimmed.hasPrefix("title:") &&
                   !trimmed.hasPrefix("date:") && !trimmed.isEmpty
        }
        
        let result = filteredLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }
    
    private func extractDurationFromTitle(_ title: String) -> Int {
        let lowercased = title.lowercased()
        
        // Look for duration patterns
        if lowercased.contains("quick") || lowercased.contains("brief") {
            return 30
        } else if lowercased.contains("workout") || lowercased.contains("gym") {
            return 90
        } else if lowercased.contains("meeting") || lowercased.contains("call") {
            return 60
        } else if lowercased.contains("study") || lowercased.contains("review") {
            return 120
        } else if lowercased.contains("coffee") || lowercased.contains("lunch") {
            return 45
        }
        
        // Extract explicit durations
        let patterns = [
            "(\\d+)\\s*hour[s]?": { (numberString: String) in Int(numberString)! * 60 },
            "(\\d+)\\s*hr[s]?": { (numberString: String) in Int(numberString)! * 60 },
            "(\\d+)\\s*min[ute]*[s]?": { (numberString: String) in Int(numberString)! },
            "(\\d+)\\s*h": { (numberString: String) in Int(numberString)! * 60 }
        ]
        
        for (pattern, multiplier) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: title, options: [], range: NSRange(title.startIndex..., in: title)),
               let range = Range(match.range(at: 1), in: title) {
                let numberString = String(title[range])
                if Int(numberString) != nil {
                    return multiplier(numberString)
                }
            }
        }
        
        return 60 // Default
    }
    
    private func categorizeTask(_ title: String) -> FlexibleTask.TaskCategory {
        let lowercased = title.lowercased()
        
        if lowercased.contains("gym") || lowercased.contains("workout") || lowercased.contains("exercise") ||
           lowercased.contains("run") || lowercased.contains("fitness") || lowercased.contains("sports") {
            return .fitness
        } else if lowercased.contains("study") || lowercased.contains("homework") || lowercased.contains("read") ||
                  lowercased.contains("learn") || lowercased.contains("research") {
            return .study
        } else if lowercased.contains("meeting") || lowercased.contains("call") || lowercased.contains("work") ||
                  lowercased.contains("project") {
            return .work
        } else if lowercased.contains("date") || lowercased.contains("friend") || lowercased.contains("social") ||
                  lowercased.contains("party") || lowercased.contains("dinner") {
            return .social
        } else if lowercased.contains("doctor") || lowercased.contains("appointment") || lowercased.contains("health") {
            return .health
        } else {
            return .personal
        }
    }
    
    private func parseDateFromString(_ dateString: String) -> Date? {
        let formatters = [
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "dd/MM/yyyy",
            "MMMM d, yyyy"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    private func parseTaskFrequency(_ text: String) -> FlexibleTask.TaskFrequency? {
        let lowercased = text.lowercased()
        if lowercased.contains("daily") {
            return .daily
        } else if lowercased.contains("times_weekly") {
            let components = lowercased.components(separatedBy: "_")
            if let timesString = components.first, let times = Int(timesString) {
                return .weekly(times: times)
            }
            return .weekly(times: 1) // Default to once weekly
        } else if lowercased.contains("weekly") {
            return .weekly(times: 1)
        }
        return nil
    }
}

// MARK: - Extensions for better debugging

extension FlexibleTask.TaskFrequency {
    var description: String {
        switch self {
        case .daily:
            return "daily"
        case .weekly(let times):
            return "weekly(\(times) times)"
        case .specific(let days):
            return "specific(\(days))"
        }
    }
}
