import Foundation
import SwiftUI

// 月間統計用の構造体
struct MonthlyStats {
    let totalShifts: Int
    let totalWorkingMinutes: Int
    let totalEarnings: Int
    let workplaceStats: [WorkplaceStats]
    
    var totalWorkingHours: Double {
        return Double(totalWorkingMinutes) / 60.0
    }
    
    init(totalShifts: Int = 0, totalWorkingMinutes: Int = 0, totalEarnings: Int = 0, workplaceStats: [WorkplaceStats] = []) {
        self.totalShifts = totalShifts
        self.totalWorkingMinutes = totalWorkingMinutes
        self.totalEarnings = totalEarnings
        self.workplaceStats = workplaceStats.sorted { $0.earnings > $1.earnings }
    }
}

// 職場別統計用の構造体
struct WorkplaceStats {
    let workplace: Workplace
    var shiftCount: Int
    var workingMinutes: Int
    var earnings: Int
    
    var workingHours: Double {
        return Double(workingMinutes) / 60.0
    }
    
    var averageShiftHours: Double {
        guard shiftCount > 0 else { return 0 }
        return workingHours / Double(shiftCount)
    }
}

// 週別統計
struct WeeklyStats {
    let weekStartDate: Date
    let shifts: [Shift]
    let totalWorkingMinutes: Int
    let totalEarnings: Int
    
    var totalWorkingHours: Double {
        return Double(totalWorkingMinutes) / 60.0
    }
}

// 年間統計
struct YearlyStats {
    let year: Int
    let monthlyStats: [MonthlyStats]
    let totalShifts: Int
    let totalWorkingMinutes: Int
    let totalEarnings: Int
    
    var totalWorkingHours: Double {
        return Double(totalWorkingMinutes) / 60.0
    }
    
    var averageMonthlyEarnings: Double {
        guard !monthlyStats.isEmpty else { return 0 }
        return Double(totalEarnings) / Double(monthlyStats.count)
    }
}