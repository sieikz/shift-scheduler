import Foundation

// 日本の祝日管理サービス
class HolidayService {
    static let shared = HolidayService()
    
    private var holidays: [Date] = []
    private let calendar = Calendar.current
    
    private init() {
        loadHolidays()
    }
    
    /// 指定した日付が祝日かどうかを判定
    func isHoliday(_ date: Date) -> Bool {
        return holidays.contains { holiday in
            calendar.isDate(date, inSameDayAs: holiday)
        }
    }
    
    /// 指定した年の祝日を取得
    func holidaysForYear(_ year: Int) -> [Date] {
        return holidays.filter { holiday in
            calendar.component(.year, from: holiday) == year
        }
    }
    
    /// 祝日データの読み込み
    private func loadHolidays() {
        let currentYear = calendar.component(.year, from: Date())
        
        // 2024年の祝日（実際の実装では外部APIまたはローカルデータベースから取得）
        holidays = generateHolidaysFor(year: currentYear)
        holidays.append(contentsOf: generateHolidaysFor(year: currentYear + 1))
    }
    
    /// 指定した年の祝日を生成（簡易版）
    private func generateHolidaysFor(year: Int) -> [Date] {
        var yearHolidays: [Date] = []
        
        // 固定日の祝日
        let fixedHolidays = [
            (1, 1),   // 元日
            (2, 11),  // 建国記念の日
            (2, 23),  // 天皇誕生日
            (4, 29),  // 昭和の日
            (5, 3),   // 憲法記念日
            (5, 4),   // みどりの日
            (5, 5),   // こどもの日
            (8, 11),  // 山の日
            (11, 3),  // 文化の日
            (11, 23), // 勤労感謝の日
        ]
        
        for (month, day) in fixedHolidays {
            if let holiday = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                yearHolidays.append(holiday)
            }
        }
        
        // 移動祝日（簡易計算）
        // 成人の日（1月第2月曜日）
        if let firstMonday = nthWeekdayOfMonth(year: year, month: 1, weekday: 2, n: 2) {
            yearHolidays.append(firstMonday)
        }
        
        // 海の日（7月第3月曜日）
        if let thirdMonday = nthWeekdayOfMonth(year: year, month: 7, weekday: 2, n: 3) {
            yearHolidays.append(thirdMonday)
        }
        
        // 敬老の日（9月第3月曜日）
        if let thirdMonday = nthWeekdayOfMonth(year: year, month: 9, weekday: 2, n: 3) {
            yearHolidays.append(thirdMonday)
        }
        
        // スポーツの日（10月第2月曜日）
        if let secondMonday = nthWeekdayOfMonth(year: year, month: 10, weekday: 2, n: 2) {
            yearHolidays.append(secondMonday)
        }
        
        // 春分の日・秋分の日は天文計算が必要なため省略
        // 実際の実装では正確な計算またはAPIから取得
        
        return yearHolidays.sorted()
    }
    
    /// 指定した年月のn番目の指定曜日を取得
    private func nthWeekdayOfMonth(year: Int, month: Int, weekday: Int, n: Int) -> Date? {
        guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return nil
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let dayOffset = (weekday - firstWeekday + 7) % 7
        let targetDay = dayOffset + (n - 1) * 7 + 1
        
        return calendar.date(from: DateComponents(year: year, month: month, day: targetDay))
    }
}

// 祝日名を取得する拡張
extension HolidayService {
    /// 指定した日付の祝日名を取得
    func holidayName(for date: Date) -> String? {
        guard isHoliday(date) else { return nil }
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        // 固定祝日の名前
        let fixedHolidayNames: [String: String] = [
            "1-1": "元日",
            "2-11": "建国記念の日",
            "2-23": "天皇誕生日",
            "4-29": "昭和の日",
            "5-3": "憲法記念日",
            "5-4": "みどりの日",
            "5-5": "こどもの日",
            "8-11": "山の日",
            "11-3": "文化の日",
            "11-23": "勤労感謝の日"
        ]
        
        let key = "\(month)-\(day)"
        if let name = fixedHolidayNames[key] {
            return name
        }
        
        // 移動祝日の判定
        if month == 1, let secondMonday = nthWeekdayOfMonth(year: year, month: 1, weekday: 2, n: 2),
           calendar.isDate(date, inSameDayAs: secondMonday) {
            return "成人の日"
        }
        
        if month == 7, let thirdMonday = nthWeekdayOfMonth(year: year, month: 7, weekday: 2, n: 3),
           calendar.isDate(date, inSameDayAs: thirdMonday) {
            return "海の日"
        }
        
        if month == 9, let thirdMonday = nthWeekdayOfMonth(year: year, month: 9, weekday: 2, n: 3),
           calendar.isDate(date, inSameDayAs: thirdMonday) {
            return "敬老の日"
        }
        
        if month == 10, let secondMonday = nthWeekdayOfMonth(year: year, month: 10, weekday: 2, n: 2),
           calendar.isDate(date, inSameDayAs: secondMonday) {
            return "スポーツの日"
        }
        
        return "祝日"
    }
}