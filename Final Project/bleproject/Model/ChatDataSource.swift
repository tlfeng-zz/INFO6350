//
//  ChatDataSource.swift
//  bleproject
//
//  Created by Tianli Feng on 4/20/19.
//  Copyright © 2019 Tianli Feng. All rights reserved.
//

import Foundation

/*
 数据提供协议
 */
protocol ChatDataSource
{
    /*返回对话记录中的全部行数*/
    func rowsForChatTable( _ tableView:TableView) -> Int
    /*返回某一行的内容*/
    func chatTableView(_ tableView:TableView, dataForRow:Int)-> MessageItem
}

