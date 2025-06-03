//
//  CalendarView.swift
//  SwiftCalendar
//
//  ULTRA-MODERN: Futuristic calendar interface
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
            ZStack {
                // Ultra-dark background
                LinearGradient(
                    colors: [
                        theme.current.primaryBackground,
                        theme.current.secondaryBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Futuristic calendar header
                    FuturisticCalendarHeader(
                        selectedMonth: $selectedMonth,
                        onWeekTap: { showingWeekView = true },
                        onAddTap: { showingAddEvent = true }
                    )
                    
                    // Neural calendar grid
                    NeuralCalendarGrid(
                        selectedMonth: selectedMonth,
                        selectedDate: $selectedDate,
                        scheduleManager: scheduleManager
                    )
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddEvent) {
                FuturisticAddEventView(scheduleManager: scheduleManager, isPresented: $showingAddEvent)
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

struct FuturisticCalendarHeader: View {
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
                // Neural navigation button
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(theme.current.tymoreAccent)
                        .frame(width: 50, height: 50)
                        .background(
                            ZStack {
                                Circle()
                                    .fill(theme.current.elevatedSurface)
                                    .background(.thinMaterial, in: Circle())
                                
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [theme.current.tymoreAccent, theme.current.tymorePurple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            }
                        )
                        .neonGlow(theme.current.tymoreAccent, radius: 8)
                }
                
                Spacer()
                
                // Neural month display
                VStack(spacing: 4) {
                    Text(selectedMonth, formatter: monthFormatter)
                        .font(TymoreTypography.headlineLarge)
                        .fontWeight(.black)
                        .tracking(1)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.current.tymoreAccent, theme.current.tymorePurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .neonGlow(theme.current.tymoreAccent, radius: 6)
                    
                    Text("NEURAL CALENDAR")
                        .font(TymoreTypography.labelSmall)
                        .fontWeight(.bold)
                        .tracking(2)
                        .foregroundColor(theme.current.accentText)
                }
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(theme.current.tymoreAccent)
                        .frame(width: 50, height: 50)
                        .background(
                            ZStack {
                                Circle()
                                    .fill(theme.current.elevatedSurface)
                                    .background(.thinMaterial, in: Circle())
                                
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [theme.current.tymoreAccent, theme.current.tymorePurple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            }
                        )
                        .neonGlow(theme.current.tymoreAccent, radius: 8)
                }
            }
            
            // Neural action buttons
            HStack(spacing: TymoreSpacing.lg) {
                Button(action: onWeekTap) {
                    HStack(spacing: TymoreSpacing.sm) {
                        Image(systemName: "calendar.day.timeline.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("WEEK VIEW")
                            .font(TymoreTypography.labelMedium)
                            .fontWeight(.bold)
                            .tracking(0.5)
                    }
                    .foregroundColor(theme.current.accentText)
                    .padding(.horizontal, TymoreSpacing.lg)
                    .padding(.vertical, TymoreSpacing.md)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: TymoreRadius.lg)
                                .fill(theme.current.elevatedSurface)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: TymoreRadius.lg))
                            
                            RoundedRectangle(cornerRadius: TymoreRadius.lg)
                                .stroke(theme.current.borderColor, lineWidth: 1)
                        }
                    )
                }
                
                Spacer()
                
                Button(action: onAddTap) {
                    HStack(spacing: TymoreSpacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .neonGlow(.white, radius: 4)
                        Text("CREATE EVENT")
                            .font(TymoreTypography.labelMedium)
                            .fontWeight(.black)
                            .tracking(0.5)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, TymoreSpacing.lg)
                    .padding(.vertical, TymoreSpacing.md)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: TymoreRadius.lg)
                                .fill(
                                    LinearGradient(
                                        colors: [theme.current.tymoreBlue, theme.current.tymorePurple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            RoundedRectangle(cornerRadius: TymoreRadius.lg)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.4), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
                    .neonGlow(theme.current.tymoreBlue, radius: 12)
                }
            }
            .padding(.top, TymoreSpacing.lg)
        }
        .padding(TymoreSpacing.xl)
        .background(
            ZStack {
                Rectangle()
                    .fill(theme.current.secondaryBackground)
                    .background(.ultraThinMaterial)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.current.tymoreAccent.opacity(0.1),
                                Color.clear,
                                theme.current.tymorePurple.opacity(0.1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .neonGlow(theme.current.tymoreAccent, radius: 4)
//                alignment: .bottom
            }
        )
    }
    
    private func previousMonth() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
        }
    }
}

