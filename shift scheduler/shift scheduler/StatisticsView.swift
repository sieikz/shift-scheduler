import SwiftUI

struct StatisticsView: View {
    @StateObject private var shiftViewModel = ShiftViewModel()
    @StateObject private var workplaceViewModel = WorkplaceViewModel()
    @State private var selectedTimeRange: TimeRange = .thisMonth
    @State private var selectedDate = Date()
    
    private var selectedRangeStats: MonthlyStats {
        let (startDate, endDate) = selectedTimeRange.dateRange(from: selectedDate)
        let shifts = shiftViewModel.shifts(from: startDate, to: endDate)
        return calculateStats(for: shifts)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 期間選択
                    timeRangePicker
                    
                    // 収入サマリー
                    earningsSummaryCard
                    
                    // 月別収入チャート
                    // Chart functionality disabled for now
                    
                    // 職場別統計
                    workplaceStatsSection
                    
                    // 勤務パターン分析
                    workPatternSection
                }
                .padding()
            }
            .refreshable {
                shiftViewModel.fetchShifts()
                workplaceViewModel.fetchWorkplaces()
            }
            .navigationTitle("")
        }
        .onChange(of: selectedTimeRange) {
            updateStats()
        }
    }
    
    private var timeRangePicker: some View {
        Picker("期間", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases) { range in
                Text(range.displayName).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var earningsSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("\(selectedTimeRange.displayName)の収入")
                    .font(.headline)
                Spacer()
            }
            
            HStack(alignment: .top, spacing: 30) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("総収入")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("¥\(selectedRangeStats.totalEarnings)")
                        .font(.title)
                        .bold()
                        .foregroundColor(.green)
                    
                    if selectedTimeRange == .thisMonth {
                        let dailyAverage = selectedRangeStats.totalEarnings / max(1, Calendar.current.component(.day, from: Date()))
                        Text("日平均: ¥\(dailyAverage)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("勤務時間")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(selectedRangeStats.totalWorkingHours, specifier: "%.1f")h")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.blue)
                    
                    Text("シフト数: \(selectedRangeStats.totalShifts)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 時給平均
            if selectedRangeStats.totalWorkingMinutes > 0 {
                let averageHourlyRate = Double(selectedRangeStats.totalEarnings) / (Double(selectedRangeStats.totalWorkingMinutes) / 60.0)
                
                HStack {
                    Text("平均時給")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("¥\(averageHourlyRate, specifier: "%.0f")")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.orange)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var monthlyEarningsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("月別収入推移")
                    .font(.headline)
                Spacer()
            }
            
            VStack {
                Image(systemName: "chart.bar")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text("チャート機能は現在無効です")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var workplaceStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("職場別統計")
                    .font(.headline)
                Spacer()
            }
            
            if selectedRangeStats.workplaceStats.isEmpty {
                VStack {
                    Image(systemName: "building.2")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("データがありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(selectedRangeStats.workplaceStats.sorted { $0.earnings > $1.earnings }) { stats in
                    WorkplaceStatsRowView(stats: stats, totalEarnings: selectedRangeStats.totalEarnings)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var workPatternSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("勤務パターン分析")
                    .font(.headline)
                Spacer()
            }
            
            let patterns = analyzeWorkPatterns()
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("最も忙しい曜日")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(patterns.busiestWeekday)
                            .font(.subheadline)
                            .bold()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("平均勤務時間/日")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(patterns.averageHoursPerDay, specifier: "%.1f")h")
                            .font(.subheadline)
                            .bold()
                    }
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("深夜勤務率")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(patterns.nightShiftRate, specifier: "%.1f")%")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.indigo)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("休日勤務率")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(patterns.holidayWorkRate, specifier: "%.1f")%")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // Chart data temporarily removed due to Charts framework dependency
    
    private func calculateStats(for shifts: [Shift]) -> MonthlyStats {
        var totalWorkingMinutes = 0
        var totalEarnings = 0
        var workplaceStats: [UUID: WorkplaceStats] = [:]
        
        for shift in shifts {
            guard let workplace = workplaceViewModel.workplaces.first(where: { $0.id == shift.workplaceId }) else { continue }
            
            let workingMinutes = shift.workingMinutes
            totalWorkingMinutes += workingMinutes
            
            // 基本給与計算
            let baseEarnings = Int(Double(workingMinutes) * workplace.hourlyWage / 60)
            
            // 深夜手当
            let nightMinutes = shift.nightWorkingMinutes()
            let nightHourlyWage = Double(nightMinutes) * workplace.hourlyWage / 60
            let nightEarnings = Int(nightHourlyWage * (workplace.nightShiftRate - 1.0))
            
            // 休日手当
            let holidayHourlyWage = Double(workingMinutes) * workplace.hourlyWage / 60
            let holidayEarnings = shift.isHoliday() ? Int(holidayHourlyWage * (workplace.holidayRate - 1.0)) : 0
            
            let shiftEarnings = baseEarnings + nightEarnings + holidayEarnings + Int(workplace.transportationAllowance)
            totalEarnings += shiftEarnings
            
            // 職場別統計
            if workplaceStats[workplace.id] == nil {
                workplaceStats[workplace.id] = WorkplaceStats(
                    workplace: workplace,
                    shiftCount: 0,
                    workingMinutes: 0,
                    earnings: 0
                )
            }
            
            workplaceStats[workplace.id]!.shiftCount += 1
            workplaceStats[workplace.id]!.workingMinutes += workingMinutes
            workplaceStats[workplace.id]!.earnings += shiftEarnings
        }
        
        return MonthlyStats(
            totalShifts: shifts.count,
            totalWorkingMinutes: totalWorkingMinutes,
            totalEarnings: totalEarnings,
            workplaceStats: Array(workplaceStats.values)
        )
    }
    
    private func analyzeWorkPatterns() -> WorkPattern {
        let (startDate, endDate) = selectedTimeRange.dateRange(from: selectedDate)
        let shifts = shiftViewModel.shifts(from: startDate, to: endDate)
        
        if shifts.isEmpty {
            return WorkPattern(
                busiestWeekday: "データなし",
                averageHoursPerDay: 0,
                nightShiftRate: 0,
                holidayWorkRate: 0
            )
        }
        
        let calendar = Calendar.current
        var weekdayShifts: [Int: Int] = [:]
        var nightShifts = 0
        var holidayShifts = 0
        
        for shift in shifts {
            let weekday = calendar.component(.weekday, from: shift.date)
            weekdayShifts[weekday, default: 0] += 1
            
            if shift.isNightShift {
                nightShifts += 1
            }
            
            if shift.isHoliday() {
                holidayShifts += 1
            }
        }
        
        let busiestWeekday = weekdayShifts.max { $0.value < $1.value }?.key ?? 1
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale(identifier: "ja_JP")
        let weekdayNames = weekdayFormatter.weekdaySymbols!
        
        let daysDifference = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        let averageHoursPerDay = selectedRangeStats.totalWorkingHours / Double(max(1, daysDifference))
        
        let nightShiftRate = Double(nightShifts) / Double(shifts.count) * 100
        let holidayWorkRate = Double(holidayShifts) / Double(shifts.count) * 100
        
        return WorkPattern(
            busiestWeekday: weekdayNames[busiestWeekday - 1],
            averageHoursPerDay: averageHoursPerDay,
            nightShiftRate: nightShiftRate,
            holidayWorkRate: holidayWorkRate
        )
    }
    
    private func updateStats() {
        // 統計更新のためのフィルタリング処理
    }
}

// 職場統計行ビュー
struct WorkplaceStatsRowView: View {
    let stats: WorkplaceStats
    let totalEarnings: Int
    
    private var percentage: Double {
        guard totalEarnings > 0 else { return 0 }
        return Double(stats.earnings) / Double(totalEarnings) * 100
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(stats.workplace.color)
                    .frame(width: 12, height: 12)
                
                Text(stats.workplace.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("¥\(stats.earnings)")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.green)
            }
            
            HStack {
                Text("\(stats.shiftCount)回 / \(stats.workingHours, specifier: "%.1f")h")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(percentage, specifier: "%.1f")%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 進捗バー
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(stats.workplace.color)
                        .frame(width: geometry.size.width * (percentage / 100))
                    
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
                .frame(height: 4)
                .cornerRadius(2)
            }
            .frame(height: 4)
        }
    }
}

