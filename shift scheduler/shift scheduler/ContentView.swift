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
    @StateObject private var shiftViewModel = ShiftViewModel()
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
                            .frame(height: geometry.size.height * 0.55) // カレンダーを画面の55%に制限してボタンの重複を回避
                        
                        // 常時表示のシフト情報エリア - 残りのスペースを使用
                        if selectedTab == 1 {
                            ShiftInfoDisplay(
                                selectedDate: sharedAppState.selectedDate,
                                shifts: sharedAppState.selectedDateShifts,
                                workplaces: workplaceViewModel.workplaces,
                                onTodayTapped: {
                                    let today = Date()
                                    let todayShifts = shiftViewModel.shifts(for: today)
                                    sharedAppState.updateSelectedDate(today, shifts: todayShifts)
                                }
                            )
                            .frame(height: geometry.size.height * 0.45) // シフト情報を画面の45%に拡大
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
