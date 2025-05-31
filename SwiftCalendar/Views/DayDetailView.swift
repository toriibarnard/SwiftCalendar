//
//  DayDetailView.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-05-31.
//


//
//  DayDetailView.swift
//  SwiftCalendar
//
//  Hour-by-hour view of a specific day
//

import SwiftUI

struct DayDetailView: View {
    let date: Date
    @ObservedObject var scheduleManager: ScheduleManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEvent: ScheduleEvent?
    @State private var showingDeleteAlert = false
    
    let hours = Array(0...23) // 12 AM to 11 PM
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
    
    private var dayEvents: [ScheduleEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        return scheduleManager.events.filter { event in
            event.startTime >= startOfDay && event.startTime < endOfDay
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with date
                    Text(date, formatter: dateFormatter)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                    
                    // Hour slots
                    ForEach(hours, id: \.self) { hour in
                        HourRow(
                            hour: hour,
                            date: date,
                            events: eventsForHour(hour),
                            onEventTap: { event in
                                selectedEvent = event
                                showingDeleteAlert = true
                            }
                        )
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .navigationTitle("Day View")
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
                    if let event = selectedEvent {
                        scheduleManager.deleteEvent(event)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let event = selectedEvent {
                    Text("Are you sure you want to delete '\(event.title)'?")
                }
            }
        }
    }
    
    private func eventsForHour(_ hour: Int) -> [ScheduleEvent] {
        dayEvents.filter { event in
            Calendar.current.component(.hour, from: event.startTime) == hour
        }
    }
}

struct HourRow: View {
    let hour: Int
    let date: Date
    let events: [ScheduleEvent]
    let onEventTap: (ScheduleEvent) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Time label
            Text(formatHour(hour))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
                .padding(.top, 4)
            
            // Events
            VStack(alignment: .leading, spacing: 4) {
                if events.isEmpty {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 50)
                } else {
                    ForEach(events) { event in
                        EventDetailBlock(event: event)
                            .onTapGesture {
                                onEventTap(event)
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing)
        }
        .frame(minHeight: 60)
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }
}

struct EventDetailBlock: View {
    let event: ScheduleEvent
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    private var endTime: Date {
        event.startTime.addingTimeInterval(TimeInterval(event.duration * 60))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if event.isAIGenerated {
                    Text("🤖")
                        .font(.caption)
                }
                Text(event.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text("\(event.startTime, formatter: timeFormatter) - \(endTime, formatter: timeFormatter)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            if event.duration > 60 {
                Text("\(event.duration / 60)h \(event.duration % 60)m")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(categoryColor(event.category))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
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

#Preview {
    DayDetailView(date: Date(), scheduleManager: ScheduleManager())
}