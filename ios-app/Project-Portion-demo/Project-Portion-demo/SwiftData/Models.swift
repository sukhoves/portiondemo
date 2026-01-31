//
//  Models.swift
//  Project-Portion-demo
//
//  Created by Evgenii Sukhov on 30.01.2026.
//


import SwiftUI
import SwiftData
import Foundation

// AppConstants
enum ServerConfig {
    static let YourIP = "000.000.0.000"
}

// MARK: ОСНОВНЫЕ ЗАКАЗЫ

@Model
final class MainPurch {
    var ProdID: Int
    var Name: String
    var Volume: Double
    var Unit: String
    var VolumeGr: Double
    var Kcal100g: Double
    var Prot100g: Double
    var Fat100g: Double
    var Carb100g: Double
    var ExpireDate: Date
    var Tag: String
    var Cat: String
    var Store: String
    var StoreID: Int
    var OrderDate: Date
    var PrefMealID: Int
    var PrefMeal: String
    var TotalCost: Double
    var Address: String
    var AddressID: Int
    var UserID: String  // UUID как строка
    var FamilyID: Int
    
    init(
        ProdID: Int,
        Name: String,
        Volume: Double,
        Unit: String,
        VolumeGr: Double,
        Kcal100g: Double,
        Prot100g: Double,
        Fat100g: Double,
        Carb100g: Double,
        ExpireDate: Date,
        Tag: String,
        Cat: String,
        Store: String = "",
        StoreID: Int = 0,
        OrderDate: Date = Date(),
        PrefMealID: Int = 0,
        PrefMeal: String = "",
        TotalCost: Double = 0.0,
        Address: String = "",
        AddressID: Int = 0,
        UserID: String = "",
        FamilyID: Int = 0
    ) {
        self.ProdID = ProdID
        self.Name = Name
        self.Volume = Volume
        self.Unit = Unit
        self.VolumeGr = VolumeGr
        self.Kcal100g = Kcal100g
        self.Prot100g = Prot100g
        self.Fat100g = Fat100g
        self.Carb100g = Carb100g
        self.ExpireDate = ExpireDate
        self.Tag = Tag
        self.Cat = Cat
        self.Store = Store
        self.StoreID = StoreID
        self.OrderDate = OrderDate
        self.PrefMealID = PrefMealID
        self.PrefMeal = PrefMeal
        self.TotalCost = TotalCost
        self.Address = Address
        self.AddressID = AddressID
        self.UserID = UserID
        self.FamilyID = FamilyID
    }
}

// Добавьте этот extension
extension MainPurch {
    var totalKcal: Double {
        return Kcal100g * (VolumeGr / 100)
    }
    
    var totalProtein: Double {
        return Prot100g * (VolumeGr / 100)
    }
    
    var totalFat: Double {
        return Fat100g * (VolumeGr / 100)
    }
    
    var totalCarbs: Double {
        return Carb100g * (VolumeGr / 100)
    }
}

struct SendableMainPurch: Sendable {
    let prodID: Int
    let name: String
    let volume: Double
    let unit: String
    let volumeGr: Double
    let kcal100g: Double
    let prot100g: Double
    let fat100g: Double
    let carb100g: Double
    let expireDate: Date
    let tag: String
    let cat: String
    let store: String
    let storeID: Int
    let orderDate: Date
    let prefMealID: Int
    let prefMeal: String
    let totalCost: Double
    let address: String
    let addressID: Int
    let userID: String
    let familyID: Int
    
    init(prodID: Int, name: String, volume: Double, unit: String, volumeGr: Double, kcal100g: Double, prot100g: Double, fat100g: Double, carb100g: Double, expireDate: Date, tag: String, cat: String, store: String, storeID: Int, orderDate: Date, prefMealID: Int, prefMeal: String, totalCost: Double, address: String, addressID: Int, userID: String, familyID: Int) {
        self.prodID = prodID
        self.name = name
        self.volume = volume
        self.unit = unit
        self.volumeGr = volumeGr
        self.kcal100g = kcal100g
        self.prot100g = prot100g
        self.fat100g = fat100g
        self.carb100g = carb100g
        self.expireDate = expireDate
        self.tag = tag
        self.cat = cat
        self.store = store
        self.storeID = storeID
        self.orderDate = orderDate
        self.prefMealID = prefMealID
        self.prefMeal = prefMeal
        self.totalCost = totalCost
        self.address = address
        self.addressID = addressID
        self.userID = userID
        self.familyID = familyID
    }
    
