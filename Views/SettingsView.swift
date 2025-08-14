import SwiftUI
import UserNotifications

struct SettingsView: View {
    @StateObject private var notificationManager = ShiftNotificationManager.shared
    @State private var showingExportSheet = false
    @State private var showingDataClearAlert = false
    @State private var showingAbout = false
    
    // 通知設定
    @State private var notificationsEnabled = false
    @State private var reminderHoursBefore = 24
    @State private var oneHourReminderEnabled = true
    @State private var dailyReminderTime = Date()
    
    // 表示設定
    @State private var isDarkModeEnabled = true
    @State private var showWeekNumbers = false
    @State private var startWeekOnSunday = true
    
    // 計算設定
    @State private var roundingMethod: WageRoundingMethod = .none
    @State private var closingDay = 31 // 31 = 月末締め
    
    var body: some View {
        NavigationView {
            Form {
                // 通知設定
                notificationSection
                
                // 表示設定
                displaySection
                
                // 計算設定
                calculationSection
                
                // データ管理
                dataManagementSection
                
                // アプリ情報
                appInfoSection
            }
            .navigationTitle("設定")
        }
        .onAppear {
            loadSettings()
        }
        .sheet(isPresented: $showingExportSheet) {
            DataExportView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert("データを削除", isPresented: $showingDataClearAlert) {
            Button("削除", role: .destructive) {
                clearAllData()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("すべてのシフトと職場データが削除されます。この操作は取り消せません。")
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
                        if enabled {
                            requestNotificationPermission()
                        } else {
                            notificationManager.disableNotifications()
                        }
                        saveSettings()
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
                        refreshNotifications()
                        saveSettings()
                    }
                }
                
                if reminderHoursBefore != 1 {
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        Toggle("1時間前にも通知", isOn: $oneHourReminderEnabled)
                            .onChange(of: oneHourReminderEnabled) { _ in
                                refreshNotifications()
                                saveSettings()
                            }
                    }
                }
                
                DatePicker("デイリー通知時刻", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                    .onChange(of: dailyReminderTime) { _ in
                        scheduleDailyReminder()
                        saveSettings()
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
                    .onChange(of: isDarkModeEnabled) { _ in
                        saveSettings()
                    }
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Toggle("週番号を表示", isOn: $showWeekNumbers)
                    .onChange(of: showWeekNumbers) { _ in
                        saveSettings()
                    }
            }
            
            HStack {
                Image(systemName: "calendar.day.timeline.leading")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                Toggle("日曜日始まり", isOn: $startWeekOnSunday)
                    .onChange(of: startWeekOnSunday) { _ in
                        saveSettings()
                    }
            }
        } header: {
            Text("表示設定")
        } footer: {
            Text("カレンダーの表示方法をカスタマイズできます。")
        }
    }
    
    private var calculationSection: some View {
        Section {
            HStack {
                Image(systemName: "yensign.circle.fill")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                Text("時給計算方法")
                
                Spacer()
                
                Picker("時給計算", selection: $roundingMethod) {
                    Text("切り捨て").tag(WageRoundingMethod.floor)
                    Text("切り上げ").tag(WageRoundingMethod.ceil)
                    Text("四捨五入").tag(WageRoundingMethod.round)
                    Text("計算しない").tag(WageRoundingMethod.none)
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: roundingMethod) { _ in
                    saveSettings()
                }
            }
            
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                
                Text("締め日")
                
                Spacer()
                
                Picker("締め日", selection: $closingDay) {
                    ForEach([15, 20, 25, 31], id: \.self) { day in
                        Text(day == 31 ? "月末" : "\(day)日").tag(day)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: closingDay) { _ in
                    saveSettings()
                }
            }
        } header: {
            Text("計算設定")
        } footer: {
            Text("給与計算時の端数処理方法と給与の締め日を設定します。")
        }
    }
    
