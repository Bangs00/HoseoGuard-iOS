//
//  HomeViewController.swift
//  HoseoGuard
//
//  Created by 방현수 on 2020/10/29.
//

import UIKit

class HomeViewController: UIViewController, CustomTableCellDellegate {
    // MARK: - vars
    @IBOutlet weak var QRScanButton: UIButton!
    @IBOutlet weak var MenuButton: UIButton!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var equipmentTableView: UITableView!
    @IBOutlet weak var mapImageView: UIImageView!
    @IBOutlet weak var equipInfoStackView: UIStackView!
    //    let serverURL = "http://192.168.0.40:3001"
    let serverURL = "http://210.119.104.160:3001"
    var equipLists : Array<Any> = []
    var equipAllLists : Array<Any> = []
    var map = -1
    //MARK: -그라데이션
    let gradientLayer : CAGradientLayer = {
        let layer = CAGradientLayer()
        let color1 = UIColor(rgb: 0xFFC371)
        let color2 = UIColor(rgb: 0xFF5F6D)
        layer.colors = [color1.cgColor, color2.cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        return layer
    }()
    //MARK: -viewDidLayoutSubviews
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.view.layer.insertSublayer(self.gradientLayer, at: 0)
        self.gradientLayer.frame = view.bounds
    }
    // MARK: - setLayout
    func setLayout() {
        QRScanButton.layer.cornerRadius = QRScanButton.frame.height / 2
        MenuButton.layer.cornerRadius = MenuButton.frame.width / 2
        mapButton.layer.cornerRadius = mapButton.frame.height / 2
        equipmentTableView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        equipmentTableView.layer.cornerRadius = 10
        equipInfoStackView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        equipInfoStackView.layer.cornerRadius = 10
        
        QRScanButton.layer.shadowColor = UIColor.black.cgColor
        QRScanButton.layer.shadowOffset = .zero
        QRScanButton.layer.shadowRadius = 3
        QRScanButton.layer.shadowOpacity = 0.5
        
        MenuButton.layer.shadowColor = UIColor.black.cgColor
        MenuButton.layer.shadowOffset = .zero
        MenuButton.layer.shadowRadius = 3
        MenuButton.layer.shadowOpacity = 0.5
        
        mapButton.layer.shadowColor = UIColor.black.cgColor
        mapButton.layer.shadowOffset = .zero
        mapButton.layer.shadowRadius = 3
        mapButton.layer.shadowOpacity = 0.5
    }
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setLayout()
        equipmentTableView.delegate = self
        equipmentTableView.dataSource = self
        map = -1
    }
    //MARK: -viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        getEquipList()
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    //MARK: -touchEquipmentButton
    func touchEquipmentButton(_ tag: Int) {
        DispatchQueue.main.async { LoadingHUD.show() }
        let eVC = self.storyboard?.instantiateViewController(withIdentifier: "EquipVC") as? EquipViewController
        eVC?.modalTransitionStyle = .coverVertical
        eVC?.modalPresentationStyle = .formSheet
        
        guard let equipList = equipLists[tag] as? NSDictionary else {
            return
        }
        
        eVC?.id = String((equipList["id"] as? Int)!)
        eVC?.serial = equipList["serial"] as? String
        eVC?.location = equipList["boarding_location"] as? String
        eVC?.equipList = equipList
        eVC?.map = (equipList["map"] as? Int)!
        if ((equipList["maxprs"] as? Int) == -1) {
            eVC?.check = "무"
        }
        else {
            eVC?.check = String(Double((equipList["maxprs"] as? Int)!))
        }
        DispatchQueue.main.async { LoadingHUD.hide() }
        self.present(eVC!, animated: true, completion: nil)
    }
    //MARK: -getEquipList
    func getEquipList() {
        DispatchQueue.main.async { LoadingHUD.show() }
        
        let urlConfig = URLSessionConfiguration.default
        let urlComponents = URLComponents(string: serverURL + "/equip/list")
        
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
                let object = try JSONSerialization.jsonObject(with: data!, options: []) as? Array<Any>
                guard let jsonObject = object else {
                    DispatchQueue.main.async { LoadingHUD.hide() }
                    return }
                self.equipAllLists = jsonObject
                
                self.getMaxprs()
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
    //MARK: -getMaxprs
    func getMaxprs() {
        DispatchQueue.main.async { LoadingHUD.show() }
        
        let urlConfig = URLSessionConfiguration.default
        let urlComponents = URLComponents(string: serverURL + "/equip/list_sax")
        
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
                
                let maxPrss : Array<Any> = jsonObject as! [Any]
                
                for i in 0..<self.equipAllLists.count {
                    var equipList = self.equipAllLists[i] as! Dictionary<String, Any>
                    for j in 0..<maxPrss.count {
                        let maxPrs = maxPrss[j] as? Dictionary<String, Any>
                        if (equipList["id"] as! Int == maxPrs!["equip_id"] as! Int) {
                            equipList["maxprs"] = maxPrs!["prs"] as? Int
                            self.equipAllLists[i] = equipList
                        }
                    }
                }
                
                print(self.equipAllLists)
                self.equipLists = self.equipAllLists
                
                DispatchQueue.main.async {
                    self.equipmentTableView.reloadData()
                }
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
//MARK: -Table View Setting
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    //Section Per Row Count
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (equipLists.count == 0) {
            return 0
        }
        return equipLists.count //받은 데이터 만큼
    }
    //Section Count
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    //Row in Data
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTableCell")! as? CustomTableCell else { return UITableViewCell()}
        
        guard let equipList = self.equipLists[indexPath.row] as? NSDictionary else {
            return UITableViewCell()
        }
        
        cell.cellDelegate = self
        cell.equipButton.tag = indexPath.row
        cell.idLabel.text = String((equipList["id"] as? Int)!)
        cell.serialLabel.text = equipList["serial"] as? String
        cell.locationLabel.text = equipList["boarding_location"] as? String
        if ((equipList["maxprs"] as? Int) == -1) {
            cell.checkLabel.text = "점검기록 없음"
        }
        else {
            cell.checkLabel.text = String(Double((equipList["maxprs"] as? Int)!)) + "X(1/10)MPa"
            
            let fontSize = UIFont.boldSystemFont(ofSize: 8)

            let attributedStr = NSMutableAttributedString(string: cell.checkLabel.text!)

            attributedStr.addAttribute(NSAttributedString.Key(rawValue: kCTFontAttributeName as String), value: fontSize, range: (cell.checkLabel.text! as NSString).range(of: "X(1/10)MPa"))
            
            cell.checkLabel.attributedText = attributedStr
        }
        
        return cell
    }
}
//MARK: -CustomTableCell
class CustomTableCell: UITableViewCell {
    @IBOutlet weak var equipButton: UIButton!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var serialLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var checkLabel: UILabel!
    
    var cellDelegate: CustomTableCellDellegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    //MARK: -touchEquipmentButton
    @IBAction func touchEquipmentButton(_ sender: UIButton) {
        cellDelegate?.touchEquipmentButton(sender.tag)
    }
}

protocol CustomTableCellDellegate {
    func touchEquipmentButton(_ tag: Int)
}
