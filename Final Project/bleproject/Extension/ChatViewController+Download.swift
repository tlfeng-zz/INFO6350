//
//  ChatViewController+Download.swift
//  bleproject
//
//  Created by Tianli Feng on 4/27/19.
//  Copyright © 2019 Tianli Feng. All rights reserved.
//

import Foundation
import UIKit

extension ChatViewController {
    func downloadImage(urlStr: String){
    //var urlStr:NSString = "https://developer.apple.com/swift/images/swift-og.png"
    
    var request: URLRequest = URLRequest(url: URL(string: urlStr as String)!, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval:2.0)
    
    NSURLConnection.sendAsynchronousRequest(request, queue:OperationQueue()) { (response, data, error) ->Void in
        var path:NSString = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory,FileManager.SearchPathDomainMask.userDomainMask,true)[0] as NSString;
        
        var cachepaht = path.appendingPathComponent("test.jpg")
        
        UIImageWriteToSavedPhotosAlbum(UIImage(data: data!)!, self, nil, nil)

    }
    
}

//fileprivate var downLoader = DownLoader()

//override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

//    let url = NSURL(string: "http://free2.macx.cn:8281/tools/photo/SnapNDragPro418.dmg")

//    self.downLoader.downLoader(url: url!)

//}
}
