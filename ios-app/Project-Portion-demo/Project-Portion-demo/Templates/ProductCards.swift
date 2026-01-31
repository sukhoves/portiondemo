//
//  ProductCards.swift
//  Project-Portion-demo
//
//  Created by Evgenii Sukhov on 30.01.2026.
//

import SwiftUI
import SwiftData


// MARK: КАРТОЧКА ДЛЯ FRIDGE

struct ProductCardMedium: View {
    @Environment(\.colorScheme) var colorScheme
    
    enum TextType {
        case expiryDate
        case tag
    }
    
    let productID: Int
    let productName: String
    let volume: String
    let expiryDate: String
    let tagColor: Color?
    let textType: TextType
    let calories: String
    let bValue: String
    let jValue: String
    let uValue: String
    
    init(
        productID: Int,
        productName: String = "Название продукта",
        volume: String = "100 мл",
        expiryDate: String = "",
        tagColor: Color? = nil,
        textType: TextType = .expiryDate,
        calories: String = "540 Ккал",
        bValue: String = "0",
        jValue: String = "0",
        uValue: String = "0"
    ) {
        self.productID = productID
        self.productName = productName
        self.volume = volume
        self.expiryDate = expiryDate
        self.tagColor = tagColor
        self.textType = textType
        self.calories = calories
        self.bValue = bValue
        self.jValue = jValue
        self.uValue = uValue
    }
    
    private var dateFont: Font {
        switch textType {
        case .expiryDate:
            return DesignSystem.Typography.ProdDateRange
        case .tag:
            return DesignSystem.Typography.Tag
        }
    }
    
    // Вычисляемое свойство для проверки, нужно ли отображать тег
    private var shouldShowTag: Bool {
        return textType == .tag && tagColor != nil && expiryDate.lowercased() != "nan"
    }
    
    // Вычисляемое свойство для ограничения строк названия продукта
    private var nameLineLimit: Int {
        // Если показываем тег - 1 строка, иначе - 2 строки
        return shouldShowTag ? 1 : 2
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            
            // Контейнер для изображения с фоном
            ZStack {
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.33) : DesignSystem.Colors.grey1)
                    .frame(width: 80, height: 80)
                    .opacity(0.5)
                    .cornerRadius(20)
                    .shadow(
                        color: Color.black.opacity(0.025),
                        radius: 3.5,
                        x: 0,
                        y: 1
                    )
                
