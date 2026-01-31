//
//  StatisticView.swift
//  Project-Portion-demo
//
//  Created by Evgenii Sukhov on 30.01.2026.
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Constants & Configuration
private enum StatisticConstants {
    static let baseURL = "http://\(ServerConfig.YourIP):8000"
    static let dateFormat = "dd.MM.yyyy"
    static let significantThreshold = 0.1
}

// MARK: - Statistic Service Protocols
protocol StatisticServiceProtocol {
    func loadRationForPeriod(startDate: Date, endDate: Date, user: SendableUserInfo) async throws -> [SendableRationInfo]
    func loadAllPurchasesForPeriod(startDate: Date, endDate: Date, user: SendableUserInfo) async throws -> [SendableAllPurch]
}

// MARK: - Network Statistic Service
final class NetworkStatisticService: StatisticServiceProtocol {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func loadRationForPeriod(startDate: Date, endDate: Date, user: SendableUserInfo) async throws -> [SendableRationInfo] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = StatisticConstants.dateFormat
        
        let parameters: [String: Any] = [
            "start_date": dateFormatter.string(from: startDate),
            "end_date": dateFormatter.string(from: endDate),
            "user_id": user.userID.uuidString
        ]
        
        let urlString = "\(StatisticConstants.baseURL)/get_ration_by_daterange"
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
    
    func loadAllPurchasesForPeriod(startDate: Date, endDate: Date, user: SendableUserInfo) async throws -> [SendableAllPurch] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = StatisticConstants.dateFormat
        
        let parameters: [String: Any] = [
            "start_date": dateFormatter.string(from: startDate),
            "end_date": dateFormatter.string(from: endDate),
            "user_id": user.userID.uuidString,
            "family_id": user.userFamilyID,
            "user_acc_type": Int(user.userAccType)
        ]
        
        let urlString = "\(StatisticConstants.baseURL)/get_allpurch_by_daterange"
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
              let purchasesData = json["purchases"] as? [[Any]] else {
            throw URLError(.cannotParseResponse)
        }
        
        return purchasesData.compactMap { parseAllPurchFromServer(data: $0) }
    }
    
    private func parseRationFromServer(data: [Any]) -> SendableRationInfo? {
        guard data.count >= 22 else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = StatisticConstants.dateFormat
        
        let expireDateString = data[9] as? String ?? ""
        let rationDateString = data[14] as? String ?? ""
        
        let expireDate = expireDateString.isEmpty ? Date() : dateFormatter.date(from: expireDateString) ?? Date()
        let rationDate = rationDateString.isEmpty ? Date() : dateFormatter.date(from: rationDateString) ?? Date()
        
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
    
    private func parseAllPurchFromServer(data: [Any]) -> SendableAllPurch? {
        guard data.count >= 20 else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = StatisticConstants.dateFormat
        
        let expireDateString = data[9] as? String ?? ""
        let orderDateString = data[14] as? String ?? ""
        
        let expireDate = expireDateString.isEmpty ? Date() : dateFormatter.date(from: expireDateString) ?? Date()
        let orderDate = orderDateString.isEmpty ? Date() : dateFormatter.date(from: orderDateString) ?? Date()
        
        return SendableAllPurch(
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
            store: data[12] as? String ?? "",
            storeID: data[13] as? Int ?? 0,
            orderDate: orderDate,
            prefMealID: data[15] as? Int ?? 0,
            prefMeal: data[16] as? String ?? "",
            totalCost: data[17] as? Double ?? 0.0,
            address: data[18] as? String ?? "",
            addressID: data[19] as? Int ?? 0
        )
    }
}

// MARK: - Statistic Data Structures
struct StatisticCache {
    let filteredRationItems: [RationInfo]
    let filteredRationOptimums: [RationOptimum]
    let filteredAllPurchases: [AllPurch]
    let categoryCosts: [(category: String, amount: Double, color: Color)]
    let dailySums: [Date: (kcal: Double, protein: Double, fat: Double, carbs: Double)]
    let averageValues: (kcal: Double, protein: Double, fat: Double, carbs: Double)
    let averageOptimumValues: (kcal: Double, protein: Double, fat: Double, carbs: Double)
    
    static let empty = StatisticCache(
        filteredRationItems: [],
        filteredRationOptimums: [],
        filteredAllPurchases: [],
        categoryCosts: [],
        dailySums: [:],
        averageValues: (0, 0, 0, 0),
        averageOptimumValues: (0, 0, 0, 0)
    )
}

