//
//  QRScannerViewController.swift
//  QRScanner
//
//  Created by Karen Nikoghosyan on 24/12/2022.
//

import UIKit
import AVFoundation
import Vision
import SafariServices
import CoreImage

class QRScannerViewController: UIViewController {
    
    private var captureSession: AVCaptureSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkPermissions()
        setupCameraLiveView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .background).async {[weak self] in
                guard let self else {return}
                
                self.captureSession?.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
}

//MARK: - Functions
extension QRScannerViewController {
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) {[weak self] granted in
                guard let self else {return}
                
                if !granted {
                    self.showPermissionsAlert()
                }
            }
        case .denied, .restricted:
            showPermissionsAlert()
            
        default:
            return
        }
    }
    
    private func showPermissionsAlert() {
        showAlertPopup(title: "Permission Required", message: "Please open Settings and grant permission for this app to use your camera.")
    }
    
    private func setupCameraLiveView() {
        if captureSession == nil {
            captureSession = AVCaptureSession()
        }

        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        
        guard let device = videoDevice,
              let videoDeciveInput = try? AVCaptureDeviceInput(device: device),
              let captureSession = captureSession,
              captureSession.canAddInput(videoDeciveInput) else {
            
            showAlertPopup(title: "Cannot Find Camera", message: "There seems to be a problem with the camera on your device.")
            return
        }
        
        captureSession.sessionPreset = .hd4K3840x2160
        captureSession.addInput(videoDeciveInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(metadataOutput)

        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        
        configurePreviewLayer(captureSession: captureSession)
        
        DispatchQueue.global(qos: .background).async {[weak self] in
            guard let self else {return}
            
            self.captureSession?.startRunning()
        }
    }
    
    private func configurePreviewLayer(captureSession: AVCaptureSession) {
        let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer.videoGravity = .resizeAspectFill
        cameraPreviewLayer.connection?.videoOrientation = .portrait
        cameraPreviewLayer.frame = view.frame
        view.layer.insertSublayer(cameraPreviewLayer, at: 0)
        addGuideView()
    }
    
    private func addGuideView() {
        let width = UIScreen.main.bounds.width - (UIScreen.main.bounds.width * 0.2)
        let height = width
        let viewX = (UIScreen.main.bounds.width / 2) - (width / 2)
        let viewY = (UIScreen.main.bounds.height / 2) - (height / 2)
                
        let viewGuide = PartialTransparentView(rectsArray: [CGRect(x: viewX, y: viewY, width: width, height: height)])
        view.addSubview(viewGuide)
        
        viewGuide.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            viewGuide.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            viewGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            viewGuide.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            viewGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
        view.bringSubviewToFront(viewGuide)
        
        let label = UILabel()
        label.text = "Align the camera to scan the QR code"
        label.textColor = .white
        label.font = UIFont(name: "Futura", size: 14)
        view.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -200),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0)
        ])
        view.bringSubviewToFront(label)
    }
    
    private func showQRMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let imageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        imageView.image = generateQRCode(from: message)
        alert.view.addSubview(imageView)
        
        if message.isValidURL() {
            alert.addAction(UIAlertAction(title: "Open URL", style: .default) {[weak self] _ in
                guard let self,
                let url = URL(string: message) else {return}
                
                let safariVC = SFSafariViewController(url: url)
                alert.dismiss(animated: true) {
                    self.present(safariVC, animated: true)
                }
            })
        }

        alert.addAction(UIAlertAction(title: "Close", style: .cancel) {[weak self] _ in
            guard let self else {return}
            
            DispatchQueue.global(qos: .background).async {
                self.captureSession?.startRunning()
            }
        })
                        
        self.present(alert, animated: true)
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
}

//MARK: - Delegates
extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let captureSession else {return}
        
        if metadataObjects.count == 0 {return}
        
        captureSession.stopRunning()
        
        guard let metadataObject = metadataObjects[0] as? AVMetadataMachineReadableCodeObject else {return}
        
        if metadataObject.type == AVMetadataObject.ObjectType.qr {
            let urlMessage = metadataObject.stringValue ?? ""
            showQRMessage(title: "Message", message: urlMessage)
        }
    }
}