    static func from(_ mainPurch: MainPurch) -> SendableMainPurch {
        SendableMainPurch(
            prodID: mainPurch.ProdID,
            name: mainPurch.Name,
            volume: mainPurch.Volume,
            unit: mainPurch.Unit,
            volumeGr: mainPurch.VolumeGr,
            kcal100g: mainPurch.Kcal100g,
            prot100g: mainPurch.Prot100g,
            fat100g: mainPurch.Fat100g,
            carb100g: mainPurch.Carb100g,
            expireDate: mainPurch.ExpireDate,
            tag: mainPurch.Tag,
            cat: mainPurch.Cat,
            store: mainPurch.Store,
            storeID: mainPurch.StoreID,
            orderDate: mainPurch.OrderDate,
            prefMealID: mainPurch.PrefMealID,
            prefMeal: mainPurch.PrefMeal,
            totalCost: mainPurch.TotalCost,
            address: mainPurch.Address,
            addressID: mainPurch.AddressID,
            userID: mainPurch.UserID,
            familyID: mainPurch.FamilyID
        )
    }
    
    func toMainPurch() -> MainPurch {
        MainPurch(
            ProdID: prodID,
            Name: name,
            Volume: volume,
            Unit: unit,
            VolumeGr: volumeGr,
            Kcal100g: kcal100g,
            Prot100g: prot100g,
            Fat100g: fat100g,
            Carb100g: carb100g,
            ExpireDate: expireDate,
            Tag: tag,
            Cat: cat,
            Store: store,
            StoreID: storeID,
            OrderDate: orderDate,
            PrefMealID: prefMealID,
            PrefMeal: prefMeal,
            TotalCost: totalCost,
            Address: address,
            AddressID: addressID,
            UserID: userID,
            FamilyID: familyID
        )
    }
}


// MARK: Остальные ЗАКАЗЫ

@Model
final class OtherPurch {
    var ProdID: Int
    var Name: String
    var Volume: Double
    var Unit: String
    var VolumeGr: Double
    var Kcal100g: Double
    var Prot100g: Double
    var Fat100g: Double
    var Carb100g: Double
    var Tag: String
    var Cat: String
    var Store: String
    var StoreID: Int
    var OrderDate: Date
    var TotalCost: Double
    var Address: String
    var AddressID: Int
    var UserID: String  // UUID как строка
    var FamilyID: Int
    
    init(
        ProdID: Int,
        Name: String,
        Volume: Double,
        Unit: String,
        VolumeGr: Double,
        Kcal100g: Double,
        Prot100g: Double,
        Fat100g: Double,
        Carb100g: Double,
        Tag: String,
        Cat: String,
        Store: String,
        StoreID: Int,
        OrderDate: Date,
        TotalCost: Double = 0.0,
        Address: String = "",
        AddressID: Int = 0,
        UserID: String = "",
        FamilyID: Int = 0
    ) {
        self.ProdID = ProdID
        self.Name = Name
        self.Volume = Volume
        self.Unit = Unit
        self.VolumeGr = VolumeGr
        self.Kcal100g = Kcal100g
        self.Prot100g = Prot100g
        self.Fat100g = Fat100g
        self.Carb100g = Carb100g
        self.Tag = Tag
        self.Cat = Cat
        self.Store = Store
        self.StoreID = StoreID
        self.OrderDate = OrderDate
        self.TotalCost = TotalCost
        self.Address = Address
        self.AddressID = AddressID
        self.UserID = UserID
        self.FamilyID = FamilyID
    }
}

struct SendableOtherPurch: Sendable {
    let prodID: Int
    let name: String
    let volume: Double
    let unit: String
    let volumeGr: Double
    let kcal100g: Double
    let prot100g: Double
    let fat100g: Double
    let carb100g: Double
    let tag: String
    let cat: String
    let store: String
    let storeID: Int
    let orderDate: Date
    let totalCost: Double
    let address: String
    let addressID: Int
    let userID: String
    let familyID: Int
    
