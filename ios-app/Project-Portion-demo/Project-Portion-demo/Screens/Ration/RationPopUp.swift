//
//  RationPopUp.swift
//  Project-Portion-demo
//
//  Created by Evgenii Sukhov on 30.01.2026.
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Constants & Configuration
private enum PopUpConstants {
    static let baseURL = "http://\(ServerConfig.YourIP):8000"
    static let dateFormat = "dd.MM.yyyy"
    static let soonExpiringThresholdDays = 20
    static let noExpireDateYears = 100
}

// MARK: - PopUp Service Protocols
protocol MainPurchServiceProtocol {
    func loadMainPurch(for user: SendableUserInfo) async throws -> [SendableMainPurch]
}

protocol OtherPurchServiceProtocol {
    func loadOtherPurch(for user: SendableUserInfo) async throws -> [SendableOtherPurch]
}

// MARK: - Network Services
final class NetworkMainPurchService: MainPurchServiceProtocol {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func loadMainPurch(for user: SendableUserInfo) async throws -> [SendableMainPurch] {
        let parameters: [String: Any] = user.userAccType == 0
            ? ["user_id": user.userID.uuidString, "family_id": "0"]
            : ["family_id": user.userFamilyID]
        
        let urlString = "\(PopUpConstants.baseURL)/get_main_purch"
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
              let productsData = json["products"] as? [[Any]] else {
            throw URLError(.cannotParseResponse)
        }
        
        return productsData.compactMap { parseProductFromServer(data: $0) }
    }
    
    private func parseProductFromServer(data: [Any]) -> SendableMainPurch? {
        guard data.count >= 20 else { return nil }
        
        let orderDate = parseDate(from: data[14] as? String) ?? Date()
        let expireDate = parseDate(from: data[9] as? String) ?? Date()
        let userID = data[18] as? String ?? ""
        let familyID = data[19] as? Int ?? 0
        
        return SendableMainPurch(
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
            prefMealID: 0,
            prefMeal: "",
            totalCost: data[15] as? Double ?? 0,
            address: data[16] as? String ?? "",
            addressID: data[17] as? Int ?? 0,
            userID: userID,
            familyID: familyID
        )
    }
    
    private func parseDate(from dateString: String?) -> Date? {
        guard let dateString = dateString, !dateString.isEmpty else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = PopUpConstants.dateFormat
        return dateFormatter.date(from: dateString)
    }
}

final class NetworkOtherPurchService: OtherPurchServiceProtocol {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func loadOtherPurch(for user: SendableUserInfo) async throws -> [SendableOtherPurch] {
        let parameters: [String: Any] = user.userAccType == 0
            ? ["user_id": user.userID.uuidString, "family_id": "0"]
            : ["family_id": user.userFamilyID]
        
        let urlString = "\(PopUpConstants.baseURL)/get_other_purch"
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
              let productsData = json["products"] as? [[Any]] else {
            throw URLError(.cannotParseResponse)
        }
        
        return productsData.compactMap { parseOtherProductFromServer(data: $0) }
    }
    
    private func parseOtherProductFromServer(data: [Any]) -> SendableOtherPurch? {
        guard data.count >= 19 else { return nil }
        
        let orderDate = parseDate(from: data[13] as? String) ?? Date()
        let userID = data[17] as? String ?? ""
        let familyID = data[18] as? Int ?? 0
        
        return SendableOtherPurch(
            prodID: data[0] as? Int ?? 0,
            name: data[1] as? String ?? "",
            volume: data[2] as? Double ?? 0,
            unit: data[3] as? String ?? "",
            volumeGr: data[4] as? Double ?? 0,
            kcal100g: data[5] as? Double ?? 0,
            prot100g: data[6] as? Double ?? 0,
            fat100g: data[7] as? Double ?? 0,
            carb100g: data[8] as? Double ?? 0,
            tag: data[9] as? String ?? "",
            cat: data[10] as? String ?? "",
            store: data[11] as? String ?? "",
            storeID: data[12] as? Int ?? 0,
            orderDate: orderDate,
            totalCost: data[14] as? Double ?? 0,
            address: data[15] as? String ?? "",
            addressID: data[16] as? Int ?? 0,
            userID: userID,
            familyID: familyID
        )
    }
    
