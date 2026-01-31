//
//  RationView.swift
//  Project-Portion-demo
//
//  Created by Evgenii Sukhov on 30.01.2026.
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Constants & Configuration
private enum RationConstants {
    static let baseURL = "http://\(ServerConfig.YourIP):8000"
    static let dateFormat = "dd.MM.yyyy"
    static let maxResponseLogLength = 500
}

// MARK: - Helper Types
enum RationGroupingType {
    case byCategory
    case byPreference
}

// MARK: - Date Formatter Helper (для использования внутри актора)
struct RationDateHelper {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    static func parseDate(from dateString: String?) -> Date? {
        guard let dateString = dateString, !dateString.isEmpty else { return nil }
        return dateFormatter.date(from: dateString)
    }
}

// MARK: - Ration Service Protocol
protocol RationServiceProtocol {
    func loadRation(for date: Date, user: SendableUserInfo) async throws -> [SendableRationInfo]
}

// MARK: - Network Ration Service
final class NetworkRationService: RationServiceProtocol {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func loadRation(for date: Date, user: SendableUserInfo) async throws -> [SendableRationInfo] {
        let dateString = RationDateHelper.dateFormatter.string(from: date)
        
        let parameters: [String: Any] = [
            "ration_date": dateString,
            "user_id": user.userID.uuidString
        ]
        
        let urlString = "\(RationConstants.baseURL)/get_ration_by_date"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["status"] as? String == "success",
              let rationsData = json["rations"] as? [[Any]] else {
            throw URLError(.cannotParseResponse)
        }
        
        return rationsData.compactMap { parseRationFromServer(data: $0) }
    }
    
    private func parseRationFromServer(data: [Any]) -> SendableRationInfo? {
        guard data.count >= 22 else { return nil }
        
        let expireDate = RationDateHelper.parseDate(from: data[9] as? String) ?? Date()
        let rationDate = RationDateHelper.parseDate(from: data[14] as? String) ?? Date()
        
        return SendableRationInfo(
            prodID: data[0] as? Int ?? 0,
            name: data[1] as? String ?? "",
            volume: data[2] as? Double ?? 0,
            unit: data[3] as? String ?? "",
            volumeGr: data[4] as? Double ?? 0,
            kcal100g: data[5] as? Double ?? 0,
            prot100g: data[6] as? Double ?? 0,
            fat100g: data[7] as? Double ?? 0,
            carb100g: data[8] as? Double ?? 0,
            expireDate: expireDate,
            tag: data[10] as? String ?? "",
            cat: data[11] as? String ?? "",
            mealID: data[12] as? Int ?? 0,
            mealName: data[13] as? String ?? "",
            rationDate: rationDate,
            volumeServ: data[15] as? Double ?? 0,
            volumeServGr: data[16] as? Double ?? 0,
            kcalServ: data[17] as? Double ?? 0,
            protServ: data[18] as? Double ?? 0,
            fatServ: data[19] as? Double ?? 0,
            carbServ: data[20] as? Double ?? 0,
            userID: data[21] as? String ?? ""
        )
    }
}

