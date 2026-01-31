//
//  CreatorView.swift
//  Project-Portion-demo
//
//  Created by Evgenii Sukhov on 30.01.2026.
//

import SwiftUI
import Combine
import SwiftData

// MARK: - ViewModel (Business Logic)

@MainActor
final class OrderCreatorViewModel: ObservableObject {
    @Published var selectedSegmentIndex = 0
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var storeID1Products: [Product] = []
    @Published var otherProducts: [Product] = []
    @Published var isSearching = false
    @Published var cartItems: [CartItem] = []
    @Published var isSyncing = false
    @Published var syncResult: String = ""
    @Published var showResult = false
    
    @Published var addressID: String = "1"
    @Published var orderDate: String = ""
    
    private var currentUser: UserInfo?
    
    struct Product: Identifiable, Codable {
        let id: Int
        let prod_id: Int
        let name: String
        let volume: Double
        let unit: String
        let volume_gr: Double
        let kcal100g: Double
        let prot100g: Double
        let fat100g: Double
        let carb100g: Double
        let tag: String
        let cat: String
        let total_cost: Double
        let store_id: Int?
        let store: String?
    }
    
    struct CartItem: Identifiable {
        let id = UUID()
        let product: Product
        var quantity: Int
    }
    
    // MARK: - Методы обновления данных
    
    func updateCurrentUser(_ user: UserInfo?) {
        self.currentUser = user
    }
    
