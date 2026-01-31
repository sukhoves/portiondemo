//
//  SearchBlocks.swift
//  Project-Portion-demo
//
//  Created by Evgenii Sukhov on 30.01.2026.
//

import SwiftUI

struct SearchMain: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    var onSearch: ((String) -> Void)?
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.15) : DesignSystem.Colors.grey1)
                .frame(height: 42)
                .cornerRadius(21)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .opacity(0.4)
                    .frame(width: 26, height: 26)
                    .padding(.leading, 16)
                
                TextField("Поиск...", text: $searchText)
                    .font(DesignSystem.Typography.ProdName)
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        onSearch?(searchText)
                    }
                    .onChange(of: searchText) {
                        print("Текущий текст: \(searchText)")
                        onSearch?(searchText)
                    }
                
                Spacer()
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        onSearch?("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .frame(width: 26, height: 26)
                    }
                    .padding(.trailing, 8)
                }
                
                // Image("LavkaAIIcon")
                    //.resizable()
                Circle()
                    .fill(Color.gray)
                    .frame(width: 28, height: 28)
                    .padding(.trailing, 16)
            }
        }
        .onTapGesture {
            isSearchFocused = true
        }
    }
}

struct SegmentedControl: View {
    @Environment(\.colorScheme) var colorScheme
    
    let items: [String]
    @Binding var selectedIndex: Int
    
    var body: some View {
        ZStack {
            // Фон селектора
            Rectangle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.15) : DesignSystem.Colors.grey1)
                .frame(height: 42)
                .frame(maxWidth: .infinity)
                .cornerRadius(21)
            
            HStack(spacing: 0) {
                ForEach(0..<items.count, id: \.self) { index in
                    Button(action: {
                        selectedIndex = index
                    }) {
                        ZStack {
                            // Белый фон для активной кнопки
                            if index == selectedIndex {
                                Rectangle()
                                    .fill(colorScheme == .dark ? Color.black.opacity(0.75) : Color.white)
                                    .frame(height: 36)
                                    .cornerRadius(21)
                                    .padding(2)
                            }
                            
                            Text(items[index])
                                .font(DesignSystem.Typography.SelectButton)
                                .foregroundColor(
                                    index == selectedIndex ?
                                    DesignSystem.Colors.primary(for: colorScheme).opacity(0.85) :
                                    DesignSystem.Colors.primary(for: colorScheme).opacity(0.4)
                                )
                                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(2)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct SegmentedControlSmall: View {
    @Environment(\.colorScheme) var colorScheme
    
    let items: [String]
    @Binding var selectedIndex: Int
    
    var body: some View {
        ZStack {
            // Фон селектора
            Rectangle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.15) : DesignSystem.Colors.grey1)
                .frame(width: 150, height: 36)
                .cornerRadius(21)
            
            HStack(spacing: 0) {
                ForEach(0..<items.count, id: \.self) { index in
                    Button(action: {
                        selectedIndex = index
                    }) {
                        ZStack {
                            // Белый фон для активной кнопки
                            if index == selectedIndex {
                                Rectangle()
                                    .fill(colorScheme == .dark ? Color.black.opacity(0.75) : Color.white)
                                    .frame(height: 28)
                                    .cornerRadius(21)
                                    .padding(2)
                            }
                            
                            Text(items[index])
                                .font(DesignSystem.Typography.SelectButton)
                                .foregroundColor(
                                    index == selectedIndex ?
                                    DesignSystem.Colors.primary(for: colorScheme).opacity(0.85) :
                                    DesignSystem.Colors.primary(for: colorScheme).opacity(0.4)
                                )
                                .tracking(DesignSystem.tracking(for: .body, percent: -3))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(2)
        }
        .fixedSize(horizontal: true, vertical: true)
    }
}