    private func parseDate(from dateString: String?) -> Date? {
        guard let dateString = dateString, !dateString.isEmpty else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = PopUpConstants.dateFormat
        return dateFormatter.date(from: dateString)
    }
}

// MARK: - PopUp ViewModels
@MainActor
final class RationPopUpFridgeViewModel: ObservableObject {
    @Published var isLoading = false
    
    private var serverProducts: [SendableMainPurch] = []
    private var users: [UserInfo] = []
    private let localProducts: [MainPurch]
    private let mainPurchService: NetworkMainPurchService
    
    var user: UserInfo? {
        users.first
    }
    
    var currentProducts: [MainPurch] {
        if serverProducts.isEmpty {
            return localProducts
        } else {
            return serverProducts.map { $0.toMainPurch() }
        }
    }
    
    var soonExpiringProducts: [MainPurch] {
        let soonExpiringThreshold = Calendar.current.date(
            byAdding: .day,
            value: PopUpConstants.soonExpiringThresholdDays,
            to: Date()
        ) ?? Date()
        
        let noExpireDate = Calendar.current.date(
            byAdding: .year,
            value: PopUpConstants.noExpireDateYears,
            to: Date()
        ) ?? Date()
        
        return currentProducts.filter { product in
            product.ExpireDate < soonExpiringThreshold && product.ExpireDate != noExpireDate
        }
    }
    
    var productsByCategory: [String: [MainPurch]] {
        let soonExpiringThreshold = Calendar.current.date(
            byAdding: .day,
            value: PopUpConstants.soonExpiringThresholdDays,
            to: Date()
        ) ?? Date()
        
        let noExpireDate = Calendar.current.date(
            byAdding: .year,
            value: PopUpConstants.noExpireDateYears,
            to: Date()
        ) ?? Date()
        
        let filteredProducts = currentProducts.filter { product in
            product.ExpireDate >= soonExpiringThreshold || product.ExpireDate == noExpireDate
        }
        
        return Dictionary(grouping: filteredProducts) { $0.Cat }
    }
    
    init(products: [MainPurch]) {
        self.localProducts = products
        self.mainPurchService = NetworkMainPurchService()
    }
    
    func updateUsers(_ users: [UserInfo]) {
        self.users = users
    }
    
    func loadServerData() async {
        guard let user = user else {
            await MainActor.run {
                serverProducts = []
                isLoading = false
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let sendableUser = SendableUserInfo.from(user)
            let loadedProducts = try await mainPurchService.loadMainPurch(for: sendableUser)
            
            await MainActor.run {
                self.serverProducts = loadedProducts
                self.isLoading = false
            }
        } catch {
            print("❌ RationPopUpFridgeViewModel: Ошибка: \(error.localizedDescription)")
            await MainActor.run {
                serverProducts = []
                isLoading = false
            }
        }
    }
    
    func getUniqueUsersCount(in products: [MainPurch]) -> Int {
        Set(products.map { $0.UserID }).count
    }
    
    func groupProductsByUser(in products: [MainPurch]) -> [String: [MainPurch]] {
        Dictionary(grouping: products) { product in
            product.UserID.isEmpty ? "unknown" : product.UserID
        }
    }
}

@MainActor
final class RationPopUpOtherViewModel: ObservableObject {
    @Published var isLoading = false
    
    private var serverOtherProducts: [SendableOtherPurch] = []
    private var users: [UserInfo] = []
    private let localOtherPurchases: [OtherPurch]
    private let otherPurchService: NetworkOtherPurchService
    
    var user: UserInfo? {
        users.first
    }
    
    var currentOtherProducts: [OtherPurch] {
        if serverOtherProducts.isEmpty {
            return localOtherPurchases
        } else {
            return serverOtherProducts.map { $0.toOtherPurch() }
        }
    }
    
