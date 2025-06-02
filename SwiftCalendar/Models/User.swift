//
//  User.swift
//  SwiftCalendar
//
//  Updated to remove working hours complexity
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
    var timeZone: String
    var notificationsEnabled: Bool
    
    init() {
        self.timeZone = TimeZone.current.identifier
        self.notificationsEnabled = true
    }
}
