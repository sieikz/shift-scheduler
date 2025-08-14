import Foundation
import SwiftUI
import CoreData
import Combine

// シフト管理用のViewModel
class ShiftViewModel: ObservableObject {
    @Published var shifts: [Shift] = []
    @Published var currentMonthShifts: [Shift] = []
    @Published var todayShifts: [Shift] = []
    @Published var tomorrowShifts: [Shift] = []
    @Published var selectedDate = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let persistenceController = PersistenceController.shared
    private let calendar = Calendar.current
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchShifts()
        updateDateBasedShifts()
        
        // 日付変更の監視
        $selectedDate
            .sink { [weak self] _ in
                self?.updateCurrentMonthShifts()
            }
            .store(in: &cancellables)
        
        // PersistenceControllerからの変更を監視
        persistenceController.$shifts
            .sink { [weak self] newShifts in
                self?.shifts = newShifts
                self?.updateDateBasedShifts()
            }
            .store(in: &cancellables)
    }
    
    // シフト一覧の取得
    func fetchShifts() {
        persistenceController.fetchShifts()
        shifts = persistenceController.shifts
        updateDateBasedShifts()
    }
    
    // 日付ベースのシフト更新
    private func updateDateBasedShifts() {
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        
        todayShifts = shifts.filter { calendar.isDate($0.date, inSameDayAs: today) }
        tomorrowShifts = shifts.filter { calendar.isDate($0.date, inSameDayAs: tomorrow) }
        updateCurrentMonthShifts()
    }
    
    // 現在月のシフト更新
    private func updateCurrentMonthShifts() {
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.end ?? selectedDate
        
        currentMonthShifts = shifts.filter { shift in
            shift.date >= startOfMonth && shift.date < endOfMonth
        }
    }
    
    // シフトの追加
    func addShift(workplaceId: UUID, date: Date, startTime: Date, endTime: Date,
                 breakMinutes: Int = 0, memo: String? = nil,
                 isRecurring: Bool = false, recurringType: RecurringType? = nil,
                 recurringEndDate: Date? = nil) {
        let shift = Shift(
            workplaceId: workplaceId,
            date: date,
            startTime: startTime,
            endTime: endTime,
            breakMinutes: breakMinutes,
            memo: memo ?? ""
        )
        
        persistenceController.addShift(shift)
    }
    
    // シフトの更新
    func updateShift(_ shift: Shift) {
        persistenceController.updateShift(shift)
    }
    
    // シフトの削除
    func deleteShift(_ shift: Shift) {
        persistenceController.deleteShift(shift)
    }
    
    // 指定日のシフト取得
    func shifts(for date: Date) -> [Shift] {
        return shifts.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    // 指定期間のシフト取得
    func shifts(from startDate: Date, to endDate: Date) -> [Shift] {
        return shifts.filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    // 職場IDでフィルタ
    func shifts(for workplaceId: UUID) -> [Shift] {
        return shifts.filter { $0.workplaceId == workplaceId }
    }
    
    // シフト重複チェック
    func checkOverlaps(workplaces: [Workplace]) -> [ShiftOverlap] {
        var overlaps: [ShiftOverlap] = []
        
        for i in 0..<shifts.count {
            for j in (i+1)..<shifts.count {
                let shift1 = shifts[i]
                let shift2 = shifts[j]
                
                // 同じ日のシフトのみチェック
                guard calendar.isDate(shift1.date, inSameDayAs: shift2.date) else { continue }
                
                // 移動時間を考慮
                let workplace1 = workplaces.first { $0.id == shift1.workplaceId }
                let travelTime = workplace1?.travelTimeMinutes ?? 0
                
                let overlap = ShiftOverlap(shift1: shift1, shift2: shift2, travelTimeMinutes: travelTime)
                if overlap.hasConflict {
                    overlaps.append(overlap)
                }
            }
        }
        
        return overlaps
    }
    
    // 指定日の重複チェック
    func hasOverlap(on date: Date, excluding shiftId: UUID? = nil, workplaces: [Workplace]) -> [ShiftOverlap] {
        let dayShifts = shifts(for: date).filter { $0.id != shiftId }
        var overlaps: [ShiftOverlap] = []
        
        for i in 0..<dayShifts.count {
            for j in (i+1)..<dayShifts.count {
                let shift1 = dayShifts[i]
                let shift2 = dayShifts[j]
                
                let workplace1 = workplaces.first { $0.id == shift1.workplaceId }
                let travelTime = workplace1?.travelTimeMinutes ?? 0
                
                let overlap = ShiftOverlap(shift1: shift1, shift2: shift2, travelTimeMinutes: travelTime)
                if overlap.hasConflict {
                    overlaps.append(overlap)
                }
            }
        }
        
        return overlaps
    }
    
    // 新規シフトとの重複チェック
    func wouldOverlap(workplaceId: UUID, date: Date, startTime: Date, endTime: Date,
                     workplaces: [Workplace], excluding shiftId: UUID? = nil) -> [ShiftOverlap] {
        let newShift = Shift(workplaceId: workplaceId, date: date, startTime: startTime, endTime: endTime)
        let dayShifts = shifts(for: date).filter { $0.id != shiftId }
        
        var overlaps: [ShiftOverlap] = []
        
        for existingShift in dayShifts {
            let workplace = workplaces.first { $0.id == newShift.workplaceId }
            let travelTime = workplace?.travelTimeMinutes ?? 0
            
            let overlap = ShiftOverlap(shift1: newShift, shift2: existingShift, travelTimeMinutes: travelTime)
            if overlap.hasConflict {
                overlaps.append(overlap)
            }
        }
        
        return overlaps
    }
    
    // 月間統計の計算
    func monthlyStats(for date: Date, workplaces: [Workplace]) -> MonthlyStats {
        let monthShifts = currentMonthShifts
        
        var totalWorkingMinutes = 0
        var totalEarnings = 0
        var workplaceStats: [UUID: WorkplaceStats] = [:]
        
        for shift in monthShifts {
            guard let workplace = workplaces.first(where: { $0.id == shift.workplaceId }) else { continue }
            
            let workingMinutes = shift.workingMinutes
            totalWorkingMinutes += workingMinutes
            
            // 基本給与計算
            let baseEarnings = Int(Double(workingMinutes) * workplace.hourlyWage / 60.0)
            
            // 深夜手当
            let nightMinutes = shift.nightWorkingMinutes()
            let nightEarnings = Int(Double(nightMinutes) * workplace.hourlyWage * (workplace.nightShiftRate - 1.0) / 60.0)
            
            // 休日手当（日本の一般的な35%増）
            let holidayEarnings = shift.isHoliday() ? Int(Double(workingMinutes) * workplace.hourlyWage * 0.35 / 60.0) : 0
            
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
            totalShifts: monthShifts.count,
            totalWorkingMinutes: totalWorkingMinutes,
            totalEarnings: totalEarnings,
            workplaceStats: Array(workplaceStats.values)
        )
    }
    
    // バリデーション
    func validateShift(workplaceId: UUID?, date: Date?, startTime: Date?, endTime: Date?) -> String? {
        guard workplaceId != nil else {
            return "職場を選択してください"
        }
        
        guard date != nil else {
            return "日付を選択してください"
        }
        
        guard let start = startTime, let end = endTime else {
            return "開始時刻と終了時刻を設定してください"
        }
        
        if start >= end {
            return "終了時刻は開始時刻より後に設定してください"
        }
        
        // 24時間を超えるシフトのチェック
        let duration = calendar.dateComponents([.hour], from: start, to: end).hour ?? 0
        if duration > 24 {
            return "シフト時間が24時間を超えています"
        }
        
        return nil
    }
}

