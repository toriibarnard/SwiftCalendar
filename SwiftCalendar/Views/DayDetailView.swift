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
    let hourHeight: CGFloat = 60 // Height for each hour
    
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
                    
                    // Time grid with events overlay
                    ZStack(alignment: .topLeading) {
                        // Hour grid lines
                        VStack(spacing: 0) {
                            ForEach(hours, id: \.self) { hour in
                                HourRow(hour: hour, hourHeight: hourHeight)
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                        
                        // Events overlay
                        ForEach(dayEvents) { event in
                            EventOverlay(
                                event: event,
                                hourHeight: hourHeight,
                                onTap: {
                                    selectedEvent = event
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    }
                    .padding(.bottom, 20)
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
}

struct HourRow: View {
    let hour: Int
    let hourHeight: CGFloat
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Time label
            Text(formatHour(hour))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
                .padding(.top, -8)
            
            // Empty space for the hour
            Rectangle()
                .fill(Color.clear)
                .frame(height: hourHeight)
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }
}

struct EventOverlay: View {
    let event: ScheduleEvent
    let hourHeight: CGFloat
    let onTap: () -> Void
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    private var endTime: Date {
        event.startTime.addingTimeInterval(TimeInterval(event.duration * 60))
    }
    
    private var topOffset: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startTime)
        let minute = calendar.component(.minute, from: event.startTime)
        return CGFloat(hour) * hourHeight + (CGFloat(minute) / 60.0 * hourHeight)
    }
    
    private var eventHeight: CGFloat {
        let durationInHours = CGFloat(event.duration) / 60.0
        return durationInHours * hourHeight - 4 // Subtract padding
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                if event.isAIGenerated {
                    Text("🤖")
                        .font(.caption2)
                }
                Text(event.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                Spacer()
            }
            
            Text("\(event.startTime, formatter: timeFormatter) - \(endTime, formatter: timeFormatter)")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(height: max(eventHeight, 30)) // Minimum height
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(categoryColor(event.category))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(event.isAIGenerated ? Color.white : Color.clear, lineWidth: 1.5)
        )
        .offset(x: 60, y: topOffset)
        .padding(.trailing, 16)
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
    DayDetailView(date: Date(), scheduleManager: ScheduleManager())
}
