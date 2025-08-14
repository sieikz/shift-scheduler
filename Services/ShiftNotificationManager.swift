//
//  ShiftNotificationManager.swift
//  shift scheduler
//
//  Enhanced notification manager for individual shift reminders
//

import Foundation
import UserNotifications
import CoreData
import UIKit

class ShiftNotificationManager: ObservableObject {
    static let shared = ShiftNotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {}
    
    // MARK: - Permission Management
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission error: \(error)")
                }
                completion(granted)
            }
        }
    }
    
    func checkPermissionStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    // MARK: - Individual Shift Notifications
    
    func scheduleShiftReminder(for shift: Shift, workplace: Workplace, hoursBeforeArray: [Int] = [24, 1]) {
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }
        
        for hoursBefore in hoursBeforeArray {
            let notificationDate = Calendar.current.date(byAdding: .hour, value: -hoursBefore, to: shift.startTime)
            
            guard let notificationDate = notificationDate, notificationDate > Date() else {
                continue // Skip past notifications
            }
            
            let content = createShiftNotificationContent(shift: shift, workplace: workplace, hoursBefore: hoursBefore)
            let identifier = "shift-\(shift.id.uuidString)-\(hoursBefore)h"
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate),
                repeats: false
            )
            
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule notification for shift \(shift.id): \(error)")
                }
            }
        }
    }
    
    private func createShiftNotificationContent(shift: Shift, workplace: Workplace, hoursBefore: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        // タイトルと本文の設定
        switch hoursBefore {
        case 24:
            content.title = "明日のシフトリマインダー"
            content.body = "\(workplace.name) - \(shift.timeDisplay)"
        case 1:
            content.title = "まもなくシフト開始"
            content.body = "\(workplace.name) - \(shift.timeDisplay) (1時間後に開始)"
        default:
            content.title = "シフトリマインダー"
            content.body = "\(workplace.name) - \(shift.timeDisplay) (\(hoursBefore)時間後に開始)"
        }
        
        // 追加情報
        if let memo = shift.memo, !memo.isEmpty {
            content.body += "\nメモ: \(memo)"
        }
        
        // 深夜手当・休日手当の表示
        var badges: [String] = []
        if shift.isNightShift {
            badges.append("深夜手当")
        }
        if shift.isHoliday() {
            badges.append("休日手当")
        }
        
        if !badges.isEmpty {
            content.body += "\n\(badges.joined(separator: "・"))"
        }
        
        content.sound = .default
        content.badge = 1
        
        // カテゴリ設定（アクション追加用）
        content.categoryIdentifier = "SHIFT_REMINDER"
        
        // ユーザー情報に職場色情報などを追加
        content.userInfo = [
            "shiftId": shift.id.uuidString,
            "workplaceId": shift.workplaceId.uuidString,
            "workplaceName": workplace.name,
            "startTime": shift.startTime.timeIntervalSince1970,
            "hoursBefore": hoursBefore
        ]
        
        return content
    }
    
    // MARK: - Notification Management
    
    func removeShiftNotifications(for shiftId: UUID) {
        let identifierPatterns = [
            "shift-\(shiftId.uuidString)-24h",
            "shift-\(shiftId.uuidString)-1h",
            "shift-\(shiftId.uuidString)-3h",
            "shift-\(shiftId.uuidString)-6h",
            "shift-\(shiftId.uuidString)-12h"
        ]
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifierPatterns)
    }
    
    func removeAllShiftNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            let shiftNotificationIds = requests
                .filter { $0.identifier.starts(with: "shift-") }
                .map { $0.identifier }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: shiftNotificationIds)
        }
    }
    
    func updateNotificationsForAllShifts(shifts: [Shift], workplaces: [Workplace]) {
        // 既存の通知を削除
        removeAllShiftNotifications()
        
        // 新しい通知をスケジュール
        for shift in shifts {
            if let workplace = workplaces.first(where: { $0.id == shift.workplaceId }) {
                let reminderHours = getUserReminderSettings()
                scheduleShiftReminder(for: shift, workplace: workplace, hoursBeforeArray: reminderHours)
            }
        }
    }
    
    private func getUserReminderSettings() -> [Int] {
        let defaults = UserDefaults.standard
        let primaryReminder = defaults.integer(forKey: "reminderHoursBefore") == 0 ? 24 : defaults.integer(forKey: "reminderHoursBefore")
        
        // デフォルトでは選択されたリマインダー + 1時間前通知
        var reminders = [primaryReminder]
        
        // 1時間前通知が別途設定されている場合は追加
        if primaryReminder != 1 && defaults.bool(forKey: "oneHourReminderEnabled") {
            reminders.append(1)
        }
        
        return reminders
    }
    
    // MARK: - Daily Summary Notifications
    
    func scheduleDailyReminder(at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "今日・明日のシフト確認"
        content.body = "シフトまとめで今日と明日のシフトを確認しましょう"
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule daily reminder: \(error)")
            }
        }
    }
    
    func removeDailyReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
    }
    
    // MARK: - Notification Actions Setup
    
    func setupNotificationCategories() {
        // シフト確認アクション
        let confirmAction = UNNotificationAction(
            identifier: "CONFIRM_SHIFT",
            title: "確認済み",
            options: []
        )
        
        // アプリを開くアクション
        let openAppAction = UNNotificationAction(
            identifier: "OPEN_APP",
            title: "アプリを開く",
            options: [.foreground]
        )
        
        // シフトリマインダーカテゴリ
        let shiftReminderCategory = UNNotificationCategory(
            identifier: "SHIFT_REMINDER",
            actions: [confirmAction, openAppAction],
            intentIdentifiers: [],
            options: []
        )
        
        // デイリーリマインダーカテゴリ  
        let dailyReminderCategory = UNNotificationCategory(
            identifier: "DAILY_REMINDER",
            actions: [openAppAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([shiftReminderCategory, dailyReminderCategory])
    }
    
    // MARK: - Conflict Notifications
    
    func scheduleConflictWarning(for shifts: [Shift], workplaces: [Workplace]) {
        guard shifts.count > 1 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "シフト重複警告"
        
        let workplaceNames = shifts.compactMap { shift in
            workplaces.first { $0.id == shift.workplaceId }?.name
        }.joined(separator: "、")
        
        content.body = "\(shifts.first?.date.formatted(date: .abbreviated, time: .omitted) ?? "")に\(workplaceNames)でシフトが重複しています"
        content.sound = .default
        content.categoryIdentifier = "CONFLICT_WARNING"
        
        // 重複している日の1日前に通知
        if let conflictDate = shifts.first?.date,
           let notificationDate = Calendar.current.date(byAdding: .day, value: -1, to: conflictDate),
           let notificationTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: notificationDate),
           notificationTime > Date() {
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime),
                repeats: false
            )
            
            let identifier = "conflict-\(conflictDate.timeIntervalSince1970)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule conflict warning: \(error)")
                }
            }
        }
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        
        // Today and tomorrow shifts count as badge
        // This should be called by the main data manager
        notificationCenter.getDeliveredNotifications { notifications in
            let unreadCount = notifications.count
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = unreadCount
            }
        }
    }
    
    func clearBadgeCount() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    // MARK: - Debugging and Testing
    
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
    
    func printScheduledNotifications() {
        getPendingNotifications { requests in
            print("=== Scheduled Notifications ===")
            for request in requests {
                print("ID: \(request.identifier)")
                print("Title: \(request.content.title)")
                print("Body: \(request.content.body)")
                if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger {
                    print("Next trigger: \(calendarTrigger.nextTriggerDate() ?? Date())")
                }
                print("---")
            }
            print("Total: \(requests.count) notifications")
        }
    }
}

// MARK: - Extensions for Shift and Date formatting

private extension Shift {
    var timeDisplay: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return "\(formatter.string(from: startTime))-\(formatter.string(from: endTime))"
    }
}