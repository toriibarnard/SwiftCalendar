//
//  ScheduleEvent.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-05-24.
//


import Foundation

struct ScheduleEvent: Identifiable {
    let id = UUID()
    var title: String
    var startTime: Date
    var duration: Int // minutes
    var category: EventCategory
    var isFixed: Bool
    var isAIGenerated: Bool
}

// Add this extension to make ScheduleEvent hashable for Set operations
extension ScheduleEvent: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ScheduleEvent, rhs: ScheduleEvent) -> Bool {
        return lhs.id == rhs.id
    }
}
