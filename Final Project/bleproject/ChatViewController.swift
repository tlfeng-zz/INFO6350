//
//  ChatViewController.swift
//  bleproject
//
//  Created by Tianli Feng on 4/20/19.
//  Copyright © 2019 Tianli Feng. All rights reserved.
//

import UIKit
import CoreBluetooth

class ChatViewController: UIViewController, ChatDataSource,UITextFieldDelegate {
    
    // Bluetooth variables
    private let Service_UUID: String = "CDD1"
    private let Characteristic_UUID: String = "CDD2"
    
    private var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?
    
    private var peripheralManager: CBPeripheralManager?
    private var characteristicP: CBMutableCharacteristic?
    
    // central or peripheral sign
    var isCentral:Bool = true
    // control handshaking
    var isHandshaking = false
    let handshakeInterval: TimeInterval = 15
    var timestamp: Double = 0
    // seqence number
    var sent_seq_num: UInt16 = 0
    var received_seq_num: UInt16 = 0
    //acknowledgement number
    var sent_ack_num: UInt16 = 0
    var received_ack_num: UInt16 = 0
    // payload size
    var sent_payload_size: UInt16 = 0
    var received_payload_size: UInt16 = 0
    // last sent message
    var sent_message: Message?
    // connection ready sign
    var isConnectionReady = false
    // timer
    var timer: Timer?
    
    var Chats: NSMutableArray!
    var tableView: TableView!
    var me: UserInfo!
    var you: UserInfo!
    var msgTextField: UITextField!
    var sendButton: UIButton!
    
    // record log
    var log: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupChatTable()
        setupSendPanel()
        
