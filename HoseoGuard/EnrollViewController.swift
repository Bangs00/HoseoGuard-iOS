//
//  EnrollViewController.swift
//  HoseoGuard
//
//  Created by 방현수 on 2020/11/15.
//

import UIKit
import AVFoundation

class EnrollViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    //MARK: -vars
    @IBOutlet weak var enrollImageView: UIImageView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var cameraView: UIView!
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
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
        captureButton.layer.cornerRadius = captureButton.frame.width / 2
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    //MARK: -touchDismissButton
    @IBAction func touchDismissButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    //MARK: -touchCaptureButton
    @IBAction func touchCaptureButton(_ sender: Any) {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        stillImageOutput.capturePhoto(with: settings, delegate: self)
    }
    //MARK: -viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Setup your camera here...
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        
        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        else {
            print("Unable to access back camera!")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            //Step 9
            stillImageOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
        }
        catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
    }
    //MARK: -setupLivePreview
    func setupLivePreview() {
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        cameraView.layer.insertSublayer(videoPreviewLayer, at: 0)
        
        //Step12
        DispatchQueue.global(qos: .userInitiated).async { //[weak self] in
            self.captureSession.startRunning()
            //Step 13
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.view.bounds
            }
        }
    }
    //MARK: -photoOutput
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let imageData = photo.fileDataRepresentation()
        else { return }
        
        let image = UIImage(data: imageData)
        
        let cropImage = cropImageToSquare(image: image!)!
        var serial = ""
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "시리얼 번호를 입력해주세요.", message: nil, preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .destructive, handler: { (action: UIAlertAction) in
                serial = (alert.textFields?[0].text)!
                self.updateEquipImage(image: cropImage,eid: serial)
                alert.dismiss(animated: true, completion: nil)
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
    //MARK: -viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }
    //MARK: -cropImageToSquare
    func cropImageToSquare(image: UIImage) -> UIImage? {
        let imageHeight = image.size.height / 10 * 3
        var imageWidth = image.size.width
        
        imageWidth = imageHeight
        
        let size = CGSize(width: imageWidth, height: imageHeight)
        
        let refWidth : CGFloat = CGFloat(image.cgImage!.width)
        let refHeight : CGFloat = CGFloat(image.cgImage!.height)
        
        let x = (refWidth - size.width) / 5 * 2
        let y = (refHeight - size.height) / 2
        
        let cropRect = CGRect(x: x, y: y, width: size.height, height: size.width)
        if let imageRef = image.cgImage!.cropping(to: cropRect) {
            return UIImage(cgImage: imageRef, scale: 0, orientation: image.imageOrientation)
        }
        
        return nil
    }
    //MARK: -updateEquipImage
    func updateEquipImage(image: UIImage,eid: String) {
        guard let imageData = image.jpegData(compressionQuality: 1) else {
            print("oops")
            return
        }
        
        let boundary = UUID().uuidString
        var paramData = Data()
        let paramName = "img"
        let fileName = eid + ".jpeg"
        
        paramData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        paramData.append("Content-Disposition: form-data; name=\"\(paramName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        paramData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        paramData.append(imageData)
        
        paramData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        let url = URL(string: serverURL + "/upload/fet")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.httpBody = paramData
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        
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
                        let alert = UIAlertController(title:  "Error : " + title, message: nil, preferredStyle: .alert)
                        self.present(alert, animated: true, completion: nil)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { alert.dismiss(animated: true, completion: nil)}
                        )
                        return
                    }
                }
            }
            
            guard successScope.contains(statusCode) else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Error : " + String(statusCode), message: nil, preferredStyle: .alert)
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
                    
                    DispatchQueue.main.async {
                        
                        let alert = UIAlertController(title: eid + "번 소화기", message: "사진 업로드 완료", preferredStyle: .alert)
                        let alertAction = UIAlertAction(title: "OK", style: .destructive, handler: { (action: UIAlertAction) in
                            alert.dismiss(animated: true, completion: nil)
                        })
                        alert.addAction(alertAction)
                        self.present(alert, animated: true, completion: nil)
                        
                        return
                    }
                }
                catch {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Error", message: "Json Pasing Fail", preferredStyle: .alert)
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
}
