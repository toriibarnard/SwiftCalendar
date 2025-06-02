//
//  SmartScheduleOptimizer.swift
//  SwiftCalendar
//
//  Core schedule optimization engine - Ty's primary purpose
//

import Foundation

class SmartScheduleOptimizer {
    
    struct TimeSlot {
        let startTime: Date
        let endTime: Date
        let score: Double // 0-1, higher is better
        let reasoning: String
    }
    
    struct FlexibleTask {
        let title: String
        let duration: Int // minutes
        let category: EventCategory
        let preferredTimes: [TimePreference]?
        let deadline: Date?
        let frequency: TaskFrequency?
    }
    
    enum TimePreference {
        case morning(before: Int) // before 9am
        case afternoon(range: ClosedRange<Int>) // 12pm-5pm
        case evening(after: Int) // after 6pm
        case anyTime
    }
    
    enum TaskFrequency {
        case daily
        case weekly(times: Int) // e.g., 3 times per week
        case specific(days: [Int]) // specific weekdays
    }
    
    // MARK: - Core Optimization Function
    
    func findOptimalTimes(
        for task: FlexibleTask,
        in dateRange: DateInterval,
        avoiding fixedEvents: [ScheduleEvent],
        considering userPreferences: UserSchedulePreferences
    ) -> [TimeSlot] {
        
        print("🎯 Finding optimal times for: \(task.title)")
        print("📅 Date range: \(dateRange.start) to \(dateRange.end)")
        print("🚫 Avoiding \(fixedEvents.count) fixed events")
        
        let calendar = Calendar.current
        var candidateSlots: [TimeSlot] = []
        
        // Generate all possible time windows
        var currentDate = dateRange.start
        while currentDate < dateRange.end {
            let dailySlots = generateDailyTimeSlots(
                for: currentDate,
                duration: task.duration,
                avoiding: fixedEvents,
                preferences: userPreferences
            )
            candidateSlots.append(contentsOf: dailySlots)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Score each slot based on multiple factors
        let scoredSlots = candidateSlots.map { slot in
            let score = calculateSlotScore(
                slot: slot,
                for: task,
                preferences: userPreferences,
                fixedEvents: fixedEvents
            )
            return TimeSlot(
                startTime: slot.startTime,
                endTime: slot.endTime,
                score: score,
                reasoning: generateReasoning(for: slot, score: score, task: task)
            )
        }
        
        // Return top 4 suggestions, sorted by score
        let topSlots = scoredSlots
            .sorted { $0.score > $1.score }
            .prefix(4)
        
        print("✅ Found \(topSlots.count) optimal time slots")
        return Array(topSlots)
    }
    
    // MARK: - Time Slot Generation
    
    private func generateDailyTimeSlots(
        for date: Date,
        duration: Int,
        avoiding fixedEvents: [ScheduleEvent],
        preferences: UserSchedulePreferences
    ) -> [TimeSlot] {
        
        let calendar = Calendar.current
        var slots: [TimeSlot] = []
        
        // Get day's fixed events
        let dayFixedEvents = fixedEvents.filter { event in
            calendar.isDate(event.startTime, inSameDayAs: date)
        }.sorted { $0.startTime < $1.startTime }
        
        // Generate hourly candidates from 6 AM to 11 PM
        for hour in 6...23 {
            guard let candidateStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) else {
                continue
            }
            
            let candidateEnd = candidateStart.addingTimeInterval(TimeInterval(duration * 60))
            
            // Skip if this would go past midnight
            if !calendar.isDate(candidateEnd, inSameDayAs: date) {
                continue
            }
            
            // Check for conflicts with fixed events
            let hasConflict = dayFixedEvents.contains { fixedEvent in
                let fixedStart = fixedEvent.startTime
                let fixedEnd = fixedEvent.startTime.addingTimeInterval(TimeInterval(fixedEvent.duration * 60))
                
                // Check if time ranges overlap
                return (candidateStart < fixedEnd && candidateEnd > fixedStart)
            }
            
            if !hasConflict {
                slots.append(TimeSlot(
                    startTime: candidateStart,
                    endTime: candidateEnd,
                    score: 0.0, // Will be calculated later
                    reasoning: ""
                ))
            }
        }
        
        return slots
    }
    
    // MARK: - Scoring Algorithm
    
    private func calculateSlotScore(
        slot: TimeSlot,
        for task: FlexibleTask,
        preferences: UserSchedulePreferences,
        fixedEvents: [ScheduleEvent]
    ) -> Double {
        
        var score = 0.5 // Base score
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: slot.startTime)
        
        // 1. Time preference scoring (30% weight)
        if let taskPreferences = task.preferredTimes {
            for preference in taskPreferences {
                switch preference {
                case .morning(let beforeHour):
                    if hour < beforeHour {
                        score += 0.3
                    }
                case .afternoon(let range):
                    if range.contains(hour) {
                        score += 0.3
                    }
                case .evening(let afterHour):
                    if hour >= afterHour {
                        score += 0.3
                    }
                case .anyTime:
                    score += 0.1
                }
            }
        }
        
        // 2. User historical preference scoring (25% weight)
        score += calculateUserPreferenceScore(hour: hour, category: task.category, preferences: preferences) * 0.25
        