// MARK: - Statistic ViewModel
@MainActor
final class StatisticViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedPeriod = 1
    @Published var selectedDate = Date()
    @Published var statIsLoading = false
    
    // MARK: - Private Properties
    private var serverRationItems: [SendableRationInfo] = []
    private var serverAllPurchases: [SendableAllPurch] = []
    private var localRationItems: [RationInfo] = []
    private var localRationOptimums: [RationOptimum] = []
    private var localAllPurchases: [AllPurch] = []
    private var localUsers: [UserInfo] = []
    private var localModelContext: ModelContext?
    private let statisticService: NetworkStatisticService
    
    // MARK: - Cached Properties
    @Published private(set) var cache = StatisticCache.empty {
        didSet {
            print("🎯 Кэш Statistic изменился")
            print("   Калории: \(Int(cache.averageValues.kcal)) (было: \(Int(oldValue.averageValues.kcal)))")
            print("   Затраты: \(cache.filteredAllPurchases.reduce(0) { $0 + $1.TotalCost }) (было: \(oldValue.filteredAllPurchases.reduce(0) { $0 + $1.TotalCost }))")
        }
    }
    
    // MARK: - Computed Properties
    var user: UserInfo? {
        localUsers.first
    }
    
    var currentRationItems: [RationInfo] {
        if serverRationItems.isEmpty {
            return localRationItems
        } else {
            return serverRationItems.map { $0.toRationInfo() }
        }
    }
    
    var currentAllPurchases: [AllPurch] {
        if serverAllPurchases.isEmpty {
            return localAllPurchases
        } else {
            return serverAllPurchases.map { $0.toAllPurch() }
        }
    }
    
    // MARK: - Display Computed Properties (как в Fridge)
    var displayAverageKcal: Int {
        Int(cache.averageValues.kcal)
    }
    
    var displayAverageProtein: Int {
        Int(cache.averageValues.protein)
    }
    
    var displayAverageFat: Int {
        Int(cache.averageValues.fat)
    }
    
    var displayAverageCarbs: Int {
        Int(cache.averageValues.carbs)
    }
    
    var displayTotalCostFormatted: String {
        formattedTotalCost
    }
    
    var displayCategoryCosts: [(category: String, amount: Double, color: Color)] {
        cache.categoryCosts
    }
    
    var displayDeviationPercentage: Int {
        Int(deviationPercentage)
    }
    
    var displayDeviationIcon: String {
        deviationIcon
    }
    
    var displayDeviationColor: Color {
        deviationColor
    }
    
    var displayDeviationDirection: String {
        deviationDirection
    }
    
    var displayRecommendation: Text {
        smartRecommendation
    }
    
    var displayAverageCostPer100Kcal: String {
        formattedCost(averageCostPer100Kcal)
    }
    
    var displayAverageOptimalRationCost: String {
        formattedCost(averageOptimalRationCost)
    }
    
    var periodDates: (start: Date, end: Date) {
        let calendar = Calendar.current
        
        switch selectedPeriod {
        case 0: // Неделя
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
            return (startOfWeek, endOfWeek)
            
        case 1: // Месяц
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            return (startOfMonth, endOfMonth)
            
        case 2: // Год
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: selectedDate))!
            let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear)!
            return (startOfYear, endOfYear)
            
        default:
            return (selectedDate, selectedDate)
        }
    }
    
    // MARK: - Health Computed Properties
    var deviationPercentage: Double {
        let actualKcal = cache.averageValues.kcal
        let optimumKcal = cache.averageOptimumValues.kcal
        
        guard optimumKcal > 0 else { return 0 }
        
        let deviation = ((actualKcal - optimumKcal) / optimumKcal) * 100
        return abs(deviation)
    }
    
    var deviationDirection: String {
        let actualKcal = cache.averageValues.kcal
        let optimumKcal = cache.averageOptimumValues.kcal
        
        if actualKcal < optimumKcal {
            return "ниже"
        } else if actualKcal > optimumKcal {
            return "выше"
        } else {
            return "соответствует"
        }
    }
    
    var deviationIcon: String {
        let actualKcal = cache.averageValues.kcal
        let optimumKcal = cache.averageOptimumValues.kcal
        
        if actualKcal < optimumKcal {
            return "arrow.down"
        } else if actualKcal > optimumKcal {
            return "arrow.up"
        } else {
            return "equal"
        }
    }
    
    var deviationColor: Color {
        let actualKcal = cache.averageValues.kcal
        let optimumKcal = cache.averageOptimumValues.kcal
        
        if actualKcal < optimumKcal {
            return DesignSystem.Colors.accent2
        } else if actualKcal > optimumKcal {
            return DesignSystem.Colors.accent2
        } else {
            return .green
        }
    }
    
    var smartRecommendation: Text {
        let kcalDeviation = cache.averageValues.kcal - cache.averageOptimumValues.kcal
        let proteinDeviation = cache.averageValues.protein - cache.averageOptimumValues.protein
        let fatDeviation = cache.averageValues.fat - cache.averageOptimumValues.fat
        let carbsDeviation = cache.averageValues.carbs - cache.averageOptimumValues.carbs
        
        let significantThreshold = StatisticConstants.significantThreshold
        let kcalDeviationPercent = abs(kcalDeviation) / cache.averageOptimumValues.kcal
        
        if kcalDeviationPercent > significantThreshold {
            let kcalAction = kcalDeviation > 0 ? "уменьшить" : "увеличить"
            return Text("Рекомендуется \(kcalAction) **энергетическую ценность** рациона")
        } else {
            var decreaseItems: [String] = []
            var increaseItems: [String] = []
            
            let proteinDeviationPercent = abs(proteinDeviation) / cache.averageOptimumValues.protein
            if proteinDeviationPercent > significantThreshold {
                if proteinDeviation > 0 {
                    decreaseItems.append("**белков**")
                } else {
                    increaseItems.append("**белков**")
                }
            }
            
            let fatDeviationPercent = abs(fatDeviation) / cache.averageOptimumValues.fat
            if fatDeviationPercent > significantThreshold {
                if fatDeviation > 0 {
                    decreaseItems.append("**жиров**")
                } else {
                    increaseItems.append("**жиров**")
                }
            }
            
            let carbsDeviationPercent = abs(carbsDeviation) / cache.averageOptimumValues.carbs
            if carbsDeviationPercent > significantThreshold {
                if carbsDeviation > 0 {
                    decreaseItems.append("**углеводов**")
                } else {
                    increaseItems.append("**углеводов**")
                }
            }
            
            if decreaseItems.isEmpty && increaseItems.isEmpty {
                return Text("Ваш рацион сбалансирован!")
            } else {
                var finalString = "Рекомендуется "
                
                if !decreaseItems.isEmpty {
                    finalString += "уменьшить потребление \(decreaseItems.joined(separator: ", "))"
                }
                
                if !increaseItems.isEmpty {
                    if !decreaseItems.isEmpty {
                        finalString += " и "
                    }
                    finalString += "увеличить потребление \(increaseItems.joined(separator: ", "))"
                }
                
                return Text(.init(finalString))
            }
        }
    }
    
    // MARK: - Finance Computed Properties
    var totalCost: Double {
        cache.filteredAllPurchases.reduce(0) { $0 + $1.TotalCost }
    }
    
    var formattedTotalCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        
        if let formatted = formatter.string(from: NSNumber(value: totalCost)) {
            return formatted
        }
        return "\(Int(totalCost))"
    }
    
    var totalKcalPurchases: Double {
        cache.filteredAllPurchases.reduce(0) { $0 + (($1.VolumeGr / 100) * $1.Kcal100g) }
    }
    
    var averageCostPer100Kcal: Double {
        guard totalKcalPurchases > 0 else { return 0 }
        return (totalCost / totalKcalPurchases) * 100
    }
    
    var userOptimalKcal: Double {
        let userFetchDescriptor = FetchDescriptor<UserInfo>()
        do {
            let users = try localModelContext?.fetch(userFetchDescriptor) ?? []
            return users.first?.UserKcalOpt ?? 2500
        } catch {
            return 2500
        }
    }
    
    var averageOptimalRationCost: Double {
        (averageCostPer100Kcal * userOptimalKcal) / 100
    }
    
    // MARK: - Initialization
    init() {
        self.statisticService = NetworkStatisticService()
    }
    
    // MARK: - Public Methods
    func updateRationItems(_ items: [RationInfo]) {
        self.localRationItems = items
        updateCache()
    }
    
    func updateRationOptimums(_ items: [RationOptimum]) {
        self.localRationOptimums = items
        updateCache()
    }
    
    func updateAllPurchases(_ items: [AllPurch]) {
        self.localAllPurchases = items
        updateCache()
    }
    
    func updateUsers(_ users: [UserInfo]) {
        self.localUsers = users
    }
    
    func updateModelContext(_ context: ModelContext?) {
        self.localModelContext = context
    }
    
    func formattedAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        
        if let formatted = formatter.string(from: NSNumber(value: amount)) {
            return "\(formatted) Р"
        }
        return "\(Int(amount)) Р"
    }
    
    func formattedCost(_ cost: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        
        if let formatted = formatter.string(from: NSNumber(value: cost)) {
            return "\(formatted) Р"
        }
        return "\(Int(cost)) Р"
    }
    
    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = StatisticConstants.dateFormat
        return dateFormatter.string(from: date)
    }
    
    // MARK: - Server Data Loading
    func loadServerData() async {
        print("🔄 Statistic: Начало загрузки данных с сервера")
        print("📅 Период: \(formatDate(periodDates.start)) - \(formatDate(periodDates.end))")
        
        await MainActor.run {
            statIsLoading = true
        }
        
        do {
            guard let user = user else {
                throw URLError(.userAuthenticationRequired)
            }
            
            let sendableUser = SendableUserInfo.from(user)
            let period = periodDates
            
            async let rationItems = statisticService.loadRationForPeriod(
                startDate: period.start,
                endDate: period.end,
                user: sendableUser
            )
            
            async let allPurchases = statisticService.loadAllPurchasesForPeriod(
                startDate: period.start,
                endDate: period.end,
                user: sendableUser
            )
            
            let (loadedRations, loadedPurchases) = try await (rationItems, allPurchases)
            
            await MainActor.run {
                print("✅ Statistic: Загружено с сервера:")
                print("   - RationItems: \(loadedRations.count) записей")
                print("   - AllPurchases: \(loadedPurchases.count) записей")
                
                self.serverRationItems = loadedRations
                self.serverAllPurchases = loadedPurchases
                self.statIsLoading = false
                
                self.updateCache()
            }
        } catch {
            print("❌ Statistic: Ошибка: \(error.localizedDescription)")
            await MainActor.run {
                self.serverRationItems = []
                self.serverAllPurchases = []
                self.statIsLoading = false
                self.updateCache()
            }
        }
    }
    
    // MARK: - Private Methods
    private func updateCache() {
        print("🔄 Statistic: Обновление кэша...")
        
        // Фильтруем рацион
        let filteredRationItems = currentRationItems.filter { item in
            item.RationDate >= periodDates.start && item.RationDate <= periodDates.end
        }
        
        print("   - Отфильтровано RationItems: \(filteredRationItems.count)")
        
        // Фильтруем оптимальные значения
        let filteredRationOptimums = localRationOptimums.filter { optimum in
            optimum.RationDate >= periodDates.start && optimum.RationDate <= periodDates.end
        }
        
        // Фильтруем покупки
        let filteredAllPurchases = currentAllPurchases.filter { purchase in
            purchase.OrderDate >= periodDates.start && purchase.OrderDate <= periodDates.end
        }
        
        print("   - Отфильтровано AllPurchases: \(filteredAllPurchases.count)")
        
        // Вычисляем категории затрат
        let categoryCosts = calculateCategoryCosts(from: filteredAllPurchases)
        
        // Вычисляем ежедневные суммы
        let dailySums = calculateDailySums(from: filteredRationItems)
        
        // Вычисляем средние значения
        let averageValues = calculateAverageValues(from: dailySums)
        
        // Вычисляем средние оптимальные значения
        let averageOptimumValues = calculateAverageOptimumValues(from: filteredRationOptimums)
        
        let newCache = StatisticCache(
            filteredRationItems: filteredRationItems,
            filteredRationOptimums: filteredRationOptimums,
            filteredAllPurchases: filteredAllPurchases,
            categoryCosts: categoryCosts,
            dailySums: dailySums,
            averageValues: averageValues,
            averageOptimumValues: averageOptimumValues
        )
        
        self.cache = newCache
        print("✅ Statistic: Кэш обновлен напрямую")
    }
    
    private func calculateCategoryCosts(from purchases: [AllPurch]) -> [(category: String, amount: Double, color: Color)] {
        var categories: [String: Double] = [:]
        
        for purchase in purchases {
            let category: String
            if purchase.StoreID == 1 {
                category = purchase.Cat.isEmpty ? "Без категории" : purchase.Cat
            } else {
                category = "Прочее"
            }
            categories[category, default: 0] += purchase.TotalCost
        }
        
        let sortedCategories = categories.sorted { $0.value > $1.value }
        let categoryColors: [Color] = [
            DesignSystem.Colors.accent3,
            DesignSystem.Colors.accent4,
            DesignSystem.Colors.accent2,
            DesignSystem.Colors.accent1,
            DesignSystem.Colors.grey1
        ]
        
        return sortedCategories.enumerated().map { index, element in
            let colorIndex = index % categoryColors.count
            return (category: element.key, amount: element.value, color: categoryColors[colorIndex])
        }
    }
    
    private func calculateDailySums(from items: [RationInfo]) -> [Date: (kcal: Double, protein: Double, fat: Double, carbs: Double)] {
        let grouped = Dictionary(grouping: items) { item in
            Calendar.current.startOfDay(for: item.RationDate)
        }
        
        return grouped.mapValues { items in
            let totalKcal = items.reduce(0) { $0 + $1.KcalServ }
            let totalProtein = items.reduce(0) { $0 + $1.ProtServ }
            let totalFat = items.reduce(0) { $0 + $1.FatServ }
            let totalCarbs = items.reduce(0) { $0 + $1.CarbServ }
            return (totalKcal, totalProtein, totalFat, totalCarbs)
        }
    }
    
    private func calculateAverageValues(from dailySums: [Date: (kcal: Double, protein: Double, fat: Double, carbs: Double)]) -> (kcal: Double, protein: Double, fat: Double, carbs: Double) {
        let daysWithData = dailySums.values
        
        guard !daysWithData.isEmpty else {
            return (0, 0, 0, 0)
        }
        
        let totalKcal = daysWithData.reduce(0) { $0 + $1.kcal }
        let totalProtein = daysWithData.reduce(0) { $0 + $1.protein }
        let totalFat = daysWithData.reduce(0) { $0 + $1.fat }
        let totalCarbs = daysWithData.reduce(0) { $0 + $1.carbs }
        
        let daysCount = Double(daysWithData.count)
        
        return (
            totalKcal / daysCount,
            totalProtein / daysCount,
            totalFat / daysCount,
            totalCarbs / daysCount
        )
    }
    
    private func calculateAverageOptimumValues(from optimums: [RationOptimum]) -> (kcal: Double, protein: Double, fat: Double, carbs: Double) {
        guard !optimums.isEmpty else {
            return (0, 0, 0, 0)
        }
        
        let totalKcalOpt = optimums.reduce(0) { $0 + $1.UserKcalOpt }
        let totalProteinOpt = optimums.reduce(0) { $0 + $1.UserProtOpt }
        let totalFatOpt = optimums.reduce(0) { $0 + $1.UserFatOpt }
        let totalCarbsOpt = optimums.reduce(0) { $0 + $1.UserCarbOpt }
        
        let optimumsCount = Double(optimums.count)
        return (
            totalKcalOpt / optimumsCount,
            totalProteinOpt / optimumsCount,
            totalFatOpt / optimumsCount,
            totalCarbsOpt / optimumsCount
        )
    }
}

