import SwiftUI

struct EditWorkplaceView: View {
    @State private var workplace: Workplace
    @ObservedObject var workplaceViewModel: WorkplaceViewModel
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var selectedColor: Color
    @State private var hourlyWage: String
    @State private var transportationAllowance: String
    @State private var address: String
    @State private var travelTimeMinutes: String
    @State private var nightShiftRate: Double
    @State private var holidayRate: Double
    
    @State private var showingColorPicker = false
    @State private var errorMessage: String?
    @State private var hasChanges = false
    
    init(workplace: Workplace, workplaceViewModel: WorkplaceViewModel, onDismiss: @escaping () -> Void) {
        self._workplace = State(initialValue: workplace)
        self.workplaceViewModel = workplaceViewModel
        self.onDismiss = onDismiss
        
        // Initialize @State variables
        self._name = State(initialValue: workplace.name)
        self._selectedColor = State(initialValue: workplace.color)
        self._hourlyWage = State(initialValue: String(workplace.hourlyWage))
        self._transportationAllowance = State(initialValue: String(workplace.transportationAllowance))
        self._address = State(initialValue: workplace.address ?? "")
        self._travelTimeMinutes = State(initialValue: String(workplace.travelTimeMinutes))
        self._nightShiftRate = State(initialValue: workplace.nightShiftRate)
        self._holidayRate = State(initialValue: workplace.holidayRate)
    }
    
    private var isFormValid: Bool {
        let validation = workplaceViewModel.validateWorkplace(
            name: name,
            hourlyWage: Int(hourlyWage) ?? 0,
            color: selectedColor,
            excludingId: workplace.id
        )
        return validation == nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    HStack {
                        Text("職場名")
                        TextField("例: カフェA", text: $name)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: name) { _ in
                                checkForChanges()
                            }
                    }
                    
                    HStack {
                        Text("色")
                        Spacer()
                        Button {
                            showingColorPicker = true
                        } label: {
                            HStack {
                                Circle()
                                    .fill(selectedColor)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                Text("変更")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    HStack {
                        Text("時給")
                        TextField("1000", text: $hourlyWage)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: hourlyWage) { _ in
                                checkForChanges()
                            }
                        Text("円")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("追加設定") {
                    HStack {
                        Text("交通費")
                        TextField("0", text: $transportationAllowance)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: transportationAllowance) { _ in
                                checkForChanges()
                            }
                        Text("円")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("移動時間")
                        TextField("0", text: $travelTimeMinutes)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: travelTimeMinutes) { _ in
                                checkForChanges()
                            }
                        Text("分")
                            .foregroundColor(.secondary)
                    }
                    .help("他の職場からの移動時間（重複チェック用）")
                    
                    VStack(alignment: .leading) {
                        Text("住所（任意）")
                        TextField("例: 東京都渋谷区...", text: $address, axis: .vertical)
                            .lineLimit(2...4)
                            .onChange(of: address) { _ in
                                checkForChanges()
                            }
                    }
                }
                
                Section("手当設定") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("深夜手当率")
                            Spacer()
                            Text("\(nightShiftRate, specifier: "%.2f")倍")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $nightShiftRate, in: 1.0...2.0, step: 0.05) {
                            Text("深夜手当率")
                        }
                        .accentColor(selectedColor)
                        .onChange(of: nightShiftRate) { _ in
                            checkForChanges()
                        }
                        
                        Text("22:00〜5:00の時間帯に適用")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("休日手当率")
                            Spacer()
                            Text("\(holidayRate, specifier: "%.2f")倍")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $holidayRate, in: 1.0...2.0, step: 0.05) {
                            Text("休日手当率")
                        }
                        .accentColor(selectedColor)
                        .onChange(of: holidayRate) { _ in
                            checkForChanges()
                        }
                        
                        Text("土日祝日に適用")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("作成日時") {
                    HStack {
                        Text("作成日")
                        Spacer()
                        Text(workplace.createdAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("職場の編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveWorkplace()
                    }
                    .disabled(!isFormValid || !hasChanges)
                }
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerView(selectedColor: $selectedColor, 
                              availableColors: Workplace.colorOptions,
                              workplaceViewModel: workplaceViewModel)
            }
            .onChange(of: selectedColor) { _ in
                checkForChanges()
                updateErrorMessage()
            }
            .onChange(of: name) { _ in
                updateErrorMessage()
            }
            .onChange(of: hourlyWage) { _ in
                updateErrorMessage()
            }
            .onAppear {
                updateErrorMessage()
            }
        }
    }
    
    private func checkForChanges() {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        hasChanges = name != workplace.name ||
                    selectedColor.toHex() != workplace.color.toHex() ||
                    hourlyWage != String(workplace.hourlyWage) ||
                    transportationAllowance != String(workplace.transportationAllowance) ||
                    (trimmedAddress.isEmpty ? nil : trimmedAddress) != workplace.address ||
                    travelTimeMinutes != String(workplace.travelTimeMinutes) ||
                    nightShiftRate != workplace.nightShiftRate ||
                    holidayRate != workplace.holidayRate
    }
    
    private func updateErrorMessage() {
        errorMessage = workplaceViewModel.validateWorkplace(
            name: name,
            hourlyWage: Int(hourlyWage) ?? 0,
            color: selectedColor,
            excludingId: workplace.id
        )
    }
    
    private func saveWorkplace() {
        let wage = Int(hourlyWage) ?? 0
        let transportation = Int(transportationAllowance) ?? 0
        let travelTime = Int(travelTimeMinutes) ?? 0
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var updatedWorkplace = workplace
        updatedWorkplace.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedWorkplace.color = selectedColor
        updatedWorkplace.hourlyWage = wage
        updatedWorkplace.transportationAllowance = transportation
        updatedWorkplace.address = trimmedAddress.isEmpty ? nil : trimmedAddress
        updatedWorkplace.travelTimeMinutes = travelTime
        updatedWorkplace.nightShiftRate = nightShiftRate
        updatedWorkplace.holidayRate = holidayRate
        
        workplaceViewModel.updateWorkplace(updatedWorkplace)
        
        dismiss()
        onDismiss()
    }
}

#Preview {
    let sampleWorkplace = Workplace(
        name: "カフェサンプル",
        color: .blue,
        hourlyWage: 1000,
        transportationAllowance: 200,
        address: "東京都渋谷区1-1-1"
    )
    
    return EditWorkplaceView(
        workplace: sampleWorkplace,
        workplaceViewModel: WorkplaceViewModel()
    ) {
        // onDismiss
    }
}