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
import MoPub
import AppLovinSDK

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
    private var mopubBanner: MPAdView?
    private var needShowBannerAfterDismisInters: Bool = false
    private var fbInterstitialAd: FBInterstitialAd?
    private var admobInterstitialAd: GADInterstitial?
    private var mopubInterstitialAd: MPInterstitialAdController?
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
        let mopubConfig = MPMoPubConfiguration.init(adUnitIdForAppInitialization: DTAdType.mopubInters.getKey())
        mopubConfig.loggingLevel = MPBLogLevel.info
        ALSdk.initializeSdk {(_) in
            if DTAdsConfigManager.shared.isTestMode == true {
                    //  ALSdk.shared()?.settings.testDeviceAdvertisingIdentifiers = ["1B385BDD-10F0-4156-B092-B82F0E94DCD6"]
                   }
        }
        MoPub.sharedInstance().initializeSdk(with: mopubConfig) {
            
        }
       
        if !isProversion {
            reloadAllAds()
        }
    }
    
    public func setProversion(isPro: Bool, config: String) {
        let configChanged = DTAdsConfigManager.shared.reloadAdKey(strConfig: config)
        if isPro == false && isProversion == true || configChanged {
           reloadAllAds()
        }
        isProversion = isPro
    }
    /// Chỉ gọi 1 lần
    public func loadBannerAds(rootVC: UIViewController) {
        self.bannerRootVC = rootVC
        fbBanner = nil
        admobBanner = nil
        mopubBanner = nil
        isLoadingBanner = false
        loadNewBannerAds()
    }
  

    private func reloadAllAds() { // Chỉ reload khi config thay đổi
        fbBanner = nil
        admobBanner = nil
        mopubBanner = nil
        fbInterstitialAd = nil
        admobInterstitialAd = nil
        mopubInterstitialAd = nil
        isLoadingBanner = false
        loadNewBannerAds()
        isLoadingInters = false
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
    public func avaiableToShowBanner() -> Bool {
       if DTAdsConfigManager.shared.didBannerGetLimited() || isProversion {
                            return false
                        }
             if self.bannerView.subviews.count > 0 {
                 return true
             } else {
                 // Load lỗi tất cả banner.
                 // Check xem lần cuối load lỗi tất cả nếu lớn hơn 1 phút thì cho reload lại (tránh trường hợp user tắt mạng lúc vào app để trick)
                 let lastTimeLoadBanner = UserDefaults.standard.double(forKey: "lastLoadBannerToReload")
                 if Date.init().timeIntervalSince1970 - lastTimeLoadBanner > DTAdsConfigManager.shared.getMinRangeShowInters() {
                     loadNewBannerAds()
                 }
             }
             return false
    }
    public func hideBannerAd() {
        self.bannerView.isHidden = true
    }
    func unHideBanner() {
        self.bannerView.isHidden = false
    }
    
    private var isLoadingBanner = false
    private func loadNewBannerAds() {
        guard let rootBannerVC = self.bannerRootVC else {
            return
        }
        if DTAdsConfigManager.shared.didBannerGetLimited() {
           // loadBannerAds(rootVC: rootBannerVC)
            self.heightConstraint?.constant = 0
            self.hideBannerAd()
            return
        }
        if isLoadingBanner {
            return
        }
     
        if let bannerType = DTAdsConfigManager.shared.getNextBannerType() {
            isLoadingBanner = true
            switch bannerType {
            case .admobBanner:
                if admobBanner == nil {
                    if self.heightConstraint?.constant == 250 {
                         admobBanner = GADBannerView.init(adSize: kGADAdSizeMediumRectangle)
                    } else {
                         admobBanner = GADBannerView.init(adSize: kGADAdSizeSmartBannerPortrait)
                    }
                   
                    admobBanner?.adUnitID = DTAdType.admobBanner.getKey()
                    admobBanner?.rootViewController = rootBannerVC
                    admobBanner?.delegate = self
                 //   admobBanner?.isAutoloadEnabled = false
                }
                admobBanner?.load(GADRequest.init())
            case .fbBanner:
                isLoadingBanner = false
                loadNewBannerAds()
                
//                if fbBanner == nil {
//                    fbBanner = FBAdView.init(placementID: DTAdType.fbBanner.getKey(), adSize: isIpad ? kFBAdSizeHeight90Banner : kFBAdSizeHeight50Banner, rootViewController: rootBannerVC)
//                    fbBanner?.delegate = self
//                }
//                fbBanner?.loadAd()
            case .mopubBanner:
                if MoPub.sharedInstance().isSdkInitialized {
                if mopubBanner == nil {
                    mopubBanner = MPAdView.init(adUnitId: DTAdType.mopubBanner.getKey())
                    mopubBanner?.delegate = self
                    mopubBanner?.frame = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: self.heightConstraint?.constant ?? 250)
                    
                       
                }
                     mopubBanner?.loadAd(withMaxAdSize: CGSize.init(width: UIScreen.main.bounds.width, height: self.heightConstraint?.constant ?? 250))
                } else {
                    isLoadingBanner = false
                    loadNewBannerAds()
                }
            default:
                break
            }
        } else {// nghỉ nếu load hết một vòng toàn lỗi
              UserDefaults.standard.set(Date.init().timeIntervalSince1970, forKey: "lastLoadBannerToReload")
        }
    }
    
    //MARK: Interstitial ads
    private var isLoadingInters = false
    private func loadNewInterstitialAds() {
        // Kiểm tra lần cuối load lỗi tất cả các mạng đã quá số phút min để load tiếp chưa
        if Date.init().timeIntervalSince1970 - UserDefaults.standard.double(forKey: "DTLastTimeLoadFailedAllInters") < DTAdsConfigManager.shared.getMinRangeShowInters() || DTAdsConfigManager.shared.didIntersGetLimited() || isLoadingInters {
            return
        }
        // Gần đến lần show tiếp theo mới load, để tăng fill rate. Trong khi load thì cho biến isLoading vào để tránh gọi load nhiều cái cùng lúc.
        let numberOfSecFromLastShow = Date().timeIntervalSince1970 - UserDefaults.standard.double(forKey: "DtLastTimeShowInterstitial")
        if numberOfSecFromLastShow + 10 < DTAdsConfigManager.shared.getMinRangeShowInters() {
            // cách lượt show < 10 giây thì cũng chưa load luôn => tăng fillrate
            return
        }
        if let intersType = DTAdsConfigManager.shared.getNextIntersType() {
            isLoadingInters = true
            switch intersType {
            case .admobInters:
               // if admobInterstitialAd == nil {
                    admobInterstitialAd = GADInterstitial.init(adUnitID: DTAdType.admobInters.getKey())
                    admobInterstitialAd?.delegate = self
              //  }
                let request = GADRequest.init()
                admobInterstitialAd?.load(request)
            case .fbInters:
              //  if fbInterstitialAd == nil {
                    fbInterstitialAd = FBInterstitialAd.init(placementID: DTAdType.fbInters.getKey())
                    fbInterstitialAd?.delegate = self
            //    }
                fbInterstitialAd?.load()
            case .mopubInters:
                if MoPub.sharedInstance().isSdkInitialized {
              //  if mopubInterstitialAd == nil {
                    mopubInterstitialAd = MPInterstitialAdController.init(forAdUnitId: DTAdType.mopubInters.getKey())
                    mopubInterstitialAd?.delegate = self
             //  }
                    mopubInterstitialAd?.loadAd()
                } else {
                    isLoadingInters = false
                    loadNewInterstitialAds()
                }
            default:
                break
            }
        } else {
        //    ALSdk.shared()?.adService.loadNextAd(ALAdSize.interstitial, andNotify: self)
            // Lỗi con mẹ nó cả 2 mạng => đợi đến lần show sau mới load. Tránh trường hợp spam load ads
            UserDefaults.standard.set(Date.init().timeIntervalSince1970, forKey: "DTLastTimeLoadFailedAllInters")
        }
    }
    public func isIntersAvaiableToShow() -> Bool {
        if fbInterstitialAd?.isAdValid == true || (admobInterstitialAd?.isReady == true && admobInterstitialAd?.hasBeenUsed == false) || mopubInterstitialAd?.ready == true {
            return true
        } else {
            return false
        }
    }
    public func showInterstitial(rootVC: UIViewController) {
        // Check xem đủ thời gian tối thiểu để show ads chưa
        let lastTimeShow = UserDefaults.standard.double(forKey: "DtLastTimeShowInterstitial")
        let numberOfSecFromLastShow = Date().timeIntervalSince1970 - lastTimeShow
        if  numberOfSecFromLastShow < DTAdsConfigManager.shared.getMinRangeShowInters() {
            if numberOfSecFromLastShow + 10 > DTAdsConfigManager.shared.getMinRangeShowInters() {
                // Cách nhỏ hơn 10 giây, nếu chưa có ad nào được load thì load thôi
                if !isIntersAvaiableToShow() {
                    loadNewInterstitialAds()
                }
            }
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
        } else if mopubInterstitialAd?.ready == true {
            needShowBannerAfterDismisInters = !self.bannerView.isHidden
            mopubInterstitialAd?.show(from: rootVC)
        } else { // Vẫn chưa thằng mặt giặc nào đc load => load lại
            loadNewInterstitialAds()
        }
    }

    
}