// MARK: - Component Views
struct StatisticTopHeaderView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: StatisticViewModel
    
    var body: some View {
        HStack {
            Text("Статистика")
                .font(DesignSystem.Typography.screentitle)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                .padding(.top, 10)
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle().frame(width: 6, height: 6)
                Circle().frame(width: 6, height: 6)
                Circle().frame(width: 6, height: 6)
            }
            .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
            .padding(.top, 10)
        }
    }
}

struct StatisticPeriodView: View {
    @ObservedObject var viewModel: StatisticViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            SegmentedControl(
                items: ["Неделя", "Месяц", "Год"],
                selectedIndex: Binding(
                    get: { viewModel.selectedPeriod },
                    set: { newValue in
                        viewModel.selectedPeriod = newValue
                    }
                )
            )
            .padding(.top, 4)
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            
            DatePicker("Выберите дату",
                      selection: $viewModel.selectedDate,
                      displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                .padding(.top, 12)
        }
    }
}

struct HealthSectionView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isExpanded: Bool
    @ObservedObject var viewModel: StatisticViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Здоровье")
                    .font(DesignSystem.Typography.CatTitle)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                }
            }
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            .padding(.top, 16)
            
            if isExpanded {
                HealthContentSectionView(viewModel: viewModel)
                    .padding(.top, 2)
            }
        }
    }
}