                HybridImage(prodID: productID)
                    .aspectRatio(contentMode: .fit) // ← используем fit чтобы изображение не обрезалось
                    .frame(width: 60, height: 60) // ← размер изображения 60x60
            }
            .frame(width: 80, height: 80)

            productInfoView
            
            Spacer()
            
            caloriesAndNutritionView
        }
        .background(DesignSystem.Colors.appbackground(for: colorScheme))
        .contextMenu {
            Button(action: {
             
            }) {
                Label("Изменить", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: {
          
            }) {
                Label("Удалить", systemImage: "trash")
            }
        }
    }
    
    private var productInfoView: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Text(productName)
                    .font(DesignSystem.Typography.ProdName)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    .frame(alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nameLineLimit)
                    .padding(.leading, 8)
                    .padding(.top, 6)
                
                Text(volume)
                    .font(DesignSystem.Typography.ProdVolume)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    .frame(alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 8)
                    .padding(.top, 0)
                
                Spacer()
            }
            
            if textType == .tag && shouldShowTag {
                // Только для тегов, которые нужно отображать
                HStack(spacing: 4) {
                    // Image("tag_icon")
                       // .resizable()
                        // .renderingMode(.template)
                    Circle()
                        .foregroundColor(tagColor)
                        .frame(width: 20, height: 20)
                        .opacity(0.75)
                    
                    Text(expiryDate)
                        .font(dateFont)
                        .foregroundColor(tagColor ?? DesignSystem.Colors.primary(for: colorScheme))
                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                        .opacity(0.75)
                }
                .frame(alignment: .leading)
                .padding(.leading, 8)
                .padding(.bottom, 6)
                .frame(maxHeight: .infinity, alignment: .bottomLeading)
            } else if textType == .expiryDate && !expiryDate.isEmpty && expiryDate.lowercased() != "nan" {
                // Для даты истечения срока
                Text(expiryDate)
                    .font(dateFont)
                    .foregroundColor(tagColor ?? DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    .frame(alignment: .leading)
                    .padding(.leading, 8)
                    .padding(.bottom, 6)
                    .frame(maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .frame(height: 80)
    }
    
    private var caloriesAndNutritionView: some View {
        VStack {
            Text(calories)
                .font(DesignSystem.Typography.CcalMedium)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                .frame(alignment: .center)
            
            HStack(spacing: 4) {
                NutrientBlock(letter: "Б", number: bValue)
                NutrientBlock(letter: "Ж", number: jValue)
                NutrientBlock(letter: "У", number: uValue)
            }
        }
        .frame(height: 80)
    }
}


// MARK: КАРТОЧКА ДЛЯ RATION

struct ProductCardSmall: View {
    @Environment(\.colorScheme) var colorScheme
    
    let rationItem: RationInfo
    let index: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    

    
    var body: some View {
                HStack {
                    // Изображение продукта
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
                        
                        HybridImage(prodID: Int(rationItem.ProdID))
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }
                    .frame(width: 66, height: 66)
                    
                    // Информация о продукте
                    VStack(alignment: .leading, spacing: 4) {
                        Text(rationItem.Name)
                            .font(DesignSystem.Typography.ProdName)
                            .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                            .lineLimit(2)
                        
                        Text("\(Int(rationItem.VolumeServ)) \(rationItem.Unit)")
                            .font(DesignSystem.Typography.ProdVolume)
                            .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.7))
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    HStack(alignment: .center, spacing: 8) {
                        
                        // Калории в порции
                        Text("\(Int(rationItem.KcalServ))")
                            .font(.custom("Montserrat-SemiBold", size: 15))
                            .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.9))
                            .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                        
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
                                
                                Text("\(Int(rationItem.ProtServ))")
                                    .font(.custom("Montserrat-SemiBold", size: 12))
                                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.8))
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
                                
                                Text("\(Int(rationItem.FatServ))")
                                    .font(.custom("Montserrat-SemiBold", size: 12))
                                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.8))
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
                                
                                Text("\(Int(rationItem.CarbServ))")
                                    .font(.custom("Montserrat-SemiBold", size: 12))
                                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.8))
                                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                                    .frame(width: 26, height: 20)
                            }
                        }
                        
                    }
                    .padding(.trailing, 0)
                }
                .background(DesignSystem.Colors.appbackground(for: colorScheme))
               // .cornerRadius(22)
                
        }
       
}

// MARK: КАРТОЧКА ДЛЯ POPUP FRIDGE

struct ProductCardPopUp: View {
    @Environment(\.colorScheme) var colorScheme
    @Query private var users: [UserInfo]
    @Environment(\.modelContext) private var modelContext
    
    let productID: Int
    let productName: String
    let volume: String
    let expiryDate: String
    let volumeserv: String
    let productMeal: Double
    let rationDate: Date
    
    let mealID: Int
    let selectedDate: Date
    let productData: MainPurch
    
    private var volumeStep: Double {
        productData.VolumeGr / productData.Volume
    }
    
    @State private var volumeServText: String = ""
    
    private func getCurrentUser() -> UserInfo? {
        return users.first
    }
    
    init(
        productID: Int = 0,
        productName: String = "Название продукта",
        volume: String,
        expiryDate: String = "",
        volumeserv: String = "100 мл",
        productMeal: Double = 0,
        rationDate: Date = Date(),
        mealID: Int = 0,
        selectedDate: Date = Date(),
        productData: MainPurch
    ) {
        self.productID = productID
        self.productName = productName
        self.volume = volume
        self.expiryDate = expiryDate
        self.volumeserv = volumeserv
        self.productMeal = productMeal
        self.rationDate = rationDate
        self.mealID = mealID
        self.selectedDate = selectedDate
        self.productData = productData
    }
    
    var body: some View {
        HStack(spacing: 0) {
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
                
                HybridImage(prodID: productID)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
            }
            .frame(width: 66, height: 66)
            
            productInfoView
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                ZStack {
                    InputField(
                        width: 60,
                        height: 30,
                        cornerRadius: 12,
                        backgroundColor: colorScheme == .dark ? Color.white.opacity(0.15) : DesignSystem.Colors.grey1
                    )
                    
                    HStack(spacing: 2) {
                        TextField("0", text: $volumeServText)
                            .frame(width: 25, height: 30)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.center)
                            .background(Color.clear)
                            .font(.system(size: 14))
                            .submitLabel(.done)
                            .onSubmit {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                    }
                }
            }
            
