//
//  FridgeView.swift
//  Project-Portion-demo
//
//  Created by Evgenii Sukhov on 30.01.2026.
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Constants & Configuration

private enum Constants {
    static let soonExpiringThresholdDays = 20
    static let baseURL = "http://\(ServerConfig.YourIP):8000"
    static let dateFormat = "dd.MM.yyyy"
    static let noExpireDateYears = 100
}

// MARK: - Helper Types
enum GroupingType {
    case byCategory
    case byPreference
}

// MARK: - Fridge Cache
struct FridgeCache {
    var soonExpiring: [MainPurch]
    var byCategory: [String: [MainPurch]]
    var byPreference: [String: [MainPurch]]
    
    static let empty = FridgeCache(
        soonExpiring: [],
        byCategory: [:],
        byPreference: [:]
    )
}

// MARK: - Fridge Service Protocol
protocol FridgeServiceProtocol {
    func loadProducts(for user: SendableUserInfo) async throws -> [SendableMainPurch]
}

// MARK: - Date Formatter Helper (для использования внутри актора)
struct FridgeDateHelper {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
    
    static func parseDate(from dateString: String?) -> Date? {
        guard let dateString = dateString, !dateString.isEmpty else { return nil }
        return dateFormatter.date(from: dateString)
    }
}

// MARK: - Network Fridge Service
final class NetworkFridgeService: FridgeServiceProtocol {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func loadProducts(for user: SendableUserInfo) async throws -> [SendableMainPurch] {
        let parameters: [String: Any] = user.userAccType == 0
            ? ["user_id": user.userID.uuidString, "family_id": "0"]
            : ["family_id": user.userFamilyID]
        
        let urlString = "\(Constants.baseURL)/get_main_purch"
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
        
        let orderDate = FridgeDateHelper.parseDate(from: data[14] as? String) ?? Date()
        let expireDate = FridgeDateHelper.parseDate(from: data[9] as? String) ?? Date()
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
}

// MARK: - Fridge ViewModel
@MainActor
final class FridgeViewModel: ObservableObject {
    // MARK: - Published Properties
        @Published var selectedGrouping: GroupingType = .byCategory
        @Published var showOrderCreator = false
        @Published var showCheckScanner = false
        @Published var isLoading = false
        @Published private(set) var cache = FridgeCache.empty
        
        // MARK: - Private Properties
        private let localProducts: [MainPurch]
        private var serverProducts: [SendableMainPurch] = []
        private var users: [UserInfo] = []
        private let fridgeService: NetworkFridgeService
    
    // MARK: - Computed Properties
    var currentProducts: [MainPurch] {
        if serverProducts.isEmpty {
            return localProducts
        } else {

            return serverProducts.map { $0.toMainPurch() }
        }
    }
    
    var user: UserInfo? {
        users.first
    }
    
    // MARK: - Date Formatter (для ViewModel)
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
    
    // MARK: - Initialization
    init(products: [MainPurch]) {
        self.localProducts = products
        self.fridgeService = NetworkFridgeService()
        updateCache()
    }
    
    // MARK: - Public Methods
    func updateUsers(_ users: [UserInfo]) {
        self.users = users
        updateCache()
    }
    