struct NeuralCalendarGrid: View {
    let selectedMonth: Date
    @Binding var selectedDate: Date?
    @ObservedObject var scheduleManager: ScheduleManager
    @EnvironmentObject var theme: TymoreTheme
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let dayLabels = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    
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
            // Neural day labels
            HStack(spacing: 0) {
                ForEach(dayLabels, id: \.self) { day in
                    Text(day)
                        .font(TymoreTypography.labelMedium)
                        .fontWeight(.black)
                        .tracking(1)
                        .foregroundColor(theme.current.accentText)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, TymoreSpacing.lg)
            .padding(.vertical, TymoreSpacing.sm)
            
            // Neural calendar grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        NeuralDayCell(
                            date: date,
                            scheduleManager: scheduleManager,
                            onTap: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selectedDate = date
                                }
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 100)
                    }
                }
            }
            .padding(.horizontal, TymoreSpacing.lg)
        }
    }
}

struct NeuralDayCell: View {
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
        VStack(spacing: 6) {
            // Neural day number
            ZStack {
                if isToday {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.current.tymoreAccent,
                                    theme.current.tymorePurple
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 20
                            )
                        )
                        .frame(width: 36, height: 36)
                        .neonGlow(theme.current.tymoreAccent, radius: 8)
                        .floating()
                }
                
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .black : .semibold))
                    .foregroundColor(
                        isToday ? .white
                        : isCurrentMonth ? theme.current.primaryText
                        : theme.current.tertiaryText
                    )
            }
            
            // Neural event indicators
            VStack(spacing: 2) {
                ForEach(dayEvents.prefix(2)) { event in
                    HStack(spacing: 3) {
                        // Neural AI indicator
                        if event.isAIGenerated {
                            Circle()
                                .fill(theme.current.tymoreAccent)
                                .frame(width: 4, height: 4)
                                .neonGlow(theme.current.tymoreAccent, radius: 2)
                        }
                        
                        // Event title with neural styling
                        Text(event.title)
                            .font(.system(size: 8, weight: .semibold))
                            .lineLimit(1)
                            .foregroundColor(.white)
                        
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        categoryColor(event.category),
                                        categoryColor(event.category).opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .neonGlow(categoryColor(event.category), radius: 2)
                    )
                }
                
                // Neural overflow indicator
                if dayEvents.count > 2 {
                    Text("+\(dayEvents.count - 2)")
                        .font(.system(size: 7, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(theme.current.tymoreAccent)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(theme.current.tymoreAccent.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(theme.current.tymoreAccent, lineWidth: 1)
                                )
                        )
                        .neonGlow(theme.current.tymoreAccent, radius: 3)
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: TymoreRadius.md)
                    .fill(theme.current.elevatedSurface)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: TymoreRadius.md))
                
                RoundedRectangle(cornerRadius: TymoreRadius.md)
                    .stroke(
                        LinearGradient(
                            colors: [
                                isToday ? theme.current.tymoreAccent.opacity(0.6) : theme.current.borderColor,
                                isToday ? theme.current.tymorePurple.opacity(0.3) : theme.current.borderColor.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isToday ? 2 : 1
                    )
                    .neonGlow(
                        isToday ? theme.current.tymoreAccent : (dayEvents.isEmpty ? Color.clear : theme.current.tymoreAccent.opacity(0.3)),
                        radius: isToday ? 6 : (dayEvents.isEmpty ? 0 : 3)
                    )
            }
        )
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

struct FuturisticAddEventView: View {
    @ObservedObject var scheduleManager: ScheduleManager
    @Binding var isPresented: Bool
    @EnvironmentObject var theme: TymoreTheme
    
    @State private var title = ""
    @State private var selectedDate = Date()
    @State private var duration = 60
    @State private var selectedCategory = EventCategory.personal
    