            Button(action: {
                addToRation()
            }) {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundColor(volumeServText.isEmpty ? DesignSystem.Colors.primary(for: colorScheme).opacity(0.3) : DesignSystem.Colors.primary(for: colorScheme))
                    .padding(.leading, 8)
            }
            .disabled(volumeServText.isEmpty)
        }
        //.padding(.top, 8)
        .frame(maxWidth: .infinity)
    }
    
    private var productInfoView: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Text(productName)
                    .font(DesignSystem.Typography.ProdName)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    .frame(width: 180, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 8)
                    .padding(.top, 6)
                
                Spacer()
            }
            
            Text("Доступно: \(volume)")
                .font(DesignSystem.Typography.ProdVolume)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                .frame(width: 180, alignment: .leading)
                .padding(.leading, 8)
                .padding(.bottom, 6)
                .frame(maxHeight: .infinity, alignment: .bottomLeading)
        }
        .frame(height: 66)
    }
    
    private func addToRation() {
        guard let volumeServ = Double(volumeServText) else { return }
        
        let volumeServGr = volumeServ * volumeStep
        
        // Проверяем, достаточно ли продукта в запасах
        guard volumeServGr <= productData.VolumeGr else {
            print("❌ Недостаточно продукта в запасах. Доступно: \(productData.VolumeGr)г, требуется: \(volumeServGr)г")
            return
        }
        
        guard volumeServ <= productData.Volume else {
            print("❌ Недостаточно продукта в запасах. Доступно: \(productData.Volume) \(productData.Unit), требуется: \(volumeServ) \(productData.Unit)")
            return
        }
        
        // Расчет питательных веществ
        let ratio = volumeServGr / 100.0
        let kcalServ = productData.Kcal100g * ratio
        let protServ = productData.Prot100g * ratio
        let fatServ = productData.Fat100g * ratio
        let carbServ = productData.Carb100g * ratio
        
        // Форматируем дату
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let rationDateStr = dateFormatter.string(from: selectedDate)
        let expireDateStr = dateFormatter.string(from: productData.ExpireDate)
        
        // Получаем текущего пользователя
        guard let currentUser = getCurrentUser() else {
            print("❌ Пользователь не найден")
            return
        }
        
        // 1. UserID для записи в рацион (ВСЕГДА текущий пользователь)
        let rationUserID = currentUser.UserID.uuidString
        
        // 2. UserID для обновления MainPurch
        let updateUserID: String
        if currentUser.UserAccType == 0 {
            // Личный аккаунт: используем текущего пользователя
            updateUserID = currentUser.UserID.uuidString
        } else {
            // Семейный аккаунт: используем UserID из карточки продукта
            updateUserID = productData.UserID.isEmpty ? currentUser.UserID.uuidString : productData.UserID
            print("🔍 Семейный аккаунт: обновляем продукт пользователя \(updateUserID.prefix(8))...")
        }
        
        // ПОДГОТОВКА ДАННЫХ ДЛЯ СЕРВЕРА
        let rationData: [String: Any] = [
            "prod_id": productData.ProdID,
            "name": productData.Name,
            "volume": productData.Volume,
            "unit": productData.Unit,
            "volume_gr": productData.VolumeGr,
            "kcal100g": productData.Kcal100g,
            "prot100g": productData.Prot100g,
            "fat100g": productData.Fat100g,
            "carb100g": productData.Carb100g,
            "expire_date": expireDateStr,
            "tag": productData.Tag,
            "cat": productData.Cat,
            "meal_id": mealID,
            "meal_name": getMealName(for: mealID),
            "ration_date": rationDateStr,
            "volume_serv": volumeServ,
            "volume_serv_gr": volumeServGr,
            "kcal_serv": kcalServ,
            "prot_serv": protServ,
            "fat_serv": fatServ,
            "carb_serv": carbServ,
            "user_id": rationUserID
        ]
        
        // Вычисляем новые значения объемов для сервера
        let newVolumeGr = max(0, productData.VolumeGr - volumeServGr)
        let newVolume = max(0, productData.Volume - volumeServ)
        
        // 1. ОТПРАВКА НА СЕРВЕР В РАЦИОН
        addToRationOnServer(rationData: rationData)
        
        // 2. ОБНОВЛЯЕМ НА СЕРВЕРЕ MainPurch
        if currentUser.UserAccType != 0 {
            // СЕМЕЙНЫЙ АККАУНТ
            if !currentUser.UserFamilyID.isEmpty {
                updateMainPurchOnServer(
                    prodID: productData.ProdID,
                    familyID: currentUser.UserFamilyID,
                    userID: updateUserID,
                    newVolumeGr: newVolumeGr,
                    newVolume: newVolume
                )
            } else {
                print("⚠️ Семейный аккаунт, но нет FamilyID")
            }
        } else {
            // ЛИЧНЫЙ АККАУНТ
            updateMainPurchOnServer(
                prodID: productData.ProdID,
                familyID: "0",
                userID: updateUserID,
                newVolumeGr: newVolumeGr,
                newVolume: newVolume
            )
        }
        
        volumeServText = ""
    }
    
    // Отправка на сервер в рацион
    private func addToRationOnServer(rationData: [String: Any]) {
        guard let url = URL(string: "http://\(ServerConfig.YourIP):8000/add_to_ration") else {
            print("❌ Неверный URL сервера для добавления в рацион")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: rationData)
            request.httpBody = jsonData
            
            print("📤 Отправка данных в рацион на сервер:")
            print("   Product: \(productData.Name)")
            print("   Meal: \(getMealName(for: mealID))")
            print("   Date: \(rationData["ration_date"] ?? "N/A")")
            print("   Volume: \(rationData["volume_serv"] ?? 0) \(productData.Unit)")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Ошибка отправки в рацион: \(error.localizedDescription)")
                    return
                }
                
                if let data = data {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📥 Ответ сервера (рацион): \(responseString)")
                    }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if json["status"] as? String == "success" {
                            print("✅ Продукт успешно добавлен в серверный рацион")
                        } else {
                            print("❌ Ошибка добавления в рацион: \(json["message"] as? String ?? "Unknown error")")
                        }
                    }
                }
            }.resume()
            
        } catch {
            print("❌ Ошибка сериализации JSON: \(error)")
        }
    }
    
    private func updateMainPurchOnServer(prodID: Int, familyID: String, userID: String, newVolumeGr: Double, newVolume: Double) {
        guard let url = URL(string: "http://\(ServerConfig.YourIP):8000/update_main_purch") else {
            print("❌ Неверный URL сервера для обновления MainPurch")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "prod_id": prodID,
            "family_id": familyID,
            "user_id": userID,
            "new_volume_gr": newVolumeGr,
            "new_volume": newVolume
        ]
        
        print("📤 Отправка обновления MainPurch на сервер:")
        print("   ProdID: \(prodID)")
        print("   FamilyID: \(familyID)")
        print("   UserID: \(userID)")
        print("   New VolumeGr: \(newVolumeGr)")
        print("   New Volume: \(newVolume)")
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Ошибка обновления MainPurch на сервере: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Ответ сервера: \(responseString)")
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if json["status"] as? String == "success" {
                        print("✅ MainPurch успешно обновлен на сервере")
                        
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ReloadServerData"),
                                object: nil
                            )
                        }
                    } else {
                        print("❌ Ошибка обновления MainPurch на сервере: \(json["message"] as? String ?? "Unknown error")")
                    }
                }
            }
        }.resume()
    }
    
    private func getMealName(for mealID: Int) -> String {
        switch mealID {
        case 0: return "Завтрак"
        case 1: return "Обед"
        case 2: return "Ужин"
        default: return "Прием пищи"
        }
    }
}

