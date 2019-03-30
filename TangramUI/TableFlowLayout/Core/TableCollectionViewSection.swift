//
//  TableCollectionViewSection.swift
//
//  Created by Malte Schonvogel on 5/10/17.
//  Copyright © 2017 Malte Schonvogel. All rights reserved.
//

import UIKit

public protocol TableCollectionViewSection {
    
    var numberOfItems: Int { get }
    var colsPerRow: Int { get }
    var rowHeight: CGFloat { get }
    var sectionInset: UIEdgeInsets { get }
    var sectionBorderWidth: CGFloat { get }
    var minimumLineSpacing: CGFloat { get }
    var minimumInteritemSpacing: CGFloat { get }
    var shouldSelectItems: Bool { get }
    var footerHeight: CGFloat { get }
    var borderColor: UIColor { get }
    var stringToCopy: String? { get }
    
    func heightForItem(at index: Int, viewWidth: CGFloat) -> CGFloat
    func heightForHeader(viewWidth: CGFloat) -> CGFloat
}

public extension TableCollectionViewSection {
    
    func heightForHeader(viewWidth: CGFloat) -> CGFloat {
        return 0
    }
    
    var footerHeight: CGFloat {
        return 0
    }
    
    var colsPerRow: Int {
        return 1
    }

    var rowHeight: CGFloat {
        return 0
    }
    
    var sectionInset: UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    var sectionBorderWidth: CGFloat {
        return  1 / UIScreen.main.scale
    }
    
    var minimumLineSpacing: CGFloat {
        return 0
    }
    
    var minimumInteritemSpacing: CGFloat {
        return 0
    }
    
    var shouldSelectItems: Bool {
        return true
    }

    var borderColor: UIColor {
        return UIColor(hue:0.05, saturation:0.03, brightness:0.90, alpha:1.00)
    }
    
    var stringToCopy: String? {
        return nil
    }
}
