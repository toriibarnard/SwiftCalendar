//
//  CalendarView.swift
//  SwiftCalendar
//
//  ELEGANT: Sophisticated calendar - Black Butler aesthetic
//

import SwiftUI

// MARK: - Fix Date Identifiable Issue
extension Date: Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

struct CalendarView: View {
    @ObservedObject var scheduleManager: ScheduleManager
    @EnvironmentObject var theme: TymoreTheme
    @State private var selectedMonth = Date()
    @State private var selectedDate: Date?
    @State private var showingAddEvent = false
    @State private var showingWeekView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Elegant calendar header
                ElegantCalendarHeader(
                    selectedMonth: $selectedMonth,
                    onWeekTap: { showingWeekView = true },
                    onAddTap: { showingAddEvent = true }
                )
                
                // Refined calendar grid
                RefinedCalendarGrid(
                    selectedMonth: selectedMonth,
                    selectedDate: $selectedDate,
                    scheduleManager: scheduleManager
                )
                
                Spacer()
            }
            .background(theme.current.primaryBackground)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddEvent) {
                ElegantAddEventView(scheduleManager: scheduleManager, isPresented: $showingAddEvent)
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

struct ElegantCalendarHeader: View {
    @Binding var selectedMonth: Date
    let onWeekTap: () -> Void
    let onAddTap: () -> Void
    @EnvironmentObject var theme: TymoreTheme
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: TymoreSpacing.xl) {
                // Refined navigation button
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(theme.current.primaryText)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(theme.current.elevatedSurface)
                                .overlay(
                                    Circle()
                                        .stroke(theme.current.borderColor, lineWidth: 0.5)
                                )
                        )
                        .tymoreShadow(TymoreShadow.subtle)
                }
                
                Spacer()
                
                // Elegant month display
                VStack(spacing: 2) {
                    Text(selectedMonth, formatter: monthFormatter)
                        .font(TymoreTypography.headlineLarge)
                        .fontWeight(.medium)
                        .foregroundColor(theme.current.primaryText)
                    
                    Text("Calendar")
                        .font(TymoreTypography.labelSmall)
                        .foregroundColor(theme.current.tertiaryText)
                        .tracking(1)
                }
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(theme.current.primaryText)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(theme.current.elevatedSurface)
                                .overlay(
                                    Circle()
                                        .stroke(theme.current.borderColor, lineWidth: 0.5)
                                )
                        )
                        .tymoreShadow(TymoreShadow.subtle)
                }
            }
            
            // Refined action buttons
            HStack(spacing: TymoreSpacing.lg) {
                Button(action: onWeekTap) {
                    HStack(spacing: TymoreSpacing.sm) {
                        Image(systemName: "calendar.day.timeline.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Week View")
                            .font(TymoreTypography.labelMedium)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(theme.current.secondaryText)
                    .padding(.horizontal, TymoreSpacing.lg)
                    .padding(.vertical, TymoreSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: TymoreRadius.md)
                            .fill(theme.current.elevatedSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: TymoreRadius.md)
                                    .stroke(theme.current.borderColor, lineWidth: 0.5)
                            )
                    )
                }
                
                Spacer()
                
                Button(action: onAddTap) {
                    HStack(spacing: TymoreSpacing.sm) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                        Text("Add Event")
                            .font(TymoreTypography.labelMedium)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, TymoreSpacing.lg)
                    .padding(.vertical, TymoreSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: TymoreRadius.md)
                            .fill(theme.current.tymoreBlue)
                    )
                    .tymoreShadow(TymoreShadow.soft)
                }
            }
            .padding(.top, TymoreSpacing.lg)
        }
        .padding(TymoreSpacing.xl)
        .background(
            Rectangle()
                .fill(theme.current.secondaryBackground)
                .overlay(
                    Rectangle()
                        .fill(theme.current.separatorColor)
                        .frame(height: 0.5),
                    alignment: .bottom
                )
        )
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
        }
    }
}

struct RefinedCalendarGrid: View {
    let selectedMonth: Date
    @Binding var selectedDate: Date?
    @ObservedObject var scheduleManager: ScheduleManager
    @EnvironmentObject var theme: TymoreTheme
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
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
        VStack(spacing: TymoreSpacing.md) {
            // Refined day labels
            HStack(spacing: 0) {
                ForEach(dayLabels, id: \.self) { day in
                    Text(day)
                        .font(TymoreTypography.labelMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.current.tertiaryText)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, TymoreSpacing.lg)
            .padding(.vertical, TymoreSpacing.sm)
            
            // Elegant calendar grid
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        RefinedDayCell(
                            date: date,
                            scheduleManager: scheduleManager,
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDate = date
                                }
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 90)
                    }
                }
            }
            .padding(.horizontal, TymoreSpacing.lg)
        }
    }
}

struct RefinedDayCell: View {
    let date: Date
    @ObservedObject var scheduleManager: ScheduleManager
    let onTap: () -> Void
    @EnvironmentObject var theme: TymoreTheme
    
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
    