    func loadServerData() async {
        guard let user = user else {
            serverProducts = []
            isLoading = false
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let sendableUser = SendableUserInfo.from(user)
            let loadedProducts = try await fridgeService.loadProducts(for: sendableUser)
            
            await MainActor.run {
                self.serverProducts = loadedProducts
                self.isLoading = false
                self.updateCache()
                print("✅ FridgeViewModel: Загружено \(loadedProducts.count) продуктов с сервера")
            }
        } catch {
            print("❌ FridgeViewModel: Ошибка: \(error.localizedDescription)")

            await MainActor.run {
                self.serverProducts = []
                self.isLoading = false
                self.updateCache()
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
    
    func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
    
    // MARK: - Private Methods
    private func updateCache() {
        let soonExpiringThreshold = Calendar.current.date(
            byAdding: .day,
            value: Constants.soonExpiringThresholdDays,
            to: Date()
        ) ?? Date()
        
        let noExpireDate = Calendar.current.date(
            byAdding: .year,
            value: Constants.noExpireDateYears,
            to: Date()
        ) ?? Date()
        
        let current = currentProducts
        
        // Скоро истекающие
        let soonExpiring = current.filter { product in
            product.ExpireDate < soonExpiringThreshold && product.ExpireDate != noExpireDate
        }
        
        // Для группировки (исключая скоро истекающие)
        let filteredForGrouping = current.filter { product in
            product.ExpireDate >= soonExpiringThreshold || product.ExpireDate == noExpireDate
        }
        
        let byCategory = Dictionary(grouping: filteredForGrouping) { $0.Cat }
        let byPreference = Dictionary(grouping: filteredForGrouping) { product in
            product.PrefMeal.isEmpty ? "Без предпочтений" : product.PrefMeal
        }
        
        cache = FridgeCache(
            soonExpiring: soonExpiring,
            byCategory: byCategory,
            byPreference: byPreference
        )
    }
}

// MARK: - Product Card Data
struct ProductCardData {
    let product: MainPurch
    let index: Int
    let isSoonExpiring: Bool
    let userID: String
    let isPersonalAccount: Bool
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
    
    var volumeText: String {
        "\(Int(product.Volume)) \(product.Unit)"
    }
    
    var expiryText: String {
        if isSoonExpiring {
            return "До: \(ProductCardData.dateFormatter.string(from: product.ExpireDate))"
        } else {
            return product.Tag
        }
    }
    
    var tagColor: Color? {
        isSoonExpiring ? nil : (product.Tag.isEmpty ? nil : TagColors.color(for: product.Tag))
    }
    
    var caloriesText: String {
        "\(Int(product.totalKcal)) Ккал"
    }
    
    var proteinText: String {
        "\(Int(product.totalProtein))"
    }
    
    var fatText: String {
        "\(Int(product.totalFat))"
    }
    
    var carbsText: String {
        "\(Int(product.totalCarbs))"
    }
}

// MARK: - Product Card Row (простая версия без свайпа)
struct ProductCardRow: View {
    let data: ProductCardData
    
    var body: some View {
        VStack(spacing: 0) {
            if data.index > 0 {
                Divider()
                    .padding(.vertical, 5)
                    .padding(.leading, 88 + AdaptiveSpacing.horizontalSpace)
                    .padding(.trailing, AdaptiveSpacing.horizontalSpace)
            }
            
            ProductCardMedium(
                productID: data.product.ProdID,
                productName: data.product.Name,
                volume: data.volumeText,
                expiryDate: data.expiryText,
                tagColor: data.tagColor,
                textType: data.isSoonExpiring ? .expiryDate : .tag,
                calories: data.caloriesText,
                bValue: data.proteinText,
                jValue: data.fatText,
                uValue: data.carbsText
            )
            .overlay(
                // Показываем UserID в правом нижнем углу для семейного аккаунта
                Group {
                    if !data.isPersonalAccount && data.userID != "unknown" && !data.userID.isEmpty {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("ID: \(data.userID.prefix(6))...")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .padding(4)
                            }
                        }
                    }
                }
            )
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            .padding(.top, data.index == 0 ? 4 : 0)
        }
    }
}

// MARK: - User Product Group View
struct UserProductGroupView: View {
    let products: [MainPurch]
    let userID: String
    let showUserHeader: Bool
    let isPersonalAccount: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if showUserHeader {
                HStack {
                    Text("Пользователь: \(userID.prefix(8))...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            }
            
            ForEach(Array(products.enumerated()), id: \.element.ProdID) { index, product in
                let isSoonExpiring = false
                let data = ProductCardData(
                    product: product,
                    index: index,
                    isSoonExpiring: isSoonExpiring,
                    userID: userID,
                    isPersonalAccount: isPersonalAccount
                )
                
                ProductCardRow(data: data)
            }
        }
    }
}

// MARK: - Soon Expiring Section View
struct SoonExpiringSectionView: View {
    @Environment(\.colorScheme) var colorScheme
    let cache: FridgeCache
    let user: UserInfo?
    let getUniqueUsersCount: ([MainPurch]) -> Int
    let groupProductsByUser: ([MainPurch]) -> [String: [MainPurch]]
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView(
                title: "Скоро истекает",
                uniqueUsersCount: user?.UserAccType != 0 ? getUniqueUsersCount(cache.soonExpiring) : 0
            )
            
