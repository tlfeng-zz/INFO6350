//
//  ViewController.swift
//  bleproject
//
//  Created by Tianli Feng on 4/9/19.
//  Copyright © 2019 Tianli Feng. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "central" {
            if let vc = segue.destination as? ChatViewController {
                print("Central")
                vc.isCentral = true
            }
        }
        else if segue.identifier == "peripheral" {
            if let vc = segue.destination as? ChatViewController {
                print("Peripheral")
                vc.isCentral = false
            }
        }
    }
}

