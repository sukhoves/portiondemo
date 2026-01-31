//
//  AccountView.swift
//  Project-Portion-demo
//
//  Created by Evgenii Sukhov on 30.01.2026.
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Constants & Configuration
private enum AccountConstants {
    static let kcalPerWeight = 22.0
    static let ageThreshold = 25
    static let heightThreshold = 180
}

// MARK: - Account ViewModel
@MainActor
final class AccountViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var editingField: String? = nil
    @Published var tempValue: String = ""
    @Published var showClearDataAlert = false
    @Published var isExpandedPD = true
    @Published var showFamilyIDDialog = false
    @Published var familyIDInput = ""
    
    // MARK: - Private Properties
    private var users: [UserInfo] = []
    
    // MARK: - Computed Properties
    var user: UserInfo? {
        users.first
    }
    
    // только для отображения
    var ration: (kcal: Int, prot: Int, fat: Int, carb: Int) {
        calculateRation()
    }
    
    // MARK: - Display Properties (по аналогии с Fridge и Statistic)
    var displayUserName: String {
        user?.UserName ?? "Новый пользователь"
    }
    
    var displayPhoneNumber: String {
        user?.UserPhoneNumber ?? "+7 777 777-77-77"
    }
    
    var displayGender: Int {
        Int(user?.UserGender ?? 0)
    }
    
    var displayAge: String {
        guard let age = user?.UserAge, age > 0 else { return "" }
        return "\(Int(age)) \(getAgeText(Int(age)))"
    }
    
    var displayHeight: String {
        guard let height = user?.UserHeight, height > 0 else { return "" }
        return "\(Int(height)) см"
    }
    
    var displayWeight: String {
        guard let weight = user?.UserWeight, weight > 0 else { return "" }
        return "\(Int(weight)) кг"
    }
    
    var displayActivity: Int {
        Int(user?.UserActivity ?? 0)
    }
    
    var displayGoal: Int {
        Int(user?.UserGoal ?? 0)
    }
    
    var displayAccountType: Int {
        Int(user?.UserAccType ?? 0)
    }
    
    var displayFamilyID: String {
        user?.UserFamilyID ?? ""
    }
    
    var displayRationKcal: Int {
        ration.kcal
    }
    
    var displayRationProtein: Int {
        ration.prot
    }
    
    var displayRationFat: Int {
        ration.fat
    }
    
    var displayRationCarbs: Int {
        ration.carb
    }
    
    // MARK: - Public Methods
    func updateUsers(_ users: [UserInfo]) {
        self.users = users
    }
    
    func checkAndSetFamilyID() {
        if let user = user {
            if user.UserAccType == 0 && user.UserFamilyID.isEmpty {
                user.UserFamilyID = "0"
                saveContext(user: user)
                print("✅ Автоматически установлен FamilyID = 0 для личного аккаунта")
            }
        }
    }
    
    func clearAllData(modelContext: ModelContext) {
        do {
            try clearModelData(RationInfo.self, modelContext: modelContext)
            try clearModelData(UserInfo.self, modelContext: modelContext)
            try clearModelData(RationOptimum.self, modelContext: modelContext)
            try clearModelData(MainPurch.self, modelContext: modelContext)
            try clearModelData(OtherPurch.self, modelContext: modelContext)
            try clearModelData(MealList.self, modelContext: modelContext)
            print("✅ Все данные успешно очищены")
        } catch {
            print("❌ Ошибка при очистке данных: \(error)")
        }
    }
    
    func startEditing(_ field: String, value: String) {
        editingField = field
        tempValue = value
    }
    
    func updateUserField(_ field: String, value: Double, user: UserInfo) {
        switch field {
        case "gender":
            user.UserGender = value
        case "age":
            user.UserAge = value
        case "height":
            user.UserHeight = value
        case "weight":
            user.UserWeight = value
        case "activity":
            user.UserActivity = value
        default:
            break
        }
        
        saveContext(user: user)
        saveOptimalValues(user: user)
    }
    
    func saveContext(user: UserInfo) {
        user.modelContext?.saveContext()
    }
    
    func saveOptimalValues(user: UserInfo) {
        let newRation = calculateRation()
        user.UserKcalOpt = Double(newRation.kcal)
        user.UserProtOpt = Double(newRation.prot)
        user.UserFatOpt = Double(newRation.fat)
        user.UserCarbOpt = Double(newRation.carb)
        saveContext(user: user)
    }
    
    func getAgeText(_ age: Int) -> String {
        let lastDigit = age % 10
        let lastTwoDigits = age % 100
        
        if lastTwoDigits >= 11 && lastTwoDigits <= 14 {
            return "лет"
        } else if lastDigit == 1 {
            return "год"
        } else if lastDigit >= 2 && lastDigit <= 4 {
            return "года"
        } else {
            return "лет"
        }
    }
    
    func cancelFamilyID() {
        if let user = user {
            user.UserAccType = 0
            user.UserFamilyID = "0"
            saveContext(user: user)
        }
        familyIDInput = ""
    }
    
    func confirmFamilyID() {
        if let user = user, !familyIDInput.isEmpty {
            user.UserFamilyID = familyIDInput
            saveContext(user: user)
        } else {
            cancelFamilyID()
        }
        familyIDInput = ""
    }
    
    func updateAccountType(_ newValue: Int) {
        if let user = user {
            user.UserAccType = Double(newValue)
            
            if newValue == 0 {
                user.UserFamilyID = "0"
                saveContext(user: user)
                print("✅ Установлен личный аккаунт, FamilyID = 0")
            } else {
                showFamilyIDDialog = true
            }
        }
    }
    
    // MARK: - Private Methods
    private func clearModelData<T: PersistentModel>(_ modelType: T.Type, modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<T>()
        let items = try modelContext.fetch(descriptor)
        for item in items {
            modelContext.delete(item)
        }
        try modelContext.save()
        print("✅ Очищены данные: \(String(describing: modelType))")
    }
    
    private func calculateRation() -> (kcal: Int, prot: Int, fat: Int, carb: Int) {
        let userAge = user?.UserAge ?? 0
        let userGender = user?.UserGender ?? 0
        let userHeight = user?.UserHeight ?? 0
        let userWeight = user?.UserWeight ?? 0
        let userActivity = Int(user?.UserActivity ?? 0)
        let userGoal = Int(user?.UserGoal ?? 0)
        
        let ageMultiplicator = userAge <= Double(AccountConstants.ageThreshold) ? 1.15 : 1.0
        let genderMultiplicator = userGender == 0 ? 1.0 : 0.95
        let heightMultiplicator = userHeight <= Double(AccountConstants.heightThreshold) ? 1.0 : 1.025
        
        let step1 = AccountConstants.kcalPerWeight * ageMultiplicator
        let step2 = step1 * genderMultiplicator
        let step3 = step2 * heightMultiplicator
        var baseKcal = step3 * userWeight
        
        let activityAdd: Double
        switch userActivity {
        case 0: activityAdd = 250
        case 1: activityAdd = 500
        case 2: activityAdd = 750
        default: activityAdd = 0
        }
        baseKcal += activityAdd
        
        let goalCorrection: Double
        switch userGoal {
        case 0: goalCorrection = -400
        case 1: goalCorrection = 0
        case 2: goalCorrection = 400
        default: goalCorrection = 0
        }
        
        var totalKcal = baseKcal + goalCorrection
        totalKcal = max(totalKcal, 0)
        
        let protKcal = totalKcal * 0.15
        let fatKcal = totalKcal * 0.25
        let carbKcal = totalKcal * 0.6
        
        let prot = Int(protKcal / 4)
        let fat = Int(fatKcal / 9)
        let carb = Int(carbKcal / 4)
        
        return (kcal: Int(totalKcal), prot: prot, fat: fat, carb: carb)
    }
}

