import SwiftUI

struct AddShiftView: View {
    @State private var selectedWorkplaceId: UUID?
    @State private var selectedDate: Date
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var breakMinutes = 0
    @State private var memo = ""
    @State private var isRecurring = false
    @State private var recurringType: RecurringType = .weekly
    @State private var recurringEndDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    
    let workplaces: [Workplace]
    let shiftViewModel: ShiftViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingOverlapWarning = false
    @State private var overlapWarnings: [ShiftOverlap] = []
    @State private var errorMessage: String?
    
    init(selectedDate: Date, workplaces: [Workplace], shiftViewModel: ShiftViewModel) {
        self._selectedDate = State(initialValue: selectedDate)
        self.workplaces = workplaces
        self.shiftViewModel = shiftViewModel
        
        // デフォルトの時間設定（9:00-17:00）
        let calendar = Calendar.current
        let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let end = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        
        self._startTime = State(initialValue: start)
        self._endTime = State(initialValue: end)
    }
    
    private var isFormValid: Bool {
        guard let selectedWorkplaceId = selectedWorkplaceId else { return false }
        return shiftViewModel.validateShift(
            workplaceId: selectedWorkplaceId,
            date: selectedDate,
            startTime: startTime,
            endTime: endTime
        ) == nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    // 職場選択
                    Picker("職場", selection: $selectedWorkplaceId) {
                        Text("職場を選択").tag(UUID?.none)
                        ForEach(workplaces) { workplace in
                            HStack {
                                Circle()
                                    .fill(workplace.color)
                                    .frame(width: 12, height: 12)
                                Text(workplace.name)
                            }
                            .tag(UUID?.some(workplace.id))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    // 日付選択
                    DatePicker("日付", selection: $selectedDate, displayedComponents: .date)
                        .onChange(of: selectedDate) { newDate in
                            DispatchQueue.main.async {
                                updateStartEndTime(for: newDate)
                                checkOverlaps()
                            }
                        }
                    
                    // 開始時間
                    DatePicker("開始時間", selection: $startTime, displayedComponents: .hourAndMinute)
                        .onChange(of: startTime) { _ in
                            DispatchQueue.main.async {
                                checkOverlaps()
                            }
                        }
                    
                    // 終了時間
                    DatePicker("終了時間", selection: $endTime, displayedComponents: .hourAndMinute)
                        .onChange(of: endTime) { _ in
                            DispatchQueue.main.async {
                                checkOverlaps()
                            }
                        }
                    
                    // 休憩時間
                    HStack {
                        Text("休憩時間")
                        Spacer()
                        Picker("休憩時間", selection: $breakMinutes) {
                            ForEach([0, 15, 30, 45, 60, 75, 90, 120], id: \.self) { minutes in
                                Text("\(minutes)分").tag(minutes)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section("追加情報") {
                    VStack(alignment: .leading) {
                        Text("メモ（任意）")
                        TextField("例: 朝番、レジ担当など", text: $memo, axis: .vertical)
                            .lineLimit(2...4)
                    }
                }
                
                Section("繰り返し設定") {
                    Toggle("繰り返しシフト", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("繰り返しタイプ", selection: $recurringType) {
                            ForEach(RecurringType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        DatePicker("終了日", selection: $recurringEndDate, displayedComponents: .date)
                    }
                }
                
                // 重複警告
                if !overlapWarnings.isEmpty {
                    Section {
                        ForEach(Array(overlapWarnings.enumerated()), id: \.offset) { _, overlap in
                            OverlapWarningView(overlap: overlap, workplaces: workplaces)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text("このまま保存することもできます")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            Text("移動時間や業務の調整が可能な場合は問題ありません")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("重複警告")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // シフト情報サマリー
                if selectedWorkplaceId != nil {
                    Section("シフトサマリー") {
                        HStack {
                            Text("労働時間")
                            Spacer()
                            Text("\(workingMinutes / 60)時間\(workingMinutes % 60)分")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("予想収入")
                            Spacer()
                            Text("¥\(currentEarnings + transportationAllowance)")
                                .foregroundColor(.green)
                        }
                        
                        if isNightShift {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .foregroundColor(.indigo)
                                Text("深夜手当対象")
                                Spacer()
                            }
                        }
                        
                        if isHoliday {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange)
                                Text("休日手当対象")
                                Spacer()
                            }
                        }
                    }
                }
                
                // エラーメッセージ
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("シフト追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveShift()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onChange(of: selectedWorkplaceId) { _ in
                DispatchQueue.main.async {
                    checkOverlaps()
                    updateErrorMessage()
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    if let firstWorkplace = workplaces.first {
                        selectedWorkplaceId = firstWorkplace.id
                    }
                    updateErrorMessage()
                }
            }
        }
    }
    
    private var isNightShift: Bool {
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: startTime)
        let endHour = calendar.component(.hour, from: endTime)
        return startHour >= 22 || startHour < 5 || endHour >= 22 || endHour < 5
    }
    
    private var isHoliday: Bool {
        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        return weekday == 1 || weekday == 7 // 土日のみ（後で祝日対応追加）
    }
    
    private var currentWorkplace: Workplace? {
        workplaces.first { $0.id == selectedWorkplaceId }
    }
    
    private var totalMinutes: Int {
        Calendar.current.dateComponents([.minute], from: startTime, to: endTime).minute ?? 0
    }
    
    private var workingMinutes: Int {
        max(0, totalMinutes - breakMinutes)
    }
    
    private var currentHourlyWage: Double {
        currentWorkplace?.hourlyWage ?? 0
    }
    
    private var currentEarnings: Int {
        Int((Double(workingMinutes) * currentHourlyWage) / 60)
    }
    
    private var transportationAllowance: Int {
        Int(currentWorkplace?.transportationAllowance ?? 0)
    }
    
    private func updateStartEndTime(for date: Date) {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        startTime = calendar.date(bySettingHour: startComponents.hour ?? 9, 
                                minute: startComponents.minute ?? 0, 
                                second: 0, of: date) ?? date
        endTime = calendar.date(bySettingHour: endComponents.hour ?? 17, 
                              minute: endComponents.minute ?? 0, 
                              second: 0, of: date) ?? date
    }
    
    private func checkOverlaps() {
        guard let workplaceId = selectedWorkplaceId else {
            overlapWarnings = []
            return
        }
        
        overlapWarnings = shiftViewModel.wouldOverlap(
            workplaceId: workplaceId,
            date: selectedDate,
            startTime: startTime,
            endTime: endTime,
            workplaces: workplaces
        )
    }
    
    private func updateErrorMessage() {
        errorMessage = shiftViewModel.validateShift(
            workplaceId: selectedWorkplaceId,
            date: selectedDate,
            startTime: startTime,
            endTime: endTime
        )
    }
    
    private func saveShift() {
        guard let workplaceId = selectedWorkplaceId else { return }
        
        shiftViewModel.addShift(
            workplaceId: workplaceId,
            date: selectedDate,
            startTime: startTime,
            endTime: endTime,
            breakMinutes: breakMinutes,
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : memo,
            isRecurring: isRecurring,
            recurringType: isRecurring ? recurringType : nil,
            recurringEndDate: isRecurring ? recurringEndDate : nil
        )
        
        dismiss()
    }
}

#Preview {
    let sampleWorkplaces = [
        Workplace(name: "カフェA", color: .blue, hourlyWage: 1000),
        Workplace(name: "レストランB", color: .red, hourlyWage: 1200)
    ]
    
    return AddShiftView(
        selectedDate: Date(),
        workplaces: sampleWorkplaces,
        shiftViewModel: ShiftViewModel()
    )
}