        // create bluetooth service
        if (isCentral) {
        centralManager = CBCentralManager.init(delegate: self, queue: .main)
        }
        else {
        peripheralManager = CBPeripheralManager.init(delegate: self, queue: .main)
        }
        
    }
    
    func setupSendPanel()
    {
        let screenWidth = UIScreen.main.bounds.width
        let sendView = UIView(frame:CGRect(x: 0,y: self.view.frame.size.height - 56,width: screenWidth,height: 56))
        
        sendView.backgroundColor=UIColor.lightGray
        sendView.alpha=0.9
        
        // create a TextField as the text input area
        msgTextField = UITextField(frame:CGRect(x: 7,y: 10,width: screenWidth - 95,height: 36))
        msgTextField.backgroundColor = UIColor.white
        msgTextField.textColor=UIColor.black
        msgTextField.font=UIFont.boldSystemFont(ofSize: 12)
        msgTextField.layer.cornerRadius = 10.0
        msgTextField.returnKeyType = UIReturnKeyType.send
        
        //Set the delegate so you can respond to user input
        msgTextField.delegate=self
        sendView.addSubview(msgTextField)
        self.view.addSubview(sendView)
        
        // create a UIButton as the send message button
        sendButton = UIButton(frame:CGRect(x: screenWidth - 80,y: 10,width: 72,height: 36))
        sendButton.backgroundColor=UIColor(red: 0x37/255, green: 0xba/255, blue: 0x46/255, alpha: 1)
        sendButton.addTarget(self, action:#selector(addTapped) ,
                             for:UIControl.Event.touchUpInside)
        sendButton.layer.cornerRadius=6.0
        sendButton.setTitle("Add", for:UIControl.State())
        sendView.addSubview(sendButton)
        
        // register tap event, to dismiss keyboard
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        
        // Move view with keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // check when textfield changes
        msgTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    
    
    func textFieldShouldReturn(_ textField:UITextField) -> Bool
    {
        sendTapped()
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if (textField.text != "") {
            sendButton.setTitle("Send", for:UIControl.State())
            sendButton.removeTarget(nil, action: nil, for: .allEvents)
            sendButton.addTarget(self, action:#selector(sendTapped) ,
                                 for:UIControl.Event.touchUpInside)
        }
        else {
            sendButton.setTitle("Add", for:UIControl.State())
            sendButton.removeTarget(nil, action: nil, for: .allEvents)
            sendButton.addTarget(self, action:#selector(addTapped) ,
                                 for:UIControl.Event.touchUpInside)
        }
    }
    
    // dismiss keyboard when tapping the view
    @objc func handleTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            print("Dissmiss Keyboard")
            msgTextField.resignFirstResponder()
        }
        sender.cancelsTouchesInView = false
    }
    
    @objc func addTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "LogVC") as! LogViewController
        vc.log = "log"
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // Move view with keyboard
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    // Move view with keyboard
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    @objc func sendTapped() {
        // check if need handshaking
        if !isConnectionReady {
            beginThreeWayHandshake()
            isHandshaking = true
        }
        
        // check if the handshake is done
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
            if self.isConnectionReady {
                // create messageItem
                let thisChat =  MessageItem(body:self.msgTextField!.text! as NSString, user:self.me, date:Date(), mtype:ChatType.mine)
                //let thatChat =  MessageItem(body:"你说的是：\(msgTextField!.text!)" as NSString, user:you, date:Date(), mtype:ChatType.someone)
                
                // add new chat bubble to tableview
                self.Chats.add(thisChat)
                //Chats.add(thatChat)
                self.tableView.chatDataSource = self
                self.tableView.reloadData()
        
                // send through bluetooth
                let data = (self.msgTextField!.text ?? "empty input")!.data(using: String.Encoding.utf8)
                self.sendMessage(payload: data!, action: .sendText, control: .none)
        
                // dismiss keyboard, and clear the input field
                //self.showTableView()
                self.msgTextField.resignFirstResponder()
                self.msgTextField.text = ""
                self.sendButton.setTitle("Add", for:UIControl.State())
                self.sendButton.removeTarget(nil, action: nil, for: .allEvents)
                self.sendButton.addTarget(self, action:#selector(self.addTapped) ,
                                     for:UIControl.Event.touchUpInside)
            }
        }

    }
    
    func setupChatTable()
    {
        self.tableView = TableView(frame:CGRect(x: 0, y: 20, width: self.view.frame.size.width, height: self.view.frame.size.height - 76), style: .plain)
        
        //创建一个重用的单元格
        self.tableView!.register(TableViewCell.self, forCellReuseIdentifier: "ChatCell")
        
        // define user for different party
        if isCentral {
            me = UserInfo(name:"Xiaoming" ,logo:("xiaoming.png"))
            you  = UserInfo(name:"Xiaohua", logo:("xiaohua.png"))
        }
        else {
            you = UserInfo(name:"Xiaoming" ,logo:("xiaoming.png"))
            me  = UserInfo(name:"Xiaohua", logo:("xiaohua.png"))
        }
        
        let zero =  MessageItem(body:"最近去哪玩了？", user:you,  date:Date(timeIntervalSinceNow:-90096400), mtype:.someone)
        
        let zero1 =  MessageItem(body:"去了趟苏州，明天发照片给你哈？", user:me,  date:Date(timeIntervalSinceNow:-90086400), mtype:.mine)
        
        let first =  MessageItem(body:"你看这风景怎么样，我周末去苏州拍的！", user:me,  date:Date(timeIntervalSinceNow:-90000600), mtype:.mine)
        
        let second =  MessageItem(image:UIImage(named:"sz.png")!,user:me, date:Date(timeIntervalSinceNow:-90000290), mtype:.mine)
        
        let third =  MessageItem(body:"太赞了，我也想去那看看呢！",user:you, date:Date(timeIntervalSinceNow:-90000060), mtype:.someone)
        
        let fouth =  MessageItem(body:"嗯，下次我们一起去吧！",user:me, date:Date(timeIntervalSinceNow:-90000020), mtype:.mine)
        
        let fifth =  MessageItem(body:"三年了，我终究没能看到这个风景",user:you, date:Date(timeIntervalSinceNow:0), mtype:.someone)
        
        
        Chats = NSMutableArray()
        Chats.addObjects(from: [first,second, third, fouth, fifth, zero, zero1])
        
        //set the chatDataSource
        self.tableView.chatDataSource = self
        
        //call the reloadData, this is actually calling your override method
        self.tableView.reloadData()
        
        self.view.addSubview(self.tableView)
    }
    
    func rowsForChatTable(_ tableView:TableView) -> Int
    {
        return self.Chats.count
    }
    
    func chatTableView(_ tableView:TableView, dataForRow row:Int) -> MessageItem
    {
        return Chats[row] as! MessageItem
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func beginThreeWayHandshake() {
        // step 1: central device send SYN
        printAndLog("HandShaking Step1 start: Central will send SYN")
        let initial_seq_num = UInt16.random(in: 0 ... UInt16.max)
        sent_seq_num = initial_seq_num
        // encapsulation
        let hlenctrl: HlenCtrlByte = [.hlen2, .hlen3, .syn]
        let head = Header(seq_num: sent_seq_num, ack_num: 0, hlenCtrlByte: hlenctrl, action: Action.empty)
        let sendStruct = Message(header: head, payload: Data())
        printAndLog("- Msg sent: seq:\(sent_seq_num), ack:\(sent_ack_num), action:\(head.action) -")
        let msgData = sendStruct.archive()
        // send
        self.peripheral?.writeValue(msgData, for: self.characteristic!, type: CBCharacteristicWriteType.withResponse)
        //save message
        sent_message = sendStruct
        
        printAndLog("HandShaking Step1 is done: Central Sent SYN")
    }
    
    func beginHandshakeStepTwo(received_seq_num: UInt16) {
        // step 2: peripheral device send ACK
        printAndLog("HandShaking Step2 start: Peripheral will send ACK")
        
        let initial_seq_num = UInt16.random(in: 0 ... UInt16.max)
        sent_seq_num = initial_seq_num
        if received_seq_num == UInt16.max {
            sent_ack_num = UInt16.min
        }
        else {
            sent_ack_num = received_seq_num + 1
        }
        
        // encapsulation
        let hlenctrl: HlenCtrlByte = [.hlen2, .hlen3, .ack, .syn]
        let head = Header(seq_num: sent_seq_num, ack_num: sent_ack_num, hlenCtrlByte: hlenctrl, action: Action.empty)
        let sendStruct = Message(header: head, payload: Data())
        printAndLog("- Msg sent: seq:\(sent_seq_num), ack:\(sent_ack_num), action:\(head.action) -")
        let msgData = sendStruct.archive()
        // send to central
        peripheralManager?.updateValue(msgData, for: characteristicP!, onSubscribedCentrals: nil)
        //save message
        sent_message = sendStruct
        
        printAndLog("HandShaking Step2 is done: Peripheral Sent ACK")
    }
    
    func beginHandshakeStepThree(received_seq_num: UInt16) {
        // step 2: peripheral device send ACK
        printAndLog("HandShaking Step3 start: Central will send ACK")
        
        // calculate seq num
        // seq_num is the last seq number central used +1
        if sent_seq_num == UInt16.max {
            sent_seq_num = UInt16.min
        }
        else {
            sent_seq_num = sent_seq_num + 1
        }
        
        // calculate ack num
        if received_seq_num == UInt16.max {
            sent_ack_num = UInt16.min
        }
        else {
            sent_ack_num = received_seq_num + 1
        }
        
        // encapsulation
        let hlenctrl: HlenCtrlByte = [.hlen2, .hlen3, .ack]
        let head = Header(seq_num: sent_seq_num, ack_num: sent_ack_num, hlenCtrlByte: hlenctrl, action: Action.empty)
        let sendStruct = Message(header: head, payload: Data())
        printAndLog("- Msg sent: seq:\(sent_seq_num), ack:\(sent_ack_num), action:\(head.action) -")
        let msgData = sendStruct.archive()
        // send to peripheral
        self.peripheral?.writeValue(msgData, for: self.characteristic!, type: CBCharacteristicWriteType.withResponse)
        //save message
        sent_message = sendStruct
        
        printAndLog("HandShaking Step3 is done: Central Sent ACK")
    }
    
    func beginTermination() {
        printAndLog("Termination Begin: I will send FIN and ACK")
        sendMessage(payload: Data(), action: .empty, control: .fin)
    }
    
    enum Control {
        case none
        case ack
        case fin
    }
    
    func sendMessage(payload: Data, action: Action, control: Control) {
        let current_payload_size = UInt16(payload.count)
        
        var sent_hlenCtrl: HlenCtrlByte!
        if let sent_message_bind = sent_message {
            sent_hlenCtrl = sent_message_bind.header.hlenCtrlByte
        } else {
            sent_hlenCtrl = HlenCtrlByte(rawValue: 0)
        }
        
        
        // calculate seq number
        // if last message is ACK: seq don't +1, if contains SYN/FIN: seq+1
        if sent_hlenCtrl.contains(.syn) || sent_hlenCtrl.contains(.fin) {
            let overflowByte = Int32(sent_payload_size) - Int32(UInt16.max - sent_seq_num)
            if overflowByte > 0 {
                sent_seq_num = UInt16.min + UInt16(overflowByte) - 1
            } else {
                sent_seq_num += sent_payload_size
            }
        }
        //calculate ack number
        let overflowByte = Int32(received_payload_size) - Int32(UInt16.max - sent_ack_num)
        if overflowByte > 0 {
            sent_ack_num = UInt16.min + UInt16(overflowByte) - 1
        } else {
            sent_ack_num += received_payload_size
        }
        
        //  encapsulation
        let hlenctrl: HlenCtrlByte?
        if control == .ack {
            hlenctrl = [.hlen2, .hlen3, .ack]
        }
        else if control == .fin {
            hlenctrl = [.hlen2, .hlen3, .ack ,.fin]
        }
        else {
            hlenctrl = [.hlen2, .hlen3]
        }
        let head = Header(seq_num: sent_seq_num, ack_num: sent_ack_num, hlenCtrlByte: hlenctrl!, action: action)
        let sendStruct = Message(header: head, payload: payload)
        printAndLog("- Msg sent: seq:\(sent_seq_num), ack:\(sent_ack_num), action:\(head.action) -")
        let msgData = sendStruct.archive()
        sent_message = sendStruct
        
        // send
        if isCentral {
            peripheral?.writeValue(msgData, for: characteristic!, type: CBCharacteristicWriteType.withResponse)
        }
        else {
            peripheralManager?.updateValue(msgData, for: characteristicP!, onSubscribedCentrals: nil)
        }
    }
    
    func parseMessageData(msgData: Data) {
        let message = Message.unarchive(data: msgData)
        received_seq_num = message.header.seq_num
        received_ack_num = message.header.ack_num
        let hlenCtrl = message.header.hlenCtrlByte
        let action = message.header.action
        received_payload_size = UInt16(message.payload.count)
        printAndLog("- Msg received: seq:\(received_seq_num), ack:\(received_ack_num), action:\(action) -")
        var sent_hlenCtrl: HlenCtrlByte!
        if let sent_message_bind = sent_message {
            sent_hlenCtrl = sent_message_bind.header.hlenCtrlByte
        } else {
            sent_hlenCtrl = HlenCtrlByte(rawValue: 0)
        }
        
        // parse the message
        
        // the message is SYN (used by peripheral)
        if hlenCtrl.contains(.syn) && !hlenCtrl.contains(.ack) {
            beginHandshakeStepTwo(received_seq_num: received_seq_num)
        }

        // received the ACK in handshake (used by central)
        if hlenCtrl.contains(.ack) && hlenCtrl.contains(.syn) {
            beginHandshakeStepThree(received_seq_num: received_seq_num)
            timestamp = NSDate().timeIntervalSince1970
            isHandshaking = false
            isConnectionReady = true
            // set timer for handshake
            timer = Timer.scheduledTimer(withTimeInterval: handshakeInterval, repeats: false) { timer in
                self.isConnectionReady = false
            }
        }

        // the message is ACK (used by peripheral)
        if hlenCtrl.contains(.ack) && !hlenCtrl.contains(.syn) && !isConnectionReady {
            printAndLog("Three Way Handshake succeed.")
            timestamp = NSDate().timeIntervalSince1970
            isHandshaking = false
            isConnectionReady = true
            // set timer for handshake
            timer = Timer.scheduledTimer(withTimeInterval: handshakeInterval, repeats: false) { timer in
                self.isConnectionReady = false
            }
            beginTermination()
        }
        
        // handle regular message with data
        if !hlenCtrl.contains(.ack) && !hlenCtrl.contains(.syn) && isConnectionReady {
            // 核对ack和seq
            if action == .sendText {
                let receivedText = message.payload.string
                
                //create local messageItem
                let thatChat =  MessageItem(body:"\(receivedText!)" as NSString, user:you, date:Date(), mtype:ChatType.someone)
                
                // add new chat bubble to tableview
                Chats.add(thatChat)
                self.tableView.chatDataSource = self
                self.tableView.reloadData()
            }
            
            // send ACK
            sendMessage(payload: Data(), action: .empty, control: .ack)
        }
        
        // handle regular ACK of receivinga data
        // besides, is not the ACK in handshake step3 or in termination step2
        if hlenCtrl.contains(.ack) && !hlenCtrl.contains(.syn) && isConnectionReady && !sent_hlenCtrl.contains(.syn) && !sent_hlenCtrl.contains(.fin) {
            // validate ack num
            if received_ack_num != sent_seq_num + sent_payload_size {
                printAndLog("error: received an incorrect ACK number")
                // add error handler
            }
        }
        
        // received FIN
        if hlenCtrl.contains(.fin){
            // received termination step1: the first FIN
            if !sent_hlenCtrl.contains(.fin) {
                printAndLog("Termination Step1 is done")
                // send ACK
                printAndLog("Termination Step2: I will send ACK")
                sendMessage(payload: Data(), action: .empty, control: .ack)
                // send FIN
                printAndLog("Termination Step3: I will send FIN and ACK")
                sendMessage(payload: Data(), action: .empty, control: .fin)
            }
            // received termination step3: the first FIN
            else {
                printAndLog("Termination Step3 is done")
                // send ACK
                printAndLog("Termination Step4: I will send ACK")
                sendMessage(payload: Data(), action: .empty, control: .ack)
                printAndLog("Termination process succeed")
            }
        }
        
    }
    
    func printAndLog(_ thisLog: String) {
        //获取当前时间
        let now = Date()
        
        // 创建一个日期格式器
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss.SSSS"
        let dateTimeStr = dformatter.string(from: now)
        
        self.log = self.log + dateTimeStr + "\n" + thisLog + "\n\n"
        print(dateTimeStr)
        print(thisLog)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "log" {
            if let vc = segue.destination as? LogViewController {
                vc.log = self.log
                vc.centralManager = self.centralManager
                vc.peripheralManager = self.peripheralManager
            }
        }
    }
}

