//
//  DTAdsKeyManager.swift
//  DTAdsMediation
//
//  Created by Pham Diep on 7/3/20.
//  Copyright © 2020 PPCLink. All rights reserved.
//

import Foundation

class DTAdsConfigManager {
    var isTestMode = false
    static var shared = DTAdsConfigManager()
    private var arrBanner: [DTAdType]!
    private var currentBannerIndex = 0
    private var arrInters: [DTAdType]!
    private var currentIntersIndex = 0
    private var arrNative: [DTAdType]!
    private var currentNativeIndex = 0
    init() {
        let json = JSON.init(parseJSON:  UserDefaults.standard.string(forKey: "savedConfigAdsKeyManager") ?? "")
        setupAdKey(jsonConfig: json)
    }
    func reloadAdKey(strConfig: String) -> Bool {
        let oldJsonConfig = JSON.init(parseJSON: UserDefaults.standard.string(forKey: "savedConfigAdsKeyManager") ?? "")
        let newJsonConfig = JSON.init(parseJSON: strConfig)
        if let newVersion = newJsonConfig["version"].int, newVersion != oldJsonConfig["version"].intValue {
            UserDefaults.standard.set(strConfig, forKey: "savedConfigAdsKeyManager")
            setupAdKey(jsonConfig: newJsonConfig)
            return true
        } else {
            return false
        }
        
    }
    private func setupAdKey(jsonConfig: JSON) {
        /*
         [
         "banner": ["fbBanner": keyfbBanner,
         "admobBanner": keyAdmobBanner],
         "inters": ["fbInters": keyFbInter],
         "native": ["fbNative": keyFbNative,
         "admobNative": keyAdmobNative],
         "version": 1,
         "minRangeShowInters": 300
         ]
         */
        // Tạo arr Banner
        arrBanner = [DTAdType]()
        if let banners = jsonConfig["banner"].dictionaryObject {
            for bannerName in Array(banners.keys.map({String($0)})) {
                if let keyValue = banners[bannerName] as? String {
                    UserDefaults.standard.set(keyValue, forKey: bannerName)
                }
                if let bannerType = DTAdType.init(rawValue: bannerName) {
                    arrBanner.append(bannerType)
                }
            }
        }
//        if arrBanner.count == 0 {
//            arrBanner = [.mopubBanner]
//        }
        
        // Tạo arr Inters
        arrInters = [DTAdType]()
        if let inters = jsonConfig["inters"].dictionaryObject {
            for intersName in Array(inters.keys.map({String($0)})) {
                if let keyValue = inters[intersName] as? String {
                    UserDefaults.standard.set(keyValue, forKey: intersName)
                }
                if let intersType = DTAdType.init(rawValue: intersName) {
                    arrInters.append(intersType)
                }
            }
        }
//        if arrInters.count == 0 {
//            arrInters = [.mopubInters]
//        }
        // Tạo arr native
        arrNative = [DTAdType]()
        if let natives = jsonConfig["native"].dictionaryObject {
            for nativeName in Array(natives.keys.map({String($0)})) {
                if let keyValue = natives[nativeName] as? String {
                    UserDefaults.standard.set(keyValue, forKey: nativeName)
                }
                if let nativeType = DTAdType.init(rawValue: nativeName) {
                    arrNative.append(nativeType)
                }
            }
        }
//        if arrNative.count == 0 {
//            arrNative = [.mopubNative, .fbNative, .admobNative]
//        }
        currentBannerIndex = 0
        currentNativeIndex = 0
        currentIntersIndex = 0
    }
    
    func getNextBannerType() -> DTAdType? {
        var bannerType: DTAdType? = nil
        if arrBanner.count > currentBannerIndex {
            bannerType = arrBanner[currentBannerIndex]
            currentBannerIndex += 1
        } else {
            currentBannerIndex = 0
        }
        return bannerType
    }
    func getNextNativeType() -> DTAdType? {
        var nativeType: DTAdType? = nil
        if arrNative.count > currentNativeIndex {
            nativeType = arrNative[currentNativeIndex]
            currentNativeIndex += 1
        } else {
            currentNativeIndex = 0
        }
        return nativeType
    }
    func getNextIntersType() -> DTAdType? {
        var intersType: DTAdType? = nil
        if arrInters.count > currentIntersIndex {
            intersType = arrInters[currentIntersIndex]
            currentIntersIndex += 1
        } else {
            currentIntersIndex = 0
        }
        return intersType
    }
    func getMinRangeShowInters() -> Double {
        if isTestMode {
                   return 1
               }
        let json = JSON.init(parseJSON:  UserDefaults.standard.string(forKey: "savedConfigAdsKeyManager") ?? "")
        let minRange = json["minRangeShowInters"].doubleValue
        if minRange > 0 {
            return minRange
        }
        return 5*60
    }
   private func getMaxClickIntersPerDay() -> Int {
        let json = JSON.init(parseJSON:  UserDefaults.standard.string(forKey: "savedConfigAdsKeyManager") ?? "")
               let maxShow = json["maxShowIntersPerDay"].intValue
               if maxShow > 0 {
                   return maxShow
               }
               return 5
    }
    func userDidClickIntersAds() {
           var timeClickInters = UserDefaults.standard.array(forKey: "arrTimeClickInters") as? [Double] ?? [Double]()
           timeClickInters.append(Date.init().timeIntervalSince1970)
           UserDefaults.standard.set(timeClickInters, forKey: "arrTimeClickInters")
       }
    func didIntersGetLimited() -> Bool {
         var timeClickInters = UserDefaults.standard.array(forKey: "arrTimeClickInters") as? [Double] ?? [Double]()
        let currentTime = Date.init().timeIntervalSince1970
        timeClickInters = timeClickInters.filter { (timeClick) -> Bool in
            // Loại bỏ những click đã quá 24 giờ
            return currentTime - timeClick < 86400
        }
        UserDefaults.standard.set(timeClickInters, forKey: "arrTimeClickInters")
        if isTestMode {
            return false
        }
        return timeClickInters.count >= getMaxClickIntersPerDay()
    }
    