// MARK: - Ration ViewModel
@MainActor
final class RationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedDate = Date()
    @Published var swipedItemID: PersistentIdentifier? = nil
    @Published var isLoading = false
    
    // MARK: - Private Properties
    private var serverRationItems: [SendableRationInfo] = []
    private var localRationItems: [RationInfo] = []
    private var users: [UserInfo] = []
    private var rationOptimums: [RationOptimum] = []
    private let rationService: NetworkRationService
    
    // MARK: - Computed Properties
    var currentRationItems: [RationInfo] {
        if serverRationItems.isEmpty {
            return localRationItems
        } else {
            return serverRationItems.map { $0.toRationInfo() }
        }
    }
    
    var user: UserInfo? {
        users.first
    }
    
    // MARK: - Date Formatter (для ViewModel)
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    // MARK: - Initialization
    init() {
        self.rationService = NetworkRationService()
    }
    
    // MARK: - Public Methods
    func updateUsers(_ users: [UserInfo]) {
        self.users = users
    }
    
    func updateRationOptimums(_ optimums: [RationOptimum]) {
        self.rationOptimums = optimums
    }
    
    func getRationItemsForSelectedDate(from items: [RationInfo]) -> [RationInfo] {
        return items.filter { item in
            Calendar.current.isDate(item.RationDate, inSameDayAs: selectedDate)
        }
    }
    
    func getTotalDailyKcal(for items: [RationInfo]) -> Double {
        let itemsForDate = getRationItemsForSelectedDate(from: items)
        return itemsForDate.reduce(0) { $0 + $1.KcalServ }
    }
    
    func getTotalDailyProtein(for items: [RationInfo]) -> Double {
        let itemsForDate = getRationItemsForSelectedDate(from: items)
        return itemsForDate.reduce(0) { $0 + $1.ProtServ }
    }
    
    func getTotalDailyFat(for items: [RationInfo]) -> Double {
        let itemsForDate = getRationItemsForSelectedDate(from: items)
        return itemsForDate.reduce(0) { $0 + $1.FatServ }
    }
    
    func getTotalDailyCarbs(for items: [RationInfo]) -> Double {
        let itemsForDate = getRationItemsForSelectedDate(from: items)
        return itemsForDate.reduce(0) { $0 + $1.CarbServ }
    }
    
    func getGuaranteedOptimalValues(for date: Date) -> (kcal: Double, protein: Double, fat: Double, carbs: Double) {
        let optimumDate = Calendar.current.startOfDay(for: date)
        if let optimum = rationOptimums.first(where: { optimum in
            Calendar.current.isDate(optimum.RationDate, inSameDayAs: optimumDate)
        }) {
            return (optimum.UserKcalOpt, optimum.UserProtOpt, optimum.UserFatOpt, optimum.UserCarbOpt)
        }
        
        let user = users.first
        return (
            user?.UserKcalOpt ?? 0,
            user?.UserProtOpt ?? 0,
            user?.UserFatOpt ?? 0,
            user?.UserCarbOpt ?? 0
        )
    }
    
    func getCompletionPercentage(for items: [RationInfo]) -> Double {
        let totalKcal = getTotalDailyKcal(for: items)
        let optimalKcal = getGuaranteedOptimalValues(for: selectedDate).kcal
        guard optimalKcal > 0 else { return 0 }
        return (totalKcal / optimalKcal) * 100
    }
    
    func getDeviationIcon(for items: [RationInfo]) -> String {
        let totalKcal = getTotalDailyKcal(for: items)
        let optimalKcal = getGuaranteedOptimalValues(for: selectedDate).kcal
        
        if totalKcal < optimalKcal {
            return "arrow.down"
        } else if totalKcal > optimalKcal {
            return "arrow.up"
        } else {
            return "equal"
        }
    }
    
    func getDeviationColor(for items: [RationInfo]) -> Color {
        let totalKcal = getTotalDailyKcal(for: items)
        let optimalKcal = getGuaranteedOptimalValues(for: selectedDate).kcal
        
        if totalKcal < optimalKcal {
            return DesignSystem.Colors.accent2
        } else if totalKcal > optimalKcal {
            return DesignSystem.Colors.accent2
        } else {
            return .green
        }
    }
    
    func getSmartRecommendation(for items: [RationInfo]) -> Text {
        let totalProtein = getTotalDailyProtein(for: items)
        let totalFat = getTotalDailyFat(for: items)
        let totalCarbs = getTotalDailyCarbs(for: items)
        let completionPercentage = getCompletionPercentage(for: items)
        
        let optimalValues = getGuaranteedOptimalValues(for: selectedDate)
        let proteinDeviation = totalProtein - optimalValues.protein
        let fatDeviation = totalFat - optimalValues.fat
        let carbsDeviation = totalCarbs - optimalValues.carbs
        
        if completionPercentage < 95 {
            return Text("Не хватает **калорий** в рационе")
        }
        else if completionPercentage >= 105 {
            return Text("Норма **калорий** превышена")
        }
        else {
            var excessItems: [String] = []
            var deficitItems: [String] = []
            
            if proteinDeviation > 0 {
                excessItems.append("**белков**")
            } else if proteinDeviation < 0 {
                deficitItems.append("**белков**")
            }
            
            if fatDeviation > 0 {
                excessItems.append("**жиров**")
            } else if fatDeviation < 0 {
                deficitItems.append("**жиров**")
            }
            
            if carbsDeviation > 0 {
                excessItems.append("**углеводов**")
            } else if carbsDeviation < 0 {
                deficitItems.append("**углеводов**")
            }

            if excessItems.isEmpty && deficitItems.isEmpty {
                return Text("Ваш рацион сбалансирован! 👍")
            } else {
                var finalString = ""
                
                if !excessItems.isEmpty && !deficitItems.isEmpty {
                    finalString = "Скорректируйте баланс \(excessItems.joined(separator: ", ")) и \(deficitItems.joined(separator: ", "))"
                } else if !excessItems.isEmpty {
                    finalString = "Уменьшите потребление \(excessItems.joined(separator: ", "))"
                } else {
                    finalString = "Увеличьте потребление \(deficitItems.joined(separator: ", "))"
                }
                
                return Text(.init(finalString))
            }
        }
    }
    
    func loadServerRation(for date: Date) async {
        guard let user = user else {
            await MainActor.run {
                serverRationItems = []
                isLoading = false
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let sendableUser = SendableUserInfo.from(user)
            let loadedRations = try await rationService.loadRation(for: date, user: sendableUser)
            
            await MainActor.run {
                self.serverRationItems = loadedRations
                self.isLoading = false
                print("✅ RationViewModel: Загружено \(loadedRations.count) записей рациона")
            }
        } catch {
            print("❌ RationViewModel: Ошибка: \(error.localizedDescription)")
            await MainActor.run {
                serverRationItems = []
                isLoading = false
            }
        }
    }
    
    func checkAndCreateRationOptimum(for date: Date, users: [UserInfo], modelContext: ModelContext) {
        let optimumDate = Calendar.current.startOfDay(for: date)
        
        let exists = rationOptimums.contains { optimum in
            Calendar.current.isDate(optimum.RationDate, inSameDayAs: optimumDate)
        }
        
        if !exists, let user = users.first {
            let newOptimum = RationOptimum(
                UserKcalOpt: user.UserKcalOpt,
                UserProtOpt: user.UserProtOpt,
                UserFatOpt: user.UserFatOpt,
                UserCarbOpt: user.UserCarbOpt,
                RationDate: optimumDate
            )
            
            modelContext.insert(newOptimum)
            
            do {
                try modelContext.save()
                print("✅ Создан оптимальный рацион на дату: \(optimumDate)")
            } catch {
                print("❌ Error saving ration optimum: \(error)")
            }
        }
    }
    
    func handleSwipe(itemID: PersistentIdentifier?, isSwiped: Bool) {
        if isSwiped {
            swipedItemID = itemID
        } else if swipedItemID == itemID {
            swipedItemID = nil
        }
    }
}