    var ordersByDateAndStore: [String: [OtherPurch]] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = PopUpConstants.dateFormat
        
        return Dictionary(grouping: currentOtherProducts) { purchase in
            let dateString = dateFormatter.string(from: purchase.OrderDate)
            return "\(dateString)|\(purchase.Store)"
        }
    }
    
    var sortedOrderKeys: [String] {
        ordersByDateAndStore.keys.sorted { key1, key2 in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = PopUpConstants.dateFormat
            
            let components1 = key1.components(separatedBy: "|")
            let components2 = key2.components(separatedBy: "|")
            
            if let date1 = dateFormatter.date(from: components1[0]),
               let date2 = dateFormatter.date(from: components2[0]) {
                return date1 > date2
            }
            return key1 > key2
        }
    }
    
    init(otherPurchases: [OtherPurch]) {
        self.localOtherPurchases = otherPurchases
        self.otherPurchService = NetworkOtherPurchService()
    }
    
    func updateUsers(_ users: [UserInfo]) {
        self.users = users
    }
    
    func loadServerOtherData() async {
        guard let user = user else {
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let sendableUser = SendableUserInfo.from(user)
            let loadedProducts = try await otherPurchService.loadOtherPurch(for: sendableUser)
            
            await MainActor.run {
                self.serverOtherProducts = loadedProducts
                self.isLoading = false
            }
        } catch {
            print("❌ RationPopUpOtherViewModel: Ошибка: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    func getUniqueUsersCount(in orders: [OtherPurch]) -> Int {
        Set(orders.map { $0.UserID }).count
    }
    
    func groupByUser(in orders: [OtherPurch]) -> [String: [OtherPurch]] {
        Dictionary(grouping: orders) { purchase in
            purchase.UserID
        }
    }
}

// MARK: - PopUp Views Data Structures
struct ProductCardRowPopUpData {
    let product: MainPurch
    let index: Int
    let isPersonalAccount: Bool
    let userID: String
    let mealID: Int
    let selectedDate: Date
}

struct CategorySectionPopUpData {
    let title: String
    let products: [MainPurch]
    let uniqueUsersCount: Int
    let userGroups: [String: [MainPurch]]
    let showUserHeaders: Bool
    let mealID: Int
    let selectedDate: Date
}

struct ProductCardRowPopUpOtherData {
    let purchase: OtherPurch
    let index: Int
    let mealID: Int
    let selectedDate: Date
}

struct OrderSectionData {
    let key: String
    let orders: [OtherPurch]
    let store: String
    let orderDate: String
    let uniqueUsersCount: Int
    let userGroups: [String: [OtherPurch]]
    let mealID: Int
    let selectedDate: Date
}

// MARK: - PopUp Component Views
struct ProductCardRowPopUp: View {
    let data: ProductCardRowPopUpData
    
    var body: some View {
        VStack(spacing: 0) {
            if data.index > 0 {
                Divider()
                    .padding(.vertical, 5)
                    .padding(.leading, 74)
                    .padding(.trailing, 24)
            }
            
            ProductCardPopUp(
                productID: data.product.ProdID,
                productName: data.product.Name,
                volume: "\(Int(data.product.Volume)) \(data.product.Unit)",
                mealID: data.mealID,
                selectedDate: data.selectedDate,
                productData: data.product
            )
            .padding(.top, data.index == 0 ? 4 : 0)
        }
    }
}

struct CategorySectionPopUp: View {
    @Environment(\.colorScheme) var colorScheme
    let data: CategorySectionPopUpData
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(data.title)
                    .font(DesignSystem.Typography.CatTitle)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                
                Spacer()
                
                if data.uniqueUsersCount > 1 {
                    Text("Участников: \(data.uniqueUsersCount)")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.accent3)
                }
            }
            
