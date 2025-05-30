//
//  ScheduleManager.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-05-24.
//

import Foundation
import SwiftUI

class ScheduleManager: ObservableObject {
    @Published var events: [ScheduleEvent] = []
    @Published var isProcessing = false
    
    func getEvent(for day: Date, hour: Int) -> ScheduleEvent? {
        let dayStart = Calendar.current.startOfDay(for: day)
        return events.first { event in
            let eventDay = Calendar.current.startOfDay(for: event.startTime)
            let eventHour = Calendar.current.component(.hour, from: event.startTime)
            return eventDay == dayStart && eventHour == hour
        }
    }
    
    func addEvent(at timeSlot: Date, title: String, category: EventCategory, duration: Int) {
        let newEvent = ScheduleEvent(
            title: title,
            startTime: timeSlot,
            duration: duration,
            category: category,
            isFixed: true,
            isAIGenerated: false
        )
        events.append(newEvent)
    }
    
    func addAIEvent(at timeSlot: Date, title: String, category: EventCategory, duration: Int) {
        let newEvent = ScheduleEvent(
            title: title,
            startTime: timeSlot,
            duration: duration,
            category: category,
            isFixed: true,
            isAIGenerated: true
        )
        events.append(newEvent)
    }
    
    func deleteEvent(_ event: ScheduleEvent) {
        events.removeAll { $0.id == event.id }
    }
    
    func updateEvent(_ event: ScheduleEvent, title: String, category: EventCategory, duration: Int) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].title = title
            events[index].category = category
            events[index].duration = duration
        }
    }
    
    func moveEvent(_ event: ScheduleEvent, to day: Date, hour: Int) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            let newTime = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
            events[index].startTime = newTime
        }
    }
    
    func clearSchedule() {
        events.removeAll()
    }
    
    func getEventsForDateRange(startDate: Date, endDate: Date) -> [ScheduleEvent] {
        return events.filter { event in
            event.startTime >= startDate && event.startTime <= endDate
        }.sorted { $0.startTime < $1.startTime }
    }
    
    func hasConflict(at timeSlot: Date, duration: Int) -> Bool {
        let endTime = timeSlot.addingTimeInterval(TimeInterval(duration * 60))
        
        return events.contains { event in
            let eventEndTime = event.startTime.addingTimeInterval(TimeInterval(event.duration * 60))
            
            // Check if the time ranges overlap
            return (timeSlot < eventEndTime && endTime > event.startTime)
        }
    }
    
    func findAvailableSlots(for duration: Int, within dateRange: (start: Date, end: Date), preferredTimes: [Int] = []) -> [Date] {
        var availableSlots: [Date] = []
        let calendar = Calendar.current
        
        var currentTime = dateRange.start
        while currentTime < dateRange.end {
            let hour = calendar.component(.hour, from: currentTime)
            
            // Skip hours outside working hours (5 AM to 11 PM)
            if hour >= 5 && hour <= 23 {
                if !hasConflict(at: currentTime, duration: duration) {
                    availableSlots.append(currentTime)
                }
            }
            
            // Move to next hour
            currentTime = calendar.date(byAdding: .hour, value: 1, to: currentTime) ?? currentTime
        }
        
        // Sort by preferred times if provided
        if !preferredTimes.isEmpty {
            availableSlots.sort { slot1, slot2 in
                let hour1 = calendar.component(.hour, from: slot1)
                let hour2 = calendar.component(.hour, from: slot2)
                
                let index1 = preferredTimes.firstIndex(of: hour1) ?? Int.max
                let index2 = preferredTimes.firstIndex(of: hour2) ?? Int.max
                
                return index1 < index2
            }
        }
        
        return availableSlots
    }
}
