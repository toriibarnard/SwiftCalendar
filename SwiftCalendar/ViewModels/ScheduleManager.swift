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
    
    func processAIRequest(_ request: String) {
        isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isProcessing = false
            self.generateDemoSchedule()
        }
    }
    
    private func generateDemoSchedule() {
        let today = Date()
        events = [
            ScheduleEvent(title: "🤖 Morning Run", startTime: Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: today)!, duration: 45, category: .fitness, isFixed: false, isAIGenerated: true),
            ScheduleEvent(title: "Work", startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: today)!, duration: 480, category: .work, isFixed: true, isAIGenerated: false),
            ScheduleEvent(title: "🤖 Gym Session", startTime: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: today)!, duration: 90, category: .fitness, isFixed: false, isAIGenerated: true)
        ]
    }
}