            if user?.UserAccType != 0 {
                let userGroups = groupProductsByUser(cache.soonExpiring)
                ForEach(Array(userGroups.keys.sorted()), id: \.self) { userID in
                    if let userProducts = userGroups[userID], !userProducts.isEmpty {
                        UserProductGroupView(
                            products: userProducts,
                            userID: userID,
                            showUserHeader: userGroups.count > 1,
                            isPersonalAccount: false
                        )
                    }
                }
            } else {
                ForEach(Array(cache.soonExpiring.enumerated()), id: \.element.ProdID) { index, product in
                    let data = ProductCardData(
                        product: product,
                        index: index,
                        isSoonExpiring: true,
                        userID: "",
                        isPersonalAccount: true
                    )
                    
                    ProductCardRow(data: data)
                }
            }
        }
        .padding(.top, 14)
    }
}

// MARK: - Category Section
struct CategorySection: View {
    @Environment(\.colorScheme) var colorScheme
    
    let title: String
    let products: [MainPurch]
    let user: UserInfo?
    let getUniqueUsersCount: ([MainPurch]) -> Int
    let groupProductsByUser: ([MainPurch]) -> [String: [MainPurch]]
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView(
                title: title,
                uniqueUsersCount: user?.UserAccType != 0 ? getUniqueUsersCount(products) : 0
            )
            
            if user?.UserAccType != 0 {
                let userGroups = groupProductsByUser(products)
                ForEach(Array(userGroups.keys.sorted()), id: \.self) { userID in
                    if let userProducts = userGroups[userID], !userProducts.isEmpty {
                        UserProductGroupView(
                            products: userProducts,
                            userID: userID,
                            showUserHeader: userGroups.count > 1,
                            isPersonalAccount: false
                        )
                    }
                }
            } else {
                ForEach(Array(products.enumerated()), id: \.element.ProdID) { index, product in
                    let data = ProductCardData(
                        product: product,
                        index: index,
                        isSoonExpiring: false,
                        userID: "",
                        isPersonalAccount: true
                    )
                    
                    ProductCardRow(data: data)
                }
            }
        }
        .padding(.top, 14)
    }
}

// MARK: - Category Sections View
struct CategorySectionsView: View {
    let selectedGrouping: GroupingType
    let cache: FridgeCache
    let user: UserInfo?
    let getUniqueUsersCount: ([MainPurch]) -> Int
    let groupProductsByUser: ([MainPurch]) -> [String: [MainPurch]]
    
