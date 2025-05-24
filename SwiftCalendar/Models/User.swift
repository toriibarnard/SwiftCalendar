//
//  User.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-05-24.
//


import Foundation

struct User: Identifiable, Codable {
    var id: String?
    var email: String
    var displayName: String?
    var createdAt: Date
    var preferences: UserPreferences
    
    init(email: String, displayName: String? = nil) {
        self.email = email
        self.displayName = displayName
        self.createdAt = Date()
        self.preferences = UserPreferences()
    }
}

struct UserPreferences: Codable {
    var workingHours: WorkingHours
    var timeZone: String
    var notificationsEnabled: Bool
    
    init() {
        self.workingHours = WorkingHours()
        self.timeZone = TimeZone.current.identifier
        self.notificationsEnabled = true
    }
}

struct WorkingHours: Codable {
    var startTime: String // "09:00"
    var endTime: String   // "17:00"
    var workDays: [Int]   // [1,2,3,4,5] (Mon-Fri)
    
    init() {
        self.startTime = "09:00"
        self.endTime = "17:00"
        self.workDays = [1, 2, 3, 4, 5]
    }
}
