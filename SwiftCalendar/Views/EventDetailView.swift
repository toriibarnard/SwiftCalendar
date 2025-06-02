//
//  EventDetailView.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-06-02.
//


//
//  EventDetailView.swift
//  SwiftCalendar
//
//  Detailed view for individual events
//

import SwiftUI

struct EventDetailView: View {
    let event: ScheduleEvent
    @ObservedObject var scheduleManager: ScheduleManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingEditView = false
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }
    
    private var hourFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    private var endTime: Date {
        event.startTime.addingTimeInterval(TimeInterval(event.duration * 60))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(event.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            if event.isAIGenerated {
                                Text("🤖")
                                    .font(.title)
                            }
                        }
                        
                        Text(event.startTime, formatter: timeFormatter)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Event Details
                    VStack(spacing: 16) {
                        DetailRow(
                            icon: "clock",
                            title: "Time",
                            value: "\(hourFormatter.string(from: event.startTime)) - \(hourFormatter.string(from: endTime))"
                        )
                        
                        DetailRow(
                            icon: "timer",
                            title: "Duration",
                            value: formatDuration(event.duration)
                        )
                        
                        DetailRow(
                            icon: "tag",
                            title: "Category",
                            value: event.category.displayName
                        )
                        
                        if event.isAIGenerated {
                            DetailRow(
                                icon: "brain",
                                title: "Created by",
                                value: "AI Assistant (Ty)"
                            )
                        }
                        
                        DetailRow(
                            icon: event.isFixed ? "lock" : "lock.open",
                            title: "Type",
                            value: event.isFixed ? "Fixed Event" : "Flexible Event"
                        )
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: { showingEditView = true }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Event")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: { showingDeleteAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Event")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Event?", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    scheduleManager.deleteEvent(event)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete '\(event.title)'? This action cannot be undone.")
            }
            .sheet(isPresented: $showingEditView) {
                EditEventView(event: event, scheduleManager: scheduleManager, isPresented: $showingEditView)
            }
        }
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 && remainingMinutes > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(remainingMinutes) minute\(remainingMinutes == 1 ? "" : "s")"
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, alignment: .center)
            
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct EditEventView: View {
    let event: ScheduleEvent
    @ObservedObject var scheduleManager: ScheduleManager
    @Binding var isPresented: Bool
    
    @State private var title: String
    @State private var selectedDate: Date
    @State private var duration: Int
    @State private var selectedCategory: EventCategory
    
    init(event: ScheduleEvent, scheduleManager: ScheduleManager, isPresented: Binding<Bool>) {
        self.event = event
        self.scheduleManager = scheduleManager
        self._isPresented = isPresented
        self._title = State(initialValue: event.title)
        self._selectedDate = State(initialValue: event.startTime)
        self._duration = State(initialValue: event.duration)
        self._selectedCategory = State(initialValue: event.category)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Title", text: $title)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(EventCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    
                    DatePicker("Date & Time", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Duration", selection: $duration) {
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                        Text("45 minutes").tag(45)
                        Text("1 hour").tag(60)
                        Text("1.5 hours").tag(90)
                        Text("2 hours").tag(120)
                        Text("3 hours").tag(180)
                        Text("4 hours").tag(240)
                    }
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // First delete the old event, then add the new one
                        scheduleManager.deleteEvent(event)
                        scheduleManager.addEvent(
                            at: selectedDate,
                            title: title,
                            category: selectedCategory,
                            duration: duration
                        )
                        isPresented = false
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    EventDetailView(
        event: ScheduleEvent(
            title: "Meeting with Team",
            startTime: Date(),
            duration: 60,
            category: .work,
            isFixed: true,
            isAIGenerated: false
        ),
        scheduleManager: ScheduleManager()
    )
}