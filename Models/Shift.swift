import Foundation
import CoreData

// Core Data Entity for Shift
@objc(ShiftEntity)
public class ShiftEntity: NSManagedObject {
    
}

extension ShiftEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShiftEntity> {
        return NSFetchRequest<ShiftEntity>(entityName: "ShiftEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var workplaceId: UUID
    @NSManaged public var date: Date
    @NSManaged public var startTime: Date
    @NSManaged public var endTime: Date
    @NSManaged public var breakMinutes: Int16
    @NSManaged public var memo: String?
    @NSManaged public var isConfirmed: Bool
    @NSManaged public var isRecurring: Bool
    @NSManaged public var recurringType: String?
    @NSManaged public var recurringEndDate: Date?
    @NSManaged public var actualStartTime: Date?
    @NSManaged public var actualEndTime: Date?
    @NSManaged public var actualBreakMinutes: Int16
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var workplace: WorkplaceEntity?
}

// Swift struct for UI usage
struct Shift: Identifiable, Hashable {
    let id: UUID
    var workplaceId: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    var breakMinutes: Int
    var memo: String?
    var isConfirmed: Bool
    var isRecurring: Bool
    var recurringType: RecurringType?
    var recurringEndDate: Date?
    var actualStartTime: Date?
    var actualEndTime: Date?
    var actualBreakMinutes: Int
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), workplaceId: UUID, date: Date, startTime: Date, endTime: Date,
         breakMinutes: Int = 0, memo: String? = nil, isConfirmed: Bool = false,
         isRecurring: Bool = false, recurringType: RecurringType? = nil,
         recurringEndDate: Date? = nil, actualStartTime: Date? = nil, 
         actualEndTime: Date? = nil, actualBreakMinutes: Int = 0,
         createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.workplaceId = workplaceId
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.breakMinutes = breakMinutes
        self.memo = memo
        self.isConfirmed = isConfirmed
        self.isRecurring = isRecurring
        self.recurringType = recurringType
        self.recurringEndDate = recurringEndDate
        self.actualStartTime = actualStartTime
        self.actualEndTime = actualEndTime
        self.actualBreakMinutes = actualBreakMinutes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// 繰り返しタイプ
enum RecurringType: String, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case biWeekly = "biWeekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .daily:
            return "毎日"
        case .weekly:
            return "毎週"
        case .biWeekly:
            return "隔週"
        case .monthly:
            return "毎月"
        }
    }
}

extension Shift {
    // Core Data Entity → Shift 変換
    init(from entity: ShiftEntity) {
        self.id = entity.id
        self.workplaceId = entity.workplaceId
        self.date = entity.date
        self.startTime = entity.startTime
        self.endTime = entity.endTime
        self.breakMinutes = Int(entity.breakMinutes)
        self.memo = entity.memo
        self.isConfirmed = entity.isConfirmed
        self.isRecurring = entity.isRecurring
        self.recurringType = entity.recurringType.map { RecurringType(rawValue: $0) } ?? nil
        self.recurringEndDate = entity.recurringEndDate
        self.actualStartTime = entity.actualStartTime
        self.actualEndTime = entity.actualEndTime
        self.actualBreakMinutes = Int(entity.actualBreakMinutes)
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
    }
    
    // Shift → Core Data Entity 反映
    func updateEntity(_ entity: ShiftEntity) {
        entity.id = self.id
        entity.workplaceId = self.workplaceId
        entity.date = self.date
        entity.startTime = self.startTime
        entity.endTime = self.endTime
        entity.breakMinutes = Int16(self.breakMinutes)
        entity.memo = self.memo
        entity.isConfirmed = self.isConfirmed
        entity.isRecurring = self.isRecurring
        entity.recurringType = self.recurringType?.rawValue
        entity.recurringEndDate = self.recurringEndDate
        entity.actualStartTime = self.actualStartTime
        entity.actualEndTime = self.actualEndTime
        entity.actualBreakMinutes = Int16(self.actualBreakMinutes)
        entity.createdAt = self.createdAt
        entity.updatedAt = self.updatedAt
    }
    
    // 労働時間計算（分）
    var workingMinutes: Int {
        let totalMinutes = Calendar.current.dateComponents([.minute], from: startTime, to: endTime).minute ?? 0
        return max(0, totalMinutes - breakMinutes)
    }
    
    // 実際の労働時間計算（分）
    var actualWorkingMinutes: Int {
        guard let actualStart = actualStartTime, let actualEnd = actualEndTime else {
            return workingMinutes
        }
        let totalMinutes = Calendar.current.dateComponents([.minute], from: actualStart, to: actualEnd).minute ?? 0
        return max(0, totalMinutes - actualBreakMinutes)
    }
    
    // 深夜時間帯の判定
    var isNightShift: Bool {
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: startTime)
        let endHour = calendar.component(.hour, from: endTime)
        
        // 22時〜5時を深夜時間帯とする
        return startHour >= 22 || startHour < 5 || endHour >= 22 || endHour < 5
    }
    
    // 深夜労働時間計算（分）
    func nightWorkingMinutes(calendar: Calendar = Calendar.current) -> Int {
        let nightStart = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: date) ?? date
        let nextDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        let nightEnd = calendar.date(bySettingHour: 5, minute: 0, second: 0, of: nextDay) ?? date
        
        let shiftStart = max(startTime, nightStart)
        let shiftEnd = min(endTime, nightEnd)
        
        if shiftStart >= shiftEnd {
            return 0
        }
        
        let nightMinutes = calendar.dateComponents([.minute], from: shiftStart, to: shiftEnd).minute ?? 0
        let nightBreakMinutes = min(breakMinutes, nightMinutes)
        
        return max(0, nightMinutes - nightBreakMinutes)
    }
    
    // 祝日判定（簡易版）
    func isHoliday(calendar: Calendar = Calendar.current) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7 // 土日のみ（後で日本の祝日対応を追加）
    }
}

// シフト重複チェック用の構造体
struct ShiftOverlap {
    let shift1: Shift
    let shift2: Shift
    let overlapMinutes: Int
    let hasConflict: Bool
    
    init(shift1: Shift, shift2: Shift, travelTimeMinutes: Int = 0) {
        self.shift1 = shift1
        self.shift2 = shift2
        
        let start1 = shift1.startTime
        let end1 = Calendar.current.date(byAdding: .minute, value: travelTimeMinutes, to: shift1.endTime) ?? shift1.endTime
        let start2 = shift2.startTime
        let end2 = shift2.endTime
        
        let overlapStart = max(start1, start2)
        let overlapEnd = min(end1, end2)
        
        if overlapStart < overlapEnd {
            self.overlapMinutes = Calendar.current.dateComponents([.minute], from: overlapStart, to: overlapEnd).minute ?? 0
            self.hasConflict = true
        } else {
            self.overlapMinutes = 0
            self.hasConflict = false
        }
    }
}