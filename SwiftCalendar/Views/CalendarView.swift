//
//  CalendarView.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-05-24.
//
import SwiftUI

struct CalendarView: View {
    @State private var currentWeek = Date()
    @ObservedObject var scheduleManager: ScheduleManager
    @State private var showingAddEvent = false
    
    let hours = Array(5...23) // 5 AM to 11 PM
    
    var weekDays: [Date] {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: currentWeek) else { return [] }
        let startOfWeek = weekInterval.start
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Week Navigation Header
                WeekHeaderSection(currentWeek: $currentWeek, weekDays: weekDays)
                
                // AI Status
                if scheduleManager.isProcessing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("🤖 AI is optimizing your schedule...")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                }
                
                // Weekly Calendar Grid
                ScrollView {
                    WeeklyGridSection(
                        hours: hours,
                        weekDays: weekDays,
                        scheduleManager: scheduleManager
                    )
                }
            }
            .navigationTitle("This Week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        scheduleManager.clearSchedule()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Add Event") {
                            showingAddEvent = true
                        }
                        Button("View Month") {
                            // Switch to month view
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView(scheduleManager: scheduleManager, isPresented: $showingAddEvent)
            }
        }
    }
}

struct AddEventView: View {
    @ObservedObject var scheduleManager: ScheduleManager
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var selectedDate = Date()
    @State private var duration = 60
    @State private var selectedCategory = EventCategory.personal
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Title", text: $title)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(EventCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized).tag(category)
                        }
                    }
                    
                    DatePicker("Date & Time", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Duration", selection: $duration) {
                        Text("30 minutes").tag(30)
                        Text("1 hour").tag(60)
                        Text("1.5 hours").tag(90)
                        Text("2 hours").tag(120)
                        Text("3 hours").tag(180)
                    }
                }
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
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

struct WeekHeaderSection: View {
    @Binding var currentWeek: Date
    let weekDays: [Date]
    
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
                
                Text(currentWeek, formatter: weekRangeFormatter)
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
                        Text(day, formatter: dayOfWeekFormatter)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(day, formatter: dayNumberFormatter)
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

struct WeeklyGridSection: View {
    let hours: [Int]
    let weekDays: [Date]
    @ObservedObject var scheduleManager: ScheduleManager
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(hours, id: \.self) { hour in
                HStack(spacing: 0) {
                    // Time label
                    Text(formatHour(hour))
                        .font(.caption)
                        .frame(width: 50)
                        .foregroundColor(.secondary)
                    
                    // Day columns
                    ForEach(weekDays, id: \.self) { day in
                        TimeSlotCell(
                            day: day,
                            hour: hour,
                            scheduleManager: scheduleManager
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
    
    func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }
}

struct TimeSlotCell: View {
    let day: Date
    let hour: Int
    @ObservedObject var scheduleManager: ScheduleManager
    
    var eventInSlot: ScheduleEvent? {
        scheduleManager.getEvent(for: day, hour: hour)
    }
    
    var body: some View {
        ZStack {
            // Background
            if Calendar.current.isDateInToday(day) && Calendar.current.component(.hour, from: Date()) == hour {
                Color.blue.opacity(0.1)
            } else {
                Color.clear
            }
            
            // Event block
            if let event = eventInSlot {
                EventBlock(event: event)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if eventInSlot != nil {
                // Handle event tap
                print("Tapped event: \(eventInSlot?.title ?? "")")
            } else {
                // Handle empty slot tap
                print("Tapped empty slot at \(hour):00")
            }
        }
    }
}

struct EventBlock: View {
    let event: ScheduleEvent
    
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                if event.isAIGenerated {
                    Text("🤖")
                        .font(.caption2)
                }
                Text(event.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            
            if event.duration > 60 {
                Text("\(event.duration/60)h \(event.duration%60)m")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(categoryColor(event.category))
                .opacity(event.isFixed ? 1.0 : 0.8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(event.isAIGenerated ? Color.white : Color.clear, lineWidth: 1.5)
        )
    }
    
    func categoryColor(_ category: EventCategory) -> Color {
        switch category {
        case .work: return .red
        case .fitness: return .green
        case .personal: return .blue
        case .study: return .purple
        case .health: return .orange
        case .social: return .pink
        case .other: return .gray
        }
    }
}

// Date formatters
let weekRangeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter
}()

let dayOfWeekFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE"
    return formatter
}()

let dayNumberFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter
}()

#Preview {
    CalendarView(scheduleManager: ScheduleManager())
}