// MARK: КАРТОЧКА ДЛЯ POPUP OTHER

struct ProductCardPopUpOther: View {
    @Environment(\.colorScheme) var colorScheme
    @Query private var users: [UserInfo]
    @Environment(\.modelContext) private var modelContext
    
    let purchase: OtherPurch
    let mealID: Int
    let selectedDate: Date
    
    private var volumeStep: Double {
        purchase.VolumeGr / purchase.Volume
    }
    
    @State private var volumeServText: String = ""
    
    private func getCurrentUser() -> UserInfo? {
        return users.first
    }
    
    var body: some View {
        HStack(spacing: 0) {
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
                
                HybridImage(prodID: Int(purchase.ProdID))
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
            }
            .frame(width: 66, height: 66)
            
            productInfoView
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                ZStack {
                    InputField(
                        width: 60,
                        height: 30,
                        cornerRadius: 12,
                        backgroundColor: colorScheme == .dark ? Color.white.opacity(0.15) : DesignSystem.Colors.grey1
                    )
                    
                    HStack(spacing: 2) {
                        TextField("0", text: $volumeServText)
                            .frame(width: 25, height: 30)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.center)
                            .background(Color.clear)
                            .font(.system(size: 14))
                            .submitLabel(.done)
                            .onSubmit {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                    }
                }
            }
            
