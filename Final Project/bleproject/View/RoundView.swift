//
//  RoundView.swift
//  bleproject
//
//  Created by Tianli Feng on 4/25/19.
//  Copyright © 2019 Tianli Feng. All rights reserved.
//

import UIKit

/// create a bezier path view
public class RoundView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    public override func draw(_ rect: CGRect) {
        let color = UIColor.white
        color.set()
        let path = UIBezierPath(ovalIn: rect)
        path.fill()
    }
}
