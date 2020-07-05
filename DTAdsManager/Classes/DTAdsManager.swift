//
//  DTAdManager.swift
//  DTAdsMediation
//
//  Created by Pham Diep on 7/1/20.
//  Copyright © 2020 PPCLink. All rights reserved.
//

import Foundation
import UIKit
import GoogleMobileAds
import FBAudienceNetwork

@objc public class DTAdsManager: NSObject {
    private var isIpad: Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        } else {
            return false
        }
    }
    private var fbBanner: FBAdView?
    private var admobBanner: GADBannerView?
    private var needShowBannerAfterDismisInters: Bool = false
    private var fbInterstitialAd: FBInterstitialAd?
    private var admobInterstitialAd: GADInterstitial?
    private var isProversion: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "DTAdsManagerIsProVersion")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "DTAdsManagerIsProVersion")
        }
    }
    public var bannerView = UIView.init()
    private var bannerRootVC: UIViewController?
    private var leftConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    private var topConstraint: NSLayoutConstraint?
   
    @objc public static var shared = DTAdsManager()
    override init() {
        super.init()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [(kGADSimulatorID as! String)]
        FBAdSettings.addTestDevices([(kGADSimulatorID as! String)])
        if !isProversion {
            reloadAllAds()
        }
    }
    
    public func setProversion(isPro: Bool) {
        if isPro == false && isProversion == true {
           reloadAllAds()
        }
        isProversion = isPro
    }
    /// Chỉ gọi 1 lần
    public func loadBannerAds(rootVC: UIViewController) {
        self.bannerRootVC = rootVC
        fbBanner = nil
        admobBanner = nil
        loadNewBannerAds()
    }
  

    private func reloadAllAds() { // Chỉ reload khi config thay đổi
        fbBanner = nil
        admobBanner = nil
        fbInterstitialAd = nil
        admobInterstitialAd = nil
        loadNewBannerAds()
        loadNewInterstitialAds()
    }
    //MARK: Banner
    public func addBannerToView(parentView: UIView, top: CGFloat? = nil, bottom: CGFloat? = nil, right: CGFloat? = nil, left: CGFloat? = nil, bannerHeight: CGFloat? = nil) {
        bannerView.removeFromSuperview()
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        self.leftConstraint = nil
        self.rightConstraint = nil
        self.topConstraint = nil
        self.bottomConstraint = nil
        self.heightConstraint = nil
        parentView.addSubview(bannerView)
        if let topCons = top {
            self.topConstraint = NSLayoutConstraint.init(item: bannerView, attribute: .top, relatedBy: .equal, toItem: parentView, attribute: .top, multiplier: 1, constant: topCons)
            parentView.addConstraint(self.topConstraint!)
            self.topConstraint?.isActive = true
        }
        if let bottomCons = bottom {
            self.bottomConstraint = NSLayoutConstraint.init(item: bannerView, attribute: .bottom, relatedBy: .equal, toItem: parentView, attribute: .bottom, multiplier: 1, constant: 0 - bottomCons)
            parentView.addConstraint(self.bottomConstraint!)
            self.bottomConstraint?.isActive = true
        }
        if let leftCons = left {
            self.leftConstraint = NSLayoutConstraint.init(item: bannerView, attribute: .left, relatedBy: .equal, toItem: parentView, attribute: .left, multiplier: 1, constant: leftCons)
            parentView.addConstraint(self.leftConstraint!)
            self.leftConstraint?.isActive = true
        }
        if let rightCons = right {
            self.rightConstraint = NSLayoutConstraint.init(item: bannerView, attribute: .right, relatedBy: .equal, toItem: parentView, attribute: .right, multiplier: 1, constant: 0 - rightCons)
            parentView.addConstraint(self.rightConstraint!)
            self.rightConstraint?.isActive = true
        }
        if let heightCons = bannerHeight {
            self.heightConstraint = NSLayoutConstraint.init(item: bannerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: heightCons)
            parentView.addConstraint(self.heightConstraint!)
            self.heightConstraint?.isActive = true
        }
    }
    public func changeBannerConstraintConstant(top: CGFloat? = nil, bottom: CGFloat? = nil, right: CGFloat? = nil, left: CGFloat? = nil, bannerHeight: CGFloat? = nil, foceShow: Bool) {
        if let top = top {
            self.topConstraint?.constant = top
        }
        if let bottom = bottom {
            self.bottomConstraint?.constant = 0 - bottom
        }
        if let right = right {
            self.rightConstraint?.constant = 0 - right
        }
        if let left = left {
            self.leftConstraint?.constant = left
        }
        if let height = bannerHeight {
            self.heightConstraint?.constant = height
        }
        if foceShow {
            bannerView.isHidden = false
        }
        // Kiểm tra xem chưa có thừng banner nào thì reload
        if self.bannerView.subviews.count == 0 {
            loadNewBannerAds()
        }
    }
    public func hideBannerAd() {
        self.bannerView.isHidden = true
    }
    
    private func loadNewBannerAds() {
        guard let rootBannerVC = self.bannerRootVC else {
            return
        }
        if let bannerType = DTAdsConfigManager.shared.getNextBannerType() {
            switch bannerType {
            case .admobBanner:
                if admobBanner == nil {
                    admobBanner = GADBannerView.init(adSize: kGADAdSizeSmartBannerPortrait)
                    admobBanner?.adUnitID = DTAdType.admobBanner.getKey()
                    admobBanner?.rootViewController = rootBannerVC
                    admobBanner?.delegate = self
                    admobBanner?.isAutoloadEnabled = false
                }
                admobBanner?.load(GADRequest.init())
            case .fbBanner:
                if fbBanner == nil {
                    fbBanner = FBAdView.init(placementID: DTAdType.fbBanner.getKey(), adSize: isIpad ? kFBAdSizeHeight90Banner : kFBAdSizeHeight50Banner, rootViewController: rootBannerVC)
                    fbBanner?.delegate = self
                }
                fbBanner?.loadAd()
            default:
                break
            }
        }
    }
    
    //MARK: Interstitial ads
    private func loadNewInterstitialAds() {
        // Kiểm tra lần cuối load lỗi tất cả các mạng đã quá số phút min để load tiếp chưa
        if Date.init().timeIntervalSince1970 - UserDefaults.standard.double(forKey: "DTLastTimeLoadFailedAllInters") < DTAdsConfigManager.shared.getMinRangeShowInters() {
            return
        }
        if let intersType = DTAdsConfigManager.shared.getNextIntersType() {
            switch intersType {
            case .admobInters:
                if admobInterstitialAd == nil {
                    admobInterstitialAd = GADInterstitial.init(adUnitID: DTAdType.admobInters.getKey())
                    admobInterstitialAd?.delegate = self
                }
                let request = GADRequest.init()
                admobInterstitialAd?.load(request)
            case .fbInters:
                if fbInterstitialAd == nil {
                    fbInterstitialAd = FBInterstitialAd.init(placementID: DTAdType.fbInters.getKey())
                    fbInterstitialAd?.delegate = self
                }
                fbInterstitialAd?.load()
            default:
                break
            }
        } else {
            // Lỗi con mẹ nó cả 2 mạng => đợi đến lần show sau mới load. Tránh trường hợp spam load ads
            UserDefaults.standard.set(Date.init().timeIntervalSince1970, forKey: "DTLastTimeLoadFailedAllInters")
        }
    }
    
    public func showInterstitial(rootVC: UIViewController) {
        // Check xem đủ thời gian tối thiểu để show ads chưa
        let lastTimeShow = UserDefaults.standard.double(forKey: "DtLastTimeShowInterstitial")
        if Date().timeIntervalSince1970 - lastTimeShow < DTAdsConfigManager.shared.getMinRangeShowInters() {
            return
        }
        // Check xem thằng nào có thì show
        if fbInterstitialAd?.isAdValid == true {
            needShowBannerAfterDismisInters = !self.bannerView.isHidden
            self.hideBannerAd()
            fbInterstitialAd?.show(fromRootViewController: rootVC)
        } else if admobInterstitialAd?.isReady == true && admobInterstitialAd?.hasBeenUsed == false {
            needShowBannerAfterDismisInters = !self.bannerView.isHidden
            self.hideBannerAd()
            admobInterstitialAd?.present(fromRootViewController: rootVC)
        } else { // Vẫn chưa thằng mặt giặc nào đc load => load lại
            loadNewInterstitialAds()
        }
    }

    
}

