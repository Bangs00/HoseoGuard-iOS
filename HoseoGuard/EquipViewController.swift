//
//  EquipViewController.swift
//  HoseoGuard
//
//  Created by 방현수 on 2020/11/17.
//

import UIKit

class EquipViewController: UIViewController {
    //MARK: -vars
    @IBOutlet weak var mapImageView: UIImageView!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var serialLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var checkLabel: UILabel!
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var screenShotButton: UIButton!
    var id: String!
    var serial: String!
    var location: String!
    var check: String!
    var equipList: NSDictionary!
    var mapLists : NSArray! = []
    var map = -1
//    let serverURL = "http://192.168.0.40:3001"
    let serverURL = "http://210.119.104.160:3001"
    var urlData = ""
    //MARK: -viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setLaytout()
    }
    
    //MARK: -setLayout
    func setLaytout() {
        screenShotButton.layer.cornerRadius = screenShotButton.frame.height / 2
    }
    //MARK: -viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        idLabel.text = "ID : " + id
        serialLabel.text = "시리얼 번호 : " + serial
        locationLabel.text = "장소 : " + location
        if (check == "무") {
            checkLabel.text = "압력 : 점검기록 없음"
        }
        else {
            checkLabel.text = "압력 : " + check + "MPa"
        }
        makeQRCode(string: serial)
        getMapList()
    }
    //MARK: -makeQRCode
    func makeQRCode(string: String) {
        let QRStr = string
        let QRData = QRStr.data(using: String.Encoding.ascii)
        
        guard let QRFilter = CIFilter(name: "CIQRCodeGenerator") else {
            return }
        
        QRFilter.setValue(QRData, forKey: "inputMessage")
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledQrImage = QRFilter.outputImage?.transformed(by: transform)
        
        let colorParameters = [
            "inputColor0": CIColor(color: UIColor.black), // Foreground
            "inputColor1": CIColor(color: UIColor.white) // Background
        ]
        let QRColor = scaledQrImage?.applyingFilter("CIFalseColor", parameters: colorParameters)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(QRColor!, from: QRColor!.extent) else {
            return }
        let processedImage = UIImage(cgImage: cgImage)
        
        qrImageView.image = processedImage
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    //MARK: -touchScreenShotButton
    @IBAction func touchScreenShotButton(_ sender: Any) {
        let renderer = UIGraphicsImageRenderer(size: view.frame.size)
        let image = renderer.image(actions: { context in
            view.layer.render(in: context.cgContext)
        })
        //Save it to the camera roll
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "스크린샷 저장 완료", message: nil, preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {alert.dismiss(animated: true, completion: nil)})
        }
    }
    //MARK: -downloadImage
    func downloadImage(from url: URL) {
        DispatchQueue.main.async { LoadingHUD.show() }
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {[weak self] in
                self?.mapImageView.image = UIImage(data: data)
                
                let image = self!.mapImageView.image
                UIGraphicsBeginImageContextWithOptions(image!.size, true, 0)
                image!.draw(at: CGPoint(x: 0,y: 0))
                let context = UIGraphicsGetCurrentContext()!
                context.setLineWidth(5.0)
                context.setStrokeColor(UIColor.red.cgColor)
                
                let lx = ((self?.equipList?["location"] as? NSDictionary)!["x"] as? Int)!
                let ly = ((self?.equipList?["location"] as? NSDictionary)!["y"] as? Int)!
                print(lx)
                print(ly)
                context.addEllipse(in: CGRect(x: CGFloat(lx) / 400 * ((self!.mapImageView.image?.size.width)!), y: CGFloat(ly) / 200 * ((self!.mapImageView.image?.size.height)!), width: 5, height: 5))
                
                context.strokePath()
                let endImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                self?.mapImageView.image = endImage
                DispatchQueue.main.async { LoadingHUD.hide() }
            }
        }
        DispatchQueue.main.async { LoadingHUD.hide() }
    }
    //MARK: -getData
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
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
                
                let mapList = self.mapLists[self.map] as? NSDictionary
                
                self.urlData = self.serverURL + "/download/map?filename=" + (mapList!["name"] as! String)
                self.downloadImage(from: URL(string: self.urlData)!)
                
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
