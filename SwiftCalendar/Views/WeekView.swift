//
//  WeekView.swift
//  SwiftCalendar
//
//  Updated to use EventDetailView
//

import SwiftUI

struct WeekView: View {
    @ObservedObject var scheduleManager: ScheduleManager
    @State private var currentWeek = Date()
    @State private var selectedEvent: ScheduleEvent?
    @State private var showingEventDetail = false
    @Environment(\.dismiss) private var dismiss
    
    let hours = Array(6...22) // 6 AM to 10 PM for a more compact view
    let hourHeight: CGFloat = 50
    
    var weekDays: [Date] {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: currentWeek) else { return [] }
        let startOfWeek = weekInterval.start
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Week navigation
                WeekNavigationHeader(currentWeek: $currentWeek)
                
                // Day headers
                DayHeaderRow(weekDays: weekDays)
                
                Divider()
                
                // Scrollable time grid
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        // Hour grid
                        TimeGrid(hours: hours, hourHeight: hourHeight, weekDays: weekDays)
                        
                        // Events overlay
                        ForEach(weekDays, id: \.self) { day in
                            ForEach(eventsForDay(day)) { event in
                                WeekEventBlock(
                                    event: event,
                                    day: day,
                                    dayIndex: dayIndex(for: day),
                                    hourHeight: hourHeight,
                                    totalDays: weekDays.count,
                                    baseHour: hours.first ?? 6,
                                    onTap: {
                                        selectedEvent = event
                                        showingEventDetail = true
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Week View")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEventDetail) {
                if let event = selectedEvent {
                    EventDetailView(event: event, scheduleManager: scheduleManager)
                }
            }
        }
    }
    
    private func eventsForDay(_ day: Date) -> [ScheduleEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        return scheduleManager.events.filter { event in
            event.startTime >= startOfDay && event.startTime < endOfDay
        }
    }
    
    private func dayIndex(for day: Date) -> Int {
        weekDays.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: day) }) ?? 0
    }
}

struct WeekNavigationHeader: View {
    @Binding var currentWeek: Date
    
    private var weekRangeText: String {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: currentWeek) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: weekInterval.start)
        let end = formatter.string(from: weekInterval.end.addingTimeInterval(-1))
        return "\(start) - \(end)"
    }
    
    var body: some View {
        HStack {
            Button(action: previousWeek) {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }
            
            Spacer()
            
            Text(weekRangeText)
                .font(.headline)
            
            Spacer()
            
            Button(action: nextWeek) {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding()
    }
    
    private func previousWeek() {
        currentWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeek) ?? currentWeek
    }
    
    private func nextWeek() {
        currentWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeek) ?? currentWeek
    }
}

struct DayHeaderRow: View {
    let weekDays: [Date]
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE\nd"
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 0) {
            // Time column header
            Text("Time")
                .font(.caption)
                .frame(width: 50)
                .foregroundColor(.secondary)
            
            // Day headers
            ForEach(weekDays, id: \.self) { day in
                Text(day, formatter: dayFormatter)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Calendar.current.isDateInToday(day) ? .blue : .primary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct TimeGrid: View {
    let hours: [Int]
    let hourHeight: CGFloat
    let weekDays: [Date]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(hours, id: \.self) { hour in
                HStack(spacing: 0) {
                    // Hour label
                    Text(formatHour(hour))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)
                        .padding(.trailing, 8)
                    
                    // Day columns
                    ForEach(weekDays, id: \.self) { day in
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: hourHeight)
                            .frame(maxWidth: .infinity)
                            .border(Color.gray.opacity(0.2), width: 0.5)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }
}

struct WeekEventBlock: View {
    let event: ScheduleEvent
    let day: Date
    let dayIndex: Int
    let hourHeight: CGFloat
    let totalDays: Int
    let baseHour: Int
    let onTap: () -> Void
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter
    }
    
    private var topOffset: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startTime)
        let minute = calendar.component(.minute, from: event.startTime)
        let hoursFromBase = CGFloat(hour - baseHour)
        return hoursFromBase * hourHeight + (CGFloat(minute) / 60.0 * hourHeight)
    }
    
    private var eventHeight: CGFloat {
        let durationInHours = CGFloat(event.duration) / 60.0
        return max(durationInHours * hourHeight - 2, 20) // Minimum height
    }
    
    private var leftOffset: CGFloat {
        let dayWidth = (UIScreen.main.bounds.width - 66) / CGFloat(totalDays)
        return 58 + (dayWidth * CGFloat(dayIndex)) + 2
    }
    
    private var eventWidth: CGFloat {
        let dayWidth = (UIScreen.main.bounds.width - 66) / CGFloat(totalDays)
        return dayWidth - 4
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 2) {
                if event.isAIGenerated {
                    Text("🤖")
                        .font(.system(size: 10))
                }
                Text(event.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            if eventHeight > 30 {
                Text(event.startTime, formatter: timeFormatter)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .frame(width: eventWidth, height: eventHeight, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(categoryColor(event.category))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(event.isAIGenerated ? Color.white : Color.clear, lineWidth: 1)
        )
        .offset(x: leftOffset, y: topOffset)
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

#Preview {
    WeekView(scheduleManager: ScheduleManager())
}
