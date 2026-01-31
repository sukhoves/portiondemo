//
//  Styles.swift
//  Project-Portion-demo
//
//  Created by Evgenii Sukhov on 30.01.2026.
//

import SwiftUI

struct DesignSystem {
    struct Typography {
        static let screentitle = Font.custom("Montserrat-SemiBold", size: 26)
        static let CatTitle = Font.custom("Montserrat-Medium", size: 23)
        static let ProdName = Font.custom("Montserrat-Medium", size: 16)
        static let ProdVolume = Font.custom("Montserrat-Regular", size: 13)
        static let ProdDateRange = Font.custom("Montserrat-Regular", size: 12)
        static let CcalMedium = Font.custom("Montserrat-SemiBold", size: 16)
        static let Tag = Font.custom("Montserrat-SemiBold", size: 12)
        static let ProdNameReg = Font.custom("Montserrat-Regular", size: 16)
        static let SelectButton = Font.custom("Montserrat-SemiBold", size: 14)
        static let Variation1 = Font.custom("Montserrat-Medium", size: 14)
        static let CcalMediumS = Font.custom("Montserrat-SemiBold", size: 15)
        static let Variation2 = Font.custom("Montserrat-Medium", size: 12)
        static let FinanceMain = Font.custom("Montserrat-SemiBold", size: 26)
        static let Variation3 = Font.custom("Montserrat-Regular", size: 14)
        static let CatTitleSmall = Font.custom("Montserrat-Medium", size: 18)
    }
    
    struct Colors {
                static func primary(for colorScheme: ColorScheme) -> Color {
                    return colorScheme == .dark ? .white : .black
                }
                static func background(for colorScheme: ColorScheme) -> Color {
                    return colorScheme == .dark ? Color(hex: "202327") : .white
                }
                static func appbackground(for colorScheme: ColorScheme) -> Color {
                    return colorScheme == .dark ? Color(hex: "0E0E0E") : .white
                }
        
        static let secondary = Color.black.opacity(0.8)
        static let background = Color.white
        static let grey1 = Color(hex: "F8F6F1")
        
        static let accent1 = Color(hex: "0F3B6E")
        static let accent2 = Color(hex: "FF4F01")
        static let accent3 = Color(hex: "0B9EE0")
        static let accent4 = Color(hex: "788DF9")
        
    }
    
    struct Spacing {
        
        static let LeftSpace: CGFloat = 24
        static let RightSpace: CGFloat = 24
        
    }
    
        static func tracking(for font: Font, percent: CGFloat) -> CGFloat {
            let fontSize: CGFloat
            switch font {
            case .title: fontSize = 26
            case .headline: fontSize = 20
            case .body: fontSize = 16
            case .caption: fontSize = 14
            default: fontSize = 16
            }
            return fontSize * (percent / 100)
        }
    
}

struct InputField: View {
    
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let backgroundColor: Color
    
    init(
        width: CGFloat = 80,
        height: CGFloat = 30,
        cornerRadius: CGFloat = 12,
        backgroundColor: Color = DesignSystem.Colors.grey1
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        Rectangle()
            .fill(backgroundColor)
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
    }
}

struct BlurredRectangle: View {
    var body: some View {
        Rectangle()
            .fill(
                AngularGradient(
                    gradient: Gradient(stops: [
                        .init(color: DesignSystem.Colors.accent3, location: 0.17),
                        .init(color: DesignSystem.Colors.accent1, location: 0.39),
                        .init(color: DesignSystem.Colors.accent4, location: 0.57),
                        .init(color: DesignSystem.Colors.accent2, location: 0.92)
                    ]),
                    center: .center
                )
            )
            .frame(width: 142, height: 172)
            .cornerRadius(20)
            .overlay(
                BlurView(style: .systemUltraThinMaterial)
                    .cornerRadius(20)
            )
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct TagColors {
    static let mapping: [String: Color] = [
        "Много белка": DesignSystem.Colors.accent2,
        "Диета": DesignSystem.Colors.accent3,
        "Быстро": DesignSystem.Colors.accent4
    ]
    
    static func color(for tag: String) -> Color {
        return mapping[tag] ?? DesignSystem.Colors.accent2
    }
}

struct AdaptiveSpacing {
    static var horizontalSpace: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        
        if screenWidth >= 428 {
            return 24 // iPhone Pro Max, Plus (большие)
        } else {
            return 16 // iPhone Pro, стандартные, mini, SE (все остальные)
        }
    }
}