// MARK: - Ration Summary Data
struct RationSummaryData {
    let totalKcal: Double
    let totalProtein: Double
    let totalFat: Double
    let totalCarbs: Double
    let completionPercentage: Double
    let deviationIcon: String
    let deviationColor: Color
    let recommendation: Text
    
    static func from(viewModel: RationViewModel) -> RationSummaryData {
        let items = viewModel.currentRationItems
        
        return RationSummaryData(
            totalKcal: viewModel.getTotalDailyKcal(for: items),
            totalProtein: viewModel.getTotalDailyProtein(for: items),
            totalFat: viewModel.getTotalDailyFat(for: items),
            totalCarbs: viewModel.getTotalDailyCarbs(for: items),
            completionPercentage: viewModel.getCompletionPercentage(for: items),
            deviationIcon: viewModel.getDeviationIcon(for: items),
            deviationColor: viewModel.getDeviationColor(for: items),
            recommendation: viewModel.getSmartRecommendation(for: items)
        )
    }
}

// MARK: - Ration Summary View
struct RationSummaryView: View {
    @Environment(\.colorScheme) var colorScheme
    let data: RationSummaryData
    
    var body: some View {
        HStack {
            ZStack {
               // Image(colorScheme == .dark ? "blurbannerdark" : "blurbanner")
                   // .resizable()
                 //   .aspectRatio(contentMode: .fill)
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 142, height: 124)
                    .cornerRadius(20)
                
                VStack(spacing: 0) {
                    Text("**Итого рацион:**")
                        .font(DesignSystem.Typography.Variation2)
                        .font(.custom("Montserrat-Medium", size: 16))
                        .foregroundColor(Color.white.opacity(0.95))
                        .frame(width: 114, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(Int(data.totalKcal)) Ккал")
                                .font(.custom("Montserrat-SemiBold", size: 20))
                                .foregroundColor(.white)
                                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                                .frame(width: 114, alignment: .trailing)
                                .multilineTextAlignment(.trailing)
                            
                            Text("из них:")
                                .font(.custom("Montserrat-Medium", size: 16))
                                .foregroundColor(.white.opacity(0.8))
                                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                                .frame(width: 114, alignment: .trailing)
                        }
                        
                        HStack(spacing: 4) {
                            NutrientBlockBanner(letter: "Б", number: "\(Int(data.totalProtein))")
                            NutrientBlockBanner(letter: "Ж", number: "\(Int(data.totalFat))")
                            NutrientBlockBanner(letter: "У", number: "\(Int(data.totalCarbs))")
                        }
                        .padding(.top, 4)
                        .frame(width: 114, alignment: .trailing)
                    }
                    .padding(.top, 1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .leading) {
                Text("Ваш рацион составляет")
                    .font(DesignSystem.Typography.Variation1)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.8))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                
                HStack(alignment: .center, spacing: 0) {
                    Text("**\(Int(data.completionPercentage))%**")
                        .font(DesignSystem.Typography.screentitle)
                        .foregroundColor(data.deviationColor.opacity(1))
                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    
                    Image(systemName: data.deviationIcon)
                        .foregroundColor(data.deviationColor)
                        .font(.system(size: 17, weight: .semibold))
                        .padding(.top, 1)
                        .padding(.leading, 1)
                }
                
                Text("От рекомендуемой нормы")
                    .font(DesignSystem.Typography.Variation1)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.8))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                
                Text("\(data.recommendation)")
                    .font(DesignSystem.Typography.ProdName)
                    .padding(.top, 4)
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
            }
            .padding(.leading, 8)
            
            Spacer()
        }
    }
}

