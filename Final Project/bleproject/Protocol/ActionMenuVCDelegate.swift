//
//  ActionMenuVCDelegate.swift
//  bleproject
//
//  Created by Tianli Feng on 4/25/19.
//  Copyright © 2019 Tianli Feng. All rights reserved.
//

import Foundation
import UIKit

protocol ActionMenuVCDelegate {
    func setImagetoSend(selectedImage: UIImage)
    func sendTakingPhotoMessage()
    func sendDownloadImageMessage(urlStr: String)
}
