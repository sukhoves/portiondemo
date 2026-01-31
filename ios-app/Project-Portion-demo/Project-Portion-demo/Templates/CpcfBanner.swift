//
//  CpcfBanner.swift
//  Project-Portion-demo
//
//  Created by Evgenii Sukhov on 30.01.2026.
//

import SwiftUI

public struct NutrientBlock: View {
    @Environment(\.colorScheme) var colorScheme
    let letter: String
    let number: String
    
    public init(letter: String, number: String) {
        self.letter = letter
        self.number = number
    }
    
    public var body: some View {
        ZStack {
            whiteRoundedRectangle()
            
            VStack(spacing: -2) {
                Text(letter)
                    .font(.custom("Montserrat-Medium", size: 12))
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .padding(.top, 10)
                
                Text(number)
                    .font(.custom("Montserrat-SemiBold", size: 13))
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    .padding(.bottom, 10)
            }
            .frame(width: 26, height: 34)
        }
    }
}

struct whiteRoundedRectangle: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Rectangle()
            .fill(colorScheme == .dark ? Color.white.opacity(0.15) : Color.white)
            .frame(width: 26, height: 34)
            .cornerRadius(8)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 3.5,
                x: 0,
                y: 1
            )
    }
}

public struct NutrientBlockBanner: View {
    @Environment(\.colorScheme) var colorScheme
    let letter: String
    let number: String
    
    public init(letter: String, number: String) {
        self.letter = letter
        self.number = number
    }
    
    public var body: some View {
        ZStack {
            whiteRoundedRectangleBanner()
            
            VStack(spacing: -2) {
                Text(letter)
                    .font(.custom("Montserrat-Medium", size: 12))
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .padding(.top, 10)
                
                Text(number)
                    .font(.custom("Montserrat-SemiBold", size: 13))
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    .padding(.bottom, 10)
            }
            .frame(width: 26, height: 34)
        }
    }
}

struct whiteRoundedRectangleBanner: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Rectangle()
            .fill(colorScheme == .dark ? Color.black.opacity(0.15) : Color.white)
            .frame(width: 26, height: 34)
            .cornerRadius(8)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 3.5,
                x: 0,
                y: 1
            )
    }
}



public struct NutrientBlockSmall: View {
    @Environment(\.colorScheme) var colorScheme
    let number: String
    
    public init(number: String) {
        self.number = number
    }
    
    public var body: some View {
        ZStack {
            whiteRoundedRectangleSmall()
            
            Text(number)
                .font(.custom("Montserrat-SemiBold", size: 12))
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.8))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
        }
        .frame(width: 26, height: 20)
    }
}

struct whiteRoundedRectangleSmall: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
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
    }
}

public struct NutrientBlockSmallBanner: View {
    @Environment(\.colorScheme) var colorScheme
    let number: String
    
    public init(number: String) {
        self.number = number
    }
    
    public var body: some View {
        ZStack {
            whiteRoundedRectangleSmallBanner()
            
            Text(number)
                .font(.custom("Montserrat-SemiBold", size: 12))
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme).opacity(0.8))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
        }
        .frame(width: 26, height: 20)
    }
}

struct whiteRoundedRectangleSmallBanner: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Rectangle()
            .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
            .frame(width: 26, height: 20)
            .cornerRadius(8)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 3.5,
                x: 0,
                y: 1
            )
    }
}

public struct NutrientBlockSmallH: View {
    @Environment(\.colorScheme) var colorScheme
    let number: String
    
    public init(number: String) {
        self.number = number
    }
    
    public var body: some View {
        ZStack {
            whiteRoundedRectangleSmall()
            
            Text(number)
                .font(.custom("Montserrat-SemiBold", size: 13))
                .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                .tracking(DesignSystem.tracking(for: .body, percent: -3))
        }
        .frame(width: 26, height: 20)
    }
}

public struct NutrientBlockL: View {
    @Environment(\.colorScheme) var colorScheme
    let letter: String
    let number: String
    
    public init(letter: String, number: String) {
        self.letter = letter
        self.number = number
    }
    
    public var body: some View {
        ZStack {
            whiteRoundedRectangleL()
            
            VStack(spacing: -2) {
                Text(letter)
                    .font(.custom("Montserrat-Medium", size: 12))
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .padding(.top, 10)
                
                Text(number)
                    .font(.custom("Montserrat-SemiBold", size: 13))
                    .foregroundColor(DesignSystem.Colors.primary(for: colorScheme))
                    .tracking(DesignSystem.tracking(for: .body, percent: -3))
                    .padding(.bottom, 10)
            }
            .frame(width: 26, height: 34)
        }
    }
}

struct whiteRoundedRectangleL: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Rectangle()
            .fill(colorScheme == .dark ? Color.black.opacity(0.15) : Color.white)
            .frame(width: 30, height: 34)
            .cornerRadius(8)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 3.5,
                x: 0,
                y: 1
            )
    }
}
