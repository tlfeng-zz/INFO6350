//
//  UIImage+Transfer.swift
//  bleproject
//
//  Created by Tianli Feng on 4/26/19.
//  Copyright © 2019 Tianli Feng. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    var jpeg: Data? {
        return self.jpegData(compressionQuality: 1) // QUALITY min = 0 / max = 1
    }
    var png: Data? {
        return self.pngData()
    }
    
    func toBase64() -> String? {
        guard let imageData = self.pngData() else { return nil }
        return imageData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
    }
}