        // 3. Buffer time scoring (20% weight) - prefer slots with breathing room
        let bufferScore = calculateBufferScore(slot: slot, fixedEvents: fixedEvents)
        score += bufferScore * 0.20
        
        // 4. Energy level scoring (15% weight) - avoid late nights for physical tasks
        if task.category == .fitness {
            if hour >= 6 && hour <= 8 { // Early morning energy
                score += 0.15
            } else if hour >= 17 && hour <= 19 { // Evening energy
                score += 0.12
            } else if hour >= 22 { // Too late
                score -= 0.10
            }
        }
        
        // 5. Day of week preference (10% weight)
        let weekday = calendar.component(.weekday, from: slot.startTime)
        if task.category == .fitness && (weekday == 2 || weekday == 4 || weekday == 6) { // Mon, Wed, Fri
            score += 0.10
        }
        
        return max(0.0, min(1.0, score)) // Clamp between 0 and 1
    }
    
    private func calculateUserPreferenceScore(hour: Int, category: EventCategory, preferences: UserSchedulePreferences) -> Double {
        // Look at user's historical scheduling for this category
        guard let categoryPrefs = preferences.categoryPreferences[category] else {
            return 0.5 // Neutral if no data
        }
        
        // Check if this hour aligns with user's typical scheduling
        if categoryPrefs.preferredHours.contains(hour) {
            return 1.0
        } else if categoryPrefs.avoidedHours.contains(hour) {
            return 0.0
        }
        
        return 0.5
    }
    
    private func calculateBufferScore(slot: TimeSlot, fixedEvents: [ScheduleEvent]) -> Double {
        let calendar = Calendar.current
        
        // Find closest events before and after this slot
        let dayEvents = fixedEvents.filter { event in
            calendar.isDate(event.startTime, inSameDayAs: slot.startTime)
        }
        
        var bufferScore = 1.0
        
        for event in dayEvents {
            let eventStart = event.startTime
            let eventEnd = event.startTime.addingTimeInterval(TimeInterval(event.duration * 60))
            
            // Check buffer before slot
            if eventEnd <= slot.startTime {
                let bufferMinutes = slot.startTime.timeIntervalSince(eventEnd) / 60
                if bufferMinutes < 30 { // Less than 30 min buffer
                    bufferScore -= 0.3
                } else if bufferMinutes < 60 { // Less than 1 hour buffer
                    bufferScore -= 0.1
                }
            }
            
            // Check buffer after slot
            if eventStart >= slot.endTime {
                let bufferMinutes = eventStart.timeIntervalSince(slot.endTime) / 60
                if bufferMinutes < 30 {
                    bufferScore -= 0.3
                } else if bufferMinutes < 60 {
                    bufferScore -= 0.1
                }
            }
        }
        
        return max(0.0, bufferScore)
    }
    
    // MARK: - Reasoning Generation
    
    private func generateReasoning(for slot: TimeSlot, score: Double, task: FlexibleTask) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "EEEE h:mm a"
        let timeString = timeFormatter.string(from: slot.startTime)
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: slot.startTime)
        
        var reasons: [String] = []
        
        // Time of day reasoning
        switch hour {
        case 6...8:
            reasons.append("Early morning - high energy and fewer distractions")
        case 12...14:
            reasons.append("Lunch time - good break from work")
        case 17...19:
            reasons.append("Evening - natural end to work day")
        case 20...22:
            reasons.append("Evening - wind down time")
        default:
            break
        }
        
        // Category-specific reasoning
        if task.category == .fitness {
            if hour >= 6 && hour <= 8 {
                reasons.append("Ideal for morning workouts")
            } else if hour >= 17 && hour <= 19 {
                reasons.append("Perfect for after-work exercise")
            }
        }
        
        // Score-based reasoning
        if score >= 0.8 {
            reasons.append("Excellent fit for your schedule")
        } else if score >= 0.6 {
            reasons.append("Good option with no conflicts")
        } else {
            reasons.append("Available but not ideal timing")
        }
        
        let reasonString = reasons.joined(separator: ", ")
        return "At \(timeString): \(reasonString)"
    }
}

// MARK: - User Preferences Storage

struct UserSchedulePreferences: Codable {
    var categoryPreferences: [EventCategory: CategoryPreference]
    var generalPreferences: GeneralPreferences
    
    init() {
        self.categoryPreferences = [:]
        self.generalPreferences = GeneralPreferences()
    }
}

struct CategoryPreference: Codable {
    var preferredHours: Set<Int> // Hours user typically schedules this category
    var avoidedHours: Set<Int>   // Hours user avoids for this category
    var averageDuration: Int     // Typical duration for this category
    
    init() {
        self.preferredHours = []
        self.avoidedHours = []
        self.averageDuration = 60
    }
}

struct GeneralPreferences: Codable {
    var workingHoursStart: Int // 9 for 9am
    var workingHoursEnd: Int   // 17 for 5pm
    var sleepTime: Int         // 23 for 11pm
    var wakeTime: Int          // 7 for 7am
    var bufferPreference: Int  // Preferred minutes between events
    
    init() {
        self.workingHoursStart = 9
        self.workingHoursEnd = 17
        self.sleepTime = 23
        self.wakeTime = 7
        self.bufferPreference = 30
    }
}
