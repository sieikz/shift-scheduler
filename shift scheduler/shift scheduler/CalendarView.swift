import SwiftUI

struct CalendarView: View {
    @StateObject private var shiftViewModel = ShiftViewModel()
    @StateObject private var workplaceViewModel = WorkplaceViewModel()
    @EnvironmentObject var sharedAppState: SharedAppState
    @State private var selectedDate = Date()
    @State private var showingAddShift = false
    @State private var showingDateShifts = false
    @State private var selectedDateShifts: [Shift] = []
    @State private var currentMonthOffset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    
    private let calendar = Calendar.current
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Month navigation
                monthNavigationHeader
                
                // Calendar section
                VStack(spacing: 0) {
                    // Weekday headers
                    weekdayHeaderView(geometry: geometry)
                    
                    // Calendar grid
                    calendarGridView(geometry: geometry)
                }
                .background(Color(.systemBackground))
                
                Spacer()
            }
        }
        .navigationTitle("カレンダー")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddShift) {
            AddShiftView(
                selectedDate: selectedDate,
                workplaces: workplaceViewModel.workplaces,
                shiftViewModel: shiftViewModel
            )
        }
        .sheet(isPresented: $showingDateShifts) {
            DateShiftsView(
                date: selectedDate,
                shifts: selectedDateShifts,
                workplaces: workplaceViewModel.workplaces,
                shiftViewModel: shiftViewModel
            )
        }
        .onAppear {
            shiftViewModel.selectedDate = selectedDate
            // 初期状態として今日のシフトを表示
            let todayShifts = shiftViewModel.shifts(for: Date())
            sharedAppState.updateSelectedDate(Date(), shifts: todayShifts)
        }
        .onChange(of: selectedDate) { _, newDate in
            Task { @MainActor in
                shiftViewModel.selectedDate = newDate
            }
        }
        .onChange(of: sharedAppState.calendarSelectedDate) { _, newDate in
            Task { @MainActor in
                selectedDate = newDate
                shiftViewModel.selectedDate = newDate
            }
        }
    }
    
    private var monthNavigationHeader: some View {
        HStack {
            Button {
                hapticFeedback.impactOccurred()
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(monthYearString)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("今月の勤務: \(monthlyWorkingHours)時間")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                hapticFeedback.impactOccurred()
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
    
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: selectedDate)
    }
    
    
    private var weekdayHeaders: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.shortWeekdaySymbols
    }
    
    private var calendarDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate) else {
            return []
        }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        
        // Add empty cells for days before the first day of the month
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        // Add all days of the month
        let numberOfDays = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 0
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        // Fill remaining cells to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    // MARK: - New Views
    
    private func weekdayHeaderView(geometry: GeometryProxy) -> some View {
        let horizontalPadding: CGFloat = 8
        let gridSpacing: CGFloat = 1
        let availableWidth = geometry.size.width - (horizontalPadding * 2)
        let spacingTotal = gridSpacing * 6  // 6つの間隔
        let cellSize = (availableWidth - spacingTotal) / 7
        
        return HStack(spacing: gridSpacing) {
            ForEach(weekdayHeaders, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(width: cellSize, height: 32)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private func calendarGridView(geometry: GeometryProxy) -> some View {
        let horizontalPadding: CGFloat = 8
        let gridSpacing: CGFloat = 1
        let availableWidth = geometry.size.width - (horizontalPadding * 2)
        let spacingTotal = gridSpacing * 6  // 6つの間隔
        let cellSize = (availableWidth - spacingTotal) / 7
        
        let calendarDaysArray = calendarDays
        let rows = stride(from: 0, to: calendarDaysArray.count, by: 7).map { startIndex in
            Array(calendarDaysArray[startIndex..<min(startIndex + 7, calendarDaysArray.count)])
        }
        
        return VStack(spacing: gridSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, week in
                HStack(spacing: gridSpacing) {
                    ForEach(Array(week.enumerated()), id: \.offset) { dayIndex, date in
                        if let date = date {
                            CalendarDayView(
                                date: date,
                                shifts: shiftViewModel.shifts(for: date),
                                workplaces: workplaceViewModel.workplaces,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isToday: calendar.isDateInToday(date),
                                overlaps: dayOverlaps(for: date),
                                cellSize: cellSize
                            ) {
                                hapticFeedback.impactOccurred()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDate = date
                                }
                                selectedDateShifts = shiftViewModel.shifts(for: date)
                                sharedAppState.updateSelectedDate(date, shifts: selectedDateShifts)
                            }
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 16)
    }
    
    // MARK: - Helper Methods
    
    private var monthlyWorkingHours: Int {
        let monthShifts = shiftViewModel.shifts.filter { shift in
            calendar.isDate(shift.date, equalTo: selectedDate, toGranularity: .month)
        }
        return monthShifts.reduce(0) { $0 + $1.workingMinutes } / 60
    }
    
    
    private func dayOverlaps(for date: Date) -> [ShiftOverlap] {
        return shiftViewModel.hasOverlap(on: date, workplaces: workplaceViewModel.workplaces)
    }
}

// カレンダー日付セルビュー
struct CalendarDayView: View {
    let date: Date
    let shifts: [Shift]
    let workplaces: [Workplace]
    let isSelected: Bool
    let isToday: Bool
    let overlaps: [ShiftOverlap]
    let cellSize: CGFloat
    @State private var isPressed: Bool = false
    let onTap: () -> Void
    
    private var hasOverlap: Bool { !overlaps.isEmpty }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func workplaceColor(for shift: Shift) -> Color {
        workplaces.first { $0.id == shift.workplaceId }?.color ?? .gray
    }
    
    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .overlay(
                    VStack(spacing: 4) {
                        HStack {
                            Text(dayNumber)
                                .font(.system(size: 16, weight: isToday ? .bold : .medium, design: .rounded))
                                .foregroundColor(textColor)
                            
                            Spacer()
                            
                            if hasOverlap {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 6)
                        
                        Spacer()
                        
                        if !shifts.isEmpty {
                            HStack(spacing: 2) {
                                ForEach(Array(shifts.prefix(4).enumerated()), id: \.offset) { _, shift in
                                    Circle()
                                        .fill(workplaceColor(for: shift))
                                        .frame(width: 4, height: 4)
                                }
                                
                                if shifts.count > 4 {
                                    Text("+")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.bottom, 6)
                        }
                    }
                )
                .frame(width: cellSize, height: cellSize)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .simultaneousGesture(pressGesture)
    }
    
    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPressed { isPressed = true }
            }
            .onEnded { _ in
                isPressed = false
            }
    }
    
    private var textColor: Color {
        if isToday || isSelected {
            return .white
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isToday {
            return Color.blue
        } else if isSelected {
            return Color.blue.opacity(0.2)
        } else if hasOverlap {
            return Color.red.opacity(0.1)
        } else if shifts.isEmpty {
            return Color(.systemBackground)
        } else {
            return Color(.systemGray6)
        }
    }
    
    private var borderColor: Color {
        if hasOverlap {
            return Color.red.opacity(0.6)
        } else if isSelected {
            return Color.blue
        } else if isToday {
            return Color.clear
        } else {
            return Color(.separator).opacity(0.3)
        }
    }
    
    private var borderWidth: CGFloat {
        if hasOverlap || isSelected {
            return 2
        } else if isToday {
            return 0
        } else {
            return 0.5
        }
    }
    
    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日E曜日"
        let dateString = formatter.string(from: date)
        
        if shifts.isEmpty {
            return "\(dateString)、シフトなし"
        } else {
            return "\(dateString)、\(shifts.count)件のシフト"
        }
    }
    
    private var accessibilityHint: String {
        if shifts.isEmpty {
            return "タップしてシフトを追加"
        } else {
            return "タップして詳細を表示"
        }
    }
}

// 日別シフト詳細ビュー
struct DateShiftsView: View {
    let date: Date
    let shifts: [Shift]
    let workplaces: [Workplace]
    let shiftViewModel: ShiftViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddShift = false
    @State private var showingEditShift = false
    @State private var selectedShift: Shift?
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: date)
    }
    
    private var overlaps: [ShiftOverlap] {
        shiftViewModel.hasOverlap(on: date, workplaces: workplaces)
    }
    
    var body: some View {
        NavigationView {
            List {
                if !overlaps.isEmpty {
                    Section {
                        ForEach(Array(overlaps.enumerated()), id: \.offset) { _, overlap in
                            OverlapWarningView(overlap: overlap, workplaces: workplaces)
                        }
                    } header: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("重複警告")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section {
                    ForEach(shifts.sorted { $0.startTime < $1.startTime }) { shift in
                        ShiftRowView(shift: shift, workplace: workplaces.first { $0.id == shift.workplaceId }) {
                            selectedShift = shift
                            showingEditShift = true
                        }
                    }
                    .onDelete(perform: deleteShifts)
                }
            }
            .navigationTitle("\(dateString)のシフト")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddShift = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddShift) {
                AddShiftView(
                    selectedDate: date,
                    workplaces: workplaces,
                    shiftViewModel: shiftViewModel
                )
            }
            .sheet(isPresented: $showingEditShift) {
                if let shift = selectedShift {
                    EditShiftView(
                        shift: shift,
                        workplaces: workplaces,
                        shiftViewModel: shiftViewModel
                    ) {
                        selectedShift = nil
                    }
                }
            }
        }
    }
    
    private func deleteShifts(offsets: IndexSet) {
        let sortedShifts = shifts.sorted { $0.startTime < $1.startTime }
        for index in offsets {
            shiftViewModel.deleteShift(sortedShifts[index])
        }
    }
}

// シフト行ビュー
struct ShiftRowView: View {
    let shift: Shift
    let workplace: Workplace?
    let onTap: () -> Void
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private var workingTime: String {
        let hours = shift.workingMinutes / 60
        let minutes = shift.workingMinutes % 60
        if minutes == 0 {
            return "\(hours)h"
        } else {
            return "\(hours)h\(minutes)m"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(workplace?.color ?? .gray)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(workplace?.name ?? "不明な職場")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("\(timeFormatter.string(from: shift.startTime)) - \(timeFormatter.string(from: shift.endTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("(\(workingTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let memo = shift.memo, !memo.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(memo)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
                
                Spacer()
                
                VStack {
                    if shift.isNightShift {
                        Image(systemName: "moon.fill")
                            .font(.caption)
                            .foregroundColor(.indigo)
                    }
                    
                    if shift.isHoliday() {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CalendarView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(SharedAppState())
}