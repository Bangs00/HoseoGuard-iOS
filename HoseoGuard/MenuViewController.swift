//
//  MenuViewController.swift
//  HoseoGuard
//
//  Created by 방현수 on 2020/11/19.
//

import UIKit

class MenuViewController: UIViewController {
    @IBOutlet weak var hoseoGuardLabel: UILabel!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var sendImageButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    //MARK: -viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setLayout()
    }
    //MARK: -그라데이션
    let gradientLayer : CAGradientLayer = {
        let layer = CAGradientLayer()
        let color1 = UIColor(rgb: 0xFFC371)
        let color2 = UIColor(rgb: 0xFF5F6D)
        layer.colors = [color1.cgColor, color2.cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        layer.cornerRadius = 25
        return layer
    }()
    //MARK: -viewDidLayoutSubviews
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.menuView.layer.insertSublayer(self.gradientLayer, at: 0)
        self.gradientLayer.frame = menuView.bounds
    }
    //MARK: -setLayout
    func setLayout() {
        hoseoGuardLabel.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        hoseoGuardLabel.layer.cornerRadius = 25

        menuView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        menuView.layer.cornerRadius = 25
        
        menuView.layer.shadowColor = UIColor.black.cgColor
        menuView.layer.shadowOffset = .zero
        menuView.layer.shadowRadius = 5
        menuView.layer.shadowOpacity = 0.5
        
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    //MARK: -touchInvisibleButton
    @IBAction func touchInvisibleButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    //MARK: -touchLogoutButton
    @IBAction func touchLogoutButton(_ sender: Any) {
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
