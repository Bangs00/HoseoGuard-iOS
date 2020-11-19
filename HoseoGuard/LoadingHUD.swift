//
//  LoadingHUD.swift
//  HoseoGuard
//
//  Created by 방현수 on 2020/11/18.
//

import Foundation
import UIKit

class LoadingHUD {
    private static let sharedInstance = LoadingHUD()
    
    private var backgroundView: UIVisualEffectView?
    private var loadingLabel: UILabel?
    
    class func show() {
        let blurEffect = UIBlurEffect(style: .light)
        
        let backgroundView = UIVisualEffectView(effect: blurEffect)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let loadingLabel = UILabel(frame: CGRect.init(x: 0, y: 0, width: 100, height: 100))
        loadingLabel.text = "Loading ..."
        loadingLabel.font = UIFont.boldSystemFont(ofSize: 20)
        loadingLabel.textColor = .black
        
        if let window = UIApplication.shared.keyWindow {
            UIView.transition(with: window, duration: 0.2, options: .transitionCrossDissolve, animations: {
                window.addSubview(backgroundView)
                window.addSubview(loadingLabel)
            }, completion: nil)
            window.addSubview(backgroundView)
            window.addSubview(loadingLabel)
            
            backgroundView.frame = CGRect(x: 0, y: 0, width: window.frame.maxX, height: window.frame.maxY)
            backgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
            
            loadingLabel.layer.position = CGPoint(x: window.frame.midX, y: window.frame.midY)
            
            sharedInstance.backgroundView?.removeFromSuperview()
            sharedInstance.loadingLabel?.removeFromSuperview()
            sharedInstance.backgroundView = backgroundView
            sharedInstance.loadingLabel = loadingLabel
        }
    }
    
    class func hide() {
        if let loadingLabel = sharedInstance.loadingLabel,
            let backgroundView = sharedInstance.backgroundView {
            UIView.transition(with: UIApplication.shared.keyWindow!, duration: 0.2, options: .transitionCrossDissolve, animations: {
                backgroundView.removeFromSuperview()
                loadingLabel.removeFromSuperview()
            }, completion: nil)
        }
    }
}
