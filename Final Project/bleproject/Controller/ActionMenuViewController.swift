//
//  ActionMenuViewController.swift
//  bleproject
//
//  Created by Tianli Feng on 4/25/19.
//  Copyright © 2019 Tianli Feng. All rights reserved.
//

import UIKit

let kScreenWidth = UIScreen.main.bounds.width
let kScreenHeight = UIScreen.main.bounds.height

final class ActionMenuViewController: PresentBottomVC, UITableViewDelegate, UITableViewDataSource,  UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let actionArray: [String] = ["Send Image", "Take Photo", "Download Image"]
    var imagePicker = UIImagePickerController()
    var delegate: ActionMenuVCDelegate?
    var apvc: ActionParamViewController?
    private var tableView: UITableView!
    
    override var controllerHeight: CGFloat {
        return 300.0
    }
    
    lazy var sureButton:UIButton = {
        let button = UIButton(frame: CGRect(x: kScreenWidth-60, y: 0, width: 40, height: 40))
        button.setImage(UIImage(named: "cross"), for: .normal)
        button.backgroundColor = .white
        button.addTarget(self, action: #selector(sureButtonClicked), for: .touchUpInside)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        return button
    }()
    lazy var containerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 75, width: kScreenWidth, height: kScreenHeight-75))
        view.backgroundColor = UIColor.white
        return view
    }()
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame:CGRect(x: (kScreenWidth-150)/2, y: 20, width: 150, height: 30))
        label.textAlignment = .center
        label.text = "Action Select"
        label.font = UIFont.systemFont(ofSize: 20)
        return label
    }()
    override public func viewDidLoad() {
        super.viewDidLoad()
        config()
    }
    private func config() {
        
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height
        
        view.backgroundColor = UIColor.clear
        let roundView = RoundView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 150))
        view.addSubview(roundView)
        roundView.addSubview(titleLabel)
        view.addSubview(containerView)
        view.addSubview(sureButton)
        
        tableView = UITableView(frame: CGRect(x: 0, y: barHeight, width: displayWidth, height: displayHeight - barHeight))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MyCell")
        tableView.dataSource = self
        tableView.delegate = self
        containerView.addSubview(tableView)
        imagePicker.delegate = self
    }
    @objc func sureButtonClicked() {
        self.dismiss(animated: true, completion: nil)
    }
    @objc func timeSelect(sender:UIDatePicker) {
        print("Time change to \(sender.date)")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return actionArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath)
        
        // Configure the cell...
        cell.textLabel?.text = actionArray[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if actionArray[indexPath.row] == "Send Image" {
            sendImageTapped(view: tableView, indexPath: indexPath)
        }
        else if actionArray[indexPath.row] == "Take Photo" {
            delegate?.sendTakingPhotoMessage()
            self.dismiss(animated: true, completion: nil)
        }else if actionArray[indexPath.row] == "Download Image" {
            //let storyboard = UIStoryboard(name: "Main", bundle: nil)
            //let vc = storyboard.instantiateViewController(withIdentifier: "ActionParamVC") as! ActionParamViewController
            //vc.delegate = self
            apvc!.paramLabelText = "Input the URL of the image\n you want to download"
            self.present(apvc!, animated: true, completion: nil)
        }
    }
    
    func sendImageTapped(view: UIView, indexPath: IndexPath)
    {
        //self.btnEdit.setTitleColor(UIColor.white, for: .normal)
        //self.btnEdit.isUserInteractionEnabled = true
        
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallary()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        /*If you want work actionsheet on ipad
         then you have to use popoverPresentationController to present the actionsheet,
         otherwise app will crash on iPad */
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            alert.popoverPresentationController?.sourceView = tableView
            alert.popoverPresentationController?.sourceRect = tableView.cellForRow(at: indexPath)!.frame
            alert.popoverPresentationController?.permittedArrowDirections = .up
        default:
            break
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func openCamera()
    {
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.camera))
        {
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func openGallary()
    {
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.allowsEditing = false
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        /*
         Get the image from the info dictionary.
         If no need to edit the photo, use `UIImagePickerControllerOriginalImage`
         instead of `UIImagePickerControllerEditedImage`
         */
        if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            //self.imgProfile.image = editedImage
            delegate?.setImagetoSend(selectedImage: originalImage)
            
        }
        
        //Dismiss the UIImagePicker after selection
        picker.dismiss(animated: true, completion: nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.isNavigationBarHidden = false
        self.dismiss(animated: true, completion: nil)
        //self.navigationController?.popViewController(animated: true)
    }
}
