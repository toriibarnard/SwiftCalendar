//
//  Event.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-05-24.
//


import Foundation

struct CalendarEvent: Identifiable, Codable {
    var id: String?
    var userId: String
    var title: String
    var description: String?
    var startDate: Date
    var endDate: Date
    var isFixed: Bool // true for fixed events, false for flexible
    var category: EventCategory
    var priority: Priority
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(userId: String, title: String, startDate: Date, endDate: Date, isFixed: Bool = true, category: EventCategory = .other) {
        self.userId = userId
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isFixed = isFixed
        self.category = category
        self.priority = .medium
        self.isCompleted = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum EventCategory: String, CaseIterable, Codable {
    case work = "work"
    case fitness = "fitness"
    case personal = "personal"
    case study = "study"
    case health = "health"
    case social = "social"
    case other = "other"
    
    var color: String {
        switch self {
        case .work: return "#FF6B6B"
        case .fitness: return "#4ECDC4"
        case .personal: return "#45B7D1"
        case .study: return "#96CEB4"
        case .health: return "#FFEAA7"
        case .social: return "#DDA0DD"
        case .other: return "#95A5A6"
        }
    }
}

enum Priority: Int, CaseIterable, Codable {
    case low = 1
    case medium = 2
    case high = 3
    case urgent = 4
}
