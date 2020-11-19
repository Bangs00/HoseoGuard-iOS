//
//  LoginViewController.swift
//  HoseoGuard
//
//  Created by 방현수 on 2020/10/29.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    //MARK: -vars
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var pwTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
//    let serverURL = "http://192.168.0.40:3001"
    let serverURL = "http://210.119.104.160:3001"
    //MARK: -viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setLayout()
    }
    //MARK: -setLayout
    func setLayout() {
        //키보드 관련 설정(키보드 타입, 자동 완성, 비밀먼호 안보이게)
        idTextField.keyboardType = .namePhonePad
        pwTextField.keyboardType = .default
        idTextField.autocorrectionType = .no
        pwTextField.autocorrectionType = .no
        pwTextField.isSecureTextEntry = true
        
        idTextField.layer.borderColor = UIColor.black.cgColor
        pwTextField.layer.borderColor = UIColor.black.cgColor
        idTextField.layer.borderWidth = 1
        pwTextField.layer.borderWidth = 1
        
        loginButton.layer.cornerRadius = loginButton.frame.height / 2
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    //MARK: -doLogin
    func doLogin() {
        DispatchQueue.main.async{ LoadingHUD.show() }
        let sid = (self.idTextField.text)!
        let pwd = (self.pwTextField.text)!
        let param = ["user" : sid, "passwd" : pwd]
        let paramData = try! JSONSerialization.data(withJSONObject: param, options: [])
        
        let url = URL(string: serverURL + "/login")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.httpBody = paramData
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                DispatchQueue.main.async{ LoadingHUD.hide() }
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "서버와 통신이 원활하지 않습니다.", message: "Wi-Fi를 끄거나 기기의 인터넷 연결 상태를 확인해 주세요.", preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "OK", style: .destructive, handler: nil)
                    alert.addAction(alertAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                DispatchQueue.main.async{ LoadingHUD.hide() }
                return }
            let failureScope = 400 ..< 500
            let successScope = 200 ..< 300
            
            if (failureScope.contains(statusCode)) {
                if (statusCode == 400) {
                    DispatchQueue.main.async{ LoadingHUD.hide() }
                    DispatchQueue.main.async {
                        
                        let alert = UIAlertController(title: "서버와 통신이 원활하지 않습니다.", message: "기기의 인터넷 상태를 확인해주세요. 증상이 계속되면 카카오플러스친구에 문의 부탁드립니다.", preferredStyle: .alert)
                        let alertAction = UIAlertAction(title: "OK", style: .destructive, handler: nil)
                        alert.addAction(alertAction)
                        self.present(alert, animated: true, completion: nil)
                        
                        return
                    }
                }
                else if (statusCode == 401) {
                    DispatchQueue.main.async{ LoadingHUD.hide() }
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "아이디 혹은 비밀번호가 틀렸습니다.", message: nil, preferredStyle: .alert)
                        self.present(alert, animated: true, completion: nil)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { alert.dismiss(animated: true, completion: nil)}
                        )
                        return
                    }
                }
            }
            
            guard successScope.contains(statusCode) else {
                DispatchQueue.main.async{ LoadingHUD.hide() }
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "!!!Error!!!" + String(statusCode), message: nil, preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "OK", style: .destructive, handler: nil)
                    alert.addAction(alertAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            DispatchQueue.main.async {
                do {
                    let object = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary
                    guard let jsonObject = object else { return }
                    print(statusCode)
                    print(jsonObject)
                    
                    UserDefaults.standard.setValue(self.idTextField.text, forKey: "id")
                    
                    DispatchQueue.main.async{ LoadingHUD.hide() }
                    
                    let HomeVC = self.storyboard?.instantiateViewController(withIdentifier: "HomeVC")
                    HomeVC?.modalTransitionStyle = .crossDissolve
                    HomeVC?.modalPresentationStyle = .fullScreen
                    self.present(HomeVC!, animated: true, completion: nil)
                }
                catch {
                    DispatchQueue.main.async{ LoadingHUD.hide() }
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Error:Parsing Fail", message: nil, preferredStyle: .alert)
                        let alertAction = UIAlertAction(title: "OK", style: .destructive, handler: nil)
                        alert.addAction(alertAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
        task.resume()
    }
    //MARK: -외부 터치시 키보드 숨김 함수
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    //MARK: -segue작동시
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        //segue identifier == LoginToHome일 경우
        if (identifier == "LoginToHome") {
            //아이디와 비밀번호가 비어있을 경우
            if (idTextField.text == "" && pwTextField.text == "") {
                let alert = UIAlertController(title: "아이디와 비밀번호를 입력해주세요.", message: nil, preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {alert.dismiss(animated: true, completion: nil)})
                return false
            }
                //비밀번호 비어있을 경우
            else if (pwTextField.text == "") {
                let alert = UIAlertController(title: "비밀번호를 입력해주세요.", message: nil, preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {alert.dismiss(animated: true, completion: nil)})
                return false
            }
                //학번 비어있을 경우
            else if (idTextField.text == ""){
                let alert = UIAlertController(title: "아이디를 입력해주세요.", message: nil, preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {alert.dismiss(animated: true, completion: nil)})
                return false
            }
            else {
                doLogin()
                return false
            }
        }
        //segue identifier != LoginToHome일 경우
        return true
    }
}
