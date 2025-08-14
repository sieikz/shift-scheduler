import SwiftUI

struct WorkplaceListView: View {
    @StateObject private var workplaceViewModel = WorkplaceViewModel()
    @State private var showingAddWorkplace = false
    @State private var showingEditWorkplace = false
    @State private var selectedWorkplace: Workplace?
    @State private var showingDeleteAlert = false
    @State private var workplaceToDelete: Workplace?
    
    var body: some View {
        NavigationView {
            ZStack {
                if workplaceViewModel.workplaces.isEmpty {
                    // Empty state
                    VStack(spacing: 24) {
                        Image(systemName: "building.2")
                            .font(.system(size: 64))
                            .foregroundColor(.blue.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("職場が登録されていません")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("最初の職場を追加してシフト管理を\n始めましょう")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("職場を追加") {
                            showingAddWorkplace = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .font(.headline)
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    List {
                        ForEach(workplaceViewModel.workplaces) { workplace in
                            WorkplaceRowView(workplace: workplace) {
                                selectedWorkplace = workplace
                                showingEditWorkplace = true
                            }
                        }
                        .onDelete(perform: deleteWorkplaces)
                        .onMove(perform: workplaceViewModel.moveWorkplace)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
                
                if workplaceViewModel.isLoading {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .navigationTitle("職場管理")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !workplaceViewModel.workplaces.isEmpty {
                        EditButton()
                    }
                    
                    Button {
                        showingAddWorkplace = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWorkplace) {
                NavigationView {
                    AddWorkplaceView(workplaceViewModel: workplaceViewModel)
                }
            }
            .sheet(isPresented: $showingEditWorkplace) {
                if let workplace = selectedWorkplace {
                    NavigationView {
                        EditWorkplaceView(workplace: workplace, workplaceViewModel: workplaceViewModel) {
                            selectedWorkplace = nil
                        }
                    }
                }
            }
            .alert("職場を削除", isPresented: $showingDeleteAlert) {
                Button("削除", role: .destructive) {
                    if let workplace = workplaceToDelete {
                        workplaceViewModel.deleteWorkplace(workplace)
                    }
                    workplaceToDelete = nil
                }
                Button("キャンセル", role: .cancel) {
                    workplaceToDelete = nil
                }
            } message: {
                if let workplace = workplaceToDelete {
                    Text("「\(workplace.name)」を削除します。関連するシフト情報も全て削除されます。この操作は取り消せません。")
                }
            }
        }
        .alert("エラー", isPresented: .constant(workplaceViewModel.errorMessage != nil)) {
            Button("OK") {
                workplaceViewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = workplaceViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func deleteWorkplaces(offsets: IndexSet) {
        for index in offsets {
            workplaceToDelete = workplaceViewModel.workplaces[index]
            showingDeleteAlert = true
        }
    }
}

// 職場行のビュー
struct WorkplaceRowView: View {
    let workplace: Workplace
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Circle()
                    .fill(workplace.color)
                    .frame(width: 24, height: 24)
                    .shadow(color: workplace.color.opacity(0.3), radius: 2)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(workplace.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "yensign.circle")
                            Text("¥\(Int(workplace.hourlyWage))")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        if workplace.transportationAllowance > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "tram")
                                Text("¥\(Int(workplace.transportationAllowance))")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    if let address = workplace.address, !address.isEmpty {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if workplace.travelTimeMinutes > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "car.fill")
                            Text("\(workplace.travelTimeMinutes)分")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    WorkplaceListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}