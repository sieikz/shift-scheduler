import Foundation
import SwiftUI
import CoreData

// WorkplaceEntity is auto-generated from Core Data model

// Swift struct for UI usage
struct Workplace: Identifiable, Hashable {
    let id: UUID
    var name: String
    var color: Color
    var hourlyWage: Double
    var transportationAllowance: Double
    var address: String?
    var priority: Int
    var travelTimeMinutes: Int
    var nightShiftRate: Double
    var holidayRate: Double
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, color: Color, hourlyWage: Double, 
         transportationAllowance: Double = 0, address: String? = nil, priority: Int = 0,
         travelTimeMinutes: Int = 0, nightShiftRate: Double = 1.25, 
         holidayRate: Double = 1.35, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.color = color
        self.hourlyWage = hourlyWage
        self.transportationAllowance = transportationAllowance
        self.address = address
        self.priority = priority
        self.travelTimeMinutes = travelTimeMinutes
        self.nightShiftRate = nightShiftRate
        self.holidayRate = holidayRate
        self.createdAt = createdAt
    }
}

extension Workplace {
    // 色の定義 - 10色以上のカラーパレット
    static let colorOptions: [Color] = [
        .blue, .red, .green, .orange, .purple, .pink, .yellow, .cyan,
        .mint, .indigo, .teal, .brown, Color(red: 0.2, green: 0.8, blue: 0.5),
        Color(red: 0.8, green: 0.3, blue: 0.7), Color(red: 0.9, green: 0.6, blue: 0.1)
    ]
    
    // Core Data Entity → Workplace 変換
    init(from entity: WorkplaceEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? ""
        self.color = Color(hex: entity.colorHex ?? "") ?? .blue
        self.hourlyWage = entity.hourlyWage
        self.transportationAllowance = entity.transportationAllowance
        self.address = nil
        self.priority = Int(entity.priority)
        self.travelTimeMinutes = Int(entity.travelTimeMinutes)
        self.nightShiftRate = entity.nightShiftRate
        self.holidayRate = entity.holidayRate
        self.createdAt = entity.createdAt ?? Date()
    }
    
    // Workplace → Core Data Entity 反映
    func updateEntity(_ entity: WorkplaceEntity) {
        entity.id = self.id
        entity.name = self.name
        entity.colorHex = self.color.toHex()
        entity.hourlyWage = self.hourlyWage
        entity.transportationAllowance = self.transportationAllowance
        entity.priority = Int32(self.priority)
        entity.travelTimeMinutes = Int32(self.travelTimeMinutes)
        entity.nightShiftRate = self.nightShiftRate
        entity.holidayRate = self.holidayRate
        entity.createdAt = self.createdAt
    }
}

// Color Extension for hex conversion
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let hex = String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        return hex
    }
}