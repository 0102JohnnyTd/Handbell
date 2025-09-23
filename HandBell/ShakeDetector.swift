//
//  ShakeDetector.swift
//  HandBell
//
//  Created by GitHub Copilot.
//

import Foundation
import CoreMotion
import Combine

/// Publishes an event when a device shake-like motion is detected using CoreMotion's userAcceleration.
final class ShakeDetector: ObservableObject {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    private var lastShakeDate: Date = .distantPast

    /// Emits a Void each time a shake is detected (rate-limited by `cooldown`).
    let shakePublisher = PassthroughSubject<Void, Never>()

    /// Minimum userAcceleration magnitude (in g) to count as a shake.
    var threshold: Double = 1.2

    /// Minimum seconds between consecutive shake events.
    var cooldown: TimeInterval = 0.8

    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let self, error == nil, let motion else { return }
            let a = motion.userAcceleration
            let magnitude = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)

            if magnitude > self.threshold {
                let now = Date()
                if now.timeIntervalSince(self.lastShakeDate) > self.cooldown {
                    self.lastShakeDate = now
                    DispatchQueue.main.async {
                        self.shakePublisher.send(())
                    }
                }
            }
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}
