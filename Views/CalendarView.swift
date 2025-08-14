import SwiftUI

struct CalendarView: View {
    @StateObject private var shiftViewModel = ShiftViewModel()
    @StateObject private var workplaceViewModel = WorkplaceViewModel()
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
                
                // Weekday headers
                weekdayHeaderView
                
                // Calendar grid
                calendarGridView(geometry: geometry)
                
                // Bottom toolbar
                bottomToolbar
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
        }
        .onChange(of: selectedDate) { newDate in
            shiftViewModel.selectedDate = newDate
        }
    }
    
    private var monthNavigationHeader: some View {
        HStack {
            Button {
                hapticFeedback.impactOccurred()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("今月の勤務: \(monthlyWorkingHours)時間")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                hapticFeedback.impactOccurred()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var bottomToolbar: some View {
        VStack(spacing: 12) {
            // Selected date info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDateString)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    let dayShifts = shiftViewModel.shifts(for: selectedDate)
                    if dayShifts.isEmpty {
                        Text("お休み")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(dayShifts.count)件のシフト・\(totalHours(for: dayShifts))時間")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                Button {
                    hapticFeedback.impactOccurred()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        selectedDate = Date()
                    }
                } label: {
                    Text("今日")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                }
            }
            
            // Action buttons
            HStack(spacing: 16) {
                Button {
                    selectedDateShifts = shiftViewModel.shifts(for: selectedDate)
                    if !selectedDateShifts.isEmpty {
                        showingDateShifts = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet")
                        Text("詳細")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                .disabled(shiftViewModel.shifts(for: selectedDate).isEmpty)
                
                Spacer()
                
                Button {
                    hapticFeedback.impactOccurred()
                    showingAddShift = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("シフト追加")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(workplaceViewModel.workplaces.isEmpty ? Color.gray : Color.blue)
                            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                }
                .disabled(workplaceViewModel.workplaces.isEmpty)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
        .padding(.horizontal, 4)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: selectedDate)
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
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
    
    private var weekdayHeaderView: some View {
        HStack(spacing: 0) {
            ForEach(weekdayHeaders, id: \.self) { weekday in
                Text(weekday)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
        }
        .padding(.horizontal, 20)
        .background(Color(.systemGray6))
    }
    
    private func calendarGridView(geometry: GeometryProxy) -> some View {
        let cellSize = (geometry.size.width - 40) / 7
        
        return ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                ForEach(calendarDays, id: \.self) { date in
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
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedDate = date
                            }
                            selectedDateShifts = shiftViewModel.shifts(for: date)
                            if !selectedDateShifts.isEmpty {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showingDateShifts = true
                                }
                            }
                        }
                    } else {
                        Color.clear
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGray6))
    }
    
    // MARK: - Helper Methods
    
    private var monthlyWorkingHours: Int {
        let monthShifts = shiftViewModel.shifts.filter { shift in
            calendar.isDate(shift.date, equalTo: selectedDate, toGranularity: .month)
        }
        return monthShifts.reduce(0) { $0 + $1.workingMinutes } / 60
    }
    
    private func totalHours(for shifts: [Shift]) -> String {
        let totalMinutes = shifts.reduce(0) { $0 + $1.workingMinutes }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return minutes > 0 ? "\(hours):\(String(format: "%02d", minutes))" : "\(hours)"
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
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var hasOverlap: Bool {
        !overlaps.isEmpty
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Day number
                Text(dayNumber)
                    .font(.system(size: max(16, cellSize * 0.35), weight: isToday ? .bold : .semibold))
                    .foregroundColor(textColor)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                
                // Shift indicators
                VStack(spacing: 2) {
                    ForEach(Array(shifts.prefix(3).enumerated()), id: \.offset) { index, shift in
                        let workplace = workplaces.first { $0.id == shift.workplaceId }
                        RoundedRectangle(cornerRadius: 2)
                            .fill(workplace?.color ?? .gray)
                            .frame(height: max(3, cellSize * 0.04))
                            .scaleEffect(isPressed ? 0.95 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                    }
                    
                    if shifts.count > 3 {
                        Text("+\(shifts.count - 3)")
                            .font(.system(size: max(8, cellSize * 0.15), weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(minHeight: cellSize * 0.25)
                
                Spacer()
                
                // Bottom indicators
                HStack(spacing: 2) {
                    if hasOverlap {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: max(10, cellSize * 0.18)))
                            .foregroundColor(.red)
                    }
                    
                    if isWeekend {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: max(8, cellSize * 0.15)))
                            .foregroundColor(.purple.opacity(0.7))
                    }
                }
                .frame(height: max(12, cellSize * 0.15))
            }
            .frame(width: cellSize, height: cellSize)
            .padding(4)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: min(12, cellSize * 0.2)))
            .overlay(
                RoundedRectangle(cornerRadius: min(12, cellSize * 0.2))
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0, y: shadowOffset
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onLongPressGesture(minimumDuration: 0) { _ in
            // Empty
        } onPressingChanged: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var textColor: Color {
        if isToday {
            return .white
        } else if isSelected {
            return .white
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isToday {
            return .blue
        } else if isSelected {
            return .gray
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
            return .red
        } else if isSelected {
            return .blue
        } else if isToday {
            return .white.opacity(0.3)
        } else {
            return Color(.systemGray4).opacity(0.3)
        }
    }
    
    private var borderWidth: CGFloat {
        if hasOverlap {
            return 2
        } else if isSelected || isToday {
            return 1.5
        } else {
            return 0.5
        }
    }
    
    private var shadowColor: Color {
        if isToday {
            return .blue.opacity(0.4)
        } else if isSelected {
            return .gray.opacity(0.3)
        } else if hasOverlap {
            return .red.opacity(0.2)
        } else {
            return .black.opacity(0.1)
        }
    }
    
    private var shadowRadius: CGFloat {
        if isToday || isSelected {
            return 6
        } else if hasOverlap {
            return 4
        } else {
            return 2
        }
    }
    
    private var shadowOffset: CGFloat {
        if isToday || isSelected {
            return 2
        } else {
            return 1
        }
    }
    
    private var isWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7 // Sunday or Saturday
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
            shiftViewModel.deleteShift(id: sortedShifts[index].id)
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
}