    var body: some View {
        Group {
            if selectedGrouping == .byCategory {
                ForEach(Array(cache.byCategory.keys.sorted()), id: \.self) { category in
                    if let categoryProducts = cache.byCategory[category], !categoryProducts.isEmpty {
                        CategorySection(
                            title: category,
                            products: categoryProducts,
                            user: user,
                            getUniqueUsersCount: getUniqueUsersCount,
                            groupProductsByUser: groupProductsByUser
                        )
                    }
                }
            } else {
                ForEach(Array(cache.byPreference.keys.sorted()), id: \.self) { preference in
                    if let preferenceProducts = cache.byPreference[preference], !preferenceProducts.isEmpty {
                        CategorySection(
                            title: preference,
                            products: preferenceProducts,
                            user: user,
                            getUniqueUsersCount: getUniqueUsersCount,
                            groupProductsByUser: groupProductsByUser
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Header View (Reusable)
struct HeaderView: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let uniqueUsersCount: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(DesignSystem.Typography.CatTitle)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
            
            Spacer()
            
            if uniqueUsersCount > 1 {
                Text("Участников: \(uniqueUsersCount)")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.accent3)
            }
        }
        .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
    }
}

// MARK: - Fridge Top Header View
struct FridgeTopHeaderView: View {
    @Environment(\.colorScheme) var colorScheme
    let selectedGrouping: GroupingType
    let isLoading: Bool
    let onGroupingSelected: (GroupingType) -> Void
    let onOrderCreatorTapped: () -> Void
    let onCheckScannerTapped: () -> Void
    
    var body: some View {
        HStack {
            Text("Запасы")
                .font(DesignSystem.Typography.screentitle)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                .padding(.top, 10)
            
            Spacer()
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .padding(.top, 10)
            }
            
            Menu {
                Button(action: { onGroupingSelected(.byCategory) }) {
                    HStack {
                        Text("По категориям")
                        if selectedGrouping == .byCategory {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button(action: { onGroupingSelected(.byPreference) }) {
                    HStack {
                        Text("По предпочтениям")
                        if selectedGrouping == .byPreference {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Divider()
                
                Button(action: onOrderCreatorTapped) {
                    HStack {
                        Image(systemName: "cart.badge.plus")
                        Text("Собрать заказ")
                    }
                }
                
                Divider()
                
                Button(action: onCheckScannerTapped) {
                    HStack {
                        Image(systemName: "cart.badge.plus")
                        Text("Отсканировать чек")
                    }
                }
                
            } label: {
                HStack(spacing: 4) {
                    Circle().frame(width: 6, height: 6)
                    Circle().frame(width: 6, height: 6)
                    Circle().frame(width: 6, height: 6)
                }
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
            }
            .padding(.top, 10)
            .disabled(isLoading)
        }
        .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
        .padding(.bottom, 8)
    }
}

// MARK: - Fridge Search Sticky View
struct FridgeSearchStickyView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let headerHeight: CGFloat = 100
            let stickyThreshold: CGFloat = headerHeight + 10
            
            SearchMain { searchText in
                print("Поиск: \(searchText)")
            }
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(
                Rectangle()
                    .fill(DesignSystem.Colors.appbackground(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(.all, edges: .horizontal)
            )
            .offset(y: minY < stickyThreshold ? stickyThreshold - minY : 0)
        }
        .frame(height: 42)
    }
}

// MARK: - Fridge Banner Wrapper
struct FridgeBannerWrapper: View {
    let products: [MainPurch]
    let userKcalOpt: Double
    
    var body: some View {
        FridgeBanner(
            products: products,
            userKcalOpt: userKcalOpt
        )
    }
}

// MARK: - Main Fridge View
struct FridgeView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    let products: [MainPurch]
    
    @Query private var users: [UserInfo]
    @StateObject private var viewModel: FridgeViewModel
    @State private var isRefreshing = false
    
    init(products: [MainPurch]) {
        self.products = products
        _viewModel = StateObject(wrappedValue: FridgeViewModel(products: products))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            FridgeTopHeaderView(
                selectedGrouping: viewModel.selectedGrouping,
                isLoading: viewModel.isLoading,
                onGroupingSelected: { viewModel.selectedGrouping = $0 },
                onOrderCreatorTapped: { viewModel.showOrderCreator = true },
                onCheckScannerTapped: { viewModel.showCheckScanner = true }
            )
            .zIndex(2)
            
            ScrollView {
                LazyVStack(spacing: 2) {
                    FridgeBannerWrapper(
                        products: viewModel.currentProducts,
                        userKcalOpt: viewModel.user?.UserKcalOpt ?? 2100
                    )
                    
                    FridgeSearchStickyView()
                        .zIndex(1)
                    
                    VStack(spacing: 0) {
                        if !viewModel.cache.soonExpiring.isEmpty {
                            SoonExpiringSectionView(
                                cache: viewModel.cache,
                                user: viewModel.user,
                                getUniqueUsersCount: viewModel.getUniqueUsersCount,
                                groupProductsByUser: viewModel.groupProductsByUser
                            )
                        }
                        
                        CategorySectionsView(
                            selectedGrouping: viewModel.selectedGrouping,
                            cache: viewModel.cache,
                            user: viewModel.user,
                            getUniqueUsersCount: viewModel.getUniqueUsersCount,
                            groupProductsByUser: viewModel.groupProductsByUser
                        )
                    }
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
        .sheet(isPresented: $viewModel.showOrderCreator) {
            OrderCreator()
        }
        .sheet(isPresented: $viewModel.showCheckScanner) {
            CheckScanner()
        }
        .onAppear {
            viewModel.updateUsers(users)
        }
        .task {
            await viewModel.loadServerData()
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
    
    // ЗАМЕНИТЬ текущую функцию на эту:
    private func refreshData() async {
        isRefreshing = true
        
        // ТОЧНАЯ КОПИЯ ОРИГИНАЛЬНОГО КОДА из StatisticView
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                Task {
                    await viewModel.loadServerData()
                    continuation.resume()
                }
            }
        }
        
        isRefreshing = false
    }
}