    func setDefaultDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        orderDate = formatter.string(from: Date())
    }
    
    // MARK: - Функции работы с корзиной
    
    func getCartQuantity(for product: Product) -> Int {
        cartItems.first(where: { $0.product.id == product.id })?.quantity ?? 0
    }
    
    func updateCart(product: Product, newQuantity: Int) {
        if newQuantity == 0 {
            cartItems.removeAll { $0.product.id == product.id }
        } else {
            if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
                cartItems[index].quantity = newQuantity
            } else {
                cartItems.append(CartItem(product: product, quantity: newQuantity))
            }
        }
    }
    
    // MARK: - Функции поиска
    
    func searchProducts() async {
        let searchQuery = searchText.trimmingCharacters(in: .whitespaces)
        
        guard !searchQuery.isEmpty else {
            storeID1Products = []
            otherProducts = []
            return
        }
        
        isLoading = true
        
        let parameters: [String: Any] = [
            "search_term": searchQuery,
            "family_id": "1"
        ]
        
        guard let url = URL(string: "http://\(ServerConfig.YourIP):8000/search_products") else {
            print("❌ Неверный URL")
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let response = try JSONDecoder().decode(SearchResponse.self, from: data)
            if response.status == "success" {
                let allProducts = response.products
                
                storeID1Products = allProducts.filter { $0.store_id == 1 }
                otherProducts = allProducts.filter { $0.store_id != 1 }
                
                print("✅ Найдено товаров: \(allProducts.count)")
                print("✅ Основной (StoreID=1): \(storeID1Products.count)")
                print("✅ Прочее: \(otherProducts.count)")
            } else {
                print("❌ Ошибка сервера: \(response.message ?? "Unknown error")")
            }
        } catch {
            print("❌ Ошибка парсинга: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Функции создания заказа
    
    func createOrderFromCart(user: UserInfo, addressID: String) async {
        guard !cartItems.isEmpty else {
            syncResult = "❌ Корзина пуста"
            showResult = true
            return
        }
        
        let familyID = user.UserFamilyID
        
        print("📦 Отправляем заказ:")
        print("   FamilyID: \(familyID)")
        print("   UserAccType: \(user.UserAccType)")
        
        guard let addressInt = Int(addressID), (1...5).contains(addressInt) else {
            syncResult = "❌ Введите корректный адрес (1-5)"
            showResult = true
            return
        }
        
        isSyncing = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let currentDate = orderDate.isEmpty ? dateFormatter.string(from: Date()) : orderDate
        
        var orderItems: [[String: Any]] = []
        
        for cartItem in cartItems {
            let product = cartItem.product
            let item: [String: Any] = [
                "prod_id": product.prod_id,
                "quantity": cartItem.quantity,
                "name": product.name,
                "volume": product.volume,
                "unit": product.unit,
                "volume_gr": product.volume_gr,
                "kcal100g": product.kcal100g,
                "prot100g": product.prot100g,
                "fat100g": product.fat100g,
                "carb100g": product.carb100g,
                "tag": product.tag,
                "cat": product.cat,
                "total_cost": product.total_cost,
                "store_id": product.store_id ?? 1,
                "store": product.store ?? "Основной"
            ]
            orderItems.append(item)
        }
        
        let orderData: [String: Any] = [
            "family_id": familyID,
            "address_id": addressInt,
            "order_date": currentDate,
            "items": orderItems,
            "user_id": user.UserID.uuidString
        ]
        
        await sendOrderToServer(orderData: orderData)
    }
    
    private func sendOrderToServer(orderData: [String: Any]) async {
        guard let url = URL(string: "http://\(ServerConfig.YourIP):8000/create_order") else {
            syncResult = "❌ Неверный URL сервера"
            isSyncing = false
            showResult = true
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: orderData)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let response = try JSONDecoder().decode(OrderResponse.self, from: data)
            
            if response.status == "success" {
                cartItems.removeAll()
                syncResult = response.message
            } else {
                syncResult = "❌ Ошибка: \(response.message)"
            }
            
            showResult = true
            
        } catch {
            syncResult = "❌ Ошибка парсинга: \(error.localizedDescription)"
            showResult = true
        }
        
        isSyncing = false
    }
}

// MARK: - Структуры для ответов сервера

struct SearchResponse: Codable {
    let status: String
    let products: [OrderCreatorViewModel.Product]
    let count: Int
    let message: String?
}

struct OrderResponse: Codable {
    let status: String
    let message: String
    let data: OrderResponseData?
}

struct OrderResponseData: Codable {
    let all_saved: Int?
    let main_updated: Int?
    let other_saved: Int?
    let total_items: Int?
}

// MARK: - Компоненты (UI Components)

// MARK: - Top Header View
struct OrderCreatorTopHeaderView: View {
    @Environment(\.colorScheme) var colorScheme
    let isSearching: Bool
    @ObservedObject var viewModel: OrderCreatorViewModel
    
    var body: some View {
        HStack {
            Text(isSearching ? "Поиск" : "Корзина")
                .font(DesignSystem.Typography.screentitle)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
            
            Spacer()
        }
    }
}

// MARK: - Content View
struct OrderCreatorContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: OrderCreatorViewModel
    
    var body: some View {
        Group {
            if viewModel.isSearching {
                // Режим поиска
                switch viewModel.selectedSegmentIndex {
                case 0:
                    StoreProductsView(viewModel: viewModel)
                case 1:
                    OtherProductsSearchView(viewModel: viewModel)
                default:
                    EmptyView()
                }
            } else {
                // Режим корзины
                CartItemsView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Store Products View
struct StoreProductsView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: OrderCreatorViewModel
    
    var body: some View {
        if viewModel.isLoading {
            ProgressView("Поиск товаров...")
                .padding(.top, 40)
        } else if viewModel.storeID1Products.isEmpty && !viewModel.searchText.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
                .padding(.top, 40)
        } else if !viewModel.storeID1Products.isEmpty {
            VStack(spacing: 0) {
                HStack {
                    Text("Найдено: \(viewModel.storeID1Products.count)")
                        .font(DesignSystem.Typography.CatTitle)
                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    
                    Spacer()
                }
                .padding(.horizontal, min(AdaptiveSpacing.horizontalSpace * 1.5, 30))
                .padding(.top, 16)
                
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.storeID1Products.enumerated()), id: \.element.id) { index, product in
                        VStack(spacing: 0) {

                            if index > 0 {
                                HStack {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: 68)
                                    
                                    Rectangle()
                                        .fill(DesignSystem.Colors.primary(for: colorScheme).opacity(0.15))
                                        .frame(height: 0.5)
                                }
                                .padding(.horizontal, min(AdaptiveSpacing.horizontalSpace * 1.5, 30))
                                .padding(.vertical, 6)
                            }
                            
                            ProductCardSearch(
                                product: product,
                                quantity: viewModel.getCartQuantity(for: product),
                                onQuantityChanged: { newQuantity in
                                    viewModel.updateCart(product: product, newQuantity: newQuantity)
                                }
                            )
                            .padding(.top, index == 0 ? 4 : 0)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Other Products Search View
struct OtherProductsSearchView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: OrderCreatorViewModel
    
    var body: some View {
        if viewModel.isLoading {
            ProgressView("Поиск товаров...")
                .padding(.top, 40)
        } else if viewModel.otherProducts.isEmpty && !viewModel.searchText.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
                .padding(.top, 40)
        } else if !viewModel.otherProducts.isEmpty {
            OtherProductsListView(
                products: viewModel.otherProducts,
                cartQuantities: viewModel.cartItems.reduce(into: [:]) { $0[$1.product.id] = $1.quantity },
                onQuantityChanged: { product, newQuantity in
                    viewModel.updateCart(product: product, newQuantity: newQuantity)
                }
            )
        }
    }
}

// MARK: - Cart Items View
struct CartItemsView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: OrderCreatorViewModel
    
    var body: some View {
        if viewModel.cartItems.isEmpty {
            VStack {
                Text("Корзина пуста")
                    .font(DesignSystem.Typography.ProdName)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.5))
                    .padding(.top, 60)
                
                Text("Нажмите на поиск, чтобы добавить товары")
                    .font(DesignSystem.Typography.ProdVolume)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.3))
                    .padding(.top, 8)
            }
        } else {
            VStack(spacing: 0) {
                HStack {
                    Text("Товаров в корзине: \(viewModel.cartItems.reduce(0) { $0 + $1.quantity })")
                        .font(DesignSystem.Typography.CatTitle)
                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    
                    Spacer()
                }
                .padding(.horizontal, min(AdaptiveSpacing.horizontalSpace * 1.5, 30))
                .padding(.top, 16)
                
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.cartItems.enumerated()), id: \.element.id) { index, cartItem in
                        VStack(spacing: 0) {

                            if index > 0 {
                                HStack {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: 68)
                                    
                                    Rectangle()
                                        .fill(DesignSystem.Colors.primary(for: colorScheme).opacity(0.15))
                                        .frame(height: 0.5)
                                }
                                .padding(.horizontal, min(AdaptiveSpacing.horizontalSpace * 1.5, 30))
                                .padding(.vertical, 6)
                            }
                            
                            ProductCardCart(
                                product: cartItem.product,
                                quantity: cartItem.quantity,
                                onQuantityChanged: { newQuantity in
                                    viewModel.updateCart(product: cartItem.product, newQuantity: newQuantity)
                                }
                            )
                            .padding(.top, index == 0 ? 4 : 0)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Floating Action Buttons
struct FloatingActionButtonsView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let isSearching: Bool
    let cartItems: [OrderCreatorViewModel.CartItem]
    let isSyncing: Bool
    let onBackAction: () -> Void
    let onConfirmAction: () -> Void
    
    var body: some View {
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
                    // Кнопка "Назад"
                    BackButtonView(
                        colorScheme: colorScheme,
                        action: onBackAction
                    )
                    
                    Spacer()
                    
                    // Кнопка "Подтвердить"
                    if !cartItems.isEmpty {
                        ConfirmButtonView(
                            colorScheme: colorScheme,
                            isSyncing: isSyncing,
                            action: onConfirmAction
                        )
                    }
                }
                .padding(.bottom, 20)
                .padding(.horizontal, CGFloat(Int(min(AdaptiveSpacing.horizontalSpace * 1.5, 30) * 1.66)))
            )
    }
}

