//
//  Data+Conversion.swift
//  bleproject
//
//  Created by Tianli Feng on 4/26/19.
//  Copyright © 2019 Tianli Feng. All rights reserved.
//

import Foundation
import UIKit

extension Data {
    var integer: Int {
        return withUnsafeBytes { $0.pointee }
    }
    var uint8: UInt8 {
        return withUnsafeBytes { $0.pointee }
    }
    var uint16: UInt16 {
        return withUnsafeBytes { $0.pointee }
    }
    var string: String? {
        return String(data: self, encoding: .utf8)
    }
    
    var uiImage: UIImage? {
        return UIImage(data: self)
    }
}