struct HealthContentSectionView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: StatisticViewModel
    
    var body: some View {
        let _ = print("🔄 HealthContentSectionView body вызывается")
        let _ = print("   - displayAverageKcal: \(viewModel.displayAverageKcal)")
        let _ = print("   - displayDeviationPercentage: \(viewModel.displayDeviationPercentage)")
        
        HStack {
            ZStack {
               // Image(colorScheme == .dark ? "blurbannerdark" : "blurbanner")
                   // .resizable()
                   // .aspectRatio(contentMode: .fill)
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 142, height: 172)
                    .cornerRadius(20)
                
                VStack {
                    Text("Ваш среднесуточный рацион составил:")
                        .font(DesignSystem.Typography.Variation2)
                        .foregroundColor(Color.white.opacity(0.85))
                        .frame(width: 120)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(viewModel.displayAverageKcal) Ккал")
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
                            NutrientBlockBanner(letter: "Б", number: "\(viewModel.displayAverageProtein)")
                            NutrientBlockBanner(letter: "Ж", number: "\(viewModel.displayAverageFat)")
                            NutrientBlockBanner(letter: "У", number: "\(viewModel.displayAverageCarbs)")
                        }
                        .padding(.top, 4)
                        .frame(width: 114, alignment: .trailing)
                    }
                    .padding(.top, 1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .leading) {
                Text("Ваш рацион на")
                    .font(DesignSystem.Typography.Variation1)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.8))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                
                HStack(alignment: .center, spacing: 0) {
                    Text("**\(viewModel.displayDeviationPercentage)%**")
                        .font(DesignSystem.Typography.screentitle)
                        .foregroundColor(viewModel.displayDeviationColor.opacity(1))
                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    
                    Image(systemName: viewModel.displayDeviationIcon)
                        .foregroundColor(viewModel.displayDeviationColor)
                        .font(.system(size: 17, weight: .semibold))
                        .padding(.top, 1)
                        .padding(.leading, 1)
                }
                
                Text("\(viewModel.displayDeviationDirection) рекомендуемой нормы")
                    .font(DesignSystem.Typography.Variation1)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                
                Text("\(viewModel.displayRecommendation)")
                    .font(DesignSystem.Typography.ProdName)
                    .padding(.top, 4)
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
            }
            .padding(.leading, 8)
            
            Spacer()
        }
        .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
    }
}

