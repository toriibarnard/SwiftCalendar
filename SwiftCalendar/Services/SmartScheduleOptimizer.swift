//
//  SmartScheduleOptimizer.swift
//  SwiftCalendar
//
//  FIXED VERSION: Core schedule optimization engine - Ty's primary purpose
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
        var allCandidateSlots: [TimeSlot] = []
        
        // Generate all possible time windows for each day
        var currentDate = dateRange.start
        while currentDate < dateRange.end {
            let dailySlots = generateDailyTimeSlots(
                for: currentDate,
                duration: task.duration,
                avoiding: fixedEvents,
                preferences: userPreferences,
                task: task
            )
            allCandidateSlots.append(contentsOf: dailySlots)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        print("🔍 Generated \(allCandidateSlots.count) candidate slots across all days")
        
        // Score each slot
        let scoredSlots = allCandidateSlots.map { slot in
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
        
        // FIXED: Ensure diversity across days - don't return all suggestions from same day
        let diverseSlots = selectDiverseTopSlots(from: scoredSlots, maxCount: 4)
        
        print("✅ Found \(diverseSlots.count) optimal time slots")
        for (index, slot) in diverseSlots.enumerated() {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE h:mm a"
            print("  \(index + 1). \(formatter.string(from: slot.startTime)) (score: \(String(format: "%.2f", slot.score)))")
        }
        
        return diverseSlots
    }
    
    // MARK: - FIXED: Diverse Slot Selection
    
    private func selectDiverseTopSlots(from slots: [TimeSlot], maxCount: Int) -> [TimeSlot] {
        let calendar = Calendar.current
        var selectedSlots: [TimeSlot] = []
        var usedDays: Set<Int> = [] // Track which days we've already used
        
        // Sort all slots by score (best first)
        let sortedSlots = slots.sorted { $0.score > $1.score }
        
        // First pass: Take the best slot from each unique day
        for slot in sortedSlots {
            guard selectedSlots.count < maxCount else { break }
            
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: slot.startTime) ?? 0
            
            if !usedDays.contains(dayOfYear) {
                selectedSlots.append(slot)
                usedDays.insert(dayOfYear)
                print("📅 Selected diverse slot: \(calendar.weekdaySymbols[calendar.component(.weekday, from: slot.startTime) - 1])")
            }
        }
        
        // Second pass: If we still need more slots and have exhausted unique days,
        // add the best remaining slots even if they're on used days
        if selectedSlots.count < maxCount {
            for slot in sortedSlots {
                guard selectedSlots.count < maxCount else { break }
                
                if !selectedSlots.contains(where: { $0.startTime == slot.startTime }) {
                    selectedSlots.append(slot)
                }
            }
        }
        
        // Sort final selection by start time for logical presentation
        return selectedSlots.sorted { $0.startTime < $1.startTime }
    }
    
    // MARK: - FIXED: Time Slot Generation
    
    private func generateDailyTimeSlots(
        for date: Date,
        duration: Int,
        avoiding fixedEvents: [ScheduleEvent],
        preferences: UserSchedulePreferences,
        task: FlexibleTask
    ) -> [TimeSlot] {
        
        let calendar = Calendar.current
        var slots: [TimeSlot] = []
        
        // Get day's fixed events
        let dayFixedEvents = fixedEvents.filter { event in
            calendar.isDate(event.startTime, inSameDayAs: date)
        }.sorted { $0.startTime < $1.startTime }
        
        // FIXED: Generate better time candidates based on task type and preferences
        let timeSlots = generateSmartTimeSlots(for: date, task: task, preferences: preferences)
        
        for candidateStart in timeSlots {
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
    
    // MARK: - FIXED: Smart Time Slot Generation
    
    private func generateSmartTimeSlots(for date: Date, task: FlexibleTask, preferences: UserSchedulePreferences) -> [Date] {
        let calendar = Calendar.current
        var timeSlots: [Date] = []
        
        // Generate time slots based on task category and user preferences
        switch task.category {
        case .fitness:
            // Fitness: Good times are early morning (6-8 AM), lunch (12-1 PM), after work (4:30-7 PM)
            timeSlots.append(contentsOf: generateTimesForHours([6, 7, 12, 16, 17, 18, 19], on: date))
            
        case .work:
            // Work: Standard business hours
            timeSlots.append(contentsOf: generateTimesForHours(Array(9...17), on: date))
            
        case .personal:
            // Personal: Flexible, avoid early morning and late night
            timeSlots.append(contentsOf: generateTimesForHours([9, 10, 11, 14, 15, 16, 17, 18, 19, 20], on: date))
            
        case .study:
            // Study: Morning focus time and evening review
            timeSlots.append(contentsOf: generateTimesForHours([8, 9, 10, 14, 15, 16, 19, 20], on: date))
            
        case .health:
            // Health: Business hours typically
            timeSlots.append(contentsOf: generateTimesForHours([9, 10, 11, 13, 14, 15, 16], on: date))
            
        case .social:
            // Social: Evenings and weekends
            timeSlots.append(contentsOf: generateTimesForHours([17, 18, 19, 20, 21], on: date))
            
        case .other:
            // Other: General availability
            timeSlots.append(contentsOf: generateTimesForHours(Array(8...20), on: date))
        }
        
        return timeSlots.sorted()
    }
    
    private func generateTimesForHours(_ hours: [Int], on date: Date) -> [Date] {
        let calendar = Calendar.current
        return hours.compactMap { hour in
            calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)
        }
    }
    
    // MARK: - FIXED: Scoring Algorithm
    
    private func calculateSlotScore(
        slot: TimeSlot,
        for task: FlexibleTask,
        preferences: UserSchedulePreferences,
        fixedEvents: [ScheduleEvent]
    ) -> Double {
        
        var score = 0.5 // Base score
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: slot.startTime)
        let weekday = calendar.component(.weekday, from: slot.startTime)
        
        // 1. FIXED: Time preference scoring (40% weight)
        if let taskPreferences = task.preferredTimes {
            for preference in taskPreferences {
                switch preference {
                case .morning(let beforeHour):
                    if hour < beforeHour {
                        score += 0.4
                    }
                case .afternoon(let range):
                    if range.contains(hour) {
                        score += 0.4
                    }
                case .evening(let afterHour):
                    if hour >= afterHour {
                        score += 0.4
                    }
                case .anyTime:
                    score += 0.2
                }
            }
        }
        
        // 2. FIXED: Category-specific optimal times (30% weight)
        let categoryScore = calculateCategoryOptimalTime(hour: hour, category: task.category, weekday: weekday)
        score += categoryScore * 0.30
        
        // 3. Buffer time scoring (20% weight) - prefer slots with breathing room
        let bufferScore = calculateBufferScore(slot: slot, fixedEvents: fixedEvents)
        score += bufferScore * 0.20
        
        // 4. FIXED: Time diversity bonus (10% weight) - encourage different times of day
        let diversityScore = calculateTimeOfDayScore(hour: hour)
        score += diversityScore * 0.10
        
        return max(0.0, min(1.0, score)) // Clamp between 0 and 1
    }
    
    // MARK: - FIXED: Category-Specific Scoring
    
    private func calculateCategoryOptimalTime(hour: Int, category: EventCategory, weekday: Int) -> Double {
        switch category {
        case .fitness:
            // Optimal: 6-8 AM (0.9), 12-1 PM (0.7), 4:30-7 PM (0.8)
            if hour >= 6 && hour <= 8 { return 0.9 }
            if hour == 12 { return 0.7 }
            if hour >= 16 && hour <= 19 { return 0.8 }
            if hour >= 9 && hour <= 11 { return 0.5 } // Okay
            return 0.2 // Poor times (early morning or late night)
            
        case .work:
            // Standard business hours
            if hour >= 9 && hour <= 17 { return 1.0 }
            if hour >= 8 && hour <= 18 { return 0.7 }
            return 0.3
            
        case .personal:
            // Flexible, avoid very early/late
            if hour >= 10 && hour <= 20 { return 0.8 }
            if hour >= 8 && hour <= 21 { return 0.6 }
            return 0.3
            
        case .study:
            // Morning focus and evening review
            if hour >= 8 && hour <= 11 { return 0.9 } // Morning focus
            if hour >= 19 && hour <= 21 { return 0.8 } // Evening review
            if hour >= 14 && hour <= 17 { return 0.6 } // Afternoon okay
            return 0.4
            
        case .health:
            // Business hours
            if hour >= 9 && hour <= 16 { return 0.9 }
            if hour >= 8 && hour <= 17 { return 0.7 }
            return 0.3
            
        case .social:
            // Evenings and weekends
            if weekday == 1 || weekday == 7 { // Weekend
                if hour >= 10 && hour <= 22 { return 0.9 }
            } else { // Weekday
                if hour >= 17 && hour <= 22 { return 0.8 }
                if hour >= 12 && hour <= 16 { return 0.6 } // Lunch/afternoon
            }
            return 0.4
            
        case .other:
            // General preference for reasonable hours
            if hour >= 9 && hour <= 18 { return 0.7 }
            if hour >= 7 && hour <= 21 { return 0.5 }
            return 0.3
        }
    }
    
    private func calculateTimeOfDayScore(hour: Int) -> Double {
        // Encourage variety in time suggestions
        switch hour {
        case 6...8: return 0.8 // Early morning
        case 9...11: return 0.9 // Mid morning
        case 12...13: return 0.7 // Lunch
        case 14...16: return 0.9 // Afternoon
        case 17...19: return 0.8 // Early evening
        case 20...21: return 0.6 // Evening
        default: return 0.4 // Very early or late
        }
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
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: slot.startTime)
        
        var reasons: [String] = []
        
        // Time of day reasoning
        switch hour {
        case 6...8:
            reasons.append("Early morning energy and focus")
        case 9...11:
            reasons.append("Prime morning productivity hours")
        case 12...13:
            reasons.append("Midday break opportunity")
        case 14...16:
            reasons.append("Post-lunch active period")
        case 17...19:
            reasons.append("After-work wind-down time")
        case 20...21:
            reasons.append("Evening availability")
        default:
            reasons.append("Available time slot")
        }
        
        // Category-specific reasoning
        if task.category == .fitness {
            if hour >= 6 && hour <= 8 {
                reasons.append("Ideal for morning workouts")
            } else if hour >= 16 && hour <= 19 {
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
        
        return reasons.joined(separator: ", ")
    }
}

// MARK: - User Preferences Storage (keeping existing)

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
