//
//  CalendarView.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-05-24.
//
import SwiftUI

struct CalendarView: View {
    @ObservedObject var scheduleManager: ScheduleManager
    @State private var selectedMonth = Date()
    @State private var selectedDate: Date?
    @State private var showingAddEvent = false
    @State private var showingWeekView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Month navigation
                MonthHeaderView(selectedMonth: $selectedMonth)
                
                // Calendar grid
                MonthGridView(
                    selectedMonth: selectedMonth,
                    selectedDate: $selectedDate,
                    scheduleManager: scheduleManager
                )
                
                Spacer()
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Week") {
                        showingWeekView = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEvent = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView(scheduleManager: scheduleManager, isPresented: $showingAddEvent)
            }
            .sheet(isPresented: $showingWeekView) {
                WeekView(scheduleManager: scheduleManager)
            }
            .sheet(item: $selectedDate) { date in
                DayDetailView(date: date, scheduleManager: scheduleManager)
            }
        }
    }
}

struct MonthHeaderView: View {
    @Binding var selectedMonth: Date
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text(selectedMonth, formatter: monthFormatter)
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    private func previousMonth() {
        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
    }
    
    private func nextMonth() {
        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
    }
}

struct MonthGridView: View {
    let selectedMonth: Date
    @Binding var selectedDate: Date?
    @ObservedObject var scheduleManager: ScheduleManager
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var monthDays: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let range = calendar.range(of: .day, in: .month, for: startOfMonth) ?? 1..<2
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1
        let leadingEmptyDays = Array(repeating: nil as Date?, count: firstWeekday)
        
        let monthDates = range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
        
        return leadingEmptyDays + monthDates
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Day labels
            HStack {
                ForEach(dayLabels, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            scheduleManager: scheduleManager,
                            isSelected: false,
                            onTap: { selectedDate = date }
                        )
                    } else {
                        Color.clear
                            .frame(height: 80)
                    }
                }
            }
            .padding()
        }
    }
}

struct DayCell: View {
    let date: Date
    @ObservedObject var scheduleManager: ScheduleManager
    let isSelected: Bool
    let onTap: () -> Void
    
    private var dayEvents: [ScheduleEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        return scheduleManager.events.filter { event in
            event.startTime >= startOfDay && event.startTime < endOfDay
        }.sorted { $0.startTime < $1.startTime }
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        VStack(spacing: 2) {
            // Day number
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? .white : .primary)
                .frame(width: 28, height: 28)
                .background(isToday ? Circle().fill(Color.blue) : nil)
            
            // Mini event indicators
            VStack(spacing: 1) {
                ForEach(dayEvents.prefix(3)) { event in
                    HStack(spacing: 2) {
                        if event.isAIGenerated {
                            Text("🤖")
                                .font(.system(size: 8))
                        }
                        Text(event.title)
                            .font(.system(size: 9))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(categoryColor(event.category).opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(2)
                }
                
                if dayEvents.count > 3 {
                    Text("+\(dayEvents.count - 3)")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
        .onTapGesture(perform: onTap)
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

// Make Date identifiable for sheet presentation
extension Date: Identifiable {
    public var id: Double { timeIntervalSince1970 }
}

#Preview {
    CalendarView(scheduleManager: ScheduleManager())
}
