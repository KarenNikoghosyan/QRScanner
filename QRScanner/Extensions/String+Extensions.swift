//
//  String+Extensions.swift
//  QRScanner
//
//  Created by Karen Nikoghosyan on 14/01/2023.
//

import Foundation

extension String {

    func isValidURL() -> Bool {
        let urlRegEx =
        "^(http|https)://([a-zA-Z0-9.-]+(?::[a-zA-Z0-9.&amp;%$-]+)*@)*((25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9])\\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[0-9])|localhost|([a-zA-Z0-9-]+\\.)*[a-zA-Z0-9-]+\\.(com|ru|kz|edu|gov|int|mil|net|org|biz|arpa|info|name|pro|aero|coop|museum|[a-zA-Z]{2}))(?::[0-9]+)*(/($|[a-zA-Z0-9.,?'\\\\+&amp;%$#=~_-]+))*(?:\\(\\d+\\))?$"
        return NSPredicate(format: "SELF MATCHES %@", urlRegEx).evaluate(with: self)
    }
}