struct FinanceSectionView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isExpanded: Bool
    @ObservedObject var viewModel: StatisticViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Финансы")
                    .font(DesignSystem.Typography.CatTitle)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                }
            }
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            .padding(.top, 12)
            
            if isExpanded {
                FinanceContentSectionView(viewModel: viewModel)
            }
        }
    }
}

struct FinanceContentSectionView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: StatisticViewModel
    
    var body: some View {
        let _ = print("💰 FinanceContentSectionView body вызывается")
        let _ = print("   - displayTotalCostFormatted: \(viewModel.displayTotalCostFormatted)")
        let _ = print("   - displayCategoryCosts.count: \(viewModel.displayCategoryCosts.count)")
        
        VStack(spacing: 0) {
            HStack {
                Text("\(viewModel.displayTotalCostFormatted)")
                    .font(DesignSystem.Typography.FinanceMain)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                
                Spacer()
            }
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            .padding(.top, 8)
            
            HStack {
                Text("Столько вы потратили на заказы этом месяце")
                    .font(DesignSystem.Typography.Variation1)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                
                Spacer()
            }
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.displayCategoryCosts, id: \.category) { category in
                        HStack {
                            Circle()
                                .fill(category.color)
                                .frame(width: 22, height: 22)
                            
                            Text(viewModel.formattedAmount(category.amount))
                                .font(DesignSystem.Typography.SelectButton)
                                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                            
                            Circle()
                                .fill(DesignSystem.Colors.primary(for: colorScheme).opacity(0.7))
                                .frame(width: 4, height: 4)
                            
                            Text(category.category)
                                .font(DesignSystem.Typography.Variation3)
                                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                        }
                    }
                    
                    if viewModel.displayCategoryCosts.isEmpty {
                        HStack {
                            Circle()
                                .fill(DesignSystem.Colors.grey1)
                                .frame(width: 22, height: 22)
                            
                            Text("0 Р")
                                .font(DesignSystem.Typography.SelectButton)
                                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                            
                            Circle()
                                .fill(DesignSystem.Colors.primary(for: colorScheme).opacity(0.7))
                                .frame(width: 4, height: 4)
                            
                            Text("Нет данных")
                                .font(DesignSystem.Typography.Variation3)
                                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                        }
                    }
                }
                .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                .padding(.vertical, 24)
            }
            
            VStack {
                HStack {
                    Text("Средняя стоимость **100 Ккал** в вашем рационе:")
                        .font(DesignSystem.Typography.Variation1)
                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                        .frame(maxWidth: 220)
                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    
                    Spacer()
                    
                    Text("\(viewModel.displayAverageCostPer100Kcal)")
                        .font(.custom("Montserrat-SemiBold", size: 22))
                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                }
                .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                
                Divider()
                    .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                    .padding(.vertical, 4)
                
                HStack {
                    HStack(alignment: .top, spacing: 0) {
                        Text("Средняя стоимость **рациона**")
                            .font(DesignSystem.Typography.Variation1)
                            .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                            .tracking(DesignSystem.tracking(for: .body, percent: -3))
                        
                        Text(" оптимального")
                            .font(DesignSystem.Typography.Variation1)
                            .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                            .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    }
                    .frame(maxWidth: 270, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    // ИСПОЛЬЗУЕМ DISPLAY PROPERTY
                    Text("\(viewModel.displayAverageOptimalRationCost)")
                        .font(.custom("Montserrat-SemiBold", size: 22))
                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    
                }
                .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            }
        }
    }
}

