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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setLayout()
    }
    //MALK: -setLayout
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
    @IBAction func touchInvisibleButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func touchLogoutButton(_ sender: Any) {
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
