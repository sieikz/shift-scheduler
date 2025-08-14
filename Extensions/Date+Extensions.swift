import Foundation

extension Date {
    /// 日本語の曜日名を取得
    var japaneseWeekdayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }
    
    /// 月日の形式で文字列を取得
    var monthDayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: self)
    }
    
    /// 月日曜日の形式で文字列を取得
    var monthDayWeekdayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: self)
    }
    
    /// 時間のみの文字列を取得
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// 同じ日かどうかを判定
    func isSameDay(as date: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    /// 月の開始日を取得
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// 月の終了日を取得
    var endOfMonth: Date {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: self)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return self
        }
        return endOfMonth
    }
    
    /// 週の開始日を取得（日曜日始まり）
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// 指定した時刻に設定した日付を取得
    func settingTime(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: self) ?? self
    }
    
    /// 営業日かどうかを判定（土日以外）
    var isWorkday: Bool {
        let weekday = Calendar.current.component(.weekday, from: self)
        return weekday != 1 && weekday != 7 // 1=日曜日, 7=土曜日
    }
    
    /// 深夜時間帯かどうかを判定（22:00-5:00）
    var isNightTime: Bool {
        let hour = Calendar.current.component(.hour, from: self)
        return hour >= 22 || hour < 5
    }
}

extension Calendar {
    /// 2つの日付の間の日数を計算
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let components = dateComponents([.day], from: from, to: to)
        return components.day ?? 0
    }
    
    /// 指定した月の日数を取得
    func numberOfDaysInMonth(for date: Date) -> Int {
        let range = range(of: .day, in: .month, for: date)
        return range?.count ?? 0
    }
}