//
//  Project_Portion_demoApp.swift
//  Project-Portion-demo
//
//  Created by Evgenii Sukhov on 30.01.2026.
//

import SwiftUI
import SwiftData

@main
struct TestUI2App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AllPurch.self,
            MainPurch.self,
            UserInfo.self,
            MealList.self,
            RationInfo.self,
            OtherPurch.self,
            RationOptimum.self
       ])
                
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Показываем путь к хранилищу
            print("📁 Путь к хранилищу SwiftData:")
            print("📍 \(modelConfiguration.url.path)")
            
            insertDefaultUserInfo(into: container)
            insertDefaultMeals(into: container)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    printDatabaseInfo()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func printDatabaseInfo() {
        let url = sharedModelContainer.configurations.first?.url
        print("📂 Файл базы данных: \(url?.lastPathComponent ?? "unknown")")
        print("📁 Полный путь: \(url?.path ?? "unknown")")
    }
    
    private static func insertDefaultMeals(into container: ModelContainer) {
        let context = container.mainContext
        
        // Проверяем, есть ли уже приемы пищи в базе
        let fetchDescriptor = FetchDescriptor<MealList>()
        do {
            let existingMeals = try context.fetch(fetchDescriptor)
            if !existingMeals.isEmpty {
                print("✅ Приемы пищи уже существуют в базе")
                return
            }
        } catch {
            print("❌ Error fetching meals: \(error)")
        }
        
        // Создаем приемы пищи по умолчанию
        let defaultMeals = [
            (0, "Завтрак"),
            (1, "Обед"),
            (2, "Ужин")
        ]
        
        for meal in defaultMeals {
            let mealItem = MealList(MealID: meal.0, MealName: meal.1)
            context.insert(mealItem)
        }
        
        // Сохраняем изменения
        do {
            try context.save()
            print("✅ Default meals inserted successfully")
        } catch {
            print("❌ Error saving default meals: \(error)")
        }
    }
    
    private static func insertDefaultUserInfo(into container: ModelContainer) {
        let context = container.mainContext
        
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        do {
            let existingUsers = try context.fetch(fetchDescriptor)
            if !existingUsers.isEmpty {
                print("✅ Пользователь уже существует в базе")
                return
            }
        } catch {
            print("❌ Error fetching user info: \(error)")
        }
        
        let defaultUser = UserInfo(
            UserName: "Новый пользователь",
            UserPhoneNumber: "+7 777 777-77-77",
            UserAge: 0,
            UserHeight: 0,
            UserWeight: 0,
            UserGender: 0,
            UserGoal: 0,
            UserKcalOpt: 3240,
            UserProtOpt: 120,
            UserFatOpt: 80,
            UserCarbOpt: 350,
            UserAccType: 0,
            UserFamilyID: "0"
        )
        
        context.insert(defaultUser)
        
        do {
            try context.save()
            print("✅ Default user info inserted successfully")
        } catch {
            print("❌ Error saving default user info: \(error)")
        }
    }
}

