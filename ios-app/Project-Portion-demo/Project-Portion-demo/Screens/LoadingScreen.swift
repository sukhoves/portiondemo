//
//  LoadingScreen.swift
//  Project-Portion-demo
//
//  Created by Evgenii Sukhov on 30.01.2026.
//

import SwiftUI

struct AdvancedMeshLoadingView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var phase1 = 0.0
    @State private var phase2 = 0.0
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: colorScheme == .dark ? [
                            Color(hex: "051529"),
                            Color(hex: "29315D"),
                            Color(hex: "06182D"),
                            Color(hex: "171B2E"),
                            Color(hex: "051529")
                        ] : [
                            Color(hex: "044CA0"),
                            Color(hex: "7C91FF"),
                            Color(hex: "0F5CB6"),
                            Color(hex: "788EFF"),
                            Color(hex: "044CA0")
                        ]),
                        center: .center,
                        angle: .degrees(phase1)
                    )
                )
                .blur(radius: 60)
                .ignoresSafeArea()
            
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                (colorScheme == .dark ? Color.black.opacity(0.3) : Color.white).opacity(0.3),
                                .clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(
                        x: cos(phase2 + Double(index) * 2.0) * 100,
                        y: sin(phase2 + Double(index) * 2.0) * 100
                    )
            }
            
            Rectangle()
                .fill(colorScheme == .dark ? Color.black.opacity(0.5) : Color.white.opacity(0.8))
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase1 = 360
            }
            
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                phase2 = .pi * 2
            }
        }
    }
}
