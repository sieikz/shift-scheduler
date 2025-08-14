import SwiftUI
import Combine

class SharedAppState: ObservableObject {
    @Published var selectedDate: Date?
    @Published var selectedDateShifts: [Shift] = []
    @Published var calendarSelectedDate: Date = Date()
    
    func updateSelectedDate(_ date: Date, shifts: [Shift]) {
        selectedDate = date
        selectedDateShifts = shifts
        calendarSelectedDate = date
    }
    
    func clearSelection() {
        selectedDate = nil
        selectedDateShifts = []
    }
}