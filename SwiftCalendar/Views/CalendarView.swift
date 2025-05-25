//
//  CalendarView.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-05-24.
//
import SwiftUI

struct CalendarView: View {
    @State private var currentWeek = Date()
    @State private var showingAddEvent = false
    
    // Sample fixed events for demo
    @State private var fixedEvents: [CalendarEvent] = [
        CalendarEvent(userId: "demo", title: "Work", startDate: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!, endDate: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date())!, isFixed: true, category: .work),
        CalendarEvent(userId: "demo", title: "Soccer", startDate: Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!, endDate: Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date())!, isFixed: true, category: .fitness)
    ]
    
    // AI-suggested flexible events
    @State private var flexibleEvents: [CalendarEvent] = [
        CalendarEvent(userId: "demo", title: "🤖 Gym Session", startDate: Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date())!, endDate: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!, isFixed: false, category: .fitness),
        CalendarEvent(userId: "demo", title: "🤖 Running", startDate: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!, endDate: Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!, isFixed: false, category: .fitness)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Week Navigation Header
                WeekHeaderView(currentWeek: $currentWeek)
                
                // Weekly Calendar Grid
                ScrollView {
                    WeeklyCalendarGrid(
                        currentWeek: currentWeek,
                        fixedEvents: fixedEvents,
                        flexibleEvents: flexibleEvents
                    )
                }
            }
            .navigationTitle("This Week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddEvent = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddFixedEventView()
            }
        }
    }
}

struct WeekHeaderView: View {
    @Binding var currentWeek: Date
    
    var weekDays: [Date] {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: currentWeek) else { return [] }
        let startOfWeek = weekInterval.start
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Week navigation
            HStack {
                Button(action: {
                    currentWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeek) ?? currentWeek
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                }
                
                Spacer()
                
                Text(currentWeek, formatter: DateFormatter.weekRange)
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    currentWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeek) ?? currentWeek
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            
            // Day headers
            HStack(spacing: 0) {
                Text("Time")
                    .font(.caption)
                    .frame(width: 50)
                    .foregroundColor(.secondary)
                
                ForEach(weekDays, id: \.self) { day in
                    VStack(spacing: 2) {
                        Text(day, formatter: DateFormatter.dayOfWeek)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(day, formatter: DateFormatter.dayNumber)
                            .font(.headline)
                            .foregroundColor(Calendar.current.isDateInToday(day) ? .blue : .primary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            Divider()
        }
        .background(Color(UIColor.systemBackground))
    }
}

struct WeeklyCalendarGrid: View {
    let currentWeek: Date
    let fixedEvents: [CalendarEvent]
    let flexibleEvents: [CalendarEvent]
    
    var weekDays: [Date] {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: currentWeek) else { return [] }
        let startOfWeek = weekInterval.start
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    let hours = Array(0...23) // 12 AM to 11 PM
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(hours, id: \.self) { hour in
                HStack(spacing: 0) {
                    // Time label
                    Text("\(hour):00")
                        .font(.caption)
                        .frame(width: 50)
                        .foregroundColor(.secondary)
                    
                    // Day columns
                    ForEach(weekDays, id: \.self) { day in
                        TimeSlotView(
                            day: day,
                            hour: hour,
                            fixedEvents: fixedEvents,
                            flexibleEvents: flexibleEvents
                        )
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                        .border(Color.gray.opacity(0.2), width: 0.5)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct TimeSlotView: View {
    let day: Date
    let hour: Int
    let fixedEvents: [CalendarEvent]
    let flexibleEvents: [CalendarEvent]
    
    var timeSlot: Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }
    
    var eventsInSlot: [CalendarEvent] {
        let allEvents = fixedEvents + flexibleEvents
        return allEvents.filter { event in
            let eventHour = Calendar.current.component(.hour, from: event.startDate)
            let eventDay = Calendar.current.startOfDay(for: event.startDate)
            let slotDay = Calendar.current.startOfDay(for: day)
            return eventDay == slotDay && eventHour == hour
        }
    }
    
    var body: some View {
        ZStack {
            // Background color based on current time
            if Calendar.current.isDateInToday(day) && Calendar.current.component(.hour, from: Date()) == hour {
                Color.blue.opacity(0.1)
            } else {
                Color.clear
            }
            
            // Events in this time slot
            if let event = eventsInSlot.first {
                EventBlockView(event: event)
            }
        }
    }
}

struct EventBlockView: View {
    let event: CalendarEvent
    
    var body: some View {
        VStack(spacing: 2) {
            Text(event.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(event.category.color))
                .opacity(event.isFixed ? 1.0 : 0.7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(event.isFixed ? Color.clear : Color.white, lineWidth: event.isFixed ? 0 : 2)
        )
        .padding(2)
    }
}

struct AddFixedEventView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var selectedDays: Set<Int> = []
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var category = EventCategory.work
    
    let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Event Details") {
                    TextField("Event Title", text: $title)
                        .textContentType(.none)
                    
                    Picker("Category", selection: $category) {
                        ForEach(EventCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized).tag(category)
                        }
                    }
                }
                
                Section("Schedule") {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        HStack {
                            Text(daysOfWeek[dayIndex])
                            Spacer()
                            if selectedDays.contains(dayIndex) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedDays.contains(dayIndex) {
                                selectedDays.remove(dayIndex)
                            } else {
                                selectedDays.insert(dayIndex)
                            }
                        }
                    }
                    
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Add Fixed Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // TODO: Save fixed event logic
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.isEmpty || selectedDays.isEmpty)
                }
            }
        }
    }
}

// Date formatters
extension DateFormatter {
    static let weekRange: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    static let dayOfWeek: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    static let dayNumber: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
}

#Preview {
    CalendarView()
}
