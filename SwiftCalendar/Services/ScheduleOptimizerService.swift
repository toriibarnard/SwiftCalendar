//
//  ScheduleOptimizerService.swift
//  SwiftCalendar
//
//  FIXED: Service for generating intelligent time slot suggestions (standalone)
//

import Foundation

class ScheduleOptimizerService {
    
    // MARK: - Public API
    
    func generateOptimalSuggestions(
        for task: FlexibleTask,
        existingEvents: [ScheduleEvent],
        userPreferences: UserSchedulePreferences
    ) -> [TimeSlotSuggestion] {
        
        print("🎯 Generating optimal suggestions for: \(task.title)")
        print("📊 Duration: \(task.duration) minutes")
        print("📅 Existing events: \(existingEvents.count)")
        
        // Create time window for suggestions (next 7 days)
        let now = Date()
        let weekStart = Calendar.current.startOfDay(for: now)
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart)!
        
        // Generate candidate time slots
        let candidates = generateCandidateSlots(
            for: task,
            in: weekStart..<weekEnd,
            avoiding: existingEvents,
            preferences: userPreferences
        )
        
        print("🔍 Generated \(candidates.count) candidate slots")
        
        // Score and rank candidates
        let scoredSuggestions = candidates.map { candidate in
            let score = calculateOptimalityScore(
                candidate: candidate,
                task: task,
                existingEvents: existingEvents,
                preferences: userPreferences
            )
            
            return TimeSlotSuggestion(
                startTime: candidate.startTime,
                endTime: candidate.endTime,
                score: score,
                reasoning: generateReasoning(for: candidate, task: task, score: score),
                category: task.category
            )
        }
        
        // Sort by score and return requested number
        let sortedSuggestions = scoredSuggestions
            .sorted { $0.score > $1.score }
            .prefix(task.count)
        
        // Ensure diversity across days
        let diverseSuggestions = selectDiverseSuggestions(from: Array(sortedSuggestions))
        
