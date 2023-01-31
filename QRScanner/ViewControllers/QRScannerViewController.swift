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
    
    private let viewModel = QRScannerViewModel()
    
    private var captureSession: AVCaptureSession?
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private var viewGuide: PartialTransparentView = PartialTransparentView(frame: .zero)
    private var label: UILabel = UILabel(frame: .zero)
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkPermissions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopSession()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil, completion: { [weak self] (context) in
            guard let self else {return}
            
            DispatchQueue.main.async  {
                self.updateVideoOrientation()
            }
        })
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
                } else {
                    self.setupCameraLiveView()
                }
            }
        case .denied, .restricted:
            self.showPermissionsAlert()
            
        case .authorized:
            setupCameraLiveView()
            
        default:
            return
        }
    }
    
    private func showPermissionsAlert() {
        DispatchQueue.main.async {[weak self] in
            guard let self else {return}
            
            self.showAlertPopup(title: "Permission Required", message: "Please open Settings and grant permission for this app to use your camera.")
        }
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
        
        //Configures the camera preview layer
        configurePreviewLayer()
        
        //Starts the camera session
        startSession()
    }
    
    private func configurePreviewLayer() {
        guard let captureSession else {
            showAlertPopup(title: "Cannot Find Camera", message: "There seems to be a problem with the camera on your device.")
            return
        }
        
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.videoGravity = .resizeAspectFill
        cameraPreviewLayer?.connection?.videoOrientation = .portrait
        
        DispatchQueue.main.async {[weak self] in
            guard let self else {return}
            
            self.cameraPreviewLayer?.frame = self.view.frame
            self.view.layer.insertSublayer(self.cameraPreviewLayer!, at: 0)
            
            //Adds the camera guide view
            UIDevice.current.orientation == .portrait ? self.setupGuideViewPotrait() : UIDevice.current.orientation == .landscapeLeft ? self.setupGuideViewLandscape() : UIDevice.current.orientation == .landscapeRight ? self.setupGuideViewLandscape() : self.setupGuideViewPotrait()
        }
    }

    private func setupGuideViewPotrait() {
        viewModel.getWidth = UIScreen.main.bounds.width - (UIScreen.main.bounds.width * 0.2)
        viewModel.getHeight = viewModel.getWidth
        viewModel.getViewX = (UIScreen.main.bounds.width / 2) - (viewModel.getWidth / 2)
        viewModel.getViewY = (UIScreen.main.bounds.height / 2) - (viewModel.getHeight / 2)
        
        setupPartialTransparentView()
        setupUILabelGuide()
    }
    
    private func setupGuideViewLandscape() {
        viewModel.getWidth = UIScreen.main.bounds.width - (UIScreen.main.bounds.width * 0.6)
        viewModel.getHeight = UIScreen.main.bounds.height - (UIScreen.main.bounds.height * 0.4)
        viewModel.getViewX = (UIScreen.main.bounds.width / 2) - (viewModel.getWidth / 2)
        viewModel.getViewY = (UIScreen.main.bounds.height / 2) - (viewModel.getHeight / 2)
        
        setupPartialTransparentView()
        setupUILabelGuide()
    }
    
    private func setupPartialTransparentView() {
        viewGuide = PartialTransparentView(rectsArray: [CGRect(x: viewModel.getViewX, y: viewModel.getViewY, width: viewModel.getWidth, height: viewModel.getHeight)])
        view.addSubview(viewGuide)
        
        viewGuide.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            viewGuide.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            viewGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            viewGuide.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            viewGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
        view.bringSubviewToFront(viewGuide)
    }
    
    private func setupUILabelGuide() {
        label = UILabel()
        label.text = "Align the camera to scan the QR code"
        label.textColor = .white
        label.font = UIFont(name: "Futura", size: 14)
        view.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        viewModel.getLabelYCenterConstraintConstant = UIDevice.current.orientation == .portrait ? -200 : UIDevice.current.orientation == .landscapeLeft ? -150 : UIDevice.current.orientation == .landscapeRight ? -150 : -200
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: viewModel.getLabelYCenterConstraintConstant),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0)
        ])
        view.bringSubviewToFront(label)
    }
      
    private func updateVideoOrientation() {
        guard let cameraPreviewLayer else { return }
        
        guard cameraPreviewLayer.connection!.isVideoOrientationSupported else {
            self.showAlertPopup(title: "Error", message: "Couldn't rotate the camera at this moment")
            return
        }
        
        let windowScenes = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = windowScenes?.windows.first
        
        let statusBarOrientation = window?.windowScene?.interfaceOrientation
        let videoOrientation: AVCaptureVideoOrientation = statusBarOrientation?.videoOrientation ?? .portrait
        
        cameraPreviewLayer.frame = view.layer.bounds
        cameraPreviewLayer.connection?.videoOrientation = videoOrientation
        cameraPreviewLayer.removeAllAnimations()
        
        updateTransparentViewSize()
    }
    
    private func updateTransparentViewSize() {
        viewGuide.removeFromSuperview()
        label.removeFromSuperview()
        
        //Updates the camera guide view
        UIDevice.current.orientation == .portrait ? setupGuideViewPotrait() : UIDevice.current.orientation == .landscapeLeft ? setupGuideViewLandscape() : UIDevice.current.orientation == .landscapeRight ? setupGuideViewLandscape() : setupGuideViewPotrait()
    }
    
    private func showQRMessage(title: String, qrText: String) {
        let alert = UIAlertController(title: title, message: qrText, preferredStyle: .alert)
        
        let imageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        //Generates an QR code image by using a string
        imageView.image = generateQRCode(from: qrText)
        alert.view.addSubview(imageView)
        
        if qrText.isValidURL() {
            alert.addAction(UIAlertAction(title: "Open URL", style: .default) {[weak self] _ in
                guard let self,
                      let url = URL(string: qrText) else {return}
                
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
    
    private func startSession() {
        if captureSession?.isRunning == false {
            DispatchQueue.global().async {[weak self] in
                guard let self else {return}
                
                self.captureSession?.startRunning()
            }
        }
    }
    
    private func stopSession() {
        if captureSession?.isRunning == true {
            DispatchQueue.global().async {[weak self] in
                guard let self else {return}
                
                self.captureSession?.stopRunning()
            }
        }
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
            showQRMessage(title: "Message", qrText: urlMessage)
        }
    }
}
