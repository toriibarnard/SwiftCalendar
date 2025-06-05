//
//  TyResponse.swift
//  SwiftCalendar
//
//  Models for Ty AI responses and related data structures
//

import Foundation

// MARK: - Ty Response Types

indirect enum TyResponse {
    case scheduleOptimization(task: FlexibleTask, suggestions: [TimeSlotSuggestion], message: String)
    case calendarAutomation(action: CalendarAction, message: String)
    case requestConfirmation(String, pendingAction: TyResponse)
    case conversational(String)
    case clarifyingQuestion(String, context: String)
}

// MARK: - Calendar Actions

enum CalendarAction {
    case addEvents([SimpleEvent])
    case removeEvents([String])
    case removeAllEvents
    case showMessage(String)
}

// MARK: - Task Models

struct FlexibleTask {
    let title: String
    let duration: Int // minutes
    let category: TaskCategory
    let preferences: [String]
    let count: Int // number of suggestions requested
    let deadline: Date?
    let frequency: TaskFrequency?
    
    enum TaskCategory: String, CaseIterable, Codable, Hashable {
        case fitness = "fitness"
        case work = "work"
        case study = "study"
        case personal = "personal"
        case social = "social"
        case health = "health"
        case other = "other"
        
        var eventCategory: EventCategory {
            switch self {
            case .fitness: return .fitness
            case .work: return .work
            case .study: return .study
            case .personal: return .personal
            case .social: return .social
            case .health: return .health
            case .other: return .other
            }
        }
    }
    
    enum TaskFrequency {
        case daily
        case weekly(times: Int)
        case specific(days: [Int])
    }
}

// MARK: - Time Slot Models

struct TimeSlotSuggestion {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let score: Double // 0-1, higher is better
    let reasoning: String?
    let category: FlexibleTask.TaskCategory
    
    var duration: Int {
        Int(endTime.timeIntervalSince(startTime) / 60) // minutes
    }
}

// MARK: - Simple Event Model

struct SimpleEvent {
    let title: String
    let startDate: Date
    let endDate: Date
    let category: String
    let isRecurring: Bool
    let recurrenceDays: [Int]
    
    var duration: Int {
        Int(endDate.timeIntervalSince(startDate) / 60) // minutes
    }
}

// MARK: - User Preferences

struct UserSchedulePreferences: Codable {
    let workingHours: (start: Int, end: Int) // Hour of day (24-hour format)
    let preferredMorningStart: Int // Earliest acceptable morning time
    let preferredEveningEnd: Int // Latest acceptable evening time
    let timePreferences: [FlexibleTask.TaskCategory: TimePreference]
    let bufferTime: Int // Minutes between events
    
    enum TimePreference: String, CaseIterable, Codable {
        case morning = "morning"
        case afternoon = "afternoon"
        case evening = "evening"
        case any = "any"
    }
    
    init(
        workingHours: (start: Int, end: Int) = (start: 9, end: 17),
        preferredMorningStart: Int = 7,
        preferredEveningEnd: Int = 22,
        timePreferences: [FlexibleTask.TaskCategory: TimePreference] = [:],
        bufferTime: Int = 30
    ) {
        self.workingHours = workingHours
        self.preferredMorningStart = preferredMorningStart
        self.preferredEveningEnd = preferredEveningEnd
        self.timePreferences = timePreferences
        self.bufferTime = bufferTime
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case workingHours
        case preferredMorningStart
        case preferredEveningEnd
        case timePreferences
        case bufferTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode working hours as array and convert to tuple
        let workingHoursArray = try container.decode([Int].self, forKey: .workingHours)
        workingHours = (start: workingHoursArray[0], end: workingHoursArray[1])
        
        preferredMorningStart = try container.decode(Int.self, forKey: .preferredMorningStart)
        preferredEveningEnd = try container.decode(Int.self, forKey: .preferredEveningEnd)
        timePreferences = try container.decode([FlexibleTask.TaskCategory: TimePreference].self, forKey: .timePreferences)
        bufferTime = try container.decode(Int.self, forKey: .bufferTime)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode tuple as array
        try container.encode([workingHours.start, workingHours.end], forKey: .workingHours)
        try container.encode(preferredMorningStart, forKey: .preferredMorningStart)
        try container.encode(preferredEveningEnd, forKey: .preferredEveningEnd)
        try container.encode(timePreferences, forKey: .timePreferences)
        try container.encode(bufferTime, forKey: .bufferTime)
    }
}

// MARK: - Claude API Models

struct ClaudeRequest {
    let model: String
    let maxTokens: Int
    let temperature: Double
    let systemPrompt: String
    let messages: [[String: Any]]
    
    func toDictionary() -> [String: Any] {
        return [
            "model": model,
            "max_tokens": maxTokens,
            "temperature": temperature,
            "system": systemPrompt,
            "messages": messages
        ]
    }
}

struct ClaudeResponse {
    let id: String
    let content: String
    let stopReason: String?
    let usage: TokenUsage?
    
    struct TokenUsage {
        let inputTokens: Int
        let outputTokens: Int
    }
}

// MARK: - Parse Results

struct ParseResult {
    let responseType: ResponseType
    let content: Any
    let message: String?
    
    enum ResponseType {
        case optimization
        case automation
        case removal
        case conversation
    }
}