        print("✅ Returning \(diverseSuggestions.count) optimal suggestions")
        return diverseSuggestions
    }
    
    // MARK: - Candidate Generation
    
    private func generateCandidateSlots(
        for task: FlexibleTask,
        in timeRange: Range<Date>,
        avoiding existingEvents: [ScheduleEvent],
        preferences: UserSchedulePreferences
    ) -> [CandidateSlot] {
        
        var candidates: [CandidateSlot] = []
        let calendar = Calendar.current
        
        // Generate slots for each day in the range
        var currentDate = timeRange.lowerBound
        while currentDate < timeRange.upperBound {
            let daySlots = generateDailySlots(
                for: task,
                on: currentDate,
                avoiding: existingEvents,
                preferences: preferences
            )
            candidates.append(contentsOf: daySlots)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return candidates
    }
    
    private func generateDailySlots(
        for task: FlexibleTask,
        on date: Date,
        avoiding existingEvents: [ScheduleEvent],
        preferences: UserSchedulePreferences
    ) -> [CandidateSlot] {
        
        let calendar = Calendar.current
        var slots: [CandidateSlot] = []
        
        // Get day's existing events
        let dayEvents = existingEvents.filter { event in
            calendar.isDate(event.startTime, inSameDayAs: date)
        }.sorted { $0.startTime < $1.startTime }
        
        // Generate time slots based on task category and preferences
        let candidateTimes = generateOptimalTimesForCategory(
            task.category,
            on: date,
            preferences: preferences
        )
        
        // Check each candidate time for conflicts
        for candidateTime in candidateTimes {
            let endTime = candidateTime.addingTimeInterval(TimeInterval(task.duration * 60))
            
            // Skip if goes past end of day
            if !calendar.isDate(endTime, inSameDayAs: date) {
                continue
            }
            
            // Check for conflicts with existing events
            let hasConflict = dayEvents.contains { existingEvent in
                let eventStart = existingEvent.startTime
                let eventEnd = existingEvent.startTime.addingTimeInterval(TimeInterval(existingEvent.duration * 60))
                
                // Check if time ranges overlap
                return (candidateTime < eventEnd && endTime > eventStart)
            }
            
            if !hasConflict {
                slots.append(CandidateSlot(
                    startTime: candidateTime,
                    endTime: endTime,
                    category: task.category
                ))
            }
        }
        
        return slots
    }
    
    private func generateOptimalTimesForCategory(
        _ category: FlexibleTask.TaskCategory,
        on date: Date,
        preferences: UserSchedulePreferences
    ) -> [Date] {
        
        let calendar = Calendar.current
        var optimalTimes: [Date] = []
        
        // Generate times based on category
        let timeSlots: [Int] = {
            switch category {
            case .fitness:
                return [6, 7, 8, 12, 13, 17, 18, 19] // Early morning, lunch, after work
            case .work:
                return Array(preferences.workingHours.start...preferences.workingHours.end)
            case .study:
                return [8, 9, 10, 11, 14, 15, 19, 20] // Morning focus, afternoon, evening
            case .social:
                return [12, 13, 17, 18, 19, 20, 21] // Lunch, evening, night
            case .health:
                return Array(9...16) // Business hours for appointments
            case .personal:
                return Array(8...20) // Flexible throughout day
            case .other:
                return Array(8...20) // Flexible throughout day
            }
        }()
        
        // Convert hours to actual Date objects
        for hour in timeSlots {
            // Add some minute variations (0, 15, 30, 45) for more options
            for minute in [0, 15, 30, 45] {
                if let timeSlot = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) {
                    optimalTimes.append(timeSlot)
                }
            }
        }
        
        return optimalTimes
    }
    
    // MARK: - Scoring System
    
    private func calculateOptimalityScore(
        candidate: CandidateSlot,
        task: FlexibleTask,
        existingEvents: [ScheduleEvent],
        preferences: UserSchedulePreferences
    ) -> Double {
        
        var score: Double = 0.5 // Base score
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: candidate.startTime)
        let weekday = calendar.component(.weekday, from: candidate.startTime)
        
        // 1. Category optimal time scoring (40% weight)
        let categoryScore = calculateCategoryScore(hour: hour, category: task.category, weekday: weekday)
        score += categoryScore * 0.4
        
        // 2. User preference scoring (25% weight)
        let preferenceScore = calculatePreferenceScore(
            hour: hour,
            task: task,
            preferences: preferences
        )
        score += preferenceScore * 0.25
        
        // 3. Buffer time scoring (20% weight)
        let bufferScore = calculateBufferScore(
            candidate: candidate,
            existingEvents: existingEvents,
            preferences: preferences
        )
        score += bufferScore * 0.2
        
        // 4. Energy level scoring (10% weight)
        let energyScore = calculateEnergyScore(hour: hour, category: task.category)
        score += energyScore * 0.1
        
        // 5. Day diversity bonus (5% weight)
        let diversityScore = calculateDiversityScore(hour: hour)
        score += diversityScore * 0.05
        
        return max(0.0, min(1.0, score)) // Clamp between 0 and 1
    }
    
    private func calculateCategoryScore(hour: Int, category: FlexibleTask.TaskCategory, weekday: Int) -> Double {
        switch category {
        case .fitness:
            // Optimal: 6-8 AM (0.9), 12-1 PM (0.7), 5-7 PM (0.8)
            if hour >= 6 && hour <= 8 { return 0.9 }
            if hour >= 12 && hour <= 13 { return 0.7 }
            if hour >= 17 && hour <= 19 { return 0.8 }
            if hour >= 9 && hour <= 11 { return 0.5 }
            return 0.3
            
        case .work:
            // Standard business hours
            if hour >= 9 && hour <= 17 { return 1.0 }
            if hour >= 8 && hour <= 18 { return 0.7 }
            return 0.3
            
        case .study:
            // Morning focus and evening review
            if hour >= 8 && hour <= 11 { return 0.9 } // Morning focus
            if hour >= 19 && hour <= 21 { return 0.8 } // Evening review
            if hour >= 14 && hour <= 17 { return 0.6 } // Afternoon okay
            return 0.4
            
        case .social:
            // Evenings and weekends
            if weekday == 1 || weekday == 7 { // Weekend
                if hour >= 10 && hour <= 22 { return 0.9 }
            } else { // Weekday
                if hour >= 17 && hour <= 22 { return 0.8 }
                if hour >= 12 && hour <= 16 { return 0.6 } // Lunch/afternoon
            }
            return 0.4
            
        case .health:
            // Business hours for appointments
            if hour >= 9 && hour <= 16 { return 0.9 }
            if hour >= 8 && hour <= 17 { return 0.7 }
            return 0.3
            
        case .personal, .other:
            // General preference for reasonable hours
            if hour >= 9 && hour <= 18 { return 0.7 }
            if hour >= 7 && hour <= 21 { return 0.5 }
            return 0.3
        }
    }
    
    private func calculatePreferenceScore(
        hour: Int,
        task: FlexibleTask,
        preferences: UserSchedulePreferences
    ) -> Double {
        
        // Check if this category has specific time preferences
        if let timePreference = preferences.timePreferences[task.category] {
            switch timePreference {
            case .morning:
                return hour <= 12 ? 1.0 : 0.3
            case .afternoon:
                return (hour >= 12 && hour <= 17) ? 1.0 : 0.3
            case .evening:
                return hour >= 17 ? 1.0 : 0.3
            case .any:
                return 0.7
            }
        }
        
        // Default to working hours preference
        if hour >= preferences.workingHours.start && hour <= preferences.workingHours.end {
            return 0.8
        }
        
        return 0.6
    }
    
    private func calculateBufferScore(
        candidate: CandidateSlot,
        existingEvents: [ScheduleEvent],
        preferences: UserSchedulePreferences
    ) -> Double {
        
        let calendar = Calendar.current
        let bufferMinutes = preferences.bufferTime
        
        // Find events on the same day
        let dayEvents = existingEvents.filter { event in
            calendar.isDate(event.startTime, inSameDayAs: candidate.startTime)
        }
        
        var bufferScore = 1.0
        
        for event in dayEvents {
            let eventStart = event.startTime
            let eventEnd = event.startTime.addingTimeInterval(TimeInterval(event.duration * 60))
            
            // Check buffer before candidate
            if eventEnd <= candidate.startTime {
                let actualBuffer = candidate.startTime.timeIntervalSince(eventEnd) / 60
                if actualBuffer < Double(bufferMinutes) {
                    bufferScore -= 0.3
                }
            }
            
            // Check buffer after candidate
            if eventStart >= candidate.endTime {
                let actualBuffer = eventStart.timeIntervalSince(candidate.endTime) / 60
                if actualBuffer < Double(bufferMinutes) {
                    bufferScore -= 0.3
                }
            }
        }
        
        return max(0.0, bufferScore)
    }
    
    private func calculateEnergyScore(hour: Int, category: FlexibleTask.TaskCategory) -> Double {
        // Energy levels throughout the day
        switch hour {
        case 6...8: return 0.9 // High morning energy
        case 9...11: return 1.0 // Peak morning
        case 12...13: return 0.6 // Post-lunch dip
        case 14...16: return 0.8 // Afternoon recovery
        case 17...19: return 0.7 // Early evening
        case 20...21: return 0.5 // Evening wind-down
        default: return 0.3 // Very early or late
        }
    }
    
    private func calculateDiversityScore(hour: Int) -> Double {
        // Encourage variety in suggested times
        switch hour {
        case 6...8: return 0.8 // Early morning
        case 9...11: return 0.9 // Mid morning
        case 12...13: return 0.7 // Lunch
        case 14...16: return 0.9 // Afternoon
        case 17...19: return 0.8 // Early evening
        case 20...21: return 0.6 // Evening
        default: return 0.4 // Other times
        }
    }
    
    // MARK: - Suggestion Selection
    
    private func selectDiverseSuggestions(from suggestions: [TimeSlotSuggestion]) -> [TimeSlotSuggestion] {
        let calendar = Calendar.current
        var selectedSuggestions: [TimeSlotSuggestion] = []
        var usedDays: Set<Int> = []
        
        // First pass: Select best suggestion from each unique day
        for suggestion in suggestions {
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: suggestion.startTime) ?? 0
            
            if !usedDays.contains(dayOfYear) && selectedSuggestions.count < 4 {
                selectedSuggestions.append(suggestion)
                usedDays.insert(dayOfYear)
            }
        }
        
        // Second pass: Fill remaining slots if needed
        for suggestion in suggestions {
            if selectedSuggestions.count >= 4 { break }
            
            if !selectedSuggestions.contains(where: { $0.startTime == suggestion.startTime }) {
                selectedSuggestions.append(suggestion)
            }
        }
        
        return selectedSuggestions.sorted { $0.startTime < $1.startTime }
    }
    
    // MARK: - Reasoning Generation
    
    private func generateReasoning(for candidate: CandidateSlot, task: FlexibleTask, score: Double) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: candidate.startTime)
        
        var reasons: [String] = []
        
        // Time of day reasoning
        switch hour {
        case 6...8:
            reasons.append("Early morning energy and focus")
        case 9...11:
            reasons.append("Prime morning productivity hours")
        case 12...13:
            reasons.append("Convenient lunch break timing")
        case 14...16:
            reasons.append("Post-lunch active period")
        case 17...19:
            reasons.append("After-work availability")
        case 20...21:
            reasons.append("Evening relaxation time")
        default:
            reasons.append("Available time slot")
        }
        
        // Category-specific reasoning
        switch task.category {
        case .fitness:
            if hour >= 6 && hour <= 8 {
                reasons.append("Ideal for morning workouts")
            } else if hour >= 17 && hour <= 19 {
                reasons.append("Perfect for after-work exercise")
            }
        case .study:
            if hour >= 8 && hour <= 11 {
                reasons.append("Optimal focus and concentration time")
            }
        case .work:
            if hour >= 9 && hour <= 17 {
                reasons.append("Standard business hours")
            }
        default:
            break
        }
        
        // Score-based reasoning
        if score >= 0.8 {
            reasons.append("Excellent fit for your schedule")
        } else if score >= 0.6 {
            reasons.append("Good option with no conflicts")
        }
        
        return reasons.joined(separator: ", ")
    }
}

// MARK: - Helper Models

private struct CandidateSlot {
    let startTime: Date
    let endTime: Date
    let category: FlexibleTask.TaskCategory
}
