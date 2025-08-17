import SwiftUI

struct EditShiftView: View {
    @State private var shift: Shift
    @State private var selectedWorkplaceId: UUID
    @State private var selectedDate: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var breakMinutes: Int
    @State private var memo: String
    @State private var isConfirmed: Bool
    
    let workplaces: [Workplace]
    let shiftViewModel: ShiftViewModel
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    
    init(shift: Shift, workplaces: [Workplace], shiftViewModel: ShiftViewModel, onDismiss: @escaping () -> Void) {
        self._shift = State(initialValue: shift)
        self.workplaces = workplaces
        self.shiftViewModel = shiftViewModel
        self.onDismiss = onDismiss
        
        // Initialize @State variables
        self._selectedWorkplaceId = State(initialValue: shift.workplaceId)
        self._selectedDate = State(initialValue: shift.date)
        self._startTime = State(initialValue: shift.startTime)
        self._endTime = State(initialValue: shift.endTime)
        self._breakMinutes = State(initialValue: shift.breakMinutes)
        self._memo = State(initialValue: shift.memo ?? "")
        self._isConfirmed = State(initialValue: shift.isConfirmed)
    }
    
    private var overlapWarnings: [ShiftOverlap] {
        shiftViewModel.wouldOverlap(
            workplaceId: selectedWorkplaceId,
            date: selectedDate,
            startTime: startTime,
            endTime: endTime,
            workplaces: workplaces,
            excluding: shift.id
        )
    }
    
    private var errorMessage: String? {
        shiftViewModel.validateShift(
            workplaceId: selectedWorkplaceId,
            date: selectedDate,
            startTime: startTime,
            endTime: endTime
        )
    }
    
    private var isFormValid: Bool {
        errorMessage == nil
    }
    
    private var hasChanges: Bool {
        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        return selectedWorkplaceId != shift.workplaceId ||
                !Calendar.current.isDate(selectedDate, equalTo: shift.date, toGranularity: .day) ||
                !Calendar.current.isDate(startTime, equalTo: shift.startTime, toGranularity: .minute) ||
                !Calendar.current.isDate(endTime, equalTo: shift.endTime, toGranularity: .minute) ||
                breakMinutes != shift.breakMinutes ||
                (trimmedMemo.isEmpty ? nil : trimmedMemo) != shift.memo ||
                isConfirmed != shift.isConfirmed
    }
    
    var body: some View {
        VStack(spacing: 0) {
                // Custom navigation bar
                HStack {
                    Button {
                        dismiss()
                        onDismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("カレンダー")
                        }
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("シフト編集")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("保存") {
                        saveShift()
                    }
                    .foregroundColor(.blue)
                    .disabled(!isFormValid || !hasChanges)
                }
                .padding()
                .background(Color(.systemBackground))
                
                Form {
                Section("基本情報") {
                    // 職場選択
                    Picker("職場", selection: $selectedWorkplaceId) {
                        ForEach(workplaces) { workplace in
                            HStack {
                                Circle()
                                    .fill(workplace.color)
                                    .frame(width: 12, height: 12)
                                Text(workplace.name)
                            }
                            .tag(workplace.id)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    // 日付選択
                    DatePicker("日付", selection: $selectedDate, displayedComponents: .date)
                        .onChange(of: selectedDate) { newDate in
                            DispatchQueue.main.async {
                                updateStartEndTime(for: newDate)
                            }
                        }
                    
                    // 開始時間
                    DatePicker("開始時間", selection: $startTime, displayedComponents: .hourAndMinute)
                    
                    // 終了時間
                    DatePicker("終了時間", selection: $endTime, displayedComponents: .hourAndMinute)
                    
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
                    
                    Toggle("シフト確定", isOn: $isConfirmed)
                }
                
                // 繰り返しシフト情報（読み取り専用）
                if shift.isRecurring {
                    Section("繰り返し設定") {
                        HStack {
                            Text("繰り返しタイプ")
                            Spacer()
                            Text(shift.recurringType?.displayName ?? "不明")
                                .foregroundColor(.secondary)
                        }
                        
                        if let endDate = shift.recurringEndDate {
                            HStack {
                                Text("終了日")
                                Spacer()
                                Text(endDate, style: .date)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text("繰り返しシフトの一部です")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            Text("このシフトのみの変更が適用されます")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 重複警告
                if !overlapWarnings.isEmpty {
                    Section {
                        ForEach(Array(overlapWarnings.enumerated()), id: \.offset) { _, overlap in
                            OverlapWarningView(overlap: overlap, workplaces: workplaces)
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
                
                Section("作成・更新日時") {
                    HStack {
                        Text("作成日")
                        Spacer()
                        Text(shift.createdAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("更新日")
                        Spacer()
                        Text(shift.updatedAt, style: .date)
                            .foregroundColor(.secondary)
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
    
    
    private func saveShift() {
        var updatedShift = shift
        updatedShift.workplaceId = selectedWorkplaceId
        updatedShift.date = selectedDate
        updatedShift.startTime = startTime
        updatedShift.endTime = endTime
        updatedShift.breakMinutes = breakMinutes
        
        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedShift.memo = trimmedMemo.isEmpty ? nil : trimmedMemo
        updatedShift.isConfirmed = isConfirmed
        
        shiftViewModel.updateShift(updatedShift)
        
        dismiss()
        onDismiss()
    }
}

#Preview {
    let sampleShift = Shift(
        workplaceId: UUID(),
        date: Date(),
        startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
        endTime: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date(),
        breakMinutes: 60,
        memo: "朝番"
    )
    
    let sampleWorkplaces = [
        Workplace(name: "カフェA", color: .blue, hourlyWage: 1000),
        Workplace(name: "レストランB", color: .red, hourlyWage: 1200)
    ]
    
    return EditShiftView(
        shift: sampleShift,
        workplaces: sampleWorkplaces,
        shiftViewModel: ShiftViewModel()
    ) {
        // onDismiss
    }
}