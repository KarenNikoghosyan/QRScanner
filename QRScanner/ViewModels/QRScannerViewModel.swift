//
//  QRScannerViewModel.swift
//  QRScanner
//
//  Created by Karen Nikoghosyan on 28/01/2023.
//

import Foundation

class QRScannerViewModel {
    
    private var height: CGFloat = 0
    private var width: CGFloat = 0
    private var viewX: CGFloat = 0
    private var viewY: CGFloat = 0
    private var labelYCenterConstraintConstant: CGFloat = 0
    
    //MARK: - Getters
    var getHeight: CGFloat {
        get { return height }
        set { height = newValue }
    }

    var getWidth: CGFloat {
        get { return width }
        set { width = newValue }
    }
    
    var getViewX: CGFloat {
        get { return viewX }
        set { viewX = newValue }
    }
    
    var getViewY: CGFloat {
        get { return viewY }
        set { viewY = newValue }
    }
    
    var getLabelYCenterConstraintConstant: CGFloat {
        get { return labelYCenterConstraintConstant }
        set { labelYCenterConstraintConstant = newValue }
    }
}