// MARK: - Empty Meals View
struct EmptyMealsView: View {
    @Environment(\.colorScheme) var colorScheme
    let modelContext: ModelContext
    @Binding var showingAddMealAlert: Bool
    
    var body: some View {
        VStack {
            Text("Добавить прием")
                .font(DesignSystem.Typography.CatTitle)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                let newMeal = MealList(MealID: 0, MealName: "Завтрак")
                modelContext.insert(newMeal)
                
                do {
                    try modelContext.save()
                } catch {
                    print("Error saving meal: \(error)")
                }
            }) {
                Text("Создать первый прием пищи")
                    .font(DesignSystem.Typography.ProdName)
                    .foregroundColor(DesignSystem.Colors.accent2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.Colors.grey1)
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Add Meal Button View
struct AddMealButtonView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var showingAddMealAlert: Bool
    
    var body: some View {
        HStack {
            Text("Добавить прием")
                .font(DesignSystem.Typography.CatTitleSmall)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.6))
                .frame(alignment: .leading)
            
            Image(systemName: "plus")
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.6))
                .padding(.leading, 12)
            
            Spacer()
        }
        .onTapGesture {
            showingAddMealAlert = true
        }
    }
}

// MARK: - Analytics View
struct AnalyticsView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Аналитика")
                .font(DesignSystem.Typography.CatTitle)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            
           // Image(colorScheme == .dark ? "blurbannerdark" : "blurbanner")
               // .resizable()
               // .aspectRatio(contentMode: .fill)
            Rectangle()
                .fill(Color.gray)
                .frame(height: 320)
                //.frame(maxWidth: .infinity)
                .cornerRadius(20)
                .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
        }
    }
}