// MARK: - Account Top Header View
struct AccountTopHeaderView: View {
    @Environment(\.colorScheme) var colorScheme
    let onClearDataTapped: () -> Void
    
    var body: some View {
        HStack {
            Text("Аккаунт")
                .font(DesignSystem.Typography.screentitle)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                .padding(.top, 10)
            
            Spacer()
            
            Button(action: onClearDataTapped) {
                HStack(spacing: 4) {
                    Circle().frame(width: 6, height: 6)
                    Circle().frame(width: 6, height: 6)
                    Circle().frame(width: 6, height: 6)
                }
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
            }
            .padding(.top, 10)
        }
    }
}

// MARK: - User Profile View
struct UserProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    let userName: String
    let phoneNumber: String
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.7))
                    .stroke(
                        Color.gray,
                        lineWidth: 2
                    )
                    .frame(width: 60, height: 60)
            }
            
            VStack(spacing: 4) {
                Text(userName)
                    .font(DesignSystem.Typography.ProdName)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(phoneNumber)
                    .font(DesignSystem.Typography.ProdNameReg)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 11)
            
            Spacer()
            
          //  Image(colorScheme == .dark ? "loyalpointdark" : "loyalpointlight")
            //.resizable()
            // .aspectRatio(contentMode: .fill)
            Rectangle()
                .fill(Color.gray)
                .frame(width: 38, height: 20)
                .cornerRadius(100)
        }
    }
}

