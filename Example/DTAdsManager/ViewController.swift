//
//  ViewController.swift
//  DTAdsManager
//
//  Created by adx-developer on 07/05/2020.
//  Copyright (c) 2020 adx-developer. All rights reserved.
//

import UIKit
import DTAdsManager

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configAds()
    }
    func configAds() {
        DTAdsManager.shared.bannerView.backgroundColor = UIColor.red
        if let app = UIApplication.shared.delegate as? AppDelegate, let window = app.window {
           DTAdsManager.shared.addBannerToView(parentView: window, top: nil, bottom: 10, right: 10, left: 10, bannerHeight: 50)
        } else {
            DTAdsManager.shared.addBannerToView(parentView: self.view, top: nil, bottom: 10, right: 0, left: 0, bannerHeight: 50)
        }
        DTAdsManager.shared.loadBannerAds(rootVC: self)
        
       
    }
    @IBAction func onShowBanner(_ sender: Any) {
        
        DTAdsManager.shared.changeBannerConstraintConstant(top: nil, bottom: CGFloat.random(in: 10...200), right: nil, left: nil, bannerHeight: nil, foceShow: true)
    }
    @IBAction func onShowInterstitial(_ sender: Any) {
        DTAdsManager.shared.showInterstitial(rootVC: self)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

