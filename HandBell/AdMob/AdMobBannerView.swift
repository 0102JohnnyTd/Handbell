//
//  AdMobBannerView.swift
//  FukugyoShushi
//
//  Created by Johnny Toda on 2025/05/21.
//

import GoogleMobileAds
import SwiftUI

struct AdMobBannerView: UIViewControllerRepresentable {
    var adBannerKey: String
    
    func makeUIViewController(context: Context) -> UIViewController {
        return GADBannerViewController(bannerAdKey: adBannerKey)
    }
        
    func updateUIViewController(_: UIViewController, context _: Context) {}
}

final class GADBannerViewController: UIViewController, BannerViewDelegate {
    var bannerView: BannerView!

    private let adUnitIDsKey = "AdUnitIDs"
    // Info.plistで管理している広告のKey
    var bannerAdKey: String

    init(bannerAdKey: String) {
        self.bannerAdKey = bannerAdKey
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadBanner()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self else { return }
            self.loadBanner()
        }
    }

    private func getAdUnitID(key: String) -> String {
        // Info.plistからadUnitIDsを取得し、[String: String]へのキャストを試みる
        guard let adUnitIDs = Bundle.main.object(forInfoDictionaryKey: adUnitIDsKey) as? [String: String] else {
            print("Warning: AdUnitIDs not found in Info.plist or has wrong format")
            // テスト用の広告IDまたは空文字列を返す
            return "ca-app-pub-3940256099942544/2934735716" // Googleのテスト用バナー広告ID
        }
        
        // 指定されたキーの値を取得、なければデフォルト値を返す
        guard let adUnitID = adUnitIDs[key] else {
            print("Warning: Ad unit ID for key \(key) not found, using test ad unit ID")
            return "ca-app-pub-3940256099942544/2934735716" // Googleのテスト用バナー広告ID
        }
        
        return adUnitID
    }

    private func loadBanner() {
        bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = getAdUnitID(key: bannerAdKey)

        bannerView.delegate = self
        bannerView.rootViewController = self

        let bannerWidth = view.frame.size.width
        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: bannerWidth)

        let request = Request()
        request.scene = view.window?.windowScene
        bannerView.load(request)

        setAdView(bannerView)
    }

    func setAdView(_ view: BannerView) {
        bannerView = view
        self.view.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 強制アンラップを避け、オプショナルバインディングを使用
        guard let bannerView = bannerView else {
            print("Warning: bannerView is nil in setAdView")
            return
        }
        
        let viewDictionary = ["_bannerView": bannerView]
        self.view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|[_bannerView]|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary
            )
        )
        self.view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|[_bannerView]|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary
            )
        )
    }
}
