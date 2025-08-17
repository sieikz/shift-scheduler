import SwiftUI
import Combine

class SharedAppState: ObservableObject {
    @Published var selectedDate: Date?
    @Published var selectedDateShifts: [Shift] = []
    @Published var calendarSelectedDate: Date = Date()
    
    func updateSelectedDate(_ date: Date, shifts: [Shift]) {
        DispatchQueue.main.async {
            self.selectedDate = date
            self.selectedDateShifts = shifts
            self.calendarSelectedDate = date
        }
    }
    
    func clearSelection() {
        DispatchQueue.main.async {
            self.selectedDate = nil
            self.selectedDateShifts = []
        }
    }
}