            if data.showUserHeaders {
                ForEach(Array(data.userGroups.keys.sorted()), id: \.self) { userID in
                    if let userProducts = data.userGroups[userID], !userProducts.isEmpty {
                        if data.userGroups.count > 1 {
                            HStack {
                                Text("Пользователь: \(userID.prefix(8))...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 4)
                                Spacer()
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        }
                        
                        ForEach(Array(userProducts.enumerated()), id: \.element.ProdID) { index, product in
                            let rowData = ProductCardRowPopUpData(
                                product: product,
                                index: index,
                                isPersonalAccount: false,
                                userID: userID,
                                mealID: data.mealID,
                                selectedDate: data.selectedDate
                            )
                            
                            ProductCardRowPopUp(data: rowData)
                        }
                    }
                }
            } else {
                ForEach(Array(data.products.enumerated()), id: \.element.ProdID) { index, product in
                    let rowData = ProductCardRowPopUpData(
                        product: product,
                        index: index,
                        isPersonalAccount: true,
                        userID: "",
                        mealID: data.mealID,
                        selectedDate: data.selectedDate
                    )
                    
                    ProductCardRowPopUp(data: rowData)
                }
            }
        }
        .padding(.horizontal, min(AdaptiveSpacing.horizontalSpace * 1.5, 30))
        .padding(.top, 12)
    }
}

struct ProductCardRowPopUpOther: View {
    let data: ProductCardRowPopUpOtherData
    
    var body: some View {
        VStack(spacing: 0) {
            if data.index > 0 {
                Divider()
                    .padding(.vertical, 5)
                    .padding(.leading, 74)
                    .padding(.trailing, 24)
            }
            
            ProductCardPopUpOther(
                purchase: data.purchase,
                mealID: data.mealID,
                selectedDate: data.selectedDate
            )
            .padding(.top, data.index == 0 ? 4 : 0)
        }
    }
}

struct OrderSectionPopUp: View {
    @Environment(\.colorScheme) var colorScheme
    let data: OrderSectionData
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.store)
                        .font(DesignSystem.Typography.CatTitle)
                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    
                    Text("Заказ от \(data.orderDate)")
                        .font(DesignSystem.Typography.ProdVolume)
                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.7))
                    
                    if data.uniqueUsersCount > 1 {
                        Text("Участников: \(data.uniqueUsersCount)")
                            .font(DesignSystem.Typography.ProdVolume)
                            .foregroundColor(DesignSystem.Colors.accent3)
                    }
                }
                
                Spacer()
            }
            
            if data.userGroups.count > 1 {
                ForEach(Array(data.userGroups.keys.sorted()), id: \.self) { userID in
                    if let userOrders = data.userGroups[userID], !userOrders.isEmpty {
                        HStack {
                            Text("Пользователь: \(userID.prefix(8))...")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                            Spacer()
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        
                        ForEach(Array(userOrders.enumerated()), id: \.element.ProdID) { index, purchase in
                            let rowData = ProductCardRowPopUpOtherData(
                                purchase: purchase,
                                index: index,
                                mealID: data.mealID,
                                selectedDate: data.selectedDate
                            )
                            
                            ProductCardRowPopUpOther(data: rowData)
                        }
                    }
                }
            } else {
                ForEach(Array(data.orders.enumerated()), id: \.element.ProdID) { index, purchase in
                    let rowData = ProductCardRowPopUpOtherData(
                        purchase: purchase,
                        index: index,
                        mealID: data.mealID,
                        selectedDate: data.selectedDate
                    )
                    
                    ProductCardRowPopUpOther(data: rowData)
                }
            }
        }
        .padding(.horizontal, min(AdaptiveSpacing.horizontalSpace * 1.5, 30))
        .padding(.top, 12)
    }
}

// MARK: - Main PopUp Views
struct RationPopUpFridge: View {
    let products: [MainPurch]
    let mealID: Int
    let selectedDate: Date
    
    @StateObject private var viewModel: RationPopUpFridgeViewModel
    @Query private var users: [UserInfo]
    
    init(products: [MainPurch], mealID: Int, selectedDate: Date) {
        self.products = products
        self.mealID = mealID
        self.selectedDate = selectedDate
        _viewModel = StateObject(wrappedValue: RationPopUpFridgeViewModel(products: products))
    }
    
