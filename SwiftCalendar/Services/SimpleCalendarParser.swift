//
//  SimpleCalendarParser.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-06-01.
//


//
//  SimpleCalendarParser.swift
//  SwiftCalendar
//
//  A deterministic calendar parser for common patterns
//

import Foundation

class SimpleCalendarParser {
    
    enum ParsedAction {
        case add(ParsedEvent)
        case remove(title: String, date: Date?)
        case query(startDate: Date, endDate: Date)
        case unknown(String)
    }
    
    struct ParsedEvent {
        let title: String
        let startTime: Date?
        let endTime: Date?
        let category: EventCategory
        let isRecurring: Bool
        let recurrenceDays: [Int]
        
        var isComplete: Bool {
            return startTime != nil && endTime != nil
        }
        
        var duration: Int? {
            guard let start = startTime, let end = endTime else { return nil }
            return Int(end.timeIntervalSince(start) / 60)
        }
    }
    
    func parse(_ input: String) -> ParsedAction {
        let normalized = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for removal requests
        if normalized.contains("remove") || normalized.contains("delete") || normalized.contains("cancel") {
            return parseRemoval(normalized)
        }
        
        // Check for query requests
        if normalized.contains("what") || normalized.contains("show") || normalized.contains("schedule") {
            return parseQuery(normalized)
        }
        
        // Default to add event
        return parseAddEvent(normalized)
    }
    
    private func parseAddEvent(_ text: String) -> ParsedAction {
        // Extract event details
        let (title, category) = extractEventDetails(from: text)
        
        // Extract temporal information
        let temporal = extractTemporalInfo(from: text)
        
        // Check for recurrence
        let (isRecurring, recurrenceDays) = extractRecurrence(from: text)
        
        let event = ParsedEvent(
            title: title,
            startTime: temporal.startTime,
            endTime: temporal.endTime,
            category: category,
            isRecurring: isRecurring,
            recurrenceDays: recurrenceDays
        )
        
        return .add(event)
    }
    
    private func parseRemoval(_ text: String) -> ParsedAction {
        // Extract what to remove
        var title = ""
        
        if text.contains("work") {
            title = "work"
        } else if text.contains("gym") || text.contains("workout") {
            title = "gym"
        } else if text.contains("dentist") {
            title = "dentist"
        } else if text.contains("doctor") {
            title = "doctor"
        } else if text.contains("meeting") {
            title = "meeting"
        }
        
        // Extract specific date if mentioned
        let date = extractSingleDate(from: text)
        
        return .remove(title: title, date: date)
    }
    
    private func parseQuery(_ text: String) -> ParsedAction {
        let today = Date()
        let calendar = Calendar.current
        
        if text.contains("today") {
            let start = calendar.startOfDay(for: today)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return .query(startDate: start, endDate: end)
        } else if text.contains("tomorrow") {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            let start = calendar.startOfDay(for: tomorrow)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return .query(startDate: start, endDate: end)
        } else if text.contains("week") {
            let start = calendar.startOfDay(for: today)
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            return .query(startDate: start, endDate: end)
        }
        
        return .unknown(text)
    }
    