// データ構造
enum TimeRange: String, CaseIterable, Identifiable {
    case thisWeek = "thisWeek"
    case thisMonth = "thisMonth"
    case lastMonth = "lastMonth"
    case last3Months = "last3Months"
    case last6Months = "last6Months"
    case thisYear = "thisYear"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .thisWeek: return "今週"
        case .thisMonth: return "今月"
        case .lastMonth: return "先月"
        case .last3Months: return "過去3ヶ月"
        case .last6Months: return "過去6ヶ月"
        case .thisYear: return "今年"
        }
    }
    
    func dateRange(from date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = date
        
        switch self {
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? now
            return (startOfWeek, endOfWeek)
            
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
            return (startOfMonth, endOfMonth)
            
        case .lastMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            let startOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.start ?? now
            let endOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.end ?? now
            return (startOfLastMonth, endOfLastMonth)
            
        case .last3Months:
            let start = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            return (start, now)
            
        case .last6Months:
            let start = calendar.date(byAdding: .month, value: -6, to: now) ?? now
            return (start, now)
            
        case .thisYear:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let endOfYear = calendar.dateInterval(of: .year, for: now)?.end ?? now
            return (startOfYear, endOfYear)
        }
    }
}

struct MonthlyEarning: Identifiable {
    let id = UUID()
    let month: String
    let earnings: Int
}

struct WorkPattern {
    let busiestWeekday: String
    let averageHoursPerDay: Double
    let nightShiftRate: Double
    let holidayWorkRate: Double
}

extension WorkplaceStats: Identifiable {
    var id: UUID { workplace.id }
}

#Preview {
    StatisticsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}