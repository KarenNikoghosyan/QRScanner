//
//  QRScannerViewController.swift
//  QRScanner
//
//  Created by Karen Nikoghosyan on 24/12/2022.
//

import UIKit
import AVFoundation
import Vision

class QRScannerViewController: UIViewController {
    
    private var captureSession: AVCaptureSession? = nil
    
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
            showQRMessage(title: "Message", message: urlMessage, captureSession: captureSession)
        }
    }
}
