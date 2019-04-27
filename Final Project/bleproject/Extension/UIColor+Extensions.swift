//
//  UIColor+Extensions.swift
//  Assignment6
//
//  Created by Tianli Feng on 3/2/19.
//  Copyright © 2019 Tianli Feng. All rights reserved.
//

import UIKit

extension UIColor {
    static func colorWithRGBValue(_ redValue: CGFloat, _ greenValue: CGFloat, _ blueValue: CGFloat, _  alpha: CGFloat) -> UIColor {
        return UIColor(red: redValue/255.0, green: greenValue/255.0, blue: blueValue/255.0, alpha: alpha)
    }
}
