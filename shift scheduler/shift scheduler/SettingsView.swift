import SwiftUI
import UserNotifications
import CoreData

struct SettingsView: View {
    @StateObject private var notificationManager = ShiftNotificationManager.shared
    @State private var showingAbout = false
    
    // 通知設定
    @State private var notificationsEnabled = false
    @State private var reminderHoursBefore = 24
    @State private var oneHourReminderEnabled = true
    @State private var dailyReminderTime = Date()
    
    // 表示設定
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled = false
    @AppStorage("startWeekOnSunday") private var startWeekOnSunday = true
    
    
    var body: some View {
        NavigationView {
            Form {
                // 通知設定
                notificationSection
                
                // 表示設定
                displaySection
                
                // アプリ情報
                appInfoSection
                
            }
            .navigationTitle("設定")
        }
        .onAppear {
            DispatchQueue.main.async {
                loadSettings()
            }
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    private var notificationSection: some View {
        Section {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Toggle("通知を有効にする", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { enabled in
                        DispatchQueue.main.async {
                            if enabled {
                                requestNotificationPermission()
                            } else {
                                notificationManager.disableNotifications()
                            }
                            saveSettings()
                        }
                    }
            }
            
            if notificationsEnabled {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    Text("事前通知")
                    
                    Spacer()
                    
                    Picker("通知タイミング", selection: $reminderHoursBefore) {
                        Text("1時間前").tag(1)
                        Text("3時間前").tag(3)
                        Text("6時間前").tag(6)
                        Text("12時間前").tag(12)
                        Text("1日前").tag(24)
                        Text("2日前").tag(48)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: reminderHoursBefore) { _ in
                        DispatchQueue.main.async {
                            refreshNotifications()
                            saveSettings()
                        }
                    }
                }
                
                if reminderHoursBefore != 1 {
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        Toggle("1時間前にも通知", isOn: $oneHourReminderEnabled)
                            .onChange(of: oneHourReminderEnabled) { _ in
                                DispatchQueue.main.async {
                                    refreshNotifications()
                                    saveSettings()
                                }
                            }
                    }
                }
                
                DatePicker("デイリー通知時刻", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                    .onChange(of: dailyReminderTime) { _ in
                        DispatchQueue.main.async {
                            scheduleDailyReminder()
                            saveSettings()
                        }
                    }
            }
        } header: {
            Text("通知設定")
        } footer: {
            if notificationsEnabled {
                Text("シフト開始前の指定した時間に通知します。デイリー通知では翌日のシフトをお知らせします。")
            } else {
                Text("通知を有効にするとシフトのリマインダーを受け取れます。")
            }
        }
    }
    
    private var displaySection: some View {
        Section {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.purple)
                    .frame(width: 24)
                
                Toggle("ダークモード", isOn: $isDarkModeEnabled)
            }
            
            HStack {
                Image(systemName: "calendar.day.timeline.leading")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                Toggle("日曜日始まり", isOn: $startWeekOnSunday)
            }
        } header: {
            Text("表示設定")
        } footer: {
            Text("カレンダーの表示方法をカスタマイズできます。")
        }
    }
    
    
    
    private var appInfoSection: some View {
        Section {
            Button {
                showingAbout = true
            } label: {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("アプリについて")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .frame(width: 24)
                
                Text("バージョン")
                
                Spacer()
                
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("アプリ情報")
        }
    }
    
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        reminderHoursBefore = defaults.integer(forKey: "reminderHoursBefore") == 0 ? 24 : defaults.integer(forKey: "reminderHoursBefore")
        oneHourReminderEnabled = defaults.bool(forKey: "oneHourReminderEnabled")
        
        if let timeData = defaults.data(forKey: "dailyReminderTime"),
           let time = try? JSONDecoder().decode(Date.self, from: timeData) {
            dailyReminderTime = time
        } else {
            // Default daily reminder time to 8 PM
            let calendar = Calendar.current
            dailyReminderTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
        }
        
        
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        
        defaults.set(notificationsEnabled, forKey: "notificationsEnabled")
        defaults.set(reminderHoursBefore, forKey: "reminderHoursBefore")
        defaults.set(oneHourReminderEnabled, forKey: "oneHourReminderEnabled")
        
        if let timeData = try? JSONEncoder().encode(dailyReminderTime) {
            defaults.set(timeData, forKey: "dailyReminderTime")
        }
        
        
    }
    
    private func refreshNotifications() {
        if notificationsEnabled {
            // TODO: Implement notification refresh
        }
    }
    
    private func requestNotificationPermission() {
        notificationManager.requestPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    self.notificationsEnabled = false
                    self.saveSettings()
                }
            }
        }
    }
    
    private func scheduleDailyReminder() {
        if notificationsEnabled {
            notificationManager.scheduleDailyReminder(at: dailyReminderTime)
        } else {
            notificationManager.removeDailyReminder()
        }
    }
    
    private func loadTermsOfService() -> String {
        guard let path = Bundle.main.path(forResource: "TermsOfService", ofType: "md"),
              let content = try? String(contentsOfFile: path) else {
            return """
            利用規約ファイルが見つかりませんでした。
            
            本アプリの利用に関する詳細な規約については、
            開発者までお問い合わせください。
            """
        }
        return content
    }
    
    private func loadPrivacyPolicy() -> String {
        guard let path = Bundle.main.path(forResource: "PrivacyPolicy", ofType: "md"),
              let content = try? String(contentsOfFile: path) else {
            return """
            プライバシーポリシーファイルが見つかりませんでした。
            
            本アプリのプライバシーに関する詳細な方針については、
            開発者までお問い合わせください。
            
            なお、本アプリはすべてのデータを端末内に保存し、
            外部サーバーへの送信は一切行いません。
            """
        }
        return content
    }
    
}