    init(prodID: Int, name: String, volume: Double, unit: String, volumeGr: Double,
         kcal100g: Double, prot100g: Double, fat100g: Double, carb100g: Double,
         tag: String, cat: String, store: String, storeID: Int, orderDate: Date,
         totalCost: Double, address: String, addressID: Int, userID: String, familyID: Int) {
        self.prodID = prodID
        self.name = name
        self.volume = volume
        self.unit = unit
        self.volumeGr = volumeGr
        self.kcal100g = kcal100g
        self.prot100g = prot100g
        self.fat100g = fat100g
        self.carb100g = carb100g
        self.tag = tag
        self.cat = cat
        self.store = store
        self.storeID = storeID
        self.orderDate = orderDate
        self.totalCost = totalCost
        self.address = address
        self.addressID = addressID
        self.userID = userID
        self.familyID = familyID
    }
    
    static func from(_ otherPurch: OtherPurch) -> SendableOtherPurch {
        SendableOtherPurch(
            prodID: otherPurch.ProdID,
            name: otherPurch.Name,
            volume: otherPurch.Volume,
            unit: otherPurch.Unit,
            volumeGr: otherPurch.VolumeGr,
            kcal100g: otherPurch.Kcal100g,
            prot100g: otherPurch.Prot100g,
            fat100g: otherPurch.Fat100g,
            carb100g: otherPurch.Carb100g,
            tag: otherPurch.Tag,
            cat: otherPurch.Cat,
            store: otherPurch.Store,
            storeID: otherPurch.StoreID,
            orderDate: otherPurch.OrderDate,
            totalCost: otherPurch.TotalCost,
            address: otherPurch.Address,
            addressID: otherPurch.AddressID,
            userID: otherPurch.UserID,
            familyID: otherPurch.FamilyID
        )
    }
    
    func toOtherPurch() -> OtherPurch {
        OtherPurch(
            ProdID: prodID,
            Name: name,
            Volume: volume,
            Unit: unit,
            VolumeGr: volumeGr,
            Kcal100g: kcal100g,
            Prot100g: prot100g,
            Fat100g: fat100g,
            Carb100g: carb100g,
            Tag: tag,
            Cat: cat,
            Store: store,
            StoreID: storeID,
            OrderDate: orderDate,
            TotalCost: totalCost,
            Address: address,
            AddressID: addressID,
            UserID: userID,
            FamilyID: familyID
        )
    }
}



// MARK: СПИСОК ПРИЕМОВ

@Model
final class MealList {
    var MealID: Int
    var MealName: String
    
    init(MealID: Int, MealName: String) {
        self.MealID = MealID
        self.MealName = MealName
    }
}


// MARK: ИНФОРМАЦИЯ О РАЦИОНЕ

@Model
final class RationInfo {
    var ProdID: Int
    var Name: String
    var Volume: Double
    var Unit: String
    var VolumeGr: Double
    var Kcal100g: Double
    var Prot100g: Double
    var Fat100g: Double
    var Carb100g: Double
    var ExpireDate: Date
    var Tag: String
    var Cat: String
    var MealID: Int
    var MealName: String
    var RationDate: Date
    var VolumeServ: Double
    var VolumeServGr: Double
    var KcalServ: Double
    var ProtServ: Double
    var FatServ: Double
    var CarbServ: Double
    var UserID: String
    
    init(
        ProdID: Int,
        Name: String,
        Volume: Double,
        Unit: String,
        VolumeGr: Double,
        Kcal100g: Double,
        Prot100g: Double,
        Fat100g: Double,
        Carb100g: Double,
        ExpireDate: Date,
        Tag: String,
        Cat: String,
        MealID: Int = 0,
        MealName: String = "",
        RationDate: Date = Date(),
        VolumeServ: Double = 0,
        VolumeServGr: Double = 0,
        KcalServ: Double = 0,
        ProtServ: Double = 0,
        FatServ: Double = 0,
        CarbServ: Double = 0,
        UserID: String = ""
    ) {
        self.ProdID = ProdID
        self.Name = Name
        self.Volume = Volume
        self.Unit = Unit
        self.VolumeGr = VolumeGr
        self.Kcal100g = Kcal100g
        self.Prot100g = Prot100g
        self.Fat100g = Fat100g
        self.Carb100g = Carb100g
        self.ExpireDate = ExpireDate
        self.Tag = Tag
        self.Cat = Cat
        self.MealID = MealID
        self.MealName = MealName
        self.RationDate = RationDate
        self.VolumeServ = VolumeServ
        self.VolumeServGr = VolumeServGr
        self.KcalServ = KcalServ
        self.ProtServ = ProtServ
        self.FatServ = FatServ
        self.CarbServ = CarbServ
        self.UserID = UserID
    }
}