    private var isPersonalAccount: Bool {
        viewModel.user?.UserAccType == 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.soonExpiringProducts.isEmpty {
                let soonExpiringData = CategorySectionPopUpData(
                    title: "Скоро истекает",
                    products: viewModel.soonExpiringProducts,
                    uniqueUsersCount: isPersonalAccount ? 0 : viewModel.getUniqueUsersCount(in: viewModel.soonExpiringProducts),
                    userGroups: isPersonalAccount ? [:] : viewModel.groupProductsByUser(in: viewModel.soonExpiringProducts),
                    showUserHeaders: !isPersonalAccount && viewModel.getUniqueUsersCount(in: viewModel.soonExpiringProducts) > 1,
                    mealID: self.mealID,
                    selectedDate: self.selectedDate
                )
                
                CategorySectionPopUp(data: soonExpiringData)
            }
            
            ForEach(Array(viewModel.productsByCategory.keys.sorted()), id: \.self) { category in
                if let categoryProducts = viewModel.productsByCategory[category], !categoryProducts.isEmpty {
                    let categoryData = CategorySectionPopUpData(
                        title: category,
                        products: categoryProducts,
                        uniqueUsersCount: isPersonalAccount ? 0 : viewModel.getUniqueUsersCount(in: categoryProducts),
                        userGroups: isPersonalAccount ? [:] : viewModel.groupProductsByUser(in: categoryProducts),
                        showUserHeaders: !isPersonalAccount && viewModel.getUniqueUsersCount(in: categoryProducts) > 1,
                        mealID: self.mealID,
                        selectedDate: self.selectedDate
                    )
                    
                    CategorySectionPopUp(data: categoryData)
                }
            }
        }
        .onAppear {
            viewModel.updateUsers(users)
            Task {
                await viewModel.loadServerData()
            }
        }
        .onChange(of: viewModel.user?.UserAccType) { oldValue, newValue in
            Task {
                await viewModel.loadServerData()
            }
        }
        .onChange(of: viewModel.user?.UserFamilyID) { oldValue, newValue in
            Task {
                await viewModel.loadServerData()
            }
        }
    }
}

struct RationPopUpOther: View {
    let otherPurchases: [OtherPurch]
    let mealID: Int
    let selectedDate: Date
    
    @StateObject private var viewModel: RationPopUpOtherViewModel
    @Query private var users: [UserInfo]
    
    init(otherPurchases: [OtherPurch], mealID: Int, selectedDate: Date) {
        self.otherPurchases = otherPurchases
        self.mealID = mealID
        self.selectedDate = selectedDate
        _viewModel = StateObject(wrappedValue: RationPopUpOtherViewModel(otherPurchases: otherPurchases))
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = PopUpConstants.dateFormat
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.sortedOrderKeys, id: \.self) { key in
                if let orders = viewModel.ordersByDateAndStore[key], !orders.isEmpty {
                    let components = key.components(separatedBy: "|")
                    let orderDate = components[0]
                    let store = components[1]
                    
                    let isPersonalAccount = viewModel.user?.UserAccType == 0
                    
                    let orderData = OrderSectionData(
                        key: key,
                        orders: orders,
                        store: store,
                        orderDate: orderDate,
                        uniqueUsersCount: isPersonalAccount ? 0 : viewModel.getUniqueUsersCount(in: orders),
                        userGroups: isPersonalAccount ? [:] : viewModel.groupByUser(in: orders),
                        mealID: self.mealID,
                        selectedDate: self.selectedDate
                    )
                    
                    OrderSectionPopUp(data: orderData)
                }
            }
        }
        .onAppear {
            viewModel.updateUsers(users)
            Task {
                await viewModel.loadServerOtherData()
            }
        }
        .onChange(of: viewModel.user?.UserAccType) { oldValue, newValue in
            Task {
                await viewModel.loadServerOtherData()
            }
        }
        .onChange(of: viewModel.user?.UserFamilyID) { oldValue, newValue in
            Task {
                await viewModel.loadServerOtherData()
            }
        }
    }
}

