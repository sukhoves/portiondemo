//
//  FridgeBanner.swift
//  Project-Portion-demo
//
//  Created by Evgenii Sukhov on 30.01.2026.
//

import SwiftUI

struct FridgeBanner: View {
    @Environment(\.colorScheme) var colorScheme
    let products: [MainPurch]
    let userKcalOpt: Double
    
    init(products: [MainPurch], userKcalOpt: Double = 2100) {
        self.products = products
        self.userKcalOpt = userKcalOpt
    }
    
    // Вычисляемые свойства для сумм
    private var totalKcal: Int {
        Int(products.reduce(0) { $0 + $1.totalKcal })
    }
    
    private var totalProtein: Int {
        Int(products.reduce(0) { $0 + $1.totalProtein })
    }
    
    private var totalFat: Int {
        Int(products.reduce(0) { $0 + $1.totalFat })
    }
    
    private var totalCarbs: Int {
        Int(products.reduce(0) { $0 + $1.totalCarbs })
    }
    
    private var fullRations: Int {

            if userKcalOpt > 0 {
                return Int(Double(totalKcal) / userKcalOpt)
            } else {
                return Int(totalKcal) / 2100
            }
        }
    
    

        private var rationText: String {
            let lastDigit = fullRations % 10
            let lastTwoDigits = fullRations % 100
            
            if lastTwoDigits >= 11 && lastTwoDigits <= 14 {
                return "Полноценных рационов"
            } else if lastDigit == 1 {
                return "Полноценный рацион"
            } else if lastDigit >= 2 && lastDigit <= 4 {
                return "Полноценных рациона"
            } else {
                return "Полноценных рационов"
            }
        }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack {
                // Image(colorScheme == .dark ? "detailedfridge3" : "detailedfridge3light")
                   // .resizable()
                  //  .frame(height: 246)
                   // .frame(maxWidth: .infinity)
                   // .clipped()
                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 240)
                    .cornerRadius(20)
                    .padding(.horizontal, AdaptiveSpacing.horizontalSpace - 3)
                   // .padding(.bottom, 6)
                    
            }
            
            // Прозрачный Rectangle как основа для блоков
            Rectangle()
                .fill(Color.clear)
                .frame(height: 246)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AdaptiveSpacing.horizontalSpace)
                .overlay(
                    HStack(alignment: .top) {
                        // Левый блок
                        VStack(alignment: .trailing, spacing: 0) {
                            VStack(alignment: .trailing, spacing: 0) {
                                Text("\(totalKcal) Ккал")
                                    .font(.custom("Montserrat-SemiBold", size: 20))
                                    .foregroundColor(.white)
                                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                                    .frame(alignment: .trailing)
                                
                                Text("из них:")
                                    .font(.custom("Montserrat-Medium", size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                                    .frame(alignment: .trailing)
                            }
                            
                            // БЖУ прямоугольники
                            HStack(spacing: 4) {
                                NutrientBlockL(letter: "Б", number: "\(totalProtein)")
                                NutrientBlockL(letter: "Ж", number: "\(totalFat)")
                                NutrientBlockL(letter: "У", number: "\(totalCarbs)")
                            }
                            .padding(.top, 14)
                            
                        }
                        .offset(x: 0, y: 0)
                        .padding(.leading, AdaptiveSpacing.horizontalSpace + AdaptiveSpacing.horizontalSpace + 12)
                        
                        Spacer()
                        
                        // Правый блок
                        VStack(alignment: .trailing, spacing: 0) {
                            VStack(alignment: .trailing, spacing: 0) {
                                HStack(spacing: 3) {
                                    Text("Холодильника")
                                        .font(.custom("Montserrat-Medium", size: 16))
                                        .foregroundColor(.white.opacity(0.8))
                                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                                        .frame(alignment: .trailing)
                                    
                                    Text("хватает")
                                        .font(.custom("Montserrat-Medium", size: 16))
                                        .foregroundColor(.white.opacity(0.8))
                                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                                        .frame(alignment: .trailing)
                                }
                                Text("на:")
                                    .font(.custom("Montserrat-Medium", size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                                    .frame(alignment: .trailing)
                            }
                            .frame(width: 180, alignment: .trailing)
                            
                            ZStack(alignment: .trailing) {
                                VStack(alignment: .trailing, spacing: 0) {
                                    Text("\(fullRations)")
                                        .font(.custom("Montserrat-Bold", size: 32))
                                        .foregroundColor(.white)
                                        .frame(alignment: .trailing)
                                    
                                    Text(rationText)
                                        .font(.custom("Montserrat-SemiBold", size: 16))
                                        .foregroundColor(.white)
                                        .tracking(DesignSystem.tracking(for: .body, percent: -3))
                                        .multilineTextAlignment(.trailing)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(width: 180, alignment: .trailing)
                            }
                        }
                        .padding(.trailing, AdaptiveSpacing.horizontalSpace + AdaptiveSpacing.horizontalSpace + 12)
                        .offset(y: 3)
                    }
                )
        }
        .padding(.top, 2)
    }
    
}