struct SendableRationInfo: Sendable {
    let prodID: Int
    let name: String
    let volume: Double
    let unit: String
    let volumeGr: Double
    let kcal100g: Double
    let prot100g: Double
    let fat100g: Double
    let carb100g: Double
    let expireDate: Date
    let tag: String
    let cat: String
    let mealID: Int
    let mealName: String
    let rationDate: Date
    let volumeServ: Double
    let volumeServGr: Double
    let kcalServ: Double
    let protServ: Double
    let fatServ: Double
    let carbServ: Double
    let userID: String
    
    init(prodID: Int, name: String, volume: Double, unit: String, volumeGr: Double,
         kcal100g: Double, prot100g: Double, fat100g: Double, carb100g: Double,
         expireDate: Date, tag: String, cat: String, mealID: Int, mealName: String,
         rationDate: Date, volumeServ: Double, volumeServGr: Double, kcalServ: Double,
         protServ: Double, fatServ: Double, carbServ: Double, userID: String) {
        self.prodID = prodID
        self.name = name
        self.volume = volume
        self.unit = unit
        self.volumeGr = volumeGr
        self.kcal100g = kcal100g
        self.prot100g = prot100g
        self.fat100g = fat100g
        self.carb100g = carb100g
        self.expireDate = expireDate
        self.tag = tag
        self.cat = cat
        self.mealID = mealID
        self.mealName = mealName
        self.rationDate = rationDate
        self.volumeServ = volumeServ
        self.volumeServGr = volumeServGr
        self.kcalServ = kcalServ
        self.protServ = protServ
        self.fatServ = fatServ
        self.carbServ = carbServ
        self.userID = userID
    }
    
    static func from(_ rationInfo: RationInfo) -> SendableRationInfo {
        SendableRationInfo(
            prodID: rationInfo.ProdID,
            name: rationInfo.Name,
            volume: rationInfo.Volume,
            unit: rationInfo.Unit,
            volumeGr: rationInfo.VolumeGr,
            kcal100g: rationInfo.Kcal100g,
            prot100g: rationInfo.Prot100g,
            fat100g: rationInfo.Fat100g,
            carb100g: rationInfo.Carb100g,
            expireDate: rationInfo.ExpireDate,
            tag: rationInfo.Tag,
            cat: rationInfo.Cat,
            mealID: rationInfo.MealID,
            mealName: rationInfo.MealName,
            rationDate: rationInfo.RationDate,
            volumeServ: rationInfo.VolumeServ,
            volumeServGr: rationInfo.VolumeServGr,
            kcalServ: rationInfo.KcalServ,
            protServ: rationInfo.ProtServ,
            fatServ: rationInfo.FatServ,
            carbServ: rationInfo.CarbServ,
            userID: rationInfo.UserID
        )
    }
    
    func toRationInfo() -> RationInfo {
        RationInfo(
            ProdID: prodID,
            Name: name,
            Volume: volume,
            Unit: unit,
            VolumeGr: volumeGr,
            Kcal100g: kcal100g,
            Prot100g: prot100g,
            Fat100g: fat100g,
            Carb100g: carb100g,
            ExpireDate: expireDate,
            Tag: tag,
            Cat: cat,
            MealID: mealID,
            MealName: mealName,
            RationDate: rationDate,
            VolumeServ: volumeServ,
            VolumeServGr: volumeServGr,
            KcalServ: kcalServ,
            ProtServ: protServ,
            FatServ: fatServ,
            CarbServ: carbServ,
            UserID: userID
        )
    }
}


// MARK: ЦЕЛЬ ДЛЯ РАЦИОНА

@Model
final class RationOptimum {
    
    var UserKcalOpt: Double
    var UserProtOpt: Double
    var UserFatOpt: Double
    var UserCarbOpt: Double
    var RationDate: Date
    
    
    init(
        UserKcalOpt: Double, UserProtOpt: Double, UserFatOpt: Double, UserCarbOpt: Double, RationDate: Date
    ) {
        self.UserKcalOpt = UserKcalOpt; self.UserProtOpt = UserProtOpt; self.UserFatOpt = UserFatOpt; self.UserCarbOpt = UserCarbOpt; self.RationDate = RationDate
    }
    
}

// MARK: ПОЛЬЗОВАТЕЛЬ