// MARK: - Back Button
struct BackButtonView: View {
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
        }
    }
}

// MARK: - Confirm Button
struct ConfirmButtonView: View {
    let colorScheme: ColorScheme
    let isSyncing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
                    Group {
                        if isSyncing {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "checkmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                    }
                )
                .frame(width: 50, height: 50)
        }
        .disabled(isSyncing)
    }
}

// MARK: - Other Products List View
struct OtherProductsListView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let products: [OrderCreatorViewModel.Product]
    let cartQuantities: [Int: Int]
    let onQuantityChanged: (OrderCreatorViewModel.Product, Int) -> Void
    
    private var productsByStore: [String: [OrderCreatorViewModel.Product]] {
        Dictionary(grouping: products) { product in
            product.store ?? "Неизвестный магазин"
        }
    }
    
    private var sortedStoreKeys: [String] {
        productsByStore.keys.sorted()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(sortedStoreKeys, id: \.self) { store in
                if let storeProducts = productsByStore[store], !storeProducts.isEmpty {
                    VStack(spacing: 0) {
                        // Заголовок магазина
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(store)
                                    .font(DesignSystem.Typography.CatTitle)
                                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, min(AdaptiveSpacing.horizontalSpace * 1.5, 30))
                        .padding(.top, 16)
                        
                        // Карточки продуктов в этом магазине
                        ForEach(Array(storeProducts.enumerated()), id: \.element.id) { index, product in
                            VStack(spacing: 0) {
                                
                                if index > 0 {
                                    HStack {
                                        Rectangle()
                                            .fill(Color.clear)
                                            .frame(width: 68)
                                        
                                        Rectangle()
                                            .fill(DesignSystem.Colors.primary(for: colorScheme).opacity(0.15))
                                            .frame(height: 0.5)
                                    }
                                    .padding(.horizontal, min(AdaptiveSpacing.horizontalSpace * 1.5, 30))
                                    .padding(.vertical, 6)
                                }
      
                                ProductCardSearch(
                                    product: product,
                                    quantity: cartQuantities[product.id] ?? 0,
                                    onQuantityChanged: { newQuantity in
                                        onQuantityChanged(product, newQuantity)
                                    }
                                )
                                .padding(.top, index == 0 ? 4 : 0)
                            }
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
        }
    }
}

// MARK: - Main View

struct OrderCreator: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @Query private var users: [UserInfo]
    
    @StateObject private var viewModel: OrderCreatorViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: OrderCreatorViewModel())
    }
    
    private var currentUser: UserInfo? {
        users.first
    }
    
    var body: some View {
        VStack {

            OrderCreatorTopHeaderView(
                isSearching: viewModel.isSearching,
                viewModel: viewModel
            )
            .padding(.horizontal, min(AdaptiveSpacing.horizontalSpace * 1.5, 30))
            .padding(.top, 30)
            
            SearchMain() { searchQuery in
                viewModel.searchText = searchQuery
                if !searchQuery.isEmpty {
                    Task {
                        await viewModel.searchProducts()
                    }
                } else {
                    viewModel.storeID1Products = []
                    viewModel.otherProducts = []
                }
            }
            .simultaneousGesture(
                TapGesture().onEnded {
                    withAnimation {
                        viewModel.isSearching = true
                    }
                }
            )
            .padding(.horizontal, min(AdaptiveSpacing.horizontalSpace * 1.5, 30))
            
            // Сегментированный контрол - показываем только при поиске
            if viewModel.isSearching {
                SegmentedControl(
                    items: ["Основной", "Прочее"],
                    selectedIndex: $viewModel.selectedSegmentIndex
                )
                .padding(.horizontal, min(AdaptiveSpacing.horizontalSpace * 1.5, 30))
                .transition(.opacity)
            }
            
            ZStack(alignment: .bottom) {
                ScrollView {
                    OrderCreatorContentView(viewModel: viewModel)
                        .padding(.bottom, 80)
                }
                
                FloatingActionButtonsView(
                    isSearching: viewModel.isSearching,
                    cartItems: viewModel.cartItems,
                    isSyncing: viewModel.isSyncing,
                    onBackAction: {
                        handleBackAction()
                    },
                    onConfirmAction: {
                        createOrderFromCart()
                    }
                )
            }
            .ignoresSafeArea(.all, edges: .bottom)
        }
        .background(DesignSystem.Colors.appbackground(for: colorScheme))
        .alert("Результат", isPresented: $viewModel.showResult) {
            Button("OK", role: .cancel) {
                if viewModel.syncResult.contains("✅") {
                    dismiss()
                }
            }
        } message: {
            Text(viewModel.syncResult)
        }
        .onAppear {
            viewModel.setDefaultDate()
            viewModel.updateCurrentUser(users.first)
        }
        .onChange(of: currentUser) { oldValue, newValue in
            viewModel.updateCurrentUser(newValue)
        }
    }
    
    // MARK: - Обработчики действий
    
    private func handleBackAction() {
        if viewModel.isSearching {
            withAnimation {
                viewModel.isSearching = false
                viewModel.searchText = ""
                viewModel.storeID1Products = []
                viewModel.otherProducts = []
            }
        } else {
            dismiss()
        }
    }
    
    private func createOrderFromCart() {
        guard !viewModel.cartItems.isEmpty else {
            viewModel.syncResult = "❌ Корзина пуста"
            viewModel.showResult = true
            return
        }
        
        guard let user = currentUser else {
            viewModel.syncResult = "❌ Пользователь не найден"
            viewModel.showResult = true
            return
        }
        
        Task {
            await viewModel.createOrderFromCart(user: user, addressID: "1")
        }
    }
}