// MARK: - Personal Data View
struct PersonalDataView: View {
    @Environment(\.colorScheme) var colorScheme
    let isExpanded: Bool
    let genderIndex: Int
    let ageText: String
    let heightText: String
    let weightText: String
    let activityIndex: Int
    let isEditingField: String?
    let tempValue: String
    let onToggleExpanded: () -> Void
    let onGenderChanged: (Int) -> Void
    let onAgeTapped: () -> Void
    let onAgeCommit: () -> Void
    let onHeightTapped: () -> Void
    let onHeightCommit: () -> Void
    let onWeightTapped: () -> Void
    let onWeightCommit: () -> Void
    let onActivityChanged: (Int) -> Void
    
    @Binding var bindingTempValue: String
    
    var body: some View {
        VStack {
            HStack {
                Text("Личные данные")
                    .font(DesignSystem.Typography.CatTitle)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Button(action: onToggleExpanded) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                }
            }
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            
            if isExpanded {
                // Пол
                HStack {
                    Text("Пол")
                        .font(DesignSystem.Typography.ProdName)
                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.7))
                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 2)
                    
                    Spacer()
                    
                    SegmentedControlSmall(
                        items: ["Муж.", "Жен."],
                        selectedIndex: Binding(
                            get: { genderIndex },
                            set: onGenderChanged
                        )
                    )
                }
                .frame(height: 44)
                .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                
                Divider()
                    .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                
                // Возраст
                EditableFieldRow(
                    title: "Возраст",
                    value: ageText,
                    isEditing: isEditingField == "age",
                    tempValue: $bindingTempValue,
                    onTap: onAgeTapped,
                    onCommit: onAgeCommit
                )
                .padding(.top, 2)
                .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                
                Divider()
                    .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                
                // Рост
                EditableFieldRow(
                    title: "Рост",
                    value: heightText,
                    isEditing: isEditingField == "height",
                    tempValue: $bindingTempValue,
                    onTap: onHeightTapped,
                    onCommit: onHeightCommit
                )
                .padding(.top, 2)
                .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                
                Divider()
                    .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                
                // Вес
                EditableFieldRow(
                    title: "Вес",
                    value: weightText,
                    isEditing: isEditingField == "weight",
                    tempValue: $bindingTempValue,
                    onTap: onWeightTapped,
                    onCommit: onWeightCommit
                )
                .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                
                Divider()
                    .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                
                // Активность
                HStack {
                    Text("Активность")
                        .font(DesignSystem.Typography.ProdName)
                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.7))
                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 2)
                    
                    Spacer()
                    
                    SegmentedControlSmall(
                        items: ["Низ", "Ср", "Выс"],
                        selectedIndex: Binding(
                            get: { activityIndex },
                            set: onActivityChanged
                        )
                    )
                }
                .frame(height: 44)
                .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            }
        }
        .padding(.top, 12)
    }
}

// MARK: - Goal View
struct GoalView: View {
    @Environment(\.colorScheme) var colorScheme
    let goalIndex: Int
    let onGoalChanged: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Цель")
                    .font(DesignSystem.Typography.CatTitle)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            
            SegmentedControl(
                items: ["Дефицит", "Баланс", "Профицит"],
                selectedIndex: Binding(
                    get: { goalIndex },
                    set: onGoalChanged
                )
            )
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
        }
    }
}

// MARK: - Optimal Ration View
struct OptimalRationView: View {
    @Environment(\.colorScheme) var colorScheme
    let rationKcal: Int
    let rationProtein: Int
    let rationFat: Int
    let rationCarbs: Int
    