struct RecommendationsSectionView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Рекомендации")
                    .font(DesignSystem.Typography.CatTitle)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                Spacer()
            }
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            .padding(.top, 12)
            
            RecTestGrid()
        }
    }
}

struct RecTestGrid: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            HStack(spacing: 10) {
                RecommendationCard(
                    imageName: "greek_yogurt",
                    price: "100 Р",
                    name: "Греческий йогурт",
                    volume: "250 г",
                    nutrients: ("8", "2", "0"),
                    tag: "Много белка",
                    tagColor: DesignSystem.Colors.accent2
                )
                
                RecommendationCard(
                    imageName: "ice_latte",
                    price: "100 Р",
                    oldPrice: "140 Р",
                    name: "Айс латте",
                    volume: "300 мл",
                    nutrients: ("1", "3", "0"),
                    tag: "На работу",
                    tagColor: DesignSystem.Colors.accent3
                )
            }
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            
            HStack(spacing: 10) {
                RecommendationCard(
                    imageName: "exponenta",
                    price: "160 Р",
                    oldPrice: "190 Р",
                    name: "Напиток exponenta",
                    volume: "300 мл",
                    nutrients: ("10", "2", "0"),
                    tag: "Много белка",
                    tagColor: DesignSystem.Colors.accent2
                )
                
                RecommendationCard(
                    imageName: "pasta_mushrooms",
                    price: "100 Р",
                    name: "Паста с грибами",
                    volume: "200 г",
                    nutrients: ("12", "20", "65"),
                    tag: "Быстро",
                    tagColor: DesignSystem.Colors.accent3
                )
            }
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            
            HStack(spacing: 10) {
                RecommendationCard(
                    imageName: "brownie_bar",
                    price: "110 Р",
                    name: "Батончик брауни",
                    volume: "40 г",
                    nutrients: ("8", "20", "0"),
                    tag: nil,
                    tagColor: nil
                )
                
                RecommendationCard(
                    imageName: "pasta",
                    price: "115 Р",
                    name: "Паста barilla",
                    volume: "400 г",
                    nutrients: ("12", "3", "65"),
                    tag: nil,
                    tagColor: nil
                )
            }
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
        }
    }
}