// アプリ情報ビュー
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingTermsOfService = false
    @State private var showingPrivacyPolicy = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // アプリアイコンとタイトル
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("シフトまとめ")
                            .font(.title)
                            .bold()
                        
                        Text("バージョン 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // アプリ説明
                    VStack(alignment: .leading, spacing: 12) {
                        Text("複数のアルバイトを掛け持ちする方のための、シンプルで使いやすいシフト管理アプリです。")
                            .font(.body)
                        
                        Text("主な機能:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "building.2.fill", title: "職場管理", description: "複数の職場を色分けして管理")
                            FeatureRow(icon: "calendar", title: "シフト管理", description: "直感的なカレンダーでシフトを登録")
                            FeatureRow(icon: "exclamationmark.triangle.fill", title: "重複チェック", description: "シフトの重複を自動で検知")
                            FeatureRow(icon: "yensign.circle.fill", title: "収入計算", description: "月間収入を自動で計算")
                            FeatureRow(icon: "chart.bar.fill", title: "統計分析", description: "勤務パターンを詳しく分析")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 利用規約・プライバシーポリシー
                    VStack(spacing: 16) {
                        Button("利用規約") {
                            showingTermsOfService = true
                        }
                        .foregroundColor(.blue)
                        
                        Button("プライバシーポリシー") {
                            showingPrivacyPolicy = true
                        }
                        .foregroundColor(.blue)
                    }
                    
                    // 著作権表示
                    Text("© 2024 シフトまとめ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .padding()
            }
            .navigationTitle("アプリについて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingTermsOfService) {
            DocumentView(title: "利用規約", content: loadTermsOfService())
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            DocumentView(title: "プライバシーポリシー", content: loadPrivacyPolicy())
        }
    }
    
    private func loadTermsOfService() -> String {
        guard let path = Bundle.main.path(forResource: "TermsOfService", ofType: "md"),
              let content = try? String(contentsOfFile: path) else {
            return """
            利用規約ファイルが見つかりませんでした。
            
            本アプリの利用に関する詳細な規約については、
            開発者までお問い合わせください。
            """
        }
        return content
    }
    
    private func loadPrivacyPolicy() -> String {
        guard let path = Bundle.main.path(forResource: "PrivacyPolicy", ofType: "md"),
              let content = try? String(contentsOfFile: path) else {
            return """
            プライバシーポリシーファイルが見つかりませんでした。
            
            本アプリのプライバシーに関する詳細な方針については、
            開発者までお問い合わせください。
            
            なお、本アプリはすべてのデータを端末内に保存し、
            外部サーバーへの送信は一切行いません。
            """
        }
        return content
    }
}

// 機能紹介行
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}



#Preview {
    SettingsView()
}