    var body: some View {
        HStack(alignment: .top) {
            Text("**Оптимальный** ежедневный рацион для заданных параметров")
                .font(DesignSystem.Typography.ProdName)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(rationKcal) Ккал")
                        .font(.custom("Montserrat-SemiBold", size: 20))
                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    Text("из них:")
                        .font(.custom("Montserrat-Medium", size: 16))
                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.8))
                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                HStack(spacing: 4) {
                    NutrientBlock(letter: "Б", number: "\(rationProtein)")
                    NutrientBlock(letter: "Ж", number: "\(rationFat)")
                    NutrientBlock(letter: "У", number: "\(rationCarbs)")
                }
                .padding(.top, 15)
            }
            .frame(width: 120)
        }
    }
}

// MARK: - Account Type View
struct AccountTypeView: View {
    @Environment(\.colorScheme) var colorScheme
    let accountTypeIndex: Int
    let onAccountTypeChanged: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Тип аккаунта")
                    .font(DesignSystem.Typography.CatTitle)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            
            SegmentedControl(
                items: ["Личный", "Семейный"],
                selectedIndex: Binding(
                    get: { accountTypeIndex },
                    set: onAccountTypeChanged
                )
            )
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
        }
    }
}

// MARK: - Family View
struct FamilyView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Семья")
                    .font(DesignSystem.Typography.CatTitle)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            
            HStack {
                VStack {
                    Rectangle()
                        .fill(DesignSystem.Colors.accent4.opacity(0.2))
                        .frame(height: 90)
                        .cornerRadius(20)
                    Text("Вы")
                        .font(DesignSystem.Typography.Variation1)
                }
                
                Spacer()
                
                VStack {
                    Rectangle()
                        .fill(DesignSystem.Colors.accent2.opacity(0.2))
                        .frame(height: 90)
                        .cornerRadius(20)
                    Text("Жена")
                        .font(DesignSystem.Typography.Variation1)
                }
                
                Spacer()
                
                VStack {
                    Rectangle()
                        .fill(DesignSystem.Colors.primary(for: colorScheme).opacity(0.1))
                        .frame(height: 90)
                        .cornerRadius(20)
                    Text("Дети")
                        .font(DesignSystem.Typography.Variation1)
                }
                
                Spacer()
                
                VStack {
                    Rectangle()
                        .fill(DesignSystem.Colors.primary(for: colorScheme).opacity(0.1))
                        .frame(height: 90)
                        .cornerRadius(20)
                    Text("Питомцы")
                        .font(DesignSystem.Typography.Variation1)
                }
            }
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
        }
    }
}

// MARK: - Editable Field Row
struct EditableFieldRow: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let value: String
    let isEditing: Bool
    @Binding var tempValue: String
    let onTap: () -> Void
    let onCommit: () -> Void
    let keyboardType: UIKeyboardType = .numbersAndPunctuation
    
    private let rowHeight: CGFloat = 44
    
    var body: some View {
        HStack {
            Text(title)
                .font(DesignSystem.Typography.ProdName)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.7))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 2)
            
            Spacer()
            
            if isEditing {
                TextField("", text: $tempValue)
                    .keyboardType(keyboardType)
                    .textFieldStyle(PlainTextFieldStyle())
                    .multilineTextAlignment(.trailing)
                    .font(DesignSystem.Typography.ProdName)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    .submitLabel(.done)
                    .onSubmit(onCommit)
                    .frame(width: 100)
                    .padding(.vertical, 4)
            } else {
                if value.isEmpty {
                    Text("Нажмите чтобы ввести")
                        .font(DesignSystem.Typography.ProdName)
                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.3))
                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                } else {
                    Text(value)
                        .font(DesignSystem.Typography.ProdName)
                        .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                }
            }
        }
        .frame(height: rowHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                onTap()
            }
        }
    }
}