@Model
final class UserInfo {
    var UserID: UUID
    var UserName: String
    var UserPhoneNumber: String
    var UserAge: Double
    var UserHeight: Double
    var UserWeight: Double
    var UserGender: Double
    var UserGoal: Double
    var UserKcalOpt: Double
    var UserProtOpt: Double
    var UserFatOpt: Double
    var UserCarbOpt: Double
    var UserAccType: Double
    var UserFamilyID: String
    var UserActivity: Double?
    
    init(
        UserID: UUID = UUID(),
        UserName: String = "",
        UserPhoneNumber: String = "",
        UserAge: Double = 0,
        UserHeight: Double = 0,
        UserWeight: Double = 0,
        UserGender: Double = 0,
        UserGoal: Double = 0,
        UserKcalOpt: Double = 0,
        UserProtOpt: Double = 0,
        UserFatOpt: Double = 0,
        UserCarbOpt: Double = 0,
        UserAccType: Double = 0,
        UserFamilyID: String = "",
        UserActivity: Double? = nil
    ) {
        self.UserID = UserID
        self.UserName = UserName
        self.UserPhoneNumber = UserPhoneNumber
        self.UserAge = UserAge
        self.UserHeight = UserHeight
        self.UserWeight = UserWeight
        self.UserGender = UserGender
        self.UserGoal = UserGoal
        self.UserKcalOpt = UserKcalOpt
        self.UserProtOpt = UserProtOpt
        self.UserFatOpt = UserFatOpt
        self.UserCarbOpt = UserCarbOpt
        self.UserAccType = UserAccType
        self.UserFamilyID = UserFamilyID
        self.UserActivity = UserActivity
    }
}


struct SendableUserInfo: Sendable {
    let userID: UUID
    let userName: String
    let userPhoneNumber: String
    let userAge: Double
    let userHeight: Double
    let userWeight: Double
    let userGender: Double
    let userGoal: Double
    let userKcalOpt: Double
    let userProtOpt: Double
    let userFatOpt: Double
    let userCarbOpt: Double
    let userAccType: Double
    let userFamilyID: String
    let userActivity: Double?
    
    init(userID: UUID, userName: String, userPhoneNumber: String, userAge: Double, userHeight: Double, userWeight: Double, userGender: Double, userGoal: Double, userKcalOpt: Double, userProtOpt: Double, userFatOpt: Double, userCarbOpt: Double, userAccType: Double, userFamilyID: String, userActivity: Double?) {
        self.userID = userID
        self.userName = userName
        self.userPhoneNumber = userPhoneNumber
        self.userAge = userAge
        self.userHeight = userHeight
        self.userWeight = userWeight
        self.userGender = userGender
        self.userGoal = userGoal
        self.userKcalOpt = userKcalOpt
        self.userProtOpt = userProtOpt
        self.userFatOpt = userFatOpt
        self.userCarbOpt = userCarbOpt
        self.userAccType = userAccType
        self.userFamilyID = userFamilyID
        self.userActivity = userActivity
    }
    
    static func from(_ userInfo: UserInfo) -> SendableUserInfo {
        SendableUserInfo(
            userID: userInfo.UserID,
            userName: userInfo.UserName,
            userPhoneNumber: userInfo.UserPhoneNumber,
            userAge: userInfo.UserAge,
            userHeight: userInfo.UserHeight,
            userWeight: userInfo.UserWeight,
            userGender: userInfo.UserGender,
            userGoal: userInfo.UserGoal,
            userKcalOpt: userInfo.UserKcalOpt,
            userProtOpt: userInfo.UserProtOpt,
            userFatOpt: userInfo.UserFatOpt,
            userCarbOpt: userInfo.UserCarbOpt,
            userAccType: userInfo.UserAccType,
            userFamilyID: userInfo.UserFamilyID,
            userActivity: userInfo.UserActivity
        )
    }
}


// MARK: ВСЕ ЗАКАЗЫ

@Model
final class AllPurch {
    var ProdID: Int
    var Name: String
    var Volume: Double
    var Unit: String
    var VolumeGr: Double
    var Kcal100g: Double
    var Prot100g: Double
    var Fat100g: Double
    var Carb100g: Double
    var ExpireDate: Date
    var Tag: String
    var Cat: String
    var Store: String
    var StoreID: Int
    var OrderDate: Date
    var PrefMealID: Int
    var PrefMeal: String
    var TotalCost: Double
    var Address: String
    var AddressID: Int
    
