//
//  LogViewController.swift
//  bleproject
//
//  Created by Tianli Feng on 4/22/19.
//  Copyright © 2019 Tianli Feng. All rights reserved.
//

import UIKit
import CoreBluetooth

class LogViewController: UIViewController, UITextViewDelegate {

    var log: String?
    var centralManager: CBCentralManager?
    var peripheralManager: CBPeripheralManager?
    
    @IBOutlet weak var logTextView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        logTextView.text = log
        logTextView.delegate = self
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
