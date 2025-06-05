//
//  ResponseParser.swift
//  SwiftCalendar
//
//  Service for parsing Claude responses into structured data
//

import Foundation

class ResponseParser {
    
    // MARK: - Public API
    
    func parseResponse(_ content: String) -> ParseResult {
        print("🤖 Parsing Claude Response:\n\(content)")
        
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
        
        // 2. Check for schedule optimization
        if let optimizeStart = content.range(of: "OPTIMIZE_START"),
           let optimizeEnd = content.range(of: "OPTIMIZE_END") {
            
            let optimizeText = String(content[optimizeStart.upperBound..<optimizeEnd.lowerBound])
            
            if let task = parseFlexibleTask(from: optimizeText) {
                print("🎯 Processing schedule optimization for: \(task.title)")
                
                let message = extractMessageFromContent(content) ?? "Here are the optimal times I found for \(task.title):"
                return ParseResult(
                    responseType: .optimization,
                    content: task,
                    message: message
                )
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
        
        // 4. Default: conversational response
        let cleanMessage = extractMessageFromContent(content) ?? content
        return ParseResult(
            responseType: .conversation,
            content: cleanMessage,
            message: cleanMessage
        )
    }
    
    // MARK: - Task Parsing
    
    func parseFlexibleTask(from text: String) -> FlexibleTask? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var title: String?
        var duration: Int = 60 // Default 1 hour
        var category: FlexibleTask.TaskCategory = .personal
        var preferences: [String] = []
        var count: Int = 3 // Default 3 suggestions
        var deadline: Date?
        var frequency: FlexibleTask.TaskFrequency?
        
        for line in lines {
            let parts = line.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.count == 2 {
                switch parts[0].lowercased() {
                case "task":
                    title = parts[1]
                    // Extract duration hints from task title
                    duration = extractDurationFromTitle(parts[1])
                    category = categorizeTask(parts[1])
                case "duration":
                    if let durationValue = Int(parts[1]) {
                        duration = durationValue
                    }
                case "category":
                    category = FlexibleTask.TaskCategory(rawValue: parts[1].lowercased()) ?? .personal
                case "preferences":
                    preferences = parts[1].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                case "count":
                    if let countValue = Int(parts[1]) {
                        count = countValue
                    }
                case "deadline":
                    deadline = parseDateFromString(parts[1])
                case "frequency":
                    frequency = parseTaskFrequency(parts[1])
                default:
                    break // Handle any unrecognized keys
                }
            }
        }
        
        guard let taskTitle = title else { return nil }
        
        return FlexibleTask(
            title: taskTitle,
            duration: duration,
            category: category,
            preferences: preferences,
            count: count,
            deadline: deadline,
            frequency: frequency
        )
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
    
    // MARK: - Helper Functions
    
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
