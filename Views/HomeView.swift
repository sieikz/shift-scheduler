import SwiftUI

struct HomeView: View {
    @StateObject private var shiftViewModel = ShiftViewModel()
    @StateObject private var workplaceViewModel = WorkplaceViewModel()
    @State private var showingAddShift = false
    
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: Date())
    }
    
    private var tomorrowString: String {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: tomorrow)
    }
    
    private var monthlyStats: MonthlyStats {
        shiftViewModel.monthlyStats(for: Date(), workplaces: workplaceViewModel.workplaces)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 月間収入サマリー
                    monthlyStatsSection
                    
                    // 今日のシフト
                    todayShiftsSection
                    
                    // 明日のシフト
                    tomorrowShiftsSection
                    
                    // 重複警告
                    if !overlaps.isEmpty {
                        overlapWarningSection
                    }
                    
                    // クイックアクション
                    quickActionsSection
                }
                .padding()
            }
            .refreshable {
                shiftViewModel.fetchShifts()
                workplaceViewModel.fetchWorkplaces()
            }
            .navigationTitle("ホーム")
            .sheet(isPresented: $showingAddShift) {
                if !workplaceViewModel.workplaces.isEmpty {
                    AddShiftView(
                        selectedDate: Date(),
                        workplaces: workplaceViewModel.workplaces,
                        shiftViewModel: shiftViewModel
                    )
                }
            }
        }
    }
    
    private var monthlyStatsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "yensign.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("今月の収入")
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("予想収入")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("¥\(monthlyStats.totalEarnings)")
                        .font(.title)
                        .bold()
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("勤務時間")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(monthlyStats.totalWorkingHours, specifier: "%.1f")h")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("シフト数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(monthlyStats.totalShifts)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.orange)
                }
            }
            
            // 職場別内訳（上位3つまで）
            if !monthlyStats.workplaceStats.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                    
                    HStack {
                        Text("職場別内訳")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    ForEach(Array(monthlyStats.workplaceStats.prefix(3).enumerated()), id: \.offset) { index, stat in
                        HStack {
                            Circle()
                                .fill(stat.workplace.color)
                                .frame(width: 8, height: 8)
                            Text(stat.workplace.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("¥\(stat.earnings)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if monthlyStats.workplaceStats.count > 3 {
                        Text("他\(monthlyStats.workplaceStats.count - 3)件")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var todayShiftsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("今日のシフト (\(todayString))")
                    .font(.headline)
                Spacer()
                
                if !shiftViewModel.todayShifts.isEmpty {
                    Text("\(shiftViewModel.todayShifts.count)件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
            }
            
            if shiftViewModel.todayShifts.isEmpty {
                VStack {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                    Text("今日はお休みです")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(shiftViewModel.todayShifts) { shift in
                    ShiftCardView(shift: shift, 
                                workplace: workplaceViewModel.workplace(for: shift.workplaceId),
                                isToday: true)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var tomorrowShiftsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("明日のシフト (\(tomorrowString))")
                    .font(.headline)
                Spacer()
                
                if !shiftViewModel.tomorrowShifts.isEmpty {
                    Text("\(shiftViewModel.tomorrowShifts.count)件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
            }
            
            if shiftViewModel.tomorrowShifts.isEmpty {
                VStack {
                    Image(systemName: "bed.double")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                    Text("明日もお休みです")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(shiftViewModel.tomorrowShifts) { shift in
                    ShiftCardView(shift: shift, 
                                workplace: workplaceViewModel.workplace(for: shift.workplaceId),
                                isToday: false)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var overlaps: [ShiftOverlap] {
        shiftViewModel.checkOverlaps(workplaces: workplaceViewModel.workplaces)
            .filter { overlap in
                Calendar.current.isDate(overlap.shift1.date, inSameDayAs: Date()) ||
                Calendar.current.isDate(overlap.shift1.date, inSameDayAs: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
            }
    }
    
    private var overlapWarningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                Text("シフト重複警告")
                    .font(.headline)
                    .foregroundColor(.red)
                Spacer()
            }
            
            ForEach(Array(overlaps.enumerated()), id: \.offset) { _, overlap in
                OverlapWarningView(overlap: overlap, workplaces: workplaceViewModel.workplaces)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("クイックアクション")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button {
                    showingAddShift = true
                } label: {
                    VStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                        Text("シフト追加")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .disabled(workplaceViewModel.workplaces.isEmpty)
                
                NavigationLink(destination: CalendarView()) {
                    VStack {
                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.orange)
                        Text("カレンダー")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                NavigationLink(destination: WorkplaceListView()) {
                    VStack {
                        Image(systemName: "building.2.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.green)
                        Text("職場管理")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            if workplaceViewModel.workplaces.isEmpty {
                VStack(spacing: 8) {
                    Divider()
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("まずは職場を追加してからシフトを登録しましょう")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// シフトカードビュー
struct ShiftCardView: View {
    let shift: Shift
    let workplace: Workplace?
    let isToday: Bool
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private var workingHours: String {
        let hours = shift.workingMinutes / 60
        let minutes = shift.workingMinutes % 60
        if minutes == 0 {
            return "\(hours)時間"
        } else {
            return "\(hours)時間\(minutes)分"
        }
    }
    
    var body: some View {
        HStack {
            // 職場色インジケーター
            Rectangle()
                .fill(workplace?.color ?? .gray)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(workplace?.name ?? "不明な職場")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
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
                
                HStack {
                    Text("\(timeFormatter.string(from: shift.startTime)) - \(timeFormatter.string(from: shift.endTime))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(workingHours)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
                
                if let memo = shift.memo, !memo.isEmpty {
                    Text(memo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.leading, 8)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

// 重複警告ビュー
struct OverlapWarningView: View {
    let overlap: ShiftOverlap
    let workplaces: [Workplace]
    
    private var workplace1: Workplace? {
        workplaces.first { $0.id == overlap.shift1.workplaceId }
    }
    
    private var workplace2: Workplace? {
        workplaces.first { $0.id == overlap.shift2.workplaceId }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("重複: \(overlap.overlapMinutes)分間")
                    .font(.caption)
                    .foregroundColor(.red)
                    .bold()
                Spacer()
            }
            
            HStack {
                Circle()
                    .fill(workplace1?.color ?? .gray)
                    .frame(width: 8, height: 8)
                Text(workplace1?.name ?? "不明")
                    .font(.caption)
                Text("\(timeFormatter.string(from: overlap.shift1.startTime))-\(timeFormatter.string(from: overlap.shift1.endTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Circle()
                    .fill(workplace2?.color ?? .gray)
                    .frame(width: 8, height: 8)
                Text(workplace2?.name ?? "不明")
                    .font(.caption)
                Text("\(timeFormatter.string(from: overlap.shift2.startTime))-\(timeFormatter.string(from: overlap.shift2.endTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}