    private func extractEventDetails(from text: String) -> (title: String, category: EventCategory) {
        // Work patterns
        if text.contains("work") || text.contains("office") {
            return ("Work", .work)
        } else if text.contains("meeting") {
            return ("Meeting", .work)
        }
        
        // Fitness patterns
        if text.contains("gym") {
            return ("Gym", .fitness)
        } else if text.contains("workout") || text.contains("exercise") {
            return ("Workout", .fitness)
        } else if text.contains("run") {
            return ("Run", .fitness)
        }
        
        // Health patterns
        if text.contains("dentist") {
            return ("Dentist Appointment", .health)
        } else if text.contains("doctor") {
            return ("Doctor Appointment", .health)
        } else if text.contains("appointment") {
            return ("Appointment", .health)
        }
        
        // Study patterns
        if text.contains("study") {
            return ("Study", .study)
        } else if text.contains("class") {
            return ("Class", .study)
        } else if text.contains("homework") {
            return ("Homework", .study)
        }
        
        // Social patterns
        if text.contains("dinner") {
            return ("Dinner", .social)
        } else if text.contains("lunch") {
            return ("Lunch", .social)
        } else if text.contains("party") {
            return ("Party", .social)
        }
        
        // Try to extract a custom title
        let words = text.split(separator: " ").map(String.init)
        for (index, word) in words.enumerated() {
            if word == "add" || word == "schedule" {
                if index + 1 < words.count {
                    let title = words[(index + 1)...].joined(separator: " ")
                        .replacingOccurrences(of: " at ", with: " ")
                        .replacingOccurrences(of: " on ", with: " ")
                        .replacingOccurrences(of: " from ", with: " ")
                        .components(separatedBy: " ")
                        .first ?? "Event"
                    return (title.capitalized, .personal)
                }
            }
        }
        
        return ("Event", .personal)
    }
    
    private func extractTemporalInfo(from text: String) -> (startTime: Date?, endTime: Date?) {
        let baseDate = extractSingleDate(from: text) ?? Date()
        let calendar = Calendar.current
        
        // Extract times using regex
        let timePattern = "(\\d{1,2})(?::(\\d{2}))?(\\s*)(am|pm|AM|PM)?"
        let regex = try! NSRegularExpression(pattern: timePattern, options: [])
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        var times: [Date] = []
        
        // Special time keywords
        if text.contains("noon") {
            var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
            components.hour = 12
            components.minute = 0
            if let date = calendar.date(from: components) {
                times.append(date)
            }
        }
        
        if text.contains("midnight") {
            var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
            components.hour = 0
            components.minute = 0
            if let date = calendar.date(from: components) {
                times.append(date)
            }
        }
        
        // Parse numeric times
        for match in matches {
            if let hourRange = Range(match.range(at: 1), in: text),
               let hour = Int(text[hourRange]) {
                
                let minute: Int
                if let minuteRange = Range(match.range(at: 2), in: text) {
                    minute = Int(text[minuteRange]) ?? 0
                } else {
                    minute = 0
                }
                
                var adjustedHour = hour
                
                // Handle AM/PM
                if let ampmRange = Range(match.range(at: 4), in: text) {
                    let ampm = text[ampmRange].lowercased()
                    if ampm == "pm" && hour < 12 {
                        adjustedHour = hour + 12
                    } else if ampm == "am" && hour == 12 {
                        adjustedHour = 0
                    }
                } else {
                    // Guess AM/PM based on context
                    if hour <= 7 {
                        // 1-7 without AM/PM is likely PM
                        adjustedHour = hour + 12
                    }
                }
                
                var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
                components.hour = adjustedHour
                components.minute = minute
                
                if let date = calendar.date(from: components) {
                    times.append(date)
                }
            }
        }
        
        // Handle "from X to Y" pattern
        if text.contains(" to ") || text.contains("-") {
            if times.count >= 2 {
                return (times[0], times[1])
            }
        }
        
        // Handle duration
        if times.count == 1 {
            let startTime = times[0]
            var endTime: Date?
            
            // Look for duration
            if let duration = extractDuration(from: text) {
                endTime = startTime.addingTimeInterval(TimeInterval(duration * 60))
            } else {
                // Default durations
                if text.contains("meeting") {
                    endTime = startTime.addingTimeInterval(3600) // 1 hour
                } else if text.contains("appointment") {
                    endTime = startTime.addingTimeInterval(1800) // 30 min
                } else if text.contains("gym") || text.contains("workout") {
                    endTime = startTime.addingTimeInterval(3600) // 1 hour
                } else if text.contains("lunch") {
                    endTime = startTime.addingTimeInterval(3600) // 1 hour
                } else if text.contains("dinner") {
                    endTime = startTime.addingTimeInterval(5400) // 1.5 hours
                }
            }
            
            return (startTime, endTime)
        }
        
        return (nil, nil)
    }
    
