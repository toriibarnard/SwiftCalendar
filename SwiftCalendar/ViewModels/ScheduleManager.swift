//
//  ScheduleManager.swift
//  SwiftCalendar
//
//  Updated to use Firebase for persistence
//

import Foundation
import SwiftUI
import FirebaseAuth
import Combine

class ScheduleManager: ObservableObject {
    @Published var events: [ScheduleEvent] = []
    @Published var isProcessing = false
    @Published var errorMessage = ""
    
    private let firebaseService = FirebaseEventService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen to Firebase events and convert to ScheduleEvents
        firebaseService.$events
            .receive(on: DispatchQueue.main)
            .map { $0.map(self.toScheduleEvent) }
            .assign(to: \.events, on: self)
            .store(in: &cancellables)
        
        firebaseService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isProcessing, on: self)
            .store(in: &cancellables)
        
        firebaseService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Event Queries
    
    func getEvent(for day: Date, hour: Int) -> ScheduleEvent? {
        let dayStart = Calendar.current.startOfDay(for: day)
        return events.first { event in
            let eventDay = Calendar.current.startOfDay(for: event.startTime)
            let eventHour = Calendar.current.component(.hour, from: event.startTime)
            return eventDay == dayStart && eventHour == hour
        }
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
            
            // Skip hours outside reasonable hours (6 AM to 11 PM)
            if hour >= 6 && hour <= 23 {
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
    
    // MARK: - Event Management
    
    func addEvent(at timeSlot: Date, title: String, category: EventCategory, duration: Int) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let endDate = timeSlot.addingTimeInterval(TimeInterval(duration * 60))
        let calendarEvent = CalendarEvent(
            userId: userId,
            title: title,
            startDate: timeSlot,
            endDate: endDate,
            isFixed: true,
            category: category
        )
        
        Task {
            do {
                try await firebaseService.addEvent(calendarEvent)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func addAIEvent(at timeSlot: Date, title: String, category: EventCategory, duration: Int) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let endDate = timeSlot.addingTimeInterval(TimeInterval(duration * 60))
        var calendarEvent = CalendarEvent(
            userId: userId,
            title: title,
            startDate: timeSlot,
            endDate: endDate,
            isFixed: true,
            category: category
        )
        
        // Add description to mark as AI-generated
        calendarEvent.description = "AI-generated event"
        
        Task {
            do {
                try await firebaseService.addEvent(calendarEvent)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func deleteEvent(_ event: ScheduleEvent) {
        // Find the corresponding CalendarEvent
        if let calendarEvent = firebaseService.events.first(where: {
            $0.title == event.title &&
            $0.startDate == event.startTime
        }) {
            Task {
                do {
                    try await firebaseService.deleteEvent(calendarEvent)
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func updateEvent(_ event: ScheduleEvent, title: String, category: EventCategory, duration: Int) {
        // Find the corresponding CalendarEvent
        if var calendarEvent = firebaseService.events.first(where: {
            $0.title == event.title &&
            $0.startDate == event.startTime
        }) {
            calendarEvent.title = title
            calendarEvent.category = category
            calendarEvent.endDate = event.startTime.addingTimeInterval(TimeInterval(duration * 60))
            
            Task {
                do {
                    try await firebaseService.updateEvent(calendarEvent)
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func moveEvent(_ event: ScheduleEvent, to day: Date, hour: Int) {
        // Find the corresponding CalendarEvent
        if var calendarEvent = firebaseService.events.first(where: {
            $0.title == event.title &&
            $0.startDate == event.startTime
        }) {
            let newTime = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
            let duration = calendarEvent.endDate.timeIntervalSince(calendarEvent.startDate)
            
            calendarEvent.startDate = newTime
            calendarEvent.endDate = newTime.addingTimeInterval(duration)
            
            Task {
                do {
                    try await firebaseService.updateEvent(calendarEvent)
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func clearSchedule() {
        Task {
            for calendarEvent in firebaseService.events {
                do {
                    try await firebaseService.deleteEvent(calendarEvent)
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                    }
                    break
                }
            }
        }
    }
    
    // MARK: - Conversion Helper
    
    private func toScheduleEvent(_ calendarEvent: CalendarEvent) -> ScheduleEvent {
        let duration = Int(calendarEvent.endDate.timeIntervalSince(calendarEvent.startDate) / 60)
        let isAIGenerated = calendarEvent.description?.contains("AI-generated") == true
        
        return ScheduleEvent(
            title: calendarEvent.title,
            startTime: calendarEvent.startDate,
            duration: duration,
            category: calendarEvent.category,
            isFixed: calendarEvent.isFixed,
            isAIGenerated: isAIGenerated
        )
    }
}
