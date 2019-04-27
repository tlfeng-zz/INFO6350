//
//  ActionParamViewController.swift
//  bleproject
//
//  Created by Tianli Feng on 4/27/19.
//  Copyright © 2019 Tianli Feng. All rights reserved.
//

import UIKit

class ActionParamViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var paramLabel: UILabel!
    @IBOutlet weak var paramTextView: UITextView!
    
    var paramLabelText = ""
    var delegate: ActionMenuVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        paramLabel.text = paramLabelText
        paramTextView.delegate = self
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            paramTextView.resignFirstResponder()
            return false
        }
        return true
    }
    
    @IBAction func confirmTapped(_ sender: Any) {
        delegate?.sendDownloadImageMessage(urlStr: paramTextView.text!)
        print("URL: \(paramTextView.text!)")
        dismiss(animated: true, completion: nil)
        dismiss(animated: true, completion: nil)
    }
    @IBAction func backTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