// MARK: - ModelContext Extension
extension ModelContext {
    func saveContext() {
        do {
            try self.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

// MARK: - Main Account View
struct AccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    @Query private var users: [UserInfo]
    @StateObject private var viewModel: AccountViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: AccountViewModel())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Верхняя панель
            AccountTopHeaderView(
                onClearDataTapped: { viewModel.showClearDataAlert = true }
            )
            .padding(.bottom, 8)
            .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
            
            ScrollView {
                VStack {
                    // Профиль пользователя
                    UserProfileView(
                        userName: viewModel.displayUserName,
                        phoneNumber: viewModel.displayPhoneNumber
                    )
                    .padding(.top, 4)
                    .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                    
                    // Личные данные
                    PersonalDataView(
                        isExpanded: viewModel.isExpandedPD,
                        genderIndex: viewModel.displayGender,
                        ageText: viewModel.displayAge,
                        heightText: viewModel.displayHeight,
                        weightText: viewModel.displayWeight,
                        activityIndex: viewModel.displayActivity,
                        isEditingField: viewModel.editingField,
                        tempValue: viewModel.tempValue,
                        onToggleExpanded: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.isExpandedPD.toggle()
                            }
                        },
                        onGenderChanged: { newValue in
                            if let user = viewModel.user {
                                viewModel.updateUserField("gender", value: Double(newValue), user: user)
                            }
                        },
                        onAgeTapped: {
                            viewModel.startEditing("age", value: viewModel.user?.UserAge ?? 0 > 0 ? String(Int(viewModel.user?.UserAge ?? 0)) : "")
                        },
                        onAgeCommit: {
                            if let newValue = Int(viewModel.tempValue), let user = viewModel.user {
                                viewModel.updateUserField("age", value: Double(newValue), user: user)
                            }
                            viewModel.editingField = nil
                        },
                        onHeightTapped: {
                            viewModel.startEditing("height", value: viewModel.user?.UserHeight ?? 0 > 0 ? String(Int(viewModel.user?.UserHeight ?? 0)) : "")
                        },
                        onHeightCommit: {
                            if let newValue = Int(viewModel.tempValue), let user = viewModel.user {
                                viewModel.updateUserField("height", value: Double(newValue), user: user)
                            }
                            viewModel.editingField = nil
                        },
                        onWeightTapped: {
                            viewModel.startEditing("weight", value: viewModel.user?.UserWeight ?? 0 > 0 ? String(Int(viewModel.user?.UserWeight ?? 0)) : "")
                        },
                        onWeightCommit: {
                            if let newValue = Int(viewModel.tempValue), let user = viewModel.user {
                                viewModel.updateUserField("weight", value: Double(newValue), user: user)
                            }
                            viewModel.editingField = nil
                        },
                        onActivityChanged: { newValue in
                            if let user = viewModel.user {
                                viewModel.updateUserField("activity", value: Double(newValue), user: user)
                            }
                        },
                        bindingTempValue: $viewModel.tempValue
                    )
                    .padding(.top, 12)
                    
                    // Цель
                    GoalView(
                        goalIndex: viewModel.displayGoal,
                        onGoalChanged: { newValue in
                            if let user = viewModel.user {
                                user.UserGoal = Double(newValue)
                                viewModel.saveContext(user: user)
                                viewModel.saveOptimalValues(user: user)
                            }
                        }
                    )
                    .padding(.top, 12)
                    
                    // Оптимальный рацион
                    OptimalRationView(
                        rationKcal: viewModel.displayRationKcal,
                        rationProtein: viewModel.displayRationProtein,
                        rationFat: viewModel.displayRationFat,
                        rationCarbs: viewModel.displayRationCarbs
                    )
                    .padding(.top, 16)
                    .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                    
                    // Тип аккаунта
                    AccountTypeView(
                        accountTypeIndex: viewModel.displayAccountType,
                        onAccountTypeChanged: viewModel.updateAccountType
                    )
                    .padding(.top, 15)
                    
                    // Семья (опционально)
                    FamilyView()
                        .padding(.top, 12)
                    
                    Spacer()
                }
            }
            .padding(.bottom, 70)
        }
        .background(DesignSystem.Colors.appbackground(for: colorScheme))
        .ignoresSafeArea(.all, edges: .bottom)
        .alert("Очистка данных", isPresented: $viewModel.showClearDataAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Очистить все данные", role: .destructive) {
                viewModel.clearAllData(modelContext: modelContext)
            }
        } message: {
            Text("Это действие удалит ВСЕ данные приложения:\n• Рационы\n• Пользователей\n• Оптимальные значения\n• Запасы\n• Заказы\n• Приемы пищи\n\nДействие нельзя отменить.")
        }
        .alert("Введите FamilyID", isPresented: $viewModel.showFamilyIDDialog) {
            TextField("FamilyID", text: $viewModel.familyIDInput)
            Button("Отмена") {
                viewModel.cancelFamilyID()
            }
            Button("Подтвердить") {
                viewModel.confirmFamilyID()
            }
        } message: {
            Text("Пожалуйста, введите идентификатор семьи для подключения к семейному аккаунту.")
        }
        .onAppear {
            viewModel.updateUsers(users)
            viewModel.checkAndSetFamilyID()
        }
        .onChange(of: users) { oldValue, newValue in
            viewModel.updateUsers(newValue)
        }
    }
}