// MARK: - Meal Data
struct MealData {
    let meal: MealList
    let rationItems: [RationInfo]
    let totalKcal: Double
    let totalProtein: Double
    let totalFat: Double
    let totalCarbs: Double
    
    init(meal: MealList, rationItems: [RationInfo]) {
        self.meal = meal
        self.rationItems = rationItems.filter { $0.MealID == meal.MealID }
        
        self.totalKcal = self.rationItems.reduce(0) { $0 + $1.KcalServ }
        self.totalProtein = self.rationItems.reduce(0) { $0 + $1.ProtServ }
        self.totalFat = self.rationItems.reduce(0) { $0 + $1.FatServ }
        self.totalCarbs = self.rationItems.reduce(0) { $0 + $1.CarbServ }
    }
}

// MARK: - Meal Block
struct MealBlock: View {
    let data: MealData
    let selectedDate: Date
    let onEdit: (RationInfo) -> Void
    let onDelete: (RationInfo) -> Void
    let onShowRationPopUp: (Int) -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(spacing: 0) {
            // ЗАГОЛОВОК ПРИЕМА ПИЩИ
            HStack {
                Text(data.meal.MealName)
                    .font(DesignSystem.Typography.CatTitle)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                
                Spacer()
                
                if !data.rationItems.isEmpty {
                    HStack(spacing: 0) {
                        HStack(alignment: .center, spacing: 8) {
                            // Калории в порции
                            Text("\(Int(data.totalKcal))")
                                .font(.custom("Montserrat-SemiBold", size: 16))
                                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(1))
                            
                            HStack(alignment: .center, spacing: 4) {
                                ZStack {
                                    Rectangle()
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.15) : Color.white)
                                        .frame(width: 26, height: 20)
                                        .cornerRadius(8)
                                        .shadow(
                                            color: Color.black.opacity(0.05),
                                            radius: 3.5,
                                            x: 0,
                                            y: 1
                                        )
                                    
                                    Text("\(Int(data.totalProtein))")
                                        .font(.custom("Montserrat-SemiBold", size: 13))
                                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(1))
                                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                                        .frame(width: 26, height: 20)
                                }
                                
                                ZStack {
                                    Rectangle()
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.15) : Color.white)
                                        .frame(width: 26, height: 20)
                                        .cornerRadius(8)
                                        .shadow(
                                            color: Color.black.opacity(0.05),
                                            radius: 3.5,
                                            x: 0,
                                            y: 1
                                        )
                                    
                                    Text("\(Int(data.totalFat))")
                                        .font(.custom("Montserrat-SemiBold", size: 13))
                                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(1))
                                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                                        .frame(width: 26, height: 20)
                                }
                                
                                ZStack {
                                    Rectangle()
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.15) : Color.white)
                                        .frame(width: 26, height: 20)
                                        .cornerRadius(8)
                                        .shadow(
                                            color: Color.black.opacity(0.05),
                                            radius: 3.5,
                                            x: 0,
                                            y: 1
                                        )
                                    
                                    Text("\(Int(data.totalCarbs))")
                                        .font(.custom("Montserrat-SemiBold", size: 13))
                                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(1))
                                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                                        .frame(width: 26, height: 20)
                                }
                            }
                        }
                        .padding(.trailing, 7)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                        }
                    }
                }
            }
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            .padding(.top, 16)
            
            // СОДЕРЖИМОЕ ПРИЕМА ПИЩИ
            if data.rationItems.isEmpty {
                // ПУСТАЯ КАРТОЧКА
                HStack {
                    HStack(spacing: 0) {
                        // Изображение продукта (пустое состояние)
                        ZStack {
                            Rectangle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.33) : DesignSystem.Colors.grey1)
                                .frame(width: 66, height: 66)
                                .opacity(0.5)
                                .cornerRadius(20)
                                .shadow(
                                    color: Color.black.opacity(0.025),
                                    radius: 3.5,
                                    x: 0,
                                    y: 1
                                )
                            
                            Image(systemName: "doc.text")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.5))
                        }
                        .frame(width: 66, height: 66)
                        
                        Text("Запишите свой прием пищи")
                            .font(DesignSystem.Typography.ProdName)
                            .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.7))
                            .padding(.leading, 12)
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        onShowRationPopUp(data.meal.MealID)
                    }) {
                        Image(systemName: "plus")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundColor(DesignSystem.Colors.accent2)
                            .padding(.trailing, 1)
                    }
                }
                .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                .padding(.top, 6)
            } else {
                if isExpanded {
                    // КАРТОЧКИ С ПРОДУКТАМИ
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(data.rationItems.enumerated()), id: \.element.id) { index, item in
                                VStack(spacing: 0) {
                                    // Карточка продукта с свайпом
                                    ProductCardSmall(
                                        rationItem: item,
                                        index: index,
                                        onEdit: { onEdit(item) },
                                        onDelete: { onDelete(item) }
                                    )
                                    .contextMenu {
                                        Button(action: {
                                           // print("Изменить нажато")
                                        }) {
                                            Label("Изменить", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive, action: {
                                            // print("Удалить нажато")
                                        }) {
                                            Label("Удалить", systemImage: "trash")
                                        }
                                    }

                                    if index < data.rationItems.count - 1 {
                                        Divider()
                                            .padding(.vertical, 7)
                                            .padding(.leading, 66 + (AdaptiveSpacing.horizontalSpace))
                                    }
                                }
                                .padding(.leading, AdaptiveSpacing.horizontalSpace)
                                .padding(.top, index == 0 ? 6 : 0)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            onShowRationPopUp(data.meal.MealID)
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.75))
                        }
                        .offset(y: 3)
                        .padding(.trailing, AdaptiveSpacing.horizontalSpace)
                    }
                }
            }
        }
    }
}