extension DTAdsManager: GADInterstitialDelegate {
    public func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        isLoadingInters = false
        print("Interstitial did load: admob")
    }
    public func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
            print("Iters: admob load loi cmnr: \(error.debugDescription)")
        isLoadingInters = false
        loadNewInterstitialAds()
    }
    public func interstitialDidDismissScreen(_ ad: GADInterstitial) {
            //Load lấy ad mới
            loadNewInterstitialAds()
        self.bannerView.isHidden = !needShowBannerAfterDismisInters
        }
    public func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        hideBannerAd()
        DTAdsConfigManager.shared.userDidClickIntersAds()
        }
}
extension DTAdsManager: MPInterstitialAdControllerDelegate {
    public func interstitialDidLoadAd(_ interstitial: MPInterstitialAdController!) {
        isLoadingInters = false
        print("Interstitial didload: mopub")
    }
    public func interstitialDidFail(toLoadAd interstitial: MPInterstitialAdController!, withError error: Error!) {
        print("Inters: mopub load loi cmnr \(error.debugDescription)")
        isLoadingInters = false
        loadNewInterstitialAds()
    }
    public func interstitialWillAppear(_ interstitial: MPInterstitialAdController!) {
        // Click vao ad ne
        hideBannerAd()
        DTAdsConfigManager.shared.userDidClickIntersAds()
    }
    public func interstitialWillDisappear(_ interstitial: MPInterstitialAdController!) {
        loadNewInterstitialAds()
        self.bannerView.isHidden = !needShowBannerAfterDismisInters
    }
}