// Bluetooth Extensions
extension ChatViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // 判断手机蓝牙状态
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("未知的")
        case .resetting:
            print("重置中")
        case .unsupported:
            print("不支持")
        case .unauthorized:
            print("未验证")
        case .poweredOff:
            print("未启动")
        case .poweredOn:
            print("可用")
            central.scanForPeripherals(withServices: [CBUUID.init(string: Service_UUID)], options: nil)
        }
    }
    
    /** 发现符合要求的外设 */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.peripheral = peripheral
        // 根据外设名称来过滤
        //        if (peripheral.name?.hasPrefix("WH"))! {
        //            central.connect(peripheral, options: nil)
        //        }
        central.connect(peripheral, options: nil)
    }
    
    /** 连接成功 */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.centralManager?.stopScan()
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID.init(string: Service_UUID)])
        print("连接成功")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("连接失败")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("断开连接")
        // 重新连接
        central.connect(peripheral, options: nil)
    }
    
    /** 发现服务 */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service: CBService in peripheral.services! {
            print("外设中的服务有：\(service)")
        }
        //本例的外设中只有一个服务
        let service = peripheral.services?.last
        // 根据UUID寻找服务中的特征
        peripheral.discoverCharacteristics([CBUUID.init(string: Characteristic_UUID)], for: service!)
    }
    
    /** 发现特征 */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic: CBCharacteristic in service.characteristics! {
            print("外设中的特征有：\(characteristic)")
        }
        
        self.characteristic = service.characteristics?.last
        // 读取特征里的数据
        peripheral.readValue(for: self.characteristic!)
        // 订阅
        peripheral.setNotifyValue(true, for: self.characteristic!)
    }
    
    /** 订阅状态 */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("订阅失败: \(error)")
            return
        }
        if characteristic.isNotifying {
            print("订阅成功")
            if !isHandshaking {
                beginThreeWayHandshake()
                isHandshaking = true
            }
            
        } else {
            print("取消订阅")
        }
    }
    
    /** 接收到数据 */ // central handle the received data
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let msgData = characteristic.value!
        parseMessageData(msgData: msgData)
    }
    
    /** 写入数据 */
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("写入数据")
    }
    
}

