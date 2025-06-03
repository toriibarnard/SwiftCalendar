//
//  CalendarView.swift
//  SwiftCalendar
//
//  FIXED: Date identifiable issue and view conflicts
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
                // Custom navigation header
                TymoreCalendarHeader(
                    selectedMonth: $selectedMonth,
                    onWeekTap: { showingWeekView = true },
                    onAddTap: { showingAddEvent = true }
                )
                
                // Calendar grid with enhanced styling
                TymoreMonthGrid(
                    selectedMonth: selectedMonth,
                    selectedDate: $selectedDate,
                    scheduleManager: scheduleManager
                )
                
                Spacer()
            }
            .background(theme.current.primaryBackground)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddEvent) {
                TymoreAddEventView(scheduleManager: scheduleManager, isPresented: $showingAddEvent)
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

struct TymoreCalendarHeader: View {
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
            HStack(spacing: TymoreSpacing.lg) {
                // Month navigation
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(theme.current.tymoreBlue)
                        .frame(width: 44, height: 44)
                        .background(theme.current.tertiaryBackground)
                        .cornerRadius(TymoreRadius.md)
                        .tymoreShadow(TymoreShadow.subtle)
                }
                
                Spacer()
                
                // Month title with enhanced styling
                VStack(spacing: 2) {
                    Text(selectedMonth, formatter: monthFormatter)
                        .font(TymoreTypography.headlineLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.current.primaryText)
                    
                    Text("Tap a date to view details")
                        .font(TymoreTypography.labelSmall)
                        .foregroundColor(theme.current.tertiaryText)
                }
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(theme.current.tymoreBlue)
                        .frame(width: 44, height: 44)
                        .background(theme.current.tertiaryBackground)
                        .cornerRadius(TymoreRadius.md)
                        .tymoreShadow(TymoreShadow.subtle)
                }
            }
            
            // Action buttons
            HStack(spacing: TymoreSpacing.md) {
                Button(action: onWeekTap) {
                    HStack(spacing: TymoreSpacing.xs) {
                        Image(systemName: "calendar.day.timeline.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Week View")
                            .font(TymoreTypography.labelMedium)
                    }
                    .foregroundColor(theme.current.secondaryText)
                    .padding(.horizontal, TymoreSpacing.md)
                    .padding(.vertical, TymoreSpacing.sm)
                    .background(theme.current.tertiaryBackground)
                    .cornerRadius(TymoreRadius.sm)
                }
                
                Spacer()
                
                Button(action: onAddTap) {
                    HStack(spacing: TymoreSpacing.xs) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("Add Event")
                            .font(TymoreTypography.labelMedium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, TymoreSpacing.md)
                    .padding(.vertical, TymoreSpacing.sm)
                    .background(
                        LinearGradient(
                            colors: [theme.current.tymoreBlue, theme.current.tymoreSteel],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(TymoreRadius.sm)
                    .tymoreShadow(TymoreShadow.soft)
                }
            }
            .padding(.top, TymoreSpacing.md)
        }
        .padding(TymoreSpacing.lg)
        .background(theme.current.secondaryBackground)
        .overlay(
            Rectangle()
                .fill(theme.current.separatorColor)
                .frame(height: 1),
            alignment: .bottom
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

struct TymoreMonthGrid: View {
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
        VStack(spacing: TymoreSpacing.sm) {
            // Day labels with enhanced styling
            HStack(spacing: 0) {
                ForEach(dayLabels, id: \.self) { day in
                    Text(day)
                        .font(TymoreTypography.labelMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.current.tertiaryText)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, TymoreSpacing.sm)
            .padding(.vertical, TymoreSpacing.xs)
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        TymoreDayCell(
                            date: date,
                            scheduleManager: scheduleManager,
                            onTap: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
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
            .padding(.horizontal, TymoreSpacing.sm)
        }
    }
}

struct TymoreDayCell: View {
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
            // Day number with enhanced styling
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .medium))
                .foregroundColor(
                    isToday ? .white
                    : isCurrentMonth ? theme.current.primaryText
                    : theme.current.tertiaryText
                )
                .frame(width: 32, height: 32)
                .background(
                    Group {
                        if isToday {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [theme.current.tymoreBlue, theme.current.tymoreSteel],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .tymoreShadow(TymoreShadow.soft)
                        } else {
                            Circle()
                                .fill(Color.clear)
                        }
                    }
                )
            
            // Event indicators with sophisticated design
            VStack(spacing: 2) {
                ForEach(dayEvents.prefix(2)) { event in
                    HStack(spacing: 2) {
                        // AI indicator
                        if event.isAIGenerated {
                            Circle()
                                .fill(theme.current.tymoreAccent)
                                .frame(width: 4, height: 4)
                        }
                        
                        // Event title
                        Text(event.title)
                            .font(.system(size: 8, weight: .medium))
                            .lineLimit(1)
                            .foregroundColor(.white)
                        
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(categoryColor(event.category))
                    )
                }
                
                // More events indicator
                if dayEvents.count > 2 {
                    Text("+\(dayEvents.count - 2)")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(theme.current.tymoreBlue)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(theme.current.tymoreBlue.opacity(0.2))
                        )
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .background(
            RoundedRectangle(cornerRadius: TymoreRadius.sm)
                .fill(theme.current.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: TymoreRadius.sm)
                        .stroke(
                            isToday ? theme.current.tymoreBlue.opacity(0.5) : theme.current.borderColor,
                            lineWidth: isToday ? 2 : 1
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

struct TymoreAddEventView: View {
    @ObservedObject var scheduleManager: ScheduleManager
    @Binding var isPresented: Bool
    @EnvironmentObject var theme: TymoreTheme
    
    @State private var title = ""
    @State private var selectedDate = Date()
    @State private var duration = 60
    @State private var selectedCategory = EventCategory.personal
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TymoreFormField(icon: "text.cursor", title: "Title") {
                        TextField("Event title", text: $title)
                            .font(TymoreTypography.bodyMedium)
                    }
                    
                    TymoreFormField(icon: "tag", title: "Category") {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(EventCategory.allCases, id: \.self) { category in
                                HStack {
                                    Circle()
                                        .fill(categoryColor(category))
                                        .frame(width: 12, height: 12)
                                    Text(category.displayName)
                                }
                                .tag(category)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    TymoreFormField(icon: "calendar", title: "Date & Time") {
                        DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }
                    
                    TymoreFormField(icon: "clock", title: "Duration") {
                        Picker("Duration", selection: $duration) {
                            Text("30 min").tag(30)
                            Text("1 hour").tag(60)
                            Text("1.5 hours").tag(90)
                            Text("2 hours").tag(120)
                            Text("3 hours").tag(180)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.current.primaryBackground)
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(theme.current.secondaryText)
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
                    .foregroundColor(theme.current.tymoreBlue)
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
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

struct TymoreFormField<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: Content
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        HStack(spacing: TymoreSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.current.tymoreBlue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TymoreTypography.labelMedium)
                    .foregroundColor(theme.current.secondaryText)
                
                content
            }
            
            Spacer()
        }
        .padding(.vertical, TymoreSpacing.xs)
    }
}

#Preview {
    CalendarView(scheduleManager: ScheduleManager())
        .environmentObject(TymoreTheme.shared)
}
