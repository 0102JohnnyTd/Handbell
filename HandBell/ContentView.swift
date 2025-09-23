//
//  ContentView.swift
//  HandBell
//
//  Created by Johnny Toda on 2025/09/19.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var detector = ShakeDetector()
    private let player = BellPlayer()
    @State private var cancellable: AnyCancellable?

    @State private var swingAngle: Double = 0
    @State private var isSwinging: Bool = false
    @State private var animationID: Int = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                BellView(angle: swingAngle)
                    .frame(width: 240, height: 320)
                    .rotationEffect(.degrees(swingAngle), anchor: .top)
                    .animation(.interpolatingSpring(stiffness: 200, damping: 9), value: swingAngle)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        ringAndSwing()
                    }

                Text("iPhoneを振る or タップでベルを鳴らそう")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .onAppear {
            // サイレントスイッチ中でも鳴らしたい場合は true
            player.overrideSilentSwitch = true
            player.volume = 1.0
            // Subscribe to shake events
            cancellable = detector.shakePublisher
                .receive(on: RunLoop.main)
                .sink {
                    ringAndSwing()
                }
            detector.start()
        }
        .onDisappear {
            detector.stop()
            cancellable?.cancel()
        }
    }

    private func ringAndSwing() {
        player.ring(filename: "old-style-door-bell-101191")
        startSwingAnimation()
    }

    private func startSwingAnimation() {
        // 再スタート対応: 新しいアニメIDを採番し、古いスケジュールは無効化する
        let currentID = animationID + 1
        animationID = currentID
        isSwinging = true

        // 減衰スイングシーケンス
        let swings = [22.0, -19.0, 15.0, -12.0, 8.0, -5.0, 2.0, 0.0]
        var delay: TimeInterval = 0
        let step: TimeInterval = 0.12

        for angle in swings {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // 途中で再スタートされた場合は無視
                guard animationID == currentID else { return }
                withAnimation(.easeOut(duration: step)) {
                    swingAngle = angle
                }
            }
            delay += step
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.02) {
            guard animationID == currentID else { return }
            isSwinging = false
        }
    }
}

#Preview {
    ContentView()
}

/// A simple bell shape using SF Symbols as placeholder; replace with custom asset if desired.
private struct BellView: View {
    var angle: Double
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let handleWidth = max(12, w * 0.14)
            let handleHeight = h * 0.52
            let ferruleHeight = max(5, h * 0.035)
            let bellWidth = w * 0.76
            let bellHeight = h * 0.48
            let clapperX = angle * 0.4
            let gapAfterFerrule: CGFloat = 8

            ZStack(alignment: .top) {
                // Wooden handle
                VStack(spacing: 2) {
                    // Handle base with richer wood gradient
                    ZStack {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.35, green: 0.20, blue: 0.08),
                                        Color(red: 0.55, green: 0.33, blue: 0.15),
                                        Color(red: 0.28, green: 0.16, blue: 0.06)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
                            )
                            .frame(width: handleWidth, height: handleHeight)

                        // Specular highlight stripe on the handle (left side)
                        Capsule()
                            .fill(
                                LinearGradient(colors: [Color.white.opacity(0.35), .clear], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: handleWidth * 0.38, height: handleHeight * 0.9)
                            .offset(x: -handleWidth * 0.22)

                        // Carved ring lines on the handle
                        VStack {
                            Spacer().frame(height: handleHeight * 0.45)
                            Rectangle()
                                .fill(Color.black.opacity(0.12))
                                .frame(width: handleWidth * 0.95, height: 1)
                            Spacer().frame(height: handleHeight * 0.08)
                            Rectangle()
                                .fill(Color.black.opacity(0.1))
                                .frame(width: handleWidth * 0.9, height: 1)
                            Spacer()
                        }
                        .frame(width: handleWidth, height: handleHeight)
                    }

                }
                .frame(maxWidth: .infinity)

                // Bell body using SF Symbol for a clean silhouette
                Image(systemName: "bell.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: bellWidth, height: bellHeight)
                    .foregroundStyle(
                        LinearGradient(colors: [Color.yellow.opacity(0.98), Color.orange.opacity(0.95)], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .offset(y: handleHeight + ferruleHeight + gapAfterFerrule - bellHeight * 0.05)

                // Ferrule (metal ring) placed between handle and bell, not overlapping
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        LinearGradient(colors: [Color(white: 0.95), Color(white: 0.82), Color(white: 0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: handleWidth * 1.24, height: ferruleHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .stroke(Color.black.opacity(0.12), lineWidth: 0.8)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
                    .offset(y: handleHeight)
            }
            .frame(width: w, height: h, alignment: .top)
        }
        .compositingGroup()
    }
}
