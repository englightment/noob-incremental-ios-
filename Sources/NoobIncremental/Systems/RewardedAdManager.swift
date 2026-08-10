import Foundation
import UIKit
import GoogleMobileAds

/// Thin wrapper around the Google Mobile Ads SDK for the two rewarded-ad placements.
///
/// Uses Google's public TEST app ID and ad unit ID (see project.yml's GADApplicationIdentifier
/// and AdBoostTier.adUnitID) — these render clearly-labeled "Test Ad" placeholders and work
/// with no AdMob account at all, which is what makes this testable without one. Before a real
/// App Store release:
///   1. Create a free AdMob account and register this app there
///   2. Replace GADApplicationIdentifier in project.yml with your real App ID
///   3. Replace the ad unit ID(s) in AdBoostTier with your real ones (one per placement,
///      or reuse one — your call)
/// I can't verify ad loading/presentation myself: it requires a real device and a network
/// round-trip to Google's ad servers, neither of which this environment has. The pure boost
/// math (AdBoostSystem) is unit-tested; this class itself isn't.
@MainActor
final class RewardedAdManager: NSObject, ObservableObject {
    @Published private(set) var isReady: [AdBoostTier: Bool] = [:]

    private var loadedAds: [AdBoostTier: RewardedAd] = [:]
    private var initialized = false

    func start() {
        guard !initialized else { return }
        initialized = true
        MobileAds.shared.start()
        for tier in AdBoostTier.allCases {
            preload(tier)
        }
    }

    func preload(_ tier: AdBoostTier) {
        guard loadedAds[tier] == nil else { return }
        Task {
            do {
                // Plain default request — no App Tracking Transparency prompt is triggered by
                // this alone. If you later want personalized ads, add Google's User Messaging
                // Platform (UMP) consent SDK before requesting ATT; out of scope here since I
                // can't verify a consent flow without a real device.
                let ad = try await RewardedAd.load(with: tier.adUnitID, request: Request())
                ad.fullScreenContentDelegate = self
                loadedAds[tier] = ad
                isReady[tier] = true
            } catch {
                isReady[tier] = false
            }
        }
    }

    func show(_ tier: AdBoostTier, onReward: @escaping () -> Void) {
        guard let ad = loadedAds[tier], let root = Self.rootViewController() else { return }
        loadedAds[tier] = nil
        isReady[tier] = false
        ad.present(from: root) {
            onReward()
        }
    }

    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}

extension RewardedAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Whichever tier just finished is already cleared from loadedAds by show(); preload
        // is a no-op for the other tier since it's presumably still loaded. Simpler and just
        // as correct as looking up which specific tier dismissed, without depending on an
        // SDK property I can't verify from here.
        for tier in AdBoostTier.allCases {
            preload(tier)
        }
    }
}
