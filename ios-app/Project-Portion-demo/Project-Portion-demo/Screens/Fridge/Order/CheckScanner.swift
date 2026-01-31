//
//  CheckScanner.swift
//  Project-Portion-demo
//
//  Created by Evgenii Sukhov on 30.01.2026.
//

import SwiftUI
import SwiftData

struct CheckScanner: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @Query private var users: [UserInfo]
    
    @State private var orderUrl = ""
    @State private var isLoading = false
 
    
    private var currentUser: UserInfo? {
        users.first
    }
    
    var body: some View {
        VStack {
            // Заголовок как в CreatorView
            CheckScannerTopHeaderView()
                .padding(.horizontal, min(AdaptiveSpacing.horizontalSpace * 1.5, 30))
                .padding(.top, 30)
            
         Text("Функционал не доступен в демонстративном материале")
                .font(DesignSystem.Typography.ProdVolume)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.75))
            
            // Плавающие кнопки
            ZStack(alignment: .bottom) {
    
                ScrollView {
                    VStack {
                      
                    }
                    .padding(.bottom, 80)
                }
                
                CheckScannerFloatingButtonsView(
                    orderUrl: "",
                    isLoading: isLoading,
                    onBackAction: {
                        dismiss()
                    },
                    onProcessAction: {
                        dismiss()
                    }
                )
            }
            .ignoresSafeArea(.all, edges: .bottom)
        }
        .background(DesignSystem.Colors.appbackground(for: colorScheme))
    }
    
}

// MARK: - Компоненты (UI Components)

// MARK: - Top Header View
struct CheckScannerTopHeaderView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Text("Сканер заказов из магазина")
                .font(DesignSystem.Typography.screentitle)
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
            
            Spacer()
        }
    }
}

// MARK: - Floating Action Buttons
struct CheckScannerFloatingButtonsView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let orderUrl: String
    let isLoading: Bool
    let onBackAction: () -> Void
    let onProcessAction: () -> Void
    
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
                    
                    // Кнопка "Обработать"
                    if !orderUrl.isEmpty {
                        ProcessButtonView(
                            colorScheme: colorScheme, 
                            isLoading: isLoading,
                            isEnabled: !orderUrl.isEmpty && !isLoading,
                            action: onProcessAction
                        )
                    }
                }
                .padding(.bottom, 20)
                .padding(.horizontal, CGFloat(Int(min(AdaptiveSpacing.horizontalSpace * 1.5, 30) * 1.66)))
            )
    }
}

// MARK: - Back Button
struct csBackButtonView: View {
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

// MARK: - Process Button
struct ProcessButtonView: View {
    let colorScheme: ColorScheme
    let isLoading: Bool
    let isEnabled: Bool
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
                    ).opacity(isEnabled ? 0.9 : 0.5)
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
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.right")
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
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.7)
    }
}

