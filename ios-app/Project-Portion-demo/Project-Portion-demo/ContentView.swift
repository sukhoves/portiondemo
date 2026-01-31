//
//  ContentView.swift
//  Project-Portion-demo
//
//  Created by Evgenii Sukhov on 30.01.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var products: [MainPurch]
    @State private var isLoading = true
    @State private var isDataLoaded = false
    
    private func checkDataLoading() {
            // Проверяем, загрузились ли основные данные
            if !products.isEmpty {
                isDataLoaded = true
            }
            
            // В любом случае скрываем загрузку через 3 секунды (fallback)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isLoading = false
                    isDataLoaded = true // на всякий случай
                }
            }
        }
    
    
    var body: some View {
        
        Group {
            
            if isLoading {
                            AdvancedMeshLoadingView()
                        } else {
            TabView {
                // Первая вкладка - Запасы
                FridgeView(products: products)
                    .tabItem {
                        Image(systemName: "refrigerator")
                        Text("Запасы")
                    }
                
                // Вторая вкладка - Рацион
                RationView()
                    .tabItem {
                        Image(systemName: "fork.knife")
                        Text("Рацион")
                    }
                
                // Третья вкладка - Статистика
                StatisticView()
                    .tabItem {
                        Image(systemName: "chart.bar")
                        Text("Статистика")
                    }
                
                // Четвертая вкладка - Аккаунт
                AccountView()
                    .tabItem {
                        Image(systemName: "person")
                        Text("Аккаунт")
                    }
            }
            .ifAvailableiOS26 {
                $0.toolbarBackground(.ultraThinMaterial, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar)
            }
        }
    }
        .onAppear {
                    checkDataLoading()
                }
        
    }
}

// Добавь это расширение для удобства
extension View {
    @ViewBuilder
    func ifAvailableiOS26<Content: View>(_ transform: (Self) -> Content) -> some View {
        if #available(iOS 26, *) {
            transform(self)
        } else {
            self
        }
    }
}
