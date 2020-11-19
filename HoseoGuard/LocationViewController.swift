//
//  LocationViewController.swift
//  HoseoGuard
//
//  Created by 방현수 on 2020/11/18.
//

import UIKit

class LocationViewController: UIViewController {
    //MARK: -vars
    @IBOutlet weak var okayButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var layoutView: UIView!
//    let serverURL = "http://192.168.0.40:3001"
    let serverURL = "http://210.119.104.160:3001"
    var urlData = ""
    var mapLists : NSArray! = []
    var map = -1
    //MARK: -그라데이션
    let gradientLayer : CAGradientLayer = {
        let layer = CAGradientLayer()
        let color1 = UIColor(rgb: 0xFFC371)
        let color2 = UIColor(rgb: 0xFF5F6D)
        layer.colors = [color1.cgColor, color2.cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        layer.cornerRadius = 25
        return layer
    }()
    //MARK: -viewDidLayoutSubviews
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.layoutView.layer.insertSublayer(self.gradientLayer, at: 0)
        self.gradientLayer.frame = layoutView.bounds
    }
    //MARK: -viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setLayout()
        pickerView.dataSource = self
        pickerView.delegate = self
    }
    //MARK: -setLayout
    func setLayout() {
        layoutView.layer.cornerRadius = 25
        
        layoutView.layer.shadowColor = UIColor.black.cgColor
        layoutView.layer.shadowOffset = .zero
        layoutView.layer.shadowRadius = 3
        layoutView.layer.shadowOpacity = 0.5
    }
    //MARK: -viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        getMapList()
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    //MARK: -touchOkayButton
    @IBAction func touchOkayButton(_ sender: Any) {
        let HomeVC = self.presentingViewController as? HomeViewController
        
        if (self.map == -1) {
            HomeVC?.map = -1
            HomeVC?.mapImageView.image = #imageLiteral(resourceName: "LaunchScreenImage")
            HomeVC?.equipLists = []
            for equip in HomeVC!.equipAllLists {
                let equipT = equip as? NSDictionary
                HomeVC?.equipLists.append(equipT!)
            }
        }
        else if (self.map < 3) {
            DispatchQueue.main.async { LoadingHUD.show() }
            guard let mapList = mapLists[self.map] as? NSDictionary else { return }
            let filename = mapList["name"] as! String
            
            self.urlData = serverURL + "/download/map?filename=" + filename
            self.downloadImage(from: URL(string: self.urlData)!)
            
            HomeVC?.equipLists = []
            for equip in HomeVC!.equipAllLists {
                let equipT = equip as? NSDictionary
                if (equipT?["map"] as? Int) == HomeVC?.map {
                    HomeVC?.equipLists.append(equipT!)
                }
            }
        }
        else {
            HomeVC?.map = -1
            HomeVC?.mapImageView.image = #imageLiteral(resourceName: "LaunchScreenImage")
            HomeVC?.equipLists = []
            for equip in HomeVC!.equipAllLists {
                let equipT = equip as? NSDictionary
                HomeVC?.equipLists.append(equipT!)
            }
        }
        
        HomeVC?.equipmentTableView.reloadData()
        self.dismiss(animated: true, completion: nil)
    }
    //MARK: -getMapList
    func getMapList() {
        DispatchQueue.main.async { LoadingHUD.show() }
        
        let urlConfig = URLSessionConfiguration.default
        let urlComponents = URLComponents(string: serverURL + "/map/list")
        
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
                //MARK: -Station Data
                let object = try JSONSerialization.jsonObject(with: data!, options: []) as? NSArray
                guard let jsonObject = object else {
                    DispatchQueue.main.async { LoadingHUD.hide() }
                    return }
                
                print(jsonObject)
                self.mapLists = jsonObject
                
                DispatchQueue.main.async {
                    self.pickerView.reloadAllComponents()
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
    //MARK: -downloadImage
    func downloadImage(from url: URL) {
        let HomeVC = self.presentingViewController as? HomeViewController
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                HomeVC?.mapImageView.image = UIImage(data: data)
                
                let image = HomeVC?.mapImageView.image
                UIGraphicsBeginImageContextWithOptions(image!.size, true, 0)
                image!.draw(at: CGPoint(x: 0,y: 0))
                let context = UIGraphicsGetCurrentContext()!
                context.setLineWidth(5.0)
                context.setStrokeColor(UIColor.red.cgColor)
                
                for equip in HomeVC!.equipAllLists {
                    let equipT = equip as? NSDictionary
                    if (equipT?["map"] as? Int) == self.map {
                        let lx = ((equipT?["location"] as? NSDictionary)!["x"] as? Int)!
                        let ly = ((equipT?["location"] as? NSDictionary)!["y"] as? Int)!
                        print(lx)
                        print(ly)
                        context.addEllipse(in: CGRect(x: CGFloat(lx) / 400 * ((HomeVC!.mapImageView.image?.size.width)!), y: CGFloat(ly) / 200 * ((HomeVC!.mapImageView.image?.size.height)!), width: 5, height: 5))
                    }
                }
                
                context.strokePath()
                let endImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                DispatchQueue.main.async {
                    HomeVC?.mapImageView.image = endImage
                }
            }
        }
        DispatchQueue.main.async { LoadingHUD.hide() }
    }
    //MARK: -getData
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
}

extension LocationViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (self.mapLists.count == 0){
            return 1
        }
        return self.mapLists.count + 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 {
            return "전체"
        }
        else if row > 0 {
            guard let mapList = mapLists[row - 1] as? NSDictionary else {
                return "전체"
            }
            return mapList["name"] as? String
        }
        else {
            return "전체"
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let HomeVC = self.presentingViewController as? HomeViewController
        if row == 0 {
            HomeVC?.map = -1
            self.map = -1
        }
        else if row > 0 {
            guard let mapList = mapLists[row - 1] as? NSDictionary else {
                HomeVC?.map = -1
                self.map = -1
                return
            }
            if HomeVC!.map < mapLists.count {
                self.map = (mapList["id"] as? Int)!
                HomeVC?.map = (mapList["id"] as? Int)!
            }
        }
    }
}