    var body: some View {
        NavigationView {
            ZStack {
                // Ultra-dark background
                LinearGradient(
                    colors: [
                        theme.current.primaryBackground,
                        theme.current.secondaryBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: TymoreSpacing.xl) {
                        // Neural header
                        VStack(spacing: TymoreSpacing.md) {
                            Text("CREATE NEURAL EVENT")
                                .font(TymoreTypography.headlineLarge)
                                .fontWeight(.black)
                                .tracking(1.5)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [theme.current.tymoreAccent, theme.current.tymorePurple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .neonGlow(theme.current.tymoreAccent, radius: 8)
                            
                            Text("Initialize new temporal node")
                                .font(TymoreTypography.bodyMedium)
                                .foregroundColor(theme.current.accentText)
                                .tracking(0.5)
                        }
                        .padding(.top, TymoreSpacing.xl)
                        
                        // Neural form fields
                        VStack(spacing: TymoreSpacing.xl) {
                            NeuralFormField(icon: "text.cursor", title: "Event Identifier") {
                                TextField("Neural event designation", text: $title)
                                    .font(TymoreTypography.bodyMedium)
                                    .foregroundColor(theme.current.primaryText)
                            }
                            
                            NeuralFormField(icon: "tag.circle.fill", title: "Classification Matrix") {
                                Picker("Category", selection: $selectedCategory) {
                                    ForEach(EventCategory.allCases, id: \.self) { category in
                                        HStack {
                                            Circle()
                                                .fill(categoryColor(category))
                                                .frame(width: 12, height: 12)
                                                .neonGlow(categoryColor(category), radius: 3)
                                            Text(category.displayName.uppercased())
                                                .tracking(0.5)
                                        }
                                        .tag(category)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            NeuralFormField(icon: "calendar.circle.fill", title: "Temporal Coordinates") {
                                DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                            
                            NeuralFormField(icon: "clock.circle.fill", title: "Duration Protocol") {
                                Picker("Duration", selection: $duration) {
                                    Text("30 MIN").tag(30)
                                    Text("1 HOUR").tag(60)
                                    Text("1.5 HOURS").tag(90)
                                    Text("2 HOURS").tag(120)
                                    Text("3 HOURS").tag(180)
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                        }
                        
                        Spacer(minLength: TymoreSpacing.xl)
                    }
                    .padding(TymoreSpacing.xl)
                }
            }
            .navigationBarHidden(true)
            .overlay(
                // Custom navigation
                VStack {
                    HStack {
                        Button("ABORT") {
                            isPresented = false
                        }
                        .font(TymoreTypography.labelMedium)
                        .fontWeight(.bold)
                        .tracking(0.5)
                        .foregroundColor(theme.current.secondaryText)
                        
                        Spacer()
                        
                        Button("INITIALIZE") {
                            scheduleManager.addEvent(
                                at: selectedDate,
                                title: title,
                                category: selectedCategory,
                                duration: duration
                            )
                            isPresented = false
                        }
                        .font(TymoreTypography.labelMedium)
                        .fontWeight(.black)
                        .tracking(0.5)
                        .foregroundColor(title.isEmpty ? theme.current.tertiaryText : theme.current.tymoreAccent)
                        .disabled(title.isEmpty)
                        .neonGlow(
                            title.isEmpty ? Color.clear : theme.current.tymoreAccent,
                            radius: title.isEmpty ? 0 : 4
                        )
                    }
                    .padding(TymoreSpacing.xl)
                    .background(
                        Rectangle()
                            .fill(theme.current.secondaryBackground)
                            .background(.ultraThinMaterial)
                    )
                    
                    Spacer()
                },
                alignment: .top
            )
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

struct NeuralFormField<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: Content
    @EnvironmentObject var theme: TymoreTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: TymoreSpacing.md) {
            HStack(spacing: TymoreSpacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.current.tymoreAccent, theme.current.tymorePurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .neonGlow(theme.current.tymoreAccent, radius: 6)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(TymoreTypography.labelLarge)
                    .fontWeight(.bold)
                    .tracking(0.5)
                    .foregroundColor(theme.current.accentText)
            }
            
            content
                .padding(TymoreSpacing.lg)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: TymoreRadius.lg)
                            .fill(theme.current.elevatedSurface)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: TymoreRadius.lg))
                        
                        RoundedRectangle(cornerRadius: TymoreRadius.lg)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        theme.current.tymoreAccent.opacity(0.3),
                                        theme.current.borderColor
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
        }
    }
}

#Preview {
    CalendarView(scheduleManager: ScheduleManager())
        .environmentObject(TymoreTheme.shared)
}