    private var dataManagementSection: some View {
        Section {
            Button {
                showingExportSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("データをエクスポート")
                        .foregroundColor(.primary)
                }
            }
            
            Button {
                showingDataClearAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("全データを削除")
                        .foregroundColor(.red)
                }
            }
        } header: {
            Text("データ管理")
        } footer: {
            Text("シフトと職場のデータをCSVファイルとしてエクスポートしたり、全データを削除したりできます。")
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
        
        isDarkModeEnabled = defaults.bool(forKey: "isDarkModeEnabled")
        showWeekNumbers = defaults.bool(forKey: "showWeekNumbers")
        startWeekOnSunday = defaults.bool(forKey: "startWeekOnSunday")
        
        roundingMethod = WageRoundingMethod(rawValue: defaults.string(forKey: "roundingMethod") ?? "none") ?? .none
        closingDay = defaults.integer(forKey: "closingDay") == 0 ? 31 : defaults.integer(forKey: "closingDay")
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        
        defaults.set(notificationsEnabled, forKey: "notificationsEnabled")
        defaults.set(reminderHoursBefore, forKey: "reminderHoursBefore")
        defaults.set(oneHourReminderEnabled, forKey: "oneHourReminderEnabled")
        
        if let timeData = try? JSONEncoder().encode(dailyReminderTime) {
            defaults.set(timeData, forKey: "dailyReminderTime")
        }
        
        defaults.set(isDarkModeEnabled, forKey: "isDarkModeEnabled")
        defaults.set(showWeekNumbers, forKey: "showWeekNumbers")
        defaults.set(startWeekOnSunday, forKey: "startWeekOnSunday")
        
        defaults.set(roundingMethod.rawValue, forKey: "roundingMethod")
        defaults.set(closingDay, forKey: "closingDay")
    }
    
    private func refreshNotifications() {
        if notificationsEnabled {
            CoreDataManager.shared.refreshAllNotifications()
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
    
    private func clearAllData() {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext
        
        // 全シフトを削除
        let shiftRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "ShiftEntity")
        let deleteShiftsRequest = NSBatchDeleteRequest(fetchRequest: shiftRequest)
        
        // 全職場を削除
        let workplaceRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "WorkplaceEntity")
        let deleteWorkplacesRequest = NSBatchDeleteRequest(fetchRequest: workplaceRequest)
        
        do {
            try context.execute(deleteShiftsRequest)
            try context.execute(deleteWorkplacesRequest)
            try context.save()
        } catch {
            print("データ削除エラー: \(error)")
        }
    }
}

// データエクスポートビュー
struct DataExportView: View {
    @StateObject private var shiftViewModel = ShiftViewModel()
    @StateObject private var workplaceViewModel = WorkplaceViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var isExporting = false
    @State private var exportSuccess = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("データエクスポート")
                    .font(.title)
                    .bold()
                
                Text("シフトと職場のデータをCSVファイルとしてエクスポートします。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("エクスポートされるデータ:")
                        .font(.headline)
                    
                    Text("• 職場情報（名前、時給、交通費など）")
                        .font(.body)
                    Text("• シフト情報（日時、職場、労働時間など）")
                        .font(.body)
                    Text("• 収入計算結果")
                        .font(.body)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                if isExporting {
                    ProgressView("エクスポート中...")
                } else {
                    Button("エクスポート開始") {
                        exportData()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
            .navigationTitle("データエクスポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        errorMessage = nil
        
        // CSVエクスポート処理をここに実装
        // 実際の実装では ActivityViewController を使用してファイル共有
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            exportSuccess = true
            // 実際の実装では成功後にファイル共有ダイアログを表示
        }
    }
}

// アプリ情報ビュー
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                            // 利用規約を表示
                        }
                        .foregroundColor(.blue)
                        
                        Button("プライバシーポリシー") {
                            // プライバシーポリシーを表示
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

// 時給計算方法の列挙型
enum WageRoundingMethod: String, CaseIterable {
    case floor = "floor"
    case ceil = "ceil"
    case round = "round"
    case none = "none"
    
    var displayName: String {
        switch self {
        case .floor: return "切り捨て"
        case .ceil: return "切り上げ"
        case .round: return "四捨五入"
        case .none: return "計算しない"
        }
    }
}


#Preview {
    SettingsView()
}