    private func getMaxClickNativePerDay() -> Int {
        let json = JSON.init(parseJSON:  UserDefaults.standard.string(forKey: "savedConfigAdsKeyManager") ?? "")
                      let maxShow = json["maxShowNativePerDay"].intValue
                      if maxShow > 0 {
                          return maxShow
                      }
                      return 10
    }
    func userDidClickNativeAds() {
           var timeClicks = UserDefaults.standard.array(forKey: "arrTimeClickNative") as? [Double] ?? [Double]()
           timeClicks.append(Date.init().timeIntervalSince1970)
           UserDefaults.standard.set(timeClicks, forKey: "arrTimeClickNative")
       }
    func didNativeGetLimited() -> Bool {
            var timeClicks = UserDefaults.standard.array(forKey: "arrTimeClickNative") as? [Double] ?? [Double]()
           let currentTime = Date.init().timeIntervalSince1970
           timeClicks = timeClicks.filter { (timeClick) -> Bool in
               // Loại bỏ những click đã quá 24 giờ
               return currentTime - timeClick < 86400
           }
        UserDefaults.standard.set(timeClicks, forKey: "arrTimeClickNative")
        if isTestMode {
                   return false
               }
           return timeClicks.count >= getMaxClickNativePerDay()
       }
    private func getMaxClickBannerPerDay() -> Int {
           let json = JSON.init(parseJSON:  UserDefaults.standard.string(forKey: "savedConfigAdsKeyManager") ?? "")
                         let maxShow = json["maxShowBannerPerDay"].intValue
                         if maxShow > 0 {
                             return maxShow
                         }
                         return 5
       }
    func userDidClickBannerAds() {
              var timeClicks = UserDefaults.standard.array(forKey: "arrTimeClickBanner") as? [Double] ?? [Double]()
              timeClicks.append(Date.init().timeIntervalSince1970)
              UserDefaults.standard.set(timeClicks, forKey: "arrTimeClickBanner")
          }
    func didBannerGetLimited() -> Bool {
               var timeClicks = UserDefaults.standard.array(forKey: "arrTimeClickBanner") as? [Double] ?? [Double]()
              let currentTime = Date.init().timeIntervalSince1970
              timeClicks = timeClicks.filter { (timeClick) -> Bool in
                  // Loại bỏ những click đã quá 24 giờ
                  return currentTime - timeClick < 86400
              }
           UserDefaults.standard.set(timeClicks, forKey: "arrTimeClickBanner")
        if isTestMode {
                   return false
               }
              return timeClicks.count >= getMaxClickBannerPerDay()
          }
    
}

enum DTAdType: String {
    case fbBanner = "fbBanner"
    case admobBanner = "admobBanner"
    case mopubBanner = "mopubBanner"
    case appLovinMrect = "appLovinMrect"
    case fbInters = "fbInters"
    case admobInters = "admobInters"
    case mopubInters = "mopubInters"
    case appLovinInters = "appLovinInters"
    case fbNative = "fbNative"
    case admobNative = "admobNative"
    case mopubNative = "mopubNative"
    case notDefine = "notDefine"
    func getKey() -> String {
        switch self {
        case .fbBanner:
            return UserDefaults.standard.string(forKey: DTAdType.fbBanner.rawValue) ?? "755638821870358_755644428536464"
        case .admobBanner:
            return UserDefaults.standard.string(forKey: DTAdType.admobBanner.rawValue) ?? "ca-app-pub-2372176163018331/3558016843"
        case .mopubBanner:
            return /*"2aae44d2ab91424d9850870af33e5af7"// */ UserDefaults.standard.string(forKey: DTAdType.mopubBanner.rawValue) ?? "ee4af3c6fdb44f13939075d98c2ac3ae"
        case .appLovinMrect:
            return ""
        case .fbInters:
            return UserDefaults.standard.string(forKey: DTAdType.fbInters.rawValue) ?? "755638821870358_755644201869820"
        case .admobInters:
            return UserDefaults.standard.string(forKey: DTAdType.admobInters.rawValue) ?? "ca-app-pub-2372176163018331/7497261857"
        case .mopubInters:
            return /*"4f117153f5c24fa6a3a92b818a5eb630" */ UserDefaults.standard.string(forKey: DTAdType.mopubInters.rawValue) ?? "28adc5afae1848c49f8bfcdb8c918371"
        case .appLovinInters:
            return ""
        case .fbNative:
            return UserDefaults.standard.string(forKey: DTAdType.fbNative.rawValue) ?? "755638821870358_755643618536545"
        case .admobNative:
            return UserDefaults.standard.string(forKey: DTAdType.admobNative.rawValue) ?? "ca-app-pub-9435646037884749/9717495464"
        case .mopubNative:
            return UserDefaults.standard.string(forKey: DTAdType.mopubNative.rawValue) ?? "06051b4176504a30a3f07e3671afd67f"
        case .notDefine:
            return ""
        }
    }
}
