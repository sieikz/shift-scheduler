//
//  ContentView.swift
//  shift scheduler
//
//  Created by ああ on 2025/08/13.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var sharedAppState = SharedAppState()
    @StateObject private var workplaceViewModel = WorkplaceViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("ホーム")
                    }
                    .tag(0)
                
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        CalendarView()
                            .environmentObject(sharedAppState)
                            .frame(height: geometry.size.height * 0.65) // カレンダーを画面の65%に制限
                        
                        // 常時表示のシフト情報エリア - 残りのスペースを使用
                        if selectedTab == 1 {
                            ShiftInfoDisplay(
                                selectedDate: sharedAppState.selectedDate,
                                shifts: sharedAppState.selectedDateShifts,
                                workplaces: workplaceViewModel.workplaces
                            )
                            .frame(height: geometry.size.height * 0.35) // シフト情報を画面の35%に制限
                            .background(Color(.systemGroupedBackground))
                        }
                    }
                }
                .tabItem {
                    Image(systemName: "calendar")
                    Text("カレンダー")
                }
                .tag(1)
            
                WorkplaceListView()
                    .tabItem {
                        Image(systemName: "building.2")
                        Text("職場")
                    }
                    .tag(2)
                
                StatisticsView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("統計")
                    }
                    .tag(3)
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("設定")
                    }
                    .tag(4)
            }
            .accentColor(.blue)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
