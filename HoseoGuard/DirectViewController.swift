//
//  DirectViewController.swift
//  HoseoGuard
//
//  Created by 방현수 on 2020/11/17.
//

import UIKit

class DirectViewController: UIViewController {
    //MARK: -vars
    @IBOutlet weak var layoutView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var serialTextField: UITextField!
    @IBOutlet weak var cancleButton: UIButton!
    @IBOutlet weak var okayButton: UIButton!
    //    let serverURL = "http://192.168.0.40:3001"
    let serverURL = "http://210.119.104.160:3001"
    var checkLists : Array<Any> = []
    var checkList : String = ""
    var checkCount : Int! = 0
    //MARK: -viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setLayout()
    }
    //MARK: -viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        getCheckList()
    }
    //MARK: -setLayout
    func setLayout() {
        serialTextField.layer.borderWidth = 1
        serialTextField.layer.borderColor = UIColor.black.cgColor
        
        layoutView.layer.cornerRadius = 25.0
        
        layoutView.layer.shadowColor = UIColor.black.cgColor
        layoutView.layer.shadowOffset = .zero
        layoutView.layer.shadowRadius = 5
        layoutView.layer.shadowOpacity = 0.5
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    //MARK: -showAlert
    func showAlert(userName: String, prs: Double) {
        if let check = checkLists.first {
            print(check)
            let alert = UIAlertController(title: check as? String, message: nil, preferredStyle: .alert)
            let alertIsntOkay = UIAlertAction(title: "이상있음", style: .destructive, handler: { (action: UIAlertAction) in
                self.checkLists.removeFirst()
                
                self.checkCount = self.checkCount + 1
                self.showAlert(userName: userName, prs: prs)
            })
            let alertIsOkay = UIAlertAction(title: "이상없음", style: .default, handler: { (action: UIAlertAction) in
                //보내줘야댐
                self.checkList = self.checkList + String(self.checkCount) + ","
                self.checkLists.removeFirst()
                
                self.checkCount = self.checkCount + 1
                self.showAlert(userName: userName, prs: prs)
            })
            
            alert.addAction(alertIsntOkay)
            alert.addAction(alertIsOkay)
            self.present(alert, animated: true, completion: nil)
        }
        else {
            print(checkList)
            self.checkCount = 0
            self.sendBranchCheck(eid: self.serialTextField.text!, user: userName, prs: prs, check_res: self.checkList)
        }
    }
    //MARK: -isDouble
    func isDouble(text:String) -> Bool {
        guard let _ = Double(text) else { return false }
        return true
    }
    //MARK: -touchCancleButton
    @IBAction func touchCancleButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    //MARK: -touchOkayButton
    @IBAction func touchOkayButton(_ sender: Any) {
        self.checkCount = 0
        var prs = 0.0
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "소화기 압력를 입력해주세요.", message: "단위 : X(1/10)MPa", preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .destructive, handler: { (action: UIAlertAction) in
                if (self.isDouble(text: (alert.textFields?[0].text)!)) {
                    self.checkCount = 0
                    prs = Double((alert.textFields?[0].text)!)!
                    let userName = UserDefaults.standard.value(forKey: "id") as! String
                    self.showAlert(userName: userName, prs: prs)
                }
                else {
                    self.present(alert, animated: true, completion: nil)
                }
            })
            let alertAction2 = UIAlertAction(title: "Cancle", style: .default, handler: { (action: UIAlertAction) in
                alert.dismiss(animated: true, completion: nil)
            })
            alert.addTextField()
            alert.addAction(alertAction2)
            alert.addAction(alertAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    //MARK: - sendBranchCheck
    func sendBranchCheck(eid: String, user: String, prs: Double, check_res: String) {
        let param = ["serial" : eid, "user" : user, "prs" : prs, "check_res" : check_res] as [String : Any]
        let paramData = try! JSONSerialization.data(withJSONObject: param, options: [])
        
        let url = URL(string: serverURL + "/equip/check/insert")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.httpBody = paramData
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "서버와 통신이 원활하지 않습니다.", message: "Wi-Fi를 끄거나 기기의 인터넷 연결 상태를 확인해 주세요.", preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "OK", style: .destructive, handler: { (action: UIAlertAction) in
                        alert.dismiss(animated: true, completion: nil)
                    })
                    alert.addAction(alertAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                return }
            let failureScope = 400 ..< 500
            let successScope = 200 ..< 300
            
            if (failureScope.contains(statusCode)) {
                if (statusCode == 400) {
                    DispatchQueue.main.async {
                        
                        let alert = UIAlertController(title: "서버와 통신이 원활하지 않습니다.", message: "기기의 인터넷 상태를 확인해주세요.", preferredStyle: .alert)
                        let alertAction = UIAlertAction(title: "OK", style: .destructive, handler: { (action: UIAlertAction) in
                            alert.dismiss(animated: true, completion: nil)
                        })
                        alert.addAction(alertAction)
                        self.present(alert, animated: true, completion: nil)
                        
                        return
                    }
                }
                else {
                    let title = String(statusCode)
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
                        self.present(alert, animated: true, completion: nil)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { alert.dismiss(animated: true, completion: nil)}
                        )
                        return
                    }
                }
            }
            
            guard successScope.contains(statusCode) else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Error : 0x001", message: "오류 발생\n카카오플러스친구에 문의 부탁드립니다.", preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "OK", style: .destructive, handler: { (action: UIAlertAction) in
                        alert.dismiss(animated: true, completion: nil)
                    })
                    alert.addAction(alertAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            DispatchQueue.main.async {
                do {
                    let object = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary
                    guard let jsonObject = object else { return }
                    
                    print(jsonObject)
                    self.presentingViewController?.presentingViewController?.dismiss(animated: false, completion: nil)
                }
                catch {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Error", message: "Json Pasing Fail\n", preferredStyle: .alert)
                        let alertAction = UIAlertAction(title: "OK", style: .destructive, handler: { (action: UIAlertAction) in
                            alert.dismiss(animated: true, completion: nil)
                        })
                        alert.addAction(alertAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
        task.resume()
    }
    //MARK: -getCheckList
    func getCheckList() {
        DispatchQueue.main.async { LoadingHUD.show() }
        
        let urlConfig = URLSessionConfiguration.default
        let urlComponents = URLComponents(string: serverURL + "/equip/checklist")
        
        let url = urlComponents?.url
        
        let task = URLSession(configuration: urlConfig).dataTask(with: url!) { (data, response, error) in
            guard error == nil else {
                DispatchQueue.main.async { LoadingHUD.hide() }
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "서버와 통신이 원활하지 않습니다.", message: "Wi-Fi를 끄거나 기기의 인터넷 연결 상태를 확인해 주세요.", preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "OK", style: .destructive, handler: nil)
                    alert.addAction(alertAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                DispatchQueue.main.async { LoadingHUD.hide() }
                return }
            let successScope = 200 ..< 300
            
            guard successScope.contains(statusCode) else {
                DispatchQueue.main.async { LoadingHUD.hide() }
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Error : " + String(statusCode), message: nil, preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "OK", style: .destructive, handler: nil)
                    alert.addAction(alertAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            do {
                let object = try JSONSerialization.jsonObject(with: data!, options: []) as? NSArray
                guard let jsonObject = object else {
                    DispatchQueue.main.async { LoadingHUD.hide() }
                    return }
                
                for i in 0..<jsonObject.count {
                    let message = jsonObject[i] as? NSDictionary
                    self.checkLists.append(message!["message"]!)
                }
                
                print(self.checkLists)
                
                DispatchQueue.main.async { LoadingHUD.hide() }
            }
            catch {
                DispatchQueue.main.async { LoadingHUD.hide() }
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "!!!Error!!!", message: "JSON Parsing Fail", preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "OK", style: .destructive, handler: nil)
                    alert.addAction(alertAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        task.resume()
    }
}
