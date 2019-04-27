//
//  ChatViewController+TakePhoto.swift
//  bleproject
//
//  Created by Tianli Feng on 4/27/19.
//  Copyright © 2019 Tianli Feng. All rights reserved.
//

import Foundation
import UIKit

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func launchCamera() {
        var imagePicker:UIImagePickerController = UIImagePickerController()
        //Set delegate to imagePicker
        imagePicker.delegate = self
        //Allow user crop or not after take picture
        imagePicker.allowsEditing = false
        //set what you need to use "camera or photo library"
        imagePicker.sourceType = .camera
        //Switch flash camera
        imagePicker.cameraFlashMode = .off
        //Set camera Capture Mode photo or Video
        imagePicker.cameraCaptureMode = .photo
        //set camera front or rear
        imagePicker.cameraDevice = .rear
        // hide the control
        imagePicker.showsCameraControls = false
        //Present camera viewcontroller
        self.present(imagePicker, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Change `2.0` to the desired number of seconds.
                // Code you want to be delayed
                imagePicker.takePicture()
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let imagePicked = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            UIImageWriteToSavedPhotosAlbum(imagePicked, nil, nil, nil)
            dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
