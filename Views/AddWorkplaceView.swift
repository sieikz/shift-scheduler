import SwiftUI

struct AddWorkplaceView: View {
    @ObservedObject var workplaceViewModel: WorkplaceViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedColor = Color.blue
    @State private var hourlyWage = ""
    @State private var transportationAllowance = ""
    @State private var address = ""
    @State private var travelTimeMinutes = ""
    @State private var nightShiftRate = 1.25
    @State private var holidayRate = 1.35
    
    @State private var showingColorPicker = false
    @State private var errorMessage: String?
    
    private var isFormValid: Bool {
        let validation = workplaceViewModel.validateWorkplace(
            name: name,
            hourlyWage: Int(hourlyWage) ?? 0,
            color: selectedColor
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
                        Text("円")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("移動時間")
                        TextField("0", text: $travelTimeMinutes)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("分")
                            .foregroundColor(.secondary)
                    }
                    .help("他の職場からの移動時間（重複チェック用）")
                    
                    VStack(alignment: .leading) {
                        Text("住所（任意）")
                        TextField("例: 東京都渋谷区...", text: $address, axis: .vertical)
                            .lineLimit(2...4)
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
                        
                        Text("土日祝日に適用")
                            .font(.caption)
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
            .navigationTitle("職場の追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveWorkplace()
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerView(selectedColor: $selectedColor, 
                              availableColors: Workplace.colorOptions,
                              workplaceViewModel: workplaceViewModel)
            }
            .onAppear {
                selectedColor = workplaceViewModel.nextAvailableColor()
            }
            .onChange(of: name) { _ in
                updateErrorMessage()
            }
            .onChange(of: hourlyWage) { _ in
                updateErrorMessage()
            }
            .onChange(of: selectedColor) { _ in
                updateErrorMessage()
            }
        }
    }
    
    private func updateErrorMessage() {
        errorMessage = workplaceViewModel.validateWorkplace(
            name: name,
            hourlyWage: Int(hourlyWage) ?? 0,
            color: selectedColor
        )
    }
    
    private func saveWorkplace() {
        let wage = Int(hourlyWage) ?? 0
        let transportation = Int(transportationAllowance) ?? 0
        let travelTime = Int(travelTimeMinutes) ?? 0
        
        workplaceViewModel.addWorkplace(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            color: selectedColor,
            hourlyWage: wage,
            transportationAllowance: transportation,
            address: address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : address,
            travelTimeMinutes: travelTime
        )
        
        dismiss()
    }
}

// カラーピッカービュー
struct ColorPickerView: View {
    @Binding var selectedColor: Color
    let availableColors: [Color]
    let workplaceViewModel: WorkplaceViewModel
    @Environment(\.dismiss) private var dismiss
    
    let columns = Array(repeating: GridItem(.flexible()), count: 5)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(availableColors.indices, id: \.self) { index in
                        let color = availableColors[index]
                        let isSelected = selectedColor.toHex() == color.toHex()
                        let isAvailable = workplaceViewModel.isColorAvailable(color)
                        
                        Button {
                            if isAvailable {
                                selectedColor = color
                                dismiss()
                            }
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(isSelected ? Color.black : Color.gray.opacity(0.3), 
                                               lineWidth: isSelected ? 3 : 1)
                                )
                                .overlay(
                                    Group {
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .font(.title2)
                                                .bold()
                                        } else if !isAvailable {
                                            Image(systemName: "xmark")
                                                .foregroundColor(.white)
                                                .font(.title2)
                                                .bold()
                                        }
                                    }
                                )
                                .opacity(isAvailable ? 1.0 : 0.3)
                        }
                        .disabled(!isAvailable)
                    }
                }
                .padding()
            }
            .navigationTitle("色を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddWorkplaceView(workplaceViewModel: WorkplaceViewModel())
}