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
            hourlyWage: Double(hourlyWage) ?? 0,
            color: selectedColor,
            excludingId: workplace.id
        )
        return validation == nil
    }
    
    var body: some View {
        Form {
                Section("基本情報") {
                    HStack {
                        Text("職場名")
                        TextField("例: カフェA", text: $name)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: name) {
                                Task { @MainActor in
                                    checkForChanges()
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("色")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Workplace.colorOptions.indices, id: \.self) { index in
                                    let color = Workplace.colorOptions[index]
                                    let isSelected = selectedColor.toHex() == color.toHex()
                                    let isAvailable = workplaceViewModel.isColorAvailable(color, excluding: workplace.id)
                                    
                                    Button {
                                        if isAvailable {
                                            selectedColor = color
                                        }
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(color)
                                                .frame(width: 36, height: 36)
                                            
                                            if isSelected {
                                                Circle()
                                                    .fill(.ultraThinMaterial)
                                                    .frame(width: 36, height: 36)
                                                
                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: 16, height: 16)
                                                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 0.5)
                                            } else if !isAvailable {
                                                Circle()
                                                    .fill(.ultraThinMaterial)
                                                    .frame(width: 36, height: 36)
                                                
                                                Image(systemName: "xmark")
                                                    .foregroundColor(.white.opacity(0.8))
                                                    .font(.system(size: 12, weight: .medium))
                                            }
                                            
                                            if isSelected {
                                                Circle()
                                                    .stroke(Color.primary, lineWidth: 2)
                                                    .frame(width: 40, height: 40)
                                            }
                                        }
                                        .opacity(isAvailable ? 1.0 : 0.5)
                                        .scaleEffect(isSelected ? 1.0 : 0.95)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                                    }
                                    .disabled(!isAvailable)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                    
                    HStack {
                        Text("時給")
                        TextField("1000", text: $hourlyWage)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: hourlyWage) {
                                Task { @MainActor in
                                    checkForChanges()
                                }
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
                            .onChange(of: transportationAllowance) {
                                Task { @MainActor in
                                    checkForChanges()
                                }
                            }
                        Text("円")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("移動時間")
                        TextField("0", text: $travelTimeMinutes)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: travelTimeMinutes) {
                                Task { @MainActor in
                                    checkForChanges()
                                }
                            }
                        Text("分")
                            .foregroundColor(.secondary)
                    }
                    .help("他の職場からの移動時間（重複チェック用）")
                    
                    VStack(alignment: .leading) {
                        Text("住所（任意）")
                        TextField("例: 東京都渋谷区...", text: $address, axis: .vertical)
                            .lineLimit(2...4)
                            .onChange(of: address) {
                                Task { @MainActor in
                                    checkForChanges()
                                }
                            }
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
                    Button("戻る") {
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
            .onChange(of: selectedColor) {
                Task { @MainActor in
                    checkForChanges()
                    updateErrorMessage()
                }
            }
            .onChange(of: name) {
                Task { @MainActor in
                    updateErrorMessage()
                }
            }
            .onChange(of: hourlyWage) {
                Task { @MainActor in
                    updateErrorMessage()
                }
            }
            .onAppear {
                DispatchQueue.main.async {
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
            hourlyWage: Double(hourlyWage) ?? 0,
            color: selectedColor,
            excludingId: workplace.id
        )
    }
    
    private func saveWorkplace() {
        let wage = Double(hourlyWage) ?? 0
        let transportation = Double(transportationAllowance) ?? 0
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