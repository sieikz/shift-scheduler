import Foundation
import SwiftUI
import CoreData
import Combine

// 職場管理用のViewModel
class WorkplaceViewModel: ObservableObject {
    @Published var workplaces: [Workplace] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchWorkplaces()
        
        // PersistenceControllerからの変更を監視
        persistenceController.$workplaces
            .sink { [weak self] newWorkplaces in
                self?.workplaces = newWorkplaces
            }
            .store(in: &cancellables)
    }
    
    // 職場一覧の取得
    func fetchWorkplaces() {
        persistenceController.fetchWorkplaces()
        workplaces = persistenceController.workplaces
    }
    
    // 職場の追加
    func addWorkplace(name: String, color: Color, hourlyWage: Double, 
                     transportationAllowance: Double = 0, address: String? = nil,
                     travelTimeMinutes: Int = 0) {
        let workplace = Workplace(
            name: name,
            color: color,
            hourlyWage: hourlyWage,
            transportationAllowance: transportationAllowance,
            address: address,
            priority: workplaces.count,
            travelTimeMinutes: travelTimeMinutes
        )
        
        persistenceController.addWorkplace(workplace)
    }
    
    // 職場の更新
    func updateWorkplace(_ workplace: Workplace) {
        persistenceController.updateWorkplaceWithRefresh(workplace)
    }
    
    // 職場の削除
    func deleteWorkplace(_ workplace: Workplace) {
        persistenceController.deleteWorkplace(workplace)
    }
    
    // 職場の並び順変更
    func moveWorkplace(from source: IndexSet, to destination: Int) {
        var updatedWorkplaces = workplaces
        updatedWorkplaces.move(fromOffsets: source, toOffset: destination)
        
        // 優先順位を更新
        for (index, workplace) in updatedWorkplaces.enumerated() {
            var updatedWorkplace = workplace
            updatedWorkplace.priority = index
            persistenceController.updateWorkplaceWithRefresh(updatedWorkplace)
        }
    }
    
    // 指定IDの職場を取得
    func workplace(for id: UUID) -> Workplace? {
        return workplaces.first { $0.id == id }
    }
    
    // 色が使用可能かチェック
    func isColorAvailable(_ color: Color, excluding workplaceId: UUID? = nil) -> Bool {
        return !workplaces.contains { workplace in
            workplace.id != workplaceId && workplace.color == color
        }
    }
    
    // 次に利用可能な色を取得
    func nextAvailableColor() -> Color {
        for color in Workplace.colorOptions {
            if isColorAvailable(color) {
                return color
            }
        }
        // 全色使用中の場合はランダムに
        return Workplace.colorOptions.randomElement() ?? .blue
    }
    
    // 職場名の重複チェック
    func isNameAvailable(_ name: String, excluding workplaceId: UUID? = nil) -> Bool {
        return !workplaces.contains { workplace in
            workplace.id != workplaceId && workplace.name.lowercased() == name.lowercased()
        }
    }
    
    // バリデーション
    func validateWorkplace(name: String, hourlyWage: Double, color: Color, 
                         excludingId: UUID? = nil) -> String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "職場名を入力してください"
        }
        
        if !isNameAvailable(name, excluding: excludingId) {
            return "この職場名は既に使用されています"
        }
        
        if hourlyWage <= 0.0 {
            return "時給は1円以上で入力してください"
        }
        
        if hourlyWage > 10000.0 {
            return "時給が高すぎます。確認してください"
        }
        
        return nil
    }
}