import SwiftUI
import Combine

class SharedAppState: ObservableObject {
    @Published var selectedDate: Date?
    @Published var selectedDateShifts: [Shift] = []
    
    func updateSelectedDate(_ date: Date, shifts: [Shift]) {
        selectedDate = date
        selectedDateShifts = shifts
    }
    
    func clearSelection() {
        selectedDate = nil
        selectedDateShifts = []
    }
}