            Button(action: {
                addToRation()
            }) {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundColor(volumeServText.isEmpty ? DesignSystem.Colors.primary(for: colorScheme).opacity(0.3) : DesignSystem.Colors.primary(for: colorScheme))
                    .padding(.leading, 8)
            }
            .disabled(volumeServText.isEmpty)
        }
        //.padding(.top, 8)
    }
    
    private var productInfoView: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Text(purchase.Name)
                    .font(DesignSystem.Typography.ProdName)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    .frame(width: 180, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 8)
                    .padding(.top, 6)
                
                Spacer()
            }
            
            Text("Доступно: \(Int(purchase.Volume)) \(purchase.Unit)")
                .font(DesignSystem.Typography.ProdVolume)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                .frame(width: 180, alignment: .leading)
                .padding(.leading, 8)
                .padding(.bottom, 6)
                .frame(maxHeight: .infinity, alignment: .bottomLeading)
        }
        .frame(height: 66)
    }
    
    private func addToRation() {
        guard let volumeServ = Double(volumeServText) else { return }
        
        let volumeServGr = volumeServ * volumeStep
        
        // Проверяем, достаточно ли продукта в заказе
        guard volumeServGr <= purchase.VolumeGr else {
            print("❌ Недостаточно продукта в заказе. Доступно: \(purchase.VolumeGr)г, требуется: \(volumeServGr)г")
            return
        }
        
        // Расчет питательных веществ
        let ratio = volumeServGr / 100.0
        let kcalServ = purchase.Kcal100g * ratio
        let protServ = purchase.Prot100g * ratio
        let fatServ = purchase.Fat100g * ratio
        let carbServ = purchase.Carb100g * ratio
        
        // Форматируем даты
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let rationDateStr = dateFormatter.string(from: selectedDate)
        // let orderDateStr = dateFormatter.string(from: purchase.OrderDate)
        
        // Получаем текущего пользователя
        guard let currentUser = getCurrentUser() else {
            print("❌ Пользователь не найден")
            return
        }
        
        // 1. UserID для записи в рацион (ВСЕГДА текущий пользователь)
        let rationUserID = currentUser.UserID.uuidString
        
        // 2. UserID для обновления OtherPurch
        let updateUserID: String
        if currentUser.UserAccType == 0 {
            // Личный аккаунт: используем текущего пользователя
            updateUserID = currentUser.UserID.uuidString
        } else {
            // Семейный аккаунт: используем UserID из карточки продукта
            updateUserID = purchase.UserID.isEmpty ? currentUser.UserID.uuidString : purchase.UserID
            print("🔍 Семейный аккаунт: обновляем заказ пользователя \(updateUserID.prefix(8))...")
        }
        
        // ПОДГОТОВКА ДАННЫХ ДЛЯ СЕРВЕРА
        let rationData: [String: Any] = [
            "prod_id": purchase.ProdID,
            "name": purchase.Name,
            "volume": purchase.Volume,
            "unit": purchase.Unit,
            "volume_gr": purchase.VolumeGr,
            "kcal100g": purchase.Kcal100g,
            "prot100g": purchase.Prot100g,
            "fat100g": purchase.Fat100g,
            "carb100g": purchase.Carb100g,
            "expire_date": "",
            "tag": purchase.Tag,
            "cat": purchase.Cat,
            "meal_id": mealID,
            "meal_name": getMealName(for: mealID),
            "ration_date": rationDateStr,
            "volume_serv": volumeServ,
            "volume_serv_gr": volumeServGr,
            "kcal_serv": kcalServ,
            "prot_serv": protServ,
            "fat_serv": fatServ,
            "carb_serv": carbServ,
            "user_id": rationUserID
        ]
        
        // Вычисляем новые значения объемов для сервера
        let newVolumeGr = max(0, purchase.VolumeGr - volumeServGr)
        let newVolume = max(0, purchase.Volume - volumeServ)
        
        // 1. ОТПРАВКА НА СЕРВЕР В РАЦИОН
        addToRationOnServer(rationData: rationData)
        
        // 2. ОБНОВЛЯЕМ НА СЕРВЕРЕ OtherPurch
        if currentUser.UserAccType != 0 {
            // СЕМЕЙНЫЙ АККАУНТ
            if !currentUser.UserFamilyID.isEmpty {
                updateOtherPurchOnServer(
                    prodID: purchase.ProdID,
                    familyID: currentUser.UserFamilyID,
                    userID: updateUserID,
                    storeID: purchase.StoreID,
                    orderDate: purchase.OrderDate,
                    newVolumeGr: newVolumeGr,
                    newVolume: newVolume
                )
            } else {
                print("⚠️ Семейный аккаунт, но нет FamilyID")
            }
        } else {
            // ЛИЧНЫЙ АККАУНТ
            updateOtherPurchOnServer(
                prodID: purchase.ProdID,
                familyID: "0",
                userID: updateUserID,
                storeID: purchase.StoreID,
                orderDate: purchase.OrderDate,
                newVolumeGr: newVolumeGr,
                newVolume: newVolume
            )
        }
        
        volumeServText = ""
    }
    
    // Отправка на сервер в рацион
    private func addToRationOnServer(rationData: [String: Any]) {
        guard let url = URL(string: "http://\(ServerConfig.YourIP):8000/add_to_ration") else {
            print("❌ Неверный URL сервера для добавления в рацион")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: rationData)
            request.httpBody = jsonData
            
            print("📤 Отправка данных в рацион на сервер (из заказа):")
            print("   Product: \(purchase.Name)")
            print("   Meal: \(getMealName(for: mealID))")
            print("   Date: \(rationData["ration_date"] ?? "N/A")")
            print("   Volume: \(rationData["volume_serv"] ?? 0) \(purchase.Unit)")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Ошибка отправки в рацион: \(error.localizedDescription)")
                    return
                }
                
                if let data = data {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📥 Ответ сервера (рацион): \(responseString)")
                    }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if json["status"] as? String == "success" {
                            print("✅ Продукт из заказа успешно добавлен в серверный рацион")
                        } else {
                            print("❌ Ошибка добавления в рацион: \(json["message"] as? String ?? "Unknown error")")
                        }
                    }
                }
            }.resume()
            
        } catch {
            print("❌ Ошибка сериализации JSON: \(error)")
        }
    }

    private func updateOtherPurchOnServer(prodID: Int, familyID: String, userID: String, storeID: Int, orderDate: Date, newVolumeGr: Double, newVolume: Double) {
        guard let url = URL(string: "http://\(ServerConfig.YourIP):8000/update_other_purch") else {
            print("❌ Неверный URL сервера для обновления OtherPurch")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Форматируем дату в строку
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let orderDateString = dateFormatter.string(from: orderDate)
        
        let body: [String: Any] = [
            "prod_id": prodID,
            "family_id": familyID,
            "user_id": userID,
            "store_id": storeID,
            "order_date": orderDateString,
            "new_volume_gr": newVolumeGr,
            "new_volume": newVolume
        ]
        
        print("📤 Отправка обновления OtherPurch на сервер:")
        print("   ProdID: \(prodID)")
        print("   FamilyID: \(familyID)")
        print("   UserID: \(userID)")
        print("   StoreID: \(storeID)")
        print("   OrderDate: \(orderDateString)")
        print("   New VolumeGr: \(newVolumeGr)")
        print("   New Volume: \(newVolume)")
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Ошибка обновления OtherPurch на сервере: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Ответ сервера: \(responseString)")
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if json["status"] as? String == "success" {
                        print("✅ OtherPurch успешно обновлен на сервере")
                        
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ReloadServerData"),
                                object: nil
                            )
                        }
                    } else {
                        print("❌ Ошибка обновления OtherPurch на сервере: \(json["message"] as? String ?? "Unknown error")")
                    }
                }
            }
        }.resume()
    }
    
    private func getMealName(for mealID: Int) -> String {
        switch mealID {
        case 0: return "Завтрак"
        case 1: return "Обед"
        case 2: return "Ужин"
        default: return "Прием пищи"
        }
    }
}

