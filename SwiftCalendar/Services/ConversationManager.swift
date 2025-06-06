//
//  ConversationManager.swift
//  SwiftCalendar
//
//  FIXED: Service for managing conversation context and building system prompts
//

import Foundation

class ConversationManager {
    
    // MARK: - Public API
    
    func buildSystemPrompt(
        with events: [ScheduleEvent],
        userPreferences: UserSchedulePreferences
    ) -> String {
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
        let todayString = formatter.string(from: currentDate)
        
        // Build user's schedule context
        let scheduleAnalysis = analyzeUserSchedule(events, relativeTo: currentDate)
        
        return """
        You are Ty, an intelligent AI scheduling assistant built directly into the user's calendar application. Current time: \(todayString)
        
        CORE IDENTITY & CAPABILITIES:
        • You ARE the calendar system itself - not an external tool
        • You have DIRECT, immediate control over all calendar operations
        • You can instantly create, modify, delete, and analyze events
        • You maintain full conversation context and follow through on requests consistently
        • Never suggest external calendar apps - you ARE the calendar
        
        PRIMARY PURPOSE: Schedule Optimization
        When users ask "when should I..." or "best time for..." or mention gym/workout/exercise timing:
        1. Analyze their fixed commitments (work, meetings, appointments)
        2. Consider user preferences, energy levels, buffer times
        3. Suggest 3-4 optimal time slots with clear reasoning unless user specifies otherwise
        4. ALWAYS use the OPTIMIZE_START/OPTIMIZE_END format below - THIS IS CRITICAL
        
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
        
        RESPONSE FORMATS - THESE ARE MANDATORY:
        
        For Schedule Optimization (USE THIS FOR ALL "when should I" or gym/workout questions):
        OPTIMIZE_START
        task: [task name]
        duration: [minutes]
        category: [fitness/work/personal/health/study/social]
        preferences: [morning/afternoon/evening/any]
        count: [number of suggestions, default 3]
        frequency: [daily/weekly/specific/none]
        deadline: [date or none]
        OPTIMIZE_END
        
        EXAMPLE - If user asks "when should I go to the gym this week?":
        OPTIMIZE_START
        task: Gym Session
        duration: 90
        category: fitness
        preferences: any
        count: 3
        frequency: none
        deadline: none
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
        
        CRITICAL RULES:
        1. ALWAYS use OPTIMIZE_START/OPTIMIZE_END for ANY scheduling question
        2. If user mentions gym, workout, exercise, fitness - use category: fitness
        3. If user asks "when should I..." - use OPTIMIZE format, don't just give text advice
        4. Be professional but conversational
        5. Ask clarifying questions only when genuinely unclear
        6. When conflicts exist, always suggest alternatives
        7. Be proactive about adding recurring schedules
        8. Never claim you "can't access" or "can't modify" the calendar
        9. Follow through on conversation logic without confusion
        
        CURRENT USER SCHEDULE:
        \(scheduleAnalysis)
        
        USER PREFERENCES:
        • Working hours: \(userPreferences.workingHours.start):00 to \(userPreferences.workingHours.end):00
        • Morning availability: from \(userPreferences.preferredMorningStart):00
        • Evening cutoff: until \(userPreferences.preferredEveningEnd):00
        • Buffer time preference: \(userPreferences.bufferTime) minutes between events (CRITICAL: Always maintain this buffer)
        
        CRITICAL CONFLICT CHECKING RULES (MANDATORY):
        1. NEVER suggest times that overlap with existing events - even partial overlaps are FORBIDDEN
        2. For longer events (2+ hours), check BOTH start AND end times for conflicts:
           - 3-hour study session at 1pm = 1pm-4pm + 15min buffer = conflicts if ANYTHING exists 12:45pm-4:15pm
        3. Always maintain 15-minute buffers: previous event end + 15min ≤ suggestion start
        4. Check the ⚠️ CRITICAL CONFLICTS list above - NEVER suggest conflicting times
        5. Only suggest times from the AVAILABLE TIME BLOCKS list
        6. If requesting 3+ hours and no blocks are big enough, say: "No available 3-hour blocks found"
        7. DOUBLE-CHECK every suggestion against the conflict warnings before responding
        
        Remember: You have complete calendar control. Maintain conversation context and follow through on requests consistently. ALWAYS use the proper response formats - especially OPTIMIZE_START/OPTIMIZE_END for scheduling questions. Always check for time conflicts with existing events when suggesting optimal times, including END TIME conflicts for longer events.
        """
    }
    