struct RecommendationCard: View {
    @Environment(\.colorScheme) var colorScheme
    let imageName: String
    let price: String
    let oldPrice: String?
    let name: String
    let volume: String
    let nutrients: (String, String, String)
    let tag: String?
    let tagColor: Color?
    
    init(imageName: String, price: String, oldPrice: String? = nil, name: String, volume: String,
         nutrients: (String, String, String), tag: String? = nil, tagColor: Color? = nil) {
        self.imageName = imageName
        self.price = price
        self.oldPrice = oldPrice
        self.name = name
        self.volume = volume
        self.nutrients = nutrients
        self.tag = tag
        self.tagColor = tagColor
    }
    
    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.33) : DesignSystem.Colors.grey1)
                    .opacity(0.5)
                    .frame(height: 196)
                    .cornerRadius(20)
                
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 140)
                
                ZStack(alignment: .bottomTrailing) {
                    Color.clear
                    HStack(spacing: 3) {
                        NutrientBlockSmallBanner(number: nutrients.0)
                        NutrientBlockSmallBanner(number: nutrients.1)
                        NutrientBlockSmallBanner(number: nutrients.2)
                    }
                    .offset(x: -9, y: -9)
                }
            }
            
            HStack {
                Text(price)
                    .font(DesignSystem.Typography.CcalMedium)
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                
                if let oldPrice = oldPrice {
                    Text(oldPrice)
                        .font(DesignSystem.Typography.ProdName)
                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.6))
                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                        .overlay(
                            GeometryReader { geometry in
                                Rectangle()
                                    .fill(Color.red)
                                    .frame(height: 2)
                                    .rotationEffect(.degrees(-13))
                                    .frame(width: geometry.size.width * 1.2)
                                    .offset(x: -geometry.size.width * 0.1, y: geometry.size.height / 2.5)
                            }
                        )
                }
                
                Spacer()
            }
            
            HStack {
                Text(name)
                    .font(DesignSystem.Typography.ProdName)
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                
                Spacer()
            }
            
            HStack {
                Text(volume)
                    .font(DesignSystem.Typography.ProdVolume)
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                
                Spacer()
            }
            
            if let tag = tag, let tagColor = tagColor {
                HStack(spacing: 3) {
                    
                    Circle()
                        .foregroundColor(tagColor)
                        .frame(width: 20, height: 20)
                        .opacity(0.75)
                    
                    Text(tag)
                        .font(DesignSystem.Typography.Tag)
                        .foregroundColor(tagColor.opacity(0.8))
                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Main Statistic View
struct StatisticView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    @Query private var rationItems: [RationInfo]
    @Query private var rationOptimums: [RationOptimum]
    @Query private var allPurchases: [AllPurch]
    @Query private var users: [UserInfo]
    
    @StateObject private var viewModel: StatisticViewModel
    @State private var isExpandedH = true
    @State private var isExpandedF = true
    @State private var isRefreshing = false
    
    init() {
        _viewModel = StateObject(wrappedValue: StatisticViewModel())
    }
    
    var body: some View {
        let _ = print("📱 StatisticView body вызывается")
        let _ = print("   - isLoading: \(viewModel.statIsLoading)")
        let _ = print("   - displayAverageKcal: \(viewModel.displayAverageKcal)")
        let _ = print("   - displayTotalCostFormatted: \(viewModel.displayTotalCostFormatted)")
        
        VStack(spacing: 0) {
            StatisticTopHeaderView(viewModel: viewModel)
                .padding(.bottom, 8)
                .background(Color.clear)
                .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            
            ScrollView {
                LazyVStack(spacing: 2) {
                    StatisticPeriodView(viewModel: viewModel)
                    
                    HealthSectionView(
                        isExpanded: $isExpandedH,
                        viewModel: viewModel
                    )
                    
                    FinanceSectionView(
                        isExpanded: $isExpandedF,
                        viewModel: viewModel
                    )
                    
                    RecommendationsSectionView()
                }
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
            print("📱 StatisticView onAppear")
            print("📊 Начальные данные:")
            print("   - RationItems: \(rationItems.count)")
            print("   - AllPurchases: \(allPurchases.count)")
            
            viewModel.updateRationItems(rationItems)
            viewModel.updateRationOptimums(rationOptimums)
            viewModel.updateAllPurchases(allPurchases)
            viewModel.updateUsers(users)
            viewModel.updateModelContext(modelContext)
            
            Task {
                await viewModel.loadServerData()
            }
        }
        .onChange(of: viewModel.selectedPeriod) { oldValue, newValue in
            print("📅 Период изменен: \(oldValue) -> \(newValue)")
            Task {
                await viewModel.loadServerData()
            }
        }
        .onChange(of: viewModel.selectedDate) { oldValue, newValue in
            print("📅 Дата изменена: \(oldValue) -> \(newValue)")
            Task {
                await viewModel.loadServerData()
            }
        }
    }
    
    private func refreshData() async {
        print("🔄 Pull-to-refresh запущен")
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                Task {
                    await viewModel.loadServerData()
                    continuation.resume()
                }
            }
        }
    }
}