struct RationPopUpSearch: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Здесь будет отображаться результат поиска по базе данных")
                .font(DesignSystem.Typography.ProdNameReg)
                .frame(width: 264, height: 60)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
}

// MARK: - Main Ration PopUp View
struct RationPopUp: View {
    @Query private var products: [MainPurch]
    @Query private var otherPurchases: [OtherPurch]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedSegmentIndex = 0
    let mealID: Int
    let selectedDate: Date
    
    private func getMealTitle() -> String {
        switch mealID {
        case 0: return "Завтрак"
        case 1: return "Обед"
        case 2: return "Ужин"
        default: return "Прием пищи"
        }
    }
    
    var body: some View {
        VStack{
            HStack {
                Text(getMealTitle())
                    .font(DesignSystem.Typography.screentitle)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                
                Spacer()
            }
            .padding(.horizontal, min(AdaptiveSpacing.horizontalSpace * 1.5, 30))
            .padding(.top, 30)
            
            SearchMain()
                .padding(.horizontal, min(AdaptiveSpacing.horizontalSpace * 1.5, 30))
            
            SegmentedControl(
                items: ["Запасы", "Заказы", "Вручную"],
                selectedIndex: $selectedSegmentIndex
            )
            .padding(.horizontal, min(AdaptiveSpacing.horizontalSpace * 1.5, 30))
            
            ZStack(alignment: .bottom) {
                ScrollView {
                    Group {
                        switch selectedSegmentIndex {
                        case 0:
                            RationPopUpFridge(
                                products: products,
                                mealID: mealID,
                                selectedDate: selectedDate
                            )
                        case 1:
                            RationPopUpOther(
                                otherPurchases: otherPurchases,
                                mealID: mealID,
                                selectedDate: selectedDate
                            )
                        case 2:
                            RationPopUpSearch()
                        default:
                            RationPopUpFridge(
                                products: products,
                                mealID: mealID,
                                selectedDate: selectedDate 
                            )
                        }
                    }
                    .padding(.bottom, 80)
                }
                
                Rectangle()
                    .fill(.thickMaterial)
                    .mask(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.05),
                                Color.black.opacity(0.6),
                                Color.black.opacity(0.8),
                                Color.black.opacity(1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 100)
                    .overlay(
                        HStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: colorScheme == .dark ? [
                                            Color(hex: "F9F9F9").opacity(0.4),
                                            Color(hex: "F0EDED").opacity(0.4)
                                        ] : [
                                            Color(hex: "F9F9F9"),
                                            Color(hex: "F0EDED")
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ).opacity(0.9)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: colorScheme == .dark ? [
                                                    Color(hex: "F5F4F4").opacity(0.05),
                                                    Color(hex: "E4E0E0").opacity(0.05)
                                                ] : [
                                                    Color(hex: "F5F4F4"),
                                                    Color(hex: "E4E0E0")
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .overlay(
                                    ZStack {
                                        Rectangle()
                                            .fill(colorScheme == .dark ? Color.black.opacity(0.45) : Color(hex: "AEAEAE"))
                                            .frame(width: 20, height: 3)
                                            .rotationEffect(.degrees(45))
                                        Rectangle()
                                            .fill(colorScheme == .dark ? Color.black.opacity(0.45) : Color(hex: "AEAEAE"))
                                            .frame(width: 20, height: 3)
                                            .rotationEffect(.degrees(-45))
                                    }
                                )
                                .frame(width: 50, height: 50)
                            Spacer()
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                DesignSystem.Colors.accent3,
                                                Color(hex: "3397E1")
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ).opacity(0.9)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color(hex: "68C0FF"),
                                                        Color(hex: "339CE9")
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 16, height: 16)
                                            .foregroundColor(.white)
                                            .fontWeight(.bold)
                                    )
                                    .frame(width: 50, height: 50)
                            }
                        }
                        .padding(.bottom, 20)
                        .padding(.horizontal, CGFloat(Int(min(AdaptiveSpacing.horizontalSpace * 1.5, 30) * 1.66)))
                    )
            }
            .ignoresSafeArea(.all, edges: .bottom)
        }
    }
}