    // MARK: - Schedule Analysis
    
    func analyzeUserSchedule(_ events: [ScheduleEvent], relativeTo date: Date) -> String {
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
        
        // Group events by day
        let groupedEvents = Dictionary(grouping: thisWeekEvents) { event in
            calendar.startOfDay(for: event.startTime)
        }
        
        // Generate day-by-day analysis
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: thisWeekStart) else { continue }
            let dayName = dayFormatter.string(from: day)
            
            if let dayEvents = groupedEvents[day] {
                analysis += "\n\(dayName):\n"
                for event in dayEvents.sorted(by: { $0.startTime < $1.startTime }) {
                    let startTime = timeFormatter.string(from: event.startTime)
                    let endTime = timeFormatter.string(from: event.startTime.addingTimeInterval(TimeInterval(event.duration * 60)))
                    analysis += "  • \(event.title): \(startTime)-\(endTime)\n"
                }
            } else {
                analysis += "\n\(dayName): FREE\n"
            }
        }
        
        // Add EXPLICIT conflict warnings
        analysis += "\n⚠️ CRITICAL CONFLICTS TO AVOID:\n"
        let conflictWarnings = generateConflictWarnings(for: thisWeekEvents, in: thisWeekStart..<thisWeekEnd)
        for warning in conflictWarnings {
            analysis += "- \(warning)\n"
        }
        
        // Add availability summary with time blocks
        analysis += "\nAVAILABLE TIME BLOCKS (conflict-free slots):\n"
        let availableBlocks = calculateAvailableTimeBlocks(for: thisWeekEvents, in: thisWeekStart..<thisWeekEnd)
        for block in availableBlocks {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE h:mm a"
            let startStr = formatter.string(from: block.start)
            let endStr = formatter.string(from: block.end)
            let duration = Int(block.end.timeIntervalSince(block.start) / 60)
            analysis += "- \(startStr) to \(endStr) (\(duration) minutes available)\n"
        }
        
        analysis += "\nSCHEDULE SUMMARY:\n"
        let totalSlots = calculateAvailableSlots(for: thisWeekEvents, in: thisWeekStart..<thisWeekEnd)
        analysis += "- Total available hours this week: \(totalSlots)\n"
        analysis += "- Busiest day: \(findBusiestDay(from: groupedEvents))\n"
        analysis += "- Most open day: \(findMostOpenDay(from: groupedEvents, weekStart: thisWeekStart))\n"
        
        return analysis
    }
    
    // MARK: - Helper Functions
    
    private func generateConflictWarnings(for events: [ScheduleEvent], in range: Range<Date>) -> [String] {
        let calendar = Calendar.current
        var warnings: [String] = []
        
        var currentDate = range.lowerBound
        while currentDate < range.upperBound {
            let dayEvents = events.filter { event in
                calendar.isDate(event.startTime, inSameDayAs: currentDate)
            }.sorted { $0.startTime < $1.startTime }
            
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            let dayName = dayFormatter.string(from: currentDate)
            
            for event in dayEvents {
                let startTime = timeFormatter.string(from: event.startTime)
                let endTime = timeFormatter.string(from: event.startTime.addingTimeInterval(TimeInterval(event.duration * 60)))
                warnings.append("NO EVENTS can be scheduled on \(dayName) from \(startTime) to \(endTime) (conflicts with \(event.title))")
                
                // Add buffer warnings
                let bufferStart = event.startTime.addingTimeInterval(TimeInterval(-15 * 60))
                let bufferEnd = event.startTime.addingTimeInterval(TimeInterval((event.duration + 15) * 60))
                let bufferStartStr = timeFormatter.string(from: bufferStart)
                let bufferEndStr = timeFormatter.string(from: bufferEnd)
                warnings.append("15-min buffers required: avoid \(dayName) \(bufferStartStr) to \(bufferEndStr)")
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return warnings
    }
    
    private func calculateAvailableTimeBlocks(for events: [ScheduleEvent], in range: Range<Date>) -> [(start: Date, end: Date)] {
        let calendar = Calendar.current
        var availableBlocks: [(start: Date, end: Date)] = []
        
        var currentDate = range.lowerBound
        while currentDate < range.upperBound {
            let dayStart = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: currentDate) ?? currentDate
            let dayEnd = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: currentDate) ?? currentDate
            
            let dayEvents = events.filter { event in
                calendar.isDate(event.startTime, inSameDayAs: currentDate)
            }.sorted { $0.startTime < $1.startTime }
            
            if dayEvents.isEmpty {
                // Entire day is free
                availableBlocks.append((start: dayStart, end: dayEnd))
            } else {
                // Check time before first event
                if dayEvents.first!.startTime > dayStart {
                    availableBlocks.append((start: dayStart, end: dayEvents.first!.startTime))
                }
                
                // Check gaps between events
                for i in 0..<(dayEvents.count - 1) {
                    let currentEventEnd = dayEvents[i].startTime.addingTimeInterval(TimeInterval(dayEvents[i].duration * 60))
                    let nextEventStart = dayEvents[i + 1].startTime
                    
                    // Add 15-minute buffer
                    let gapStart = currentEventEnd.addingTimeInterval(TimeInterval(15 * 60))
                    let gapEnd = nextEventStart.addingTimeInterval(TimeInterval(-15 * 60))
                    
                    if gapStart < gapEnd {
                        availableBlocks.append((start: gapStart, end: gapEnd))
                    }
                }
                
                // Check time after last event
                let lastEventEnd = dayEvents.last!.startTime.addingTimeInterval(TimeInterval(dayEvents.last!.duration * 60))
                if lastEventEnd < dayEnd {
                    let gapStart = lastEventEnd.addingTimeInterval(TimeInterval(15 * 60))
                    if gapStart < dayEnd {
                        availableBlocks.append((start: gapStart, end: dayEnd))
                    }
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Filter out blocks shorter than 45 minutes (need room for meaningful events + buffers)
        return availableBlocks.filter { block in
            block.end.timeIntervalSince(block.start) >= 45 * 60
        }.sorted { block1, block2 in
            // Sort by size (largest first) to show best options first
            let duration1 = block1.end.timeIntervalSince(block1.start)
            let duration2 = block2.end.timeIntervalSince(block2.start)
            return duration1 > duration2
        }
    }
    
    private func calculateAvailableSlots(for events: [ScheduleEvent], in range: Range<Date>) -> Int {
        // Calculate 1-hour available slots during reasonable hours (7 AM - 10 PM)
        let calendar = Calendar.current
        var totalSlots = 0
        
        var currentDate = range.lowerBound
        while currentDate < range.upperBound {
            let dayEvents = events.filter { event in
                calendar.isDate(event.startTime, inSameDayAs: currentDate)
            }
            
            // Count available hours (7 AM to 10 PM = 15 hours per day)
            let totalDaySlots = 15
            let busySlots = dayEvents.reduce(0) { total, event in
                total + (event.duration / 60) // Convert minutes to hours
            }
            
            totalSlots += max(0, totalDaySlots - busySlots)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return totalSlots
    }
    
    private func findBusiestDay(from groupedEvents: [Date: [ScheduleEvent]]) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        
        var busiestDay = "None"
        var maxDuration = 0
        
        for (day, events) in groupedEvents {
            let totalDuration = events.reduce(0) { $0 + $1.duration }
            if totalDuration > maxDuration {
                maxDuration = totalDuration
                busiestDay = dayFormatter.string(from: day)
            }
        }
        
        return busiestDay
    }
    
    private func findMostOpenDay(from groupedEvents: [Date: [ScheduleEvent]], weekStart: Date) -> String {
        let calendar = Calendar.current
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        
        var mostOpenDay = "None"
        var minDuration = Int.max
        
        // Check each day of the week
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            
            let dayEvents = groupedEvents[day] ?? []
            let totalDuration = dayEvents.reduce(0) { $0 + $1.duration }
            
            if totalDuration < minDuration {
                minDuration = totalDuration
                mostOpenDay = dayFormatter.string(from: day)
            }
        }
        
        return mostOpenDay
    }
}

// MARK: - Extensions

extension DateInterval {
    var days: [Date] {
        var dates: [Date] = []
        var currentDate = start
        while currentDate < end {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return dates
    }
}