// MARK: - Nutrient Info View
struct NutrientInfoView: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(DesignSystem.Typography.ProdVolume)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.7))
            
            Text(value)
                .font(DesignSystem.Typography.ProdName)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
        }
    }
}

// MARK: - Main Ration View
struct RationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query private var meals: [MealList]
    @Query private var users: [UserInfo]
    @Query private var rationOptimums: [RationOptimum]
    
    @StateObject private var viewModel: RationViewModel
    @State private var isRefreshing = false
    @State private var showingAddMealAlert = false
    @State private var newMealName = ""
    @State private var showRationPopUp = false
    @State private var selectedMealIDForPopUp: Int = 0
    
    init() {
        _viewModel = StateObject(wrappedValue: RationViewModel())
    }
    
    private var summaryData: RationSummaryData {
        RationSummaryData.from(viewModel: viewModel)
    }
    
    private var mealsData: [MealData] {
        meals.sorted(by: { $0.MealID < $1.MealID }).map { meal in
            MealData(meal: meal, rationItems: viewModel.getRationItemsForSelectedDate(from: viewModel.currentRationItems))
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Рацион")
                    .font(DesignSystem.Typography.screentitle)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    .padding(.top, 10)
                
                Spacer()
                
                if viewModel.isLoading || isRefreshing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.top, 10)
                }
                
                HStack(spacing: 4) {
                    Circle().frame(width: 6, height: 6)
                    Circle().frame(width: 6, height: 6)
                    Circle().frame(width: 6, height: 6)
                }
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                .padding(.top, 10)
            }
            .padding(.bottom, 8)
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            
            ScrollView {
                VStack(spacing: 0) {
                    DatePicker("Выберите дату", selection: $viewModel.selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                        .padding(.top, 4)
                        .onChange(of: viewModel.selectedDate) { oldValue, newValue in
                            Task {
                                await viewModel.loadServerRation(for: newValue)
                            }
                        }
                    
                    RationSummaryView(data: summaryData)
                        .padding(.top, 18)
                        .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                }
                
                VStack(spacing: 16) {
                    if meals.isEmpty {
                        EmptyMealsView(modelContext: modelContext, showingAddMealAlert: $showingAddMealAlert)
                            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                    } else {
                        ForEach(mealsData, id: \.meal.MealID) { mealData in
                            MealBlock(
                                data: mealData,
                                selectedDate: viewModel.selectedDate,
                                // Убраны параметры isSwipedItemID и onSwipe
                                onEdit: { rationItem in
                                    print("Редактировать продукт \(rationItem.id)")
                                },
                                onDelete: { rationItem in
                                    deleteRationItem(rationItem)
                                },
                                onShowRationPopUp: { mealID in
                                    selectedMealIDForPopUp = mealID
                                    showRationPopUp = true
                                }
                            )
                        }
                    }
                    
                    AddMealButtonView(showingAddMealAlert: $showingAddMealAlert)
                        .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                    
                    AnalyticsView()
                }
                .padding(.top, 8)
            }
            .refreshable {
                await refreshData()
            }
            .padding(.bottom, 70)
            
            Spacer()
        }
        .background(DesignSystem.Colors.appbackground(for: colorScheme))
        .ignoresSafeArea(.all, edges: .bottom)
        .onAppear {
            viewModel.updateUsers(users)
            viewModel.updateRationOptimums(rationOptimums)
            
            Task {
                await viewModel.loadServerRation(for: viewModel.selectedDate)
                viewModel.checkAndCreateRationOptimum(for: viewModel.selectedDate, users: users, modelContext: modelContext)
            }
        }
        .alert("Новый прием пищи", isPresented: $showingAddMealAlert) {
            TextField("Название", text: $newMealName)
            Button("Отмена", role: .cancel) {
                newMealName = ""
            }
            Button("Добавить") {
                guard !newMealName.isEmpty else { return }
                
                let maxID = meals.map { $0.MealID }.max() ?? 0
                let newMeal = MealList(MealID: maxID + 1, MealName: newMealName)
                modelContext.insert(newMeal)
                
                do {
                    try modelContext.save()
                    newMealName = ""
                } catch {
                    print("Error saving meal: \(error)")
                }
            }
        } message: {
            Text("Введите название для нового приема пищи")
        }
        .sheet(isPresented: $showRationPopUp) {
            RationPopUp(
                mealID: selectedMealIDForPopUp,
                selectedDate: viewModel.selectedDate
            )
            .presentationDetents([.medium, .large])
        }
    }
    
    private func refreshData() async {
        isRefreshing = true
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                Task {
                    await viewModel.loadServerRation(for: viewModel.selectedDate)
                    continuation.resume()
                }
            }
        }
        isRefreshing = false
    }
    
    private func deleteRationItem(_ item: RationInfo) {
        modelContext.delete(item)
        do {
            try modelContext.save()
        } catch {
            print("❌ Error deleting ration item: \(error)")
        }
    }
}