    private func extractSingleDate(from text: String) -> Date? {
        let calendar = Calendar.current
        let today = Date()
        
        // Today
        if text.contains("today") {
            return today
        }
        
        // Tomorrow
        if text.contains("tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: today)
        }
        
        // Day after tomorrow
        if text.contains("day after tomorrow") {
            return calendar.date(byAdding: .day, value: 2, to: today)
        }
        
        // Weekday names
        let weekdays = [
            "sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4,
            "thursday": 5, "friday": 6, "saturday": 7
        ]
        
        for (dayName, weekdayNumber) in weekdays {
            if text.contains(dayName) && !text.contains("every") {
                let todayWeekday = calendar.component(.weekday, from: today)
                var daysToAdd = weekdayNumber - todayWeekday
                
                // If it's "next [day]", add 7 days
                if text.contains("next \(dayName)") {
                    daysToAdd += 7
                } else if daysToAdd <= 0 {
                    // If the day already passed this week, assume next week
                    daysToAdd += 7
                }
                
                return calendar.date(byAdding: .day, value: daysToAdd, to: today)
            }
        }
        
        // Month and day patterns (June 4th, June 4, etc.)
        let months = [
            "january": 1, "february": 2, "march": 3, "april": 4,
            "may": 5, "june": 6, "july": 7, "august": 8,
            "september": 9, "october": 10, "november": 11, "december": 12
        ]
        
        for (monthName, monthNumber) in months {
            if let range = text.range(of: monthName) {
                let afterMonth = String(text[range.upperBound...])
                // Extract day number
                let dayPattern = "(\\d{1,2})"
                if let dayRegex = try? NSRegularExpression(pattern: dayPattern),
                   let dayMatch = dayRegex.firstMatch(in: afterMonth, range: NSRange(afterMonth.startIndex..., in: afterMonth)),
                   let dayRange = Range(dayMatch.range(at: 1), in: afterMonth),
                   let day = Int(afterMonth[dayRange]) {
                    
                    var components = DateComponents()
                    components.year = calendar.component(.year, from: today)
                    components.month = monthNumber
                    components.day = day
                    
                    if let date = calendar.date(from: components) {
                        // If the date is in the past, assume next year
                        if date < today {
                            components.year! += 1
                            return calendar.date(from: components)
                        }
                        return date
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractDuration(from text: String) -> Int? {
        // Hours
        let hourPattern = "(\\d+(?:\\.\\d+)?)\\s*(?:hours?|hrs?)"
        if let regex = try? NSRegularExpression(pattern: hourPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text),
           let hours = Double(text[range]) {
            return Int(hours * 60)
        }
        
        // Minutes
        let minPattern = "(\\d+)\\s*(?:minutes?|mins?)"
        if let regex = try? NSRegularExpression(pattern: minPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text),
           let minutes = Int(text[range]) {
            return minutes
        }
        
        return nil
    }
    
    private func extractRecurrence(from text: String) -> (Bool, [Int]) {
        var days: [Int] = []
        
        // Every day
        if text.contains("every day") || text.contains("everyday") {
            return (true, [0, 1, 2, 3, 4, 5, 6])
        }
        
        // Weekdays
        if text.contains("weekday") || text.contains("weekdays") {
            return (true, [1, 2, 3, 4, 5])
        }
        
        // Weekends
        if text.contains("weekend") || text.contains("weekends") {
            return (true, [0, 6])
        }
        
        // Specific days with "every"
        if text.contains("every") {
            let weekdayMap = [
                "sunday": 0, "monday": 1, "tuesday": 2, "wednesday": 3,
                "thursday": 4, "friday": 5, "saturday": 6
            ]
            
            for (day, index) in weekdayMap {
                if text.contains(day) {
                    days.append(index)
                }
            }
            
            if !days.isEmpty {
                return (true, days)
            }
        }
        
        return (false, [])
    }
}