// MARK: - Product Card for Search
struct ProductCardSearch: View {
    @Environment(\.colorScheme) var colorScheme
    
    let product: OrderCreatorViewModel.Product
    let quantity: Int
    let onQuantityChanged: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Изображение продукта
            productImageView
            
            // Информация о продукте
            productInfoView
                .padding(.leading, 12)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            
            // Счетчик
            quantityCounterView
        }
        //.padding(.top, 8)
        .padding(.horizontal, min(AdaptiveSpacing.horizontalSpace * 1.5, 30))
    }
    
    private var productImageView: some View {
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
            
            HybridImage(prodID: product.prod_id)
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
        }
        .frame(width: 66, height: 66)
    }
    
    private var productInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.name)
                .font(DesignSystem.Typography.ProdName)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("\(Int(product.volume)) \(product.unit)")
                .font(DesignSystem.Typography.ProdVolume)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.7))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                .lineLimit(1)
            
            Text("\(String(format: "%.0f", product.total_cost)) Р")
                .font(.custom("Montserrat-SemiBold", size: 14))
                .foregroundColor(DesignSystem.Colors.accent2)
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
        }
    }
    
    private var quantityCounterView: some View {
        HStack(spacing: 0) {
            // Кнопка минус
            Button(action: {
                let newQuantity = max(0, quantity - 1)
                onQuantityChanged(newQuantity)
            }) {
                ZStack {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.15) : DesignSystem.Colors.grey1)
                    
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(quantity > 0 ?
                            DesignSystem.Colors.primary(for: colorScheme) :
                            DesignSystem.Colors.primary(for: colorScheme).opacity(0.3))
                }
                .frame(width: 30, height: 30)
            }
            .disabled(quantity == 0)
            
            // Поле с числом
            ZStack {
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.15) : DesignSystem.Colors.grey1)
                    .frame(width: 40, height: 30)
                
                Text("\(quantity)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .frame(width: 40)
            }
            
            // Кнопка плюс
            Button(action: {
                onQuantityChanged(quantity + 1)
            }) {
                ZStack {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.15) : DesignSystem.Colors.grey1)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                }
                .frame(width: 30, height: 30)
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.2), lineWidth: 0)
        )
        .frame(width: 100, height: 30)
    }
}

