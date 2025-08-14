import CoreData
import Foundation
import Combine
import SwiftUI

// Core Data persistence controller
class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    // Published variables for ViewModels
    @Published var workplaces: [Workplace] = []
    @Published var shifts: [Shift] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // Preview用のコンテナ（SwiftUI Previewで使用）
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // サンプルデータの作成
        let sampleWorkplace = WorkplaceEntity(context: viewContext)
        sampleWorkplace.id = UUID()
        sampleWorkplace.name = "カフェA"
        sampleWorkplace.colorHex = "007AFF"
        sampleWorkplace.hourlyWage = 1000
        sampleWorkplace.transportationAllowance = 200
        sampleWorkplace.priority = 1
        sampleWorkplace.travelTimeMinutes = 15
        sampleWorkplace.nightShiftRate = 1.25
        sampleWorkplace.holidayRate = 1.35
        sampleWorkplace.createdAt = Date()
        
        let sampleShift = ShiftEntity(context: viewContext)
        sampleShift.id = UUID()
        sampleShift.workplaceId = sampleWorkplace.id
        sampleShift.date = Date()
        sampleShift.startTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        sampleShift.endTime = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
        sampleShift.breakMinutes = 60
        sampleShift.isConfirmed = false
        sampleShift.isRecurring = false
        sampleShift.actualBreakMinutes = 0
        sampleShift.createdAt = Date()
        sampleShift.updatedAt = Date()
        sampleShift.workplace = sampleWorkplace
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // プロジェクト内のCore Dataモデル名を使用
        container = NSPersistentContainer(name: "ShiftScheduler")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // 新しいデータベースファイル名を使用
            let storeURL = container.persistentStoreDescriptions.first?.url
            let newURL = storeURL?.deletingLastPathComponent().appendingPathComponent("ShiftScheduler.sqlite")
            container.persistentStoreDescriptions.first?.url = newURL
        }
        
        // CoreData設定を統一（HistoryTrackingを無効化）
        container.persistentStoreDescriptions.first?.setOption(false as NSNumber, 
                                                               forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber,
                                                               forKey: NSMigratePersistentStoresAutomaticallyOption)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber,
                                                               forKey: NSInferMappingModelAutomaticallyOption)
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // 既存のデータベースに問題がある場合、削除して再作成
                if let storeURL = storeDescription.url {
                    try? FileManager.default.removeItem(at: storeURL)
                    // 再試行
                    self.container.loadPersistentStores { _, retryError in
                        if let retryError = retryError as NSError? {
                            print("CoreData initialization failed: \(retryError)")
                            // 開発時のみfatalError、本番では別の対応を検討
                            fatalError("Unresolved error \(retryError), \(retryError.userInfo)")
                        }
                    }
                } else {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            }
        }
        
        // Merge policy for concurrent updates
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // 初期データの読み込み
        fetchWorkplaces()
        fetchShifts()
    }
    
    // データ保存
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // 職場の作成
    func createWorkplace(_ workplace: Workplace) {
        let entity = WorkplaceEntity(context: container.viewContext)
        workplace.updateEntity(entity)
        save()
    }
    
    // 職場の更新
    func updateWorkplace(_ workplace: Workplace) {
        let request: NSFetchRequest<WorkplaceEntity> = WorkplaceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", workplace.id as CVarArg)
        
        do {
            let entities = try container.viewContext.fetch(request)
            if let entity = entities.first {
                workplace.updateEntity(entity)
                save()
            }
        } catch {
            print("Update workplace error: \(error)")
        }
    }
    
    // 職場の削除
    func deleteWorkplace(id: UUID) {
        let request: NSFetchRequest<WorkplaceEntity> = WorkplaceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let entities = try container.viewContext.fetch(request)
            for entity in entities {
                container.viewContext.delete(entity)
            }
            save()
        } catch {
            print("Delete workplace error: \(error)")
        }
    }
    
    // シフトの作成
    func createShift(_ shift: Shift) {
        let entity = ShiftEntity(context: container.viewContext)
        shift.updateEntity(entity)
        
        // 職場との関連付け
        let workplaceRequest: NSFetchRequest<WorkplaceEntity> = WorkplaceEntity.fetchRequest()
        workplaceRequest.predicate = NSPredicate(format: "id == %@", shift.workplaceId as CVarArg)
        
        do {
            let workplaces = try container.viewContext.fetch(workplaceRequest)
            entity.workplace = workplaces.first
        } catch {
            print("Fetch workplace error: \(error)")
        }
        
        save()
    }
    
    // シフトの更新
    func updateShift(_ shift: Shift) {
        let request: NSFetchRequest<ShiftEntity> = ShiftEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", shift.id as CVarArg)
        
        do {
            let entities = try container.viewContext.fetch(request)
            if let entity = entities.first {
                shift.updateEntity(entity)
                save()
            }
        } catch {
            print("Update shift error: \(error)")
        }
    }
    
    // シフトの削除
    func deleteShift(id: UUID) {
        let request: NSFetchRequest<ShiftEntity> = ShiftEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let entities = try container.viewContext.fetch(request)
            for entity in entities {
                container.viewContext.delete(entity)
            }
            save()
        } catch {
            print("Delete shift error: \(error)")
        }
    }
    
    // 繰り返しシフトの作成
    func createRecurringShifts(_ shift: Shift) {
        guard let recurringType = shift.recurringType,
              let endDate = shift.recurringEndDate else {
            createShift(shift)
            return
        }
        
        var currentDate = shift.date
        let calendar = Calendar.current
        
        while currentDate <= endDate {
            // 開始・終了時刻を現在の日付に調整
            let startComponents = calendar.dateComponents([.hour, .minute], from: shift.startTime)
            let endComponents = calendar.dateComponents([.hour, .minute], from: shift.endTime)
            
            let startTime = calendar.date(bySettingHour: startComponents.hour ?? 0, 
                                        minute: startComponents.minute ?? 0, 
                                        second: 0, of: currentDate) ?? currentDate
            let endTime = calendar.date(bySettingHour: endComponents.hour ?? 0, 
                                      minute: endComponents.minute ?? 0, 
                                      second: 0, of: currentDate) ?? currentDate
            
            // 新しいShiftインスタンスを作成
            let newShift = Shift(
                id: UUID(),
                workplaceId: shift.workplaceId,
                date: currentDate,
                startTime: startTime,
                endTime: endTime,
                breakMinutes: shift.breakMinutes,
                memo: shift.memo,
                isConfirmed: shift.isConfirmed,
                isRecurring: shift.isRecurring,
                recurringType: shift.recurringType,
                recurringEndDate: shift.recurringEndDate,
                actualStartTime: shift.actualStartTime,
                actualEndTime: shift.actualEndTime,
                actualBreakMinutes: shift.actualBreakMinutes,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            createShift(newShift)
            
            // 次の日付を計算
            switch recurringType {
            case .daily:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            case .weekly:
                currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
            case .biWeekly:
                currentDate = calendar.date(byAdding: .weekOfYear, value: 2, to: currentDate) ?? currentDate
            case .monthly:
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            }
        }
    }
    
    // MARK: - Published Variables用のメソッド
    
    // 職場一覧の取得
    func fetchWorkplaces() {
        let request: NSFetchRequest<WorkplaceEntity> = WorkplaceEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: true)]
        
        do {
            let entities = try container.viewContext.fetch(request)
            self.workplaces = entities.map { Workplace(from: $0) }
        } catch {
            print("Fetch workplaces error: \(error)")
            self.workplaces = []
        }
    }
    
    // シフト一覧の取得
    func fetchShifts() {
        let request: NSFetchRequest<ShiftEntity> = ShiftEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let entities = try container.viewContext.fetch(request)
            self.shifts = entities.map { Shift(from: $0) }
        } catch {
            print("Fetch shifts error: \(error)")
            self.shifts = []
        }
    }
    
    // 職場の追加（Published変数も更新）
    func addWorkplace(_ workplace: Workplace) {
        createWorkplace(workplace)
        fetchWorkplaces()
    }
    
    // 職場の更新（Published変数も更新）
    func updateWorkplaceWithRefresh(_ workplace: Workplace) {
        updateWorkplace(workplace)
        fetchWorkplaces()
    }
    
    // 職場の削除（Published変数も更新）
    func deleteWorkplace(_ workplace: Workplace) {
        deleteWorkplace(id: workplace.id)
        fetchWorkplaces()
        fetchShifts() // 関連するシフトも更新
    }
    
    // シフトの追加（Published変数も更新）
    func addShift(_ shift: Shift) {
        createShift(shift)
        fetchShifts()
    }
    
    // シフトの更新（Published変数も更新）
    func updateShiftWithRefresh(_ shift: Shift) {
        updateShift(shift)
        fetchShifts()
    }
    
    // シフトの削除（Published変数も更新）
    func deleteShift(_ shift: Shift) {
        deleteShift(id: shift.id)
        fetchShifts()
    }
}