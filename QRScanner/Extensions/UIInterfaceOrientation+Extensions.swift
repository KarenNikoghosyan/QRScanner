//
//  UIInterfaceOrientation+Extensions.swift
//  QRScanner
//
//  Created by Karen Nikoghosyan on 20/01/2023.
//

import Foundation
import UIKit
import AVFoundation

extension UIInterfaceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeRight: return .landscapeRight
        case .landscapeLeft: return .landscapeLeft
        case .portrait: return .portrait
        default: return nil
        }
    }
}