// MARK: - Product Card for Cart
struct ProductCardCart: View {
    @Environment(\.colorScheme) var colorScheme
    
    let product: OrderCreatorViewModel.Product
    let quantity: Int
    let onQuantityChanged: (Int) -> Void
    
    private var totalVolume: Double {
        product.volume * Double(quantity)
    }
    
    private var totalCost: Double {
        product.total_cost * Double(quantity)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Изображение продукта
            productImageView
            
            // Информация о продукте
            productInfoView
                .padding(.leading, 12)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            
            // Счетчик
            quantityCounterView
        }
       // .padding(.top, 8)
        .padding(.horizontal, min(AdaptiveSpacing.horizontalSpace * 1.5, 30))
    }
    
    private var productImageView: some View {
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
            
            HybridImage(prodID: product.prod_id)
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
        }
        .frame(width: 66, height: 66)
    }
    
    private var productInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.name)
                .font(DesignSystem.Typography.ProdName)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("\(Int(totalVolume)) \(product.unit)")
                .font(DesignSystem.Typography.ProdVolume)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.7))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                .lineLimit(1)
            
            Text("Итого: \(String(format: "%.0f", totalCost)) Р")
                .font(.custom("Montserrat-SemiBold", size: 14))
                .foregroundColor(DesignSystem.Colors.accent2)
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
        }
    }
    
    private var quantityCounterView: some View {
        HStack(spacing: 0) {
            // Кнопка минус
            Button(action: {
                let newQuantity = max(0, quantity - 1)
                onQuantityChanged(newQuantity)
            }) {
                ZStack {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.15) : DesignSystem.Colors.grey1)
                    
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(quantity > 0 ?
                            DesignSystem.Colors.primary(for: colorScheme) :
                            DesignSystem.Colors.primary(for: colorScheme).opacity(0.3))
                }
                .frame(width: 30, height: 30)
            }
            .disabled(quantity == 0)
            
            // Поле с числом
            ZStack {
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.15) : DesignSystem.Colors.grey1)
                    .frame(width: 40, height: 30)
                
                Text("\(quantity)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .frame(width: 40)
            }
            
            // Кнопка плюс
            Button(action: {
                onQuantityChanged(quantity + 1)
            }) {
                ZStack {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.15) : DesignSystem.Colors.grey1)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                }
                .frame(width: 30, height: 30)
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.2), lineWidth: 0)
        )
        .frame(width: 100, height: 30)
    }
}

