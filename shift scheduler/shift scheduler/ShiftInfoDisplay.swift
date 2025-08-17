import SwiftUI

struct ShiftInfoDisplay: View {
    let selectedDate: Date?
    let shifts: [Shift]
    let workplaces: [Workplace]
    let onTodayTapped: () -> Void
    @StateObject private var shiftViewModel = ShiftViewModel()
    @StateObject private var workplaceViewModel = WorkplaceViewModel()
    @State private var showingAddShift = false
    @State private var showingDeleteAlert = false
    @State private var shiftToDelete: Shift?
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    private var dateString: String {
        guard let date = selectedDate else { return "日付を選択してください" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: date)
    }
    
    private var totalWorkingTime: String {
        let totalMinutes = shifts.reduce(0) { $0 + $1.workingMinutes }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return minutes > 0 ? "\(hours):\(String(format: "%02d", minutes))" : "\(hours)"
    }
    
    private func workplaceColor(for shift: Shift) -> Color {
        workplaces.first { $0.id == shift.workplaceId }?.color ?? .gray
    }
    
    private func workplaceName(for shift: Shift) -> String {
        workplaces.first { $0.id == shift.workplaceId }?.name ?? "不明な職場"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header section with buttons
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(dateString)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if selectedDate == nil {
                        Text("カレンダーから日付を選択してください")
                            .font(.body)
                            .foregroundColor(.secondary)
                    } else if shifts.isEmpty {
                        HStack {
                            Image(systemName: "moon.zzz")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            Text("お休み")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Image(systemName: "briefcase.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                            Text("\(shifts.count)件のシフト・\(totalWorkingTime)時間")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Today button
                    Button {
                        hapticFeedback.impactOccurred()
                        onTodayTapped()
                    } label: {
                        Text("今日")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.blue)
                                    .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 1)
                            )
                    }
                    
                    // Add shift button
                    Button {
                        hapticFeedback.impactOccurred()
                        showingAddShift = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(workplaceViewModel.workplaces.isEmpty ? Color.gray : Color.blue)
                                    .shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 2)
                            )
                    }
                    .disabled(workplaceViewModel.workplaces.isEmpty)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Shift details section
            if !shifts.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(shifts.sorted { $0.startTime < $1.startTime }) { shift in
                            ShiftDetailCard(
                                shift: shift,
                                workplaceName: workplaceName(for: shift),
                                workplaceColor: workplaceColor(for: shift),
                                workplaces: workplaces,
                                shiftViewModel: shiftViewModel,
                                onDelete: {
                                    shiftToDelete = shift
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingAddShift) {
            if let date = selectedDate {
                AddShiftView(
                    selectedDate: date,
                    workplaces: workplaces,
                    shiftViewModel: shiftViewModel
                )
            }
        }
        .alert("シフト削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                if let shift = shiftToDelete {
                    shiftViewModel.deleteShift(shift)
                    shiftToDelete = nil
                }
            }
            Button("キャンセル", role: .cancel) {
                shiftToDelete = nil
            }
        } message: {
            if let shift = shiftToDelete {
                Text("\(workplaceName(for: shift))のシフトを削除しますか？")
            }
        }
    }
}

struct ShiftDetailCard: View {
    let shift: Shift
    let workplaceName: String
    let workplaceColor: Color
    let workplaces: [Workplace]
    let shiftViewModel: ShiftViewModel
    let onDelete: () -> Void
    
    @State private var showingEditSheet = false
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: shift.startTime) + " - " + formatter.string(from: shift.endTime)
    }
    
    private var workingTime: String {
        let hours = shift.workingMinutes / 60
        let minutes = shift.workingMinutes % 60
        if minutes == 0 {
            return "\(hours)時間"
        } else {
            return "\(hours)時間\(minutes)分"
        }
    }
    
    private var breakTime: String {
        if shift.breakMinutes == 0 {
            return "休憩なし"
        } else {
            let hours = shift.breakMinutes / 60
            let minutes = shift.breakMinutes % 60
            if hours == 0 {
                return "休憩\(minutes)分"
            } else if minutes == 0 {
                return "休憩\(hours)時間"
            } else {
                return "休憩\(hours)時間\(minutes)分"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Workplace header
            HStack {
                Circle()
                    .fill(workplaceColor)
                    .frame(width: 12, height: 12)
                
                Text(workplaceName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    if shift.isNightShift {
                        HStack(spacing: 4) {
                            Image(systemName: "moon.fill")
                                .font(.caption)
                                .foregroundColor(.indigo)
                            Text("深夜")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.indigo)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.indigo.opacity(0.1))
                        )
                    }
                    
                    
                    // Edit button
                    Button {
                        showingEditSheet = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    
                    // Delete button
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color.red.opacity(0.1))
                            )
                    }
                }
            }
            
            // Time and details
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "clock")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(timeString)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Image(systemName: "timer")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            Text(workingTime)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack {
                            Image(systemName: "pause.circle")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(breakTime)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if shift.isHoliday() {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("休日")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                if let memo = shift.memo, !memo.isEmpty {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(memo)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .sheet(isPresented: $showingEditSheet) {
            EditShiftView(
                shift: shift,
                workplaces: workplaces,
                shiftViewModel: shiftViewModel
            ) {
                // onDismiss
            }
        }
    }
}

struct ShiftCompactCard: View {
    let shift: Shift
    let workplaceName: String
    let workplaceColor: Color
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: shift.startTime) + " - " + formatter.string(from: shift.endTime)
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
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Circle()
                    .fill(workplaceColor)
                    .frame(width: 6, height: 6)
                
                Text(workplaceName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            
            Text(timeString)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(workingTime)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    let sampleWorkplace = Workplace(
        id: UUID(),
        name: "サンプル職場",
        color: .blue,
        hourlyWage: 1000,
        transportationAllowance: 200,
        createdAt: Date()
    )
    
    let sampleShift = Shift(
        workplaceId: sampleWorkplace.id,
        date: Date(),
        startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
        endTime: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date(),
        breakMinutes: 60
    )
    
    ShiftInfoDisplay(
        selectedDate: Date(),
        shifts: [sampleShift],
        workplaces: [sampleWorkplace],
        onTodayTapped: {}
    )
    .frame(height: 400)
}