extension DTAdsManager: FBInterstitialAdDelegate {
    public func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {
        isLoadingInters = false
         print("Interstitial did load: facebook")
    }
    public func interstitialAd(_ interstitialAd: FBInterstitialAd, didFailWithError error: Error) {
        print("Inters: fb load loi cmnr \(error.localizedDescription)")
        isLoadingInters = false
        loadNewInterstitialAds()
    }
    public func interstitialAdDidClose(_ interstitialAd: FBInterstitialAd) {
      //  loadNewInterstitialAds()
        self.bannerView.isHidden = !needShowBannerAfterDismisInters
    }
    public func interstitialAdDidClick(_ interstitialAd: FBInterstitialAd) {
        // Click vào ad => Ẩn banner
        hideBannerAd()
        DTAdsConfigManager.shared.userDidClickIntersAds()
    }
}

extension DTAdsManager: GADBannerViewDelegate {//}, FBAdViewDelegate { // Tạm thời bỏ facebook
    
    // admob
    public func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        // Load được rồi thì add vào bannerView
        print("admob banner load ok")
        isLoadingBanner = false
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
        print("admob banner load loi cmnr \(error.debugDescription)")
        isLoadingBanner = false
        loadNewBannerAds()
    }
    public func adViewWillPresentScreen(_ bannerView: GADBannerView) {
       hideBannerAd()
        DTAdsConfigManager.shared.userDidClickBannerAds()
    }
    public func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        unHideBanner()
        loadNewBannerAds()
    }
    public func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        DTAdsConfigManager.shared.userDidClickBannerAds()
    }
    /*
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
    public func adViewDidClick(_ adView: FBAdView) {
        hideBannerAd()
    }
    public func adViewDidFinishHandlingClick(_ adView: FBAdView) {
        unHideBanner()
        loadNewBannerAds()
    }
 */
    
}
extension DTAdsManager: MPAdViewDelegate {
    // Mopub
  public func viewControllerForPresentingModalView() -> UIViewController! {
              return bannerRootVC!
          }
       public func adViewDidLoadAd(_ view: MPAdView!, adSize: CGSize) {
        print("mopub banner load ok")
        isLoadingBanner = false
        if view.superview != nil {
              return
          }
          for subV in self.bannerView.subviews {
              subV.removeFromSuperview()
          }
        self.bannerView.addSubview(view)
        //  self.bannerView.autoresizesSubviews = true
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
       }
       public func adViewDidFail(toLoadAd view: MPAdView!) {
         print("mopub banner load loi cmnr")
        isLoadingBanner = false
            loadNewBannerAds()
       }
    public func willPresentModalView(forAd view: MPAdView!) {
        DTAdsConfigManager.shared.userDidClickBannerAds()
        hideBannerAd()
    }
    public func didDismissModalView(forAd view: MPAdView!) {
        unHideBanner()
        loadNewBannerAds()
    }
    public func willLeaveApplication(fromAd view: MPAdView!) {
        DTAdsConfigManager.shared.userDidClickBannerAds()
    }
}