    init(
        ProdID: Int,
        Name: String,
        Volume: Double,
        Unit: String,
        VolumeGr: Double,
        Kcal100g: Double,
        Prot100g: Double,
        Fat100g: Double,
        Carb100g: Double,
        ExpireDate: Date,
        Tag: String,
        Cat: String,
        // Существующие параметры
        Store: String = "",
        StoreID: Int = 0,
        OrderDate: Date = Date(),
        PrefMealID: Int = 0,
        PrefMeal: String = "",
        TotalCost: Double = 0.0,
        // Новые параметры адреса
        Address: String = "",
        AddressID: Int = 0
    ) {
        self.ProdID = ProdID
        self.Name = Name
        self.Volume = Volume
        self.Unit = Unit
        self.VolumeGr = VolumeGr
        self.Kcal100g = Kcal100g
        self.Prot100g = Prot100g
        self.Fat100g = Fat100g
        self.Carb100g = Carb100g
        self.ExpireDate = ExpireDate
        self.Tag = Tag
        self.Cat = Cat
        self.Store = Store
        self.StoreID = StoreID
        self.OrderDate = OrderDate
        self.PrefMealID = PrefMealID
        self.PrefMeal = PrefMeal
        self.TotalCost = TotalCost
        self.Address = Address
        self.AddressID = AddressID
    }
}

struct SendableAllPurch: Sendable {
    let prodID: Int
    let name: String
    let volume: Double
    let unit: String
    let volumeGr: Double
    let kcal100g: Double
    let prot100g: Double
    let fat100g: Double
    let carb100g: Double
    let expireDate: Date
    let tag: String
    let cat: String
    let store: String
    let storeID: Int
    let orderDate: Date
    let prefMealID: Int
    let prefMeal: String
    let totalCost: Double
    let address: String
    let addressID: Int
    
    init(prodID: Int, name: String, volume: Double, unit: String, volumeGr: Double,
         kcal100g: Double, prot100g: Double, fat100g: Double, carb100g: Double,
         expireDate: Date, tag: String, cat: String, store: String, storeID: Int,
         orderDate: Date, prefMealID: Int, prefMeal: String, totalCost: Double,
         address: String, addressID: Int) {
        self.prodID = prodID
        self.name = name
        self.volume = volume
        self.unit = unit
        self.volumeGr = volumeGr
        self.kcal100g = kcal100g
        self.prot100g = prot100g
        self.fat100g = fat100g
        self.carb100g = carb100g
        self.expireDate = expireDate
        self.tag = tag
        self.cat = cat
        self.store = store
        self.storeID = storeID
        self.orderDate = orderDate
        self.prefMealID = prefMealID
        self.prefMeal = prefMeal
        self.totalCost = totalCost
        self.address = address
        self.addressID = addressID
    }
    
    static func from(_ allPurch: AllPurch) -> SendableAllPurch {
        SendableAllPurch(
            prodID: allPurch.ProdID,
            name: allPurch.Name,
            volume: allPurch.Volume,
            unit: allPurch.Unit,
            volumeGr: allPurch.VolumeGr,
            kcal100g: allPurch.Kcal100g,
            prot100g: allPurch.Prot100g,
            fat100g: allPurch.Fat100g,
            carb100g: allPurch.Carb100g,
            expireDate: allPurch.ExpireDate,
            tag: allPurch.Tag,
            cat: allPurch.Cat,
            store: allPurch.Store,
            storeID: allPurch.StoreID,
            orderDate: allPurch.OrderDate,
            prefMealID: allPurch.PrefMealID,
            prefMeal: allPurch.PrefMeal,
            totalCost: allPurch.TotalCost,
            address: allPurch.Address,
            addressID: allPurch.AddressID
        )
    }
    
    func toAllPurch() -> AllPurch {
        AllPurch(
            ProdID: prodID,
            Name: name,
            Volume: volume,
            Unit: unit,
            VolumeGr: volumeGr,
            Kcal100g: kcal100g,
            Prot100g: prot100g,
            Fat100g: fat100g,
            Carb100g: carb100g,
            ExpireDate: expireDate,
            Tag: tag,
            Cat: cat,
            Store: store,
            StoreID: storeID,
            OrderDate: orderDate,
            PrefMealID: prefMealID,
            PrefMeal: prefMeal,
            TotalCost: totalCost,
            Address: address,
            AddressID: addressID
        )
    }
}