extension DTAdsManager: GADInterstitialDelegate {
    public func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        print("Interstitial did load: admob")
    }
    public func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
            print("Iters: admob load loi cmnr: \(error.debugDescription)")
        loadNewInterstitialAds()
    }
    public func interstitialDidDismissScreen(_ ad: GADInterstitial) {
            //Load lấy ad mới
            loadNewInterstitialAds()
        self.bannerView.isHidden = !needShowBannerAfterDismisInters
        }
    public func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        }
}

extension DTAdsManager: FBInterstitialAdDelegate {
    public func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {
         print("Interstitial did load: facebook")
    }
    public func interstitialAd(_ interstitialAd: FBInterstitialAd, didFailWithError error: Error) {
        print("Inters: fb load loi cmnr \(error.localizedDescription)")
        loadNewInterstitialAds()
    }
    public func interstitialAdDidClose(_ interstitialAd: FBInterstitialAd) {
        loadNewInterstitialAds()
        self.bannerView.isHidden = !needShowBannerAfterDismisInters
    }
    public func interstitialAdDidClick(_ interstitialAd: FBInterstitialAd) {
        // Click vào ad => Ẩn banner
        hideBannerAd()
    }
}

extension DTAdsManager: GADBannerViewDelegate, FBAdViewDelegate {
    // admob
    public func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        // Load được rồi thì add vào bannerView
        print("admob banner load ok")
        if bannerView.superview != nil {
            return
        }
        for subV in self.bannerView.subviews {
            subV.removeFromSuperview()
        }
        self.bannerView.addSubview(bannerView)
      //  self.bannerView.autoresizesSubviews = true
        bannerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    public func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
         print("admob banner load loi cmnr")
        loadNewBannerAds()
    }
    
    //facebook
    public func adViewDidLoad(_ adView: FBAdView) {
        print("FB banner load ok")
        if adView.superview != nil {
                   return
               }
               for subV in self.bannerView.subviews {
                   subV.removeFromSuperview()
               }
               self.bannerView.addSubview(adView)
      //  self.bannerView.autoresizesSubviews = true
               adView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    public func adView(_ adView: FBAdView, didFailWithError error: Error) {
        print("FB banner load loi cmnr")
        loadNewBannerAds()
    }
    
}
