//
//  FirebaseEventService.swift
//  SwiftCalendar
//
//  Service for saving/loading events to/from Firebase (without FirebaseFirestoreSwift)
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class FirebaseEventService: ObservableObject {
    private let db = Firestore.firestore()
    private var eventsListener: ListenerRegistration?
    
    @Published var events: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    init() {
        setupAuthListener()
    }
    
    deinit {
        eventsListener?.remove()
    }
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let userId = user?.uid {
                self?.startListening(for: userId)
            } else {
                self?.stopListening()
                self?.events = []
            }
        }
    }
    
    private func startListening(for userId: String) {
        eventsListener?.remove()
        
        eventsListener = db.collection("users")
            .document(userId)
            .collection("events")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = "Failed to load events: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.events = documents.compactMap { doc in
                    do {
                        let data = doc.data()
                        var event = try self?.decodeCalendarEvent(from: data) ?? CalendarEvent(userId: userId, title: "Unknown", startDate: Date(), endDate: Date())
                        event.id = doc.documentID
                        return event
                    } catch {
                        print("Error decoding event: \(error)")
                        return nil
                    }
                }
            }
    }
    
    private func stopListening() {
        eventsListener?.remove()
        eventsListener = nil
    }
    
    // MARK: - Manual Codable Handling
    
    private func decodeCalendarEvent(from data: [String: Any]) throws -> CalendarEvent {
        guard let userId = data["userId"] as? String,
              let title = data["title"] as? String,
              let startTimestamp = data["startDate"] as? Timestamp,
              let endTimestamp = data["endDate"] as? Timestamp,
              let isFixed = data["isFixed"] as? Bool,
              let categoryRaw = data["category"] as? String,
              let category = EventCategory(rawValue: categoryRaw),
              let priorityRaw = data["priority"] as? Int,
              let priority = Priority(rawValue: priorityRaw),
              let isCompleted = data["isCompleted"] as? Bool,
              let createdTimestamp = data["createdAt"] as? Timestamp,
              let updatedTimestamp = data["updatedAt"] as? Timestamp else {
            throw NSError(domain: "Decode", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid event data"])
        }
        
        var event = CalendarEvent(
            userId: userId,
            title: title,
            startDate: startTimestamp.dateValue(),
            endDate: endTimestamp.dateValue(),
            isFixed: isFixed,
            category: category
        )
        
        event.description = data["description"] as? String
        event.priority = priority
        event.isCompleted = isCompleted
        event.createdAt = createdTimestamp.dateValue()
        event.updatedAt = updatedTimestamp.dateValue()
        
        return event
    }
    
    private func encodeCalendarEvent(_ event: CalendarEvent) -> [String: Any] {
        return [
            "userId": event.userId,
            "title": event.title,
            "description": event.description as Any,
            "startDate": Timestamp(date: event.startDate),
            "endDate": Timestamp(date: event.endDate),
            "isFixed": event.isFixed,
            "category": event.category.rawValue,
            "priority": event.priority.rawValue,
            "isCompleted": event.isCompleted,
            "createdAt": Timestamp(date: event.createdAt),
            "updatedAt": Timestamp(date: event.updatedAt)
        ]
    }
    
    // MARK: - Event Operations
    
    func addEvent(_ event: CalendarEvent) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        var eventToSave = event
        eventToSave.userId = userId
        eventToSave.updatedAt = Date()
        
        do {
            _ = try await db.collection("users")
                .document(userId)
                .collection("events")
                .addDocument(data: encodeCalendarEvent(eventToSave))
        } catch {
            throw NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to save event: \(error.localizedDescription)"])
        }
    }
    
    func updateEvent(_ event: CalendarEvent) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let eventId = event.id else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user or event"])
        }
        
        var eventToUpdate = event
        eventToUpdate.updatedAt = Date()
        
        do {
            try await db.collection("users")
                .document(userId)
                .collection("events")
                .document(eventId)
                .setData(encodeCalendarEvent(eventToUpdate))
        } catch {
            throw NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to update event: \(error.localizedDescription)"])
        }
    }
    
    func deleteEvent(_ event: CalendarEvent) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let eventId = event.id else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user or event"])
        }
        
        do {
            try await db.collection("users")
                .document(userId)
                .collection("events")
                .document(eventId)
                .delete()
        } catch {
            throw NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to delete event: \(error.localizedDescription)"])
        }
    }
    
    // MARK: - Conversion Helpers
    
    func toScheduleEvents() -> [ScheduleEvent] {
        return events.map { calendarEvent in
            ScheduleEvent(
                title: calendarEvent.title,
                startTime: calendarEvent.startDate,
                duration: Int(calendarEvent.endDate.timeIntervalSince(calendarEvent.startDate) / 60),
                category: calendarEvent.category,
                isFixed: calendarEvent.isFixed,
                isAIGenerated: calendarEvent.description?.contains("AI-generated") == true
            )
        }
    }
    
    func fromScheduleEvent(_ scheduleEvent: ScheduleEvent, userId: String) -> CalendarEvent {
        let endDate = scheduleEvent.startTime.addingTimeInterval(TimeInterval(scheduleEvent.duration * 60))
        
        return CalendarEvent(
            userId: userId,
            title: scheduleEvent.title,
            startDate: scheduleEvent.startTime,
            endDate: endDate,
            isFixed: scheduleEvent.isFixed,
            category: scheduleEvent.category
        )
    }
}

