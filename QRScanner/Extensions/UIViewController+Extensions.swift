//
//  UIViewController+Extensions.swift
//  QRScanner
//
//  Created by Karen Nikoghosyan on 24/12/2022.
//

import UIKit
import SafariServices
import AVFoundation

extension UIViewController {
    func showAlertPopup(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        self.present(alert, animated: true)
    }
    
    func showQRMessage(title: String, message: String, captureSession: AVCaptureSession) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if message.contains("https://") {
            alert.addAction(UIAlertAction(title: "Open URL", style: .default) { _ in
                guard let url = URL(string: message) else {return}
                
                let safariVC = SFSafariViewController(url: url)
                alert.dismiss(animated: true) {
                    self.present(safariVC, animated: true)
                }
            })
        }

        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { _ in
            DispatchQueue.global(qos: .background).async {
                captureSession.startRunning()
            }
        })
                        
        self.present(alert, animated: true)
    }
}