extension ChatViewController: CBPeripheralManagerDelegate {
    
    // 蓝牙状态
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            print("未知的")
        case .resetting:
            print("重置中")
        case .unsupported:
            print("不支持")
        case .unauthorized:
            print("未验证")
        case .poweredOff:
            print("未启动")
        case .poweredOn:
            print("可用")
            // 创建Service（服务）和Characteristics（特征）
            setupServiceAndCharacteristics()
            // 根据服务的UUID开始广播
            self.peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [CBUUID.init(string: Service_UUID)]])
        }
    }
    
    /** 创建服务和特征
     注意swift中枚举的按位运算 '|' 要用[.read, .write, .notify]这种形式
     */
    private func setupServiceAndCharacteristics() {
        let serviceID = CBUUID.init(string: Service_UUID)
        let service = CBMutableService.init(type: serviceID, primary: true)
        let characteristicID = CBUUID.init(string: Characteristic_UUID)
        let characteristic = CBMutableCharacteristic.init(type: characteristicID,
                                                          properties: [.read, .write, .notify],
                                                          value: nil,
                                                          permissions: [.readable, .writeable])
        service.characteristics = [characteristic]
        self.peripheralManager?.add(service)
        self.characteristicP = characteristic
    }
    
    /** 中心设备读取数据的时候回调 */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        // 请求中的数据，这里把文本框中的数据发给中心设备
        //request.value = self.textField.text?.data(using: .utf8)
        // 成功响应请求
        peripheral.respond(to: request, withResult: .success)
    }
    
    /** 中心设备写入数据 */ // peripheral handle the received data
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        let request = requests.last!
        let msgData = request.value!
        parseMessageData(msgData: msgData)
        
        // respond to central
        peripheral.respond(to: request, withResult: .success)
    }
    
    /** 订阅成功回调 */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristicP: CBCharacteristic) {
        print("\(#function) 订阅成功回调")
    }
    
    /** 取消订阅回调 */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristicP: CBCharacteristic) {
        print("\(#function) 取消订阅回调")
    }
    
}
