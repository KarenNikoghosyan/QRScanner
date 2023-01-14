//
//  UIViewController+Extensions.swift
//  QRScanner
//
//  Created by Karen Nikoghosyan on 24/12/2022.
//

import UIKit

extension UIViewController {
    func showAlertPopup(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        self.present(alert, animated: true)
    }
}