    private var isCurrentMonth: Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Elegant day number
            ZStack {
                if isToday {
                    Circle()
                        .fill(theme.current.tymoreBlue)
                        .frame(width: 32, height: 32)
                        .tymoreShadow(TymoreShadow.soft)
                }
                
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .semibold : .medium))
                    .foregroundColor(
                        isToday ? .white
                        : isCurrentMonth ? theme.current.primaryText
                        : theme.current.tertiaryText
                    )
            }
            
            // Refined event indicators
            VStack(spacing: 1) {
                ForEach(dayEvents.prefix(2)) { event in
                    HStack(spacing: 2) {
                        // Minimal AI indicator
                        if event.isAIGenerated {
                            Circle()
                                .fill(theme.current.tymoreBlue)
                                .frame(width: 3, height: 3)
                        }
                        
                        // Event title with refined styling
                        Text(event.title)
                            .font(.system(size: 9, weight: .medium))
                            .lineLimit(1)
                            .foregroundColor(.white)
                        
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(categoryColor(event.category))
                    )
                }
                
                // Clean overflow indicator
                if dayEvents.count > 2 {
                    Text("+\(dayEvents.count - 2)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(theme.current.tymoreBlue)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(theme.current.tymoreBlue.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(theme.current.tymoreBlue.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .background(
            RoundedRectangle(cornerRadius: TymoreRadius.sm)
                .fill(theme.current.elevatedSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: TymoreRadius.sm)
                        .stroke(
                            isToday ? theme.current.tymoreBlue.opacity(0.3) : theme.current.borderColor,
                            lineWidth: isToday ? 1 : 0.5
                        )
                )
        )
        .tymoreShadow(dayEvents.isEmpty ? TymoreShadow.subtle : TymoreShadow.soft)
        .onTapGesture(perform: onTap)
    }
    
    func categoryColor(_ category: EventCategory) -> Color {
        switch category {
        case .work: return theme.current.workColor
        case .fitness: return theme.current.fitnessColor
        case .personal: return theme.current.personalColor
        case .study: return theme.current.studyColor
        case .health: return theme.current.healthColor
        case .social: return theme.current.socialColor
        case .other: return theme.current.otherColor
        }
    }
}

struct ElegantAddEventView: View {
    @ObservedObject var scheduleManager: ScheduleManager
    @Binding var isPresented: Bool
    @EnvironmentObject var theme: TymoreTheme
    
    @State private var title = ""
    @State private var selectedDate = Date()
    @State private var duration = 60
    @State private var selectedCategory = EventCategory.personal
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Elegant header
                VStack(spacing: TymoreSpacing.md) {
                    Text("New Event")
                        .font(TymoreTypography.headlineLarge)
                        .fontWeight(.medium)
                        .foregroundColor(theme.current.primaryText)
                    
                    Text("Create a new calendar event")
                        .font(TymoreTypography.bodyMedium)
                        .foregroundColor(theme.current.secondaryText)
                }
                .padding(.top, TymoreSpacing.xl)
                .padding(.bottom, TymoreSpacing.xl)
                
                // Refined form
                ScrollView {
                    VStack(spacing: TymoreSpacing.xl) {
                        ElegantFormField(icon: "text.cursor", title: "Title") {
                            TextField("Event title", text: $title)
                                .font(TymoreTypography.bodyMedium)
                                .foregroundColor(theme.current.primaryText)
                        }
                        
                        ElegantFormField(icon: "tag", title: "Category") {
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(EventCategory.allCases, id: \.self) { category in
                                    HStack {
                                        Circle()
                                            .fill(categoryColor(category))
                                            .frame(width: 10, height: 10)
                                        Text(category.displayName)
                                    }
                                    .tag(category)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        ElegantFormField(icon: "calendar", title: "Date & Time") {
                            DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        
                        ElegantFormField(icon: "clock", title: "Duration") {
                            Picker("Duration", selection: $duration) {
                                Text("30 minutes").tag(30)
                                Text("1 hour").tag(60)
                                Text("1.5 hours").tag(90)
                                Text("2 hours").tag(120)
                                Text("3 hours").tag(180)
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                    .padding(TymoreSpacing.xl)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: TymoreSpacing.lg) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(TymoreTypography.labelMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.current.secondaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: TymoreRadius.md)
                            .fill(theme.current.elevatedSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: TymoreRadius.md)
                                    .stroke(theme.current.borderColor, lineWidth: 0.5)
                            )
                    )
                    
                    Button("Create") {
                        scheduleManager.addEvent(
                            at: selectedDate,
                            title: title,
                            category: selectedCategory,
                            duration: duration
                        )
                        isPresented = false
                    }
                    .font(TymoreTypography.labelMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: TymoreRadius.md)
                            .fill(title.isEmpty ? theme.current.tertiaryText : theme.current.tymoreBlue)
                    )
                    .disabled(title.isEmpty)
                    .tymoreShadow(title.isEmpty ? TymoreShadow.none : TymoreShadow.soft)
                }
                .padding(TymoreSpacing.xl)
                .background(
                    Rectangle()
                        .fill(theme.current.secondaryBackground)
                        .overlay(
                            Rectangle()
                                .fill(theme.current.separatorColor)
                                .frame(height: 0.5),
                            alignment: .top
                        )
                )
            }
            .background(theme.current.primaryBackground)
            .navigationBarHidden(true)
        }
    }
    
    func categoryColor(_ category: EventCategory) -> Color {
        switch category {
        case .work: return theme.current.workColor
        case .fitness: return theme.current.fitnessColor
        case .personal: return theme.current.personalColor
        case .study: return theme.current.studyColor
        case .health: return theme.current.healthColor
        case .social: return theme.current.socialColor
        case .other: return theme.current.otherColor
        }
    }
}

struct ElegantFormField<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: Content
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: TymoreSpacing.md) {
            HStack(spacing: TymoreSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.current.tymoreBlue)
                    .frame(width: 20)
                
                Text(title)
                    .font(TymoreTypography.labelLarge)
                    .fontWeight(.medium)
                    .foregroundColor(theme.current.primaryText)
            }
            
            content
                .padding(TymoreSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: TymoreRadius.md)
                        .fill(theme.current.elevatedSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: TymoreRadius.md)
                                .stroke(theme.current.borderColor, lineWidth: 0.5)
                        )
                )
                .tymoreShadow(TymoreShadow.subtle)
        }
    }
}

#Preview {
    CalendarView(scheduleManager: ScheduleManager())
        .environmentObject(TymoreTheme.shared)
}
