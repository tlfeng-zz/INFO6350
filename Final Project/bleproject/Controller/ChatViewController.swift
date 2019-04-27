//
//  ChatViewController.swift
//  bleproject
//
//  Created by Tianli Feng on 4/20/19.
//  Copyright © 2019 Tianli Feng. All rights reserved.
//

import UIKit
import CoreBluetooth
import UserNotifications

class ChatViewController: UIViewController, ChatDataSource, UITextFieldDelegate, ActionMenuVCDelegate {
    
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
    let handshakeInterval: TimeInterval = 120
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
    
    // First up, check if we're meant to be sending an EOM
    fileprivate var sendingEOM = false;
    //var sendDataIndex: Int?
    //var dataToSend: Data?
    //var data: Data = Data()
    var NOTIFY_MTU: Int = 500
    
    // image data
    var imageToSend: UIImage?
    var imageStr: String?
    var imageData: Data?
    var amountToSend: Int = 0
    var sendDataIndex: Int = 0
    var received_dataSoFar: Data =  Data()
    var willReceiveImageDataSize: Int = 0
    
    var Chats: NSMutableArray!
    var tableView: TableView!
    var me: UserInfo!
    var you: UserInfo!
    var msgTextField: UITextField!
    var sendButton: UIButton!
    
    // notification
    var badge: Int = 0
    
    fileprivate var downLoader = DownLoader()
    
    // record log
    var log: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupChatTable()
        setupSendPanel()
        
        self.navigationController?.navigationBar.isHidden = false
        // create bluetooth service
        if (isCentral) {
        centralManager = CBCentralManager.init(delegate: self, queue: .main)
        }
        else {
        peripheralManager = CBPeripheralManager.init(delegate: self, queue: .main)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
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
            // clear badge
            UIApplication.shared.applicationIconBadgeNumber = 0
            badge = 0
        }
        sender.cancelsTouchesInView = false
    }
    
    @objc func addTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let apvc = storyboard.instantiateViewController(withIdentifier: "ActionParamVC") as! ActionParamViewController
        apvc.delegate = self
        //self.navigationController?.pushViewController(vc, animated: true)
        
        let actionMenuVC = ActionMenuViewController()
        actionMenuVC.delegate = self
        actionMenuVC.apvc = apvc
        self.presentBottom(actionMenuVC)
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
        var mtypeMe: ChatType = .mine
        var mtypeYou: ChatType = .someone
        if !isCentral {
            mtypeMe = .someone
            mtypeYou = .mine
        }
        
            me = UserInfo(name:"Xiaoming" ,logo:("xiaoming.png"))
            you  = UserInfo(name:"Xiaohua", logo:("xiaohua.png"))
        
        let zero =  MessageItem(body:"Where did you go recently？", user:you,  date:Date(timeIntervalSinceNow:-90096400), mtype:mtypeYou)
        
        let zero1 =  MessageItem(body:"Went to Suzhou，I'll send you some photos tomorrow？", user:me,  date:Date(timeIntervalSinceNow:-90086400), mtype:mtypeMe)
        
        let first =  MessageItem(body:"How about the scenery，I took them at Suzhou！", user:me,  date:Date(timeIntervalSinceNow:-90000600), mtype:mtypeMe)
        
        let second =  MessageItem(image:UIImage(named:"sz.png")!,user:me, date:Date(timeIntervalSinceNow:-90000290), mtype:mtypeMe)
        
        let third =  MessageItem(body:"That's awesome, I would like to go there!",user:you, date:Date(timeIntervalSinceNow:-90000060), mtype:mtypeYou)
        
        let fouth =  MessageItem(body:"Ok，next time let's go there together！",user:me, date:Date(timeIntervalSinceNow:-90000020), mtype:mtypeMe)
        
        let fifth =  MessageItem(body:"I has been 3 years, I haven't see the view  eventually.",user:you, date:Date(timeIntervalSinceNow:0), mtype:mtypeYou)
        
        
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
        // if contains no control, seq+last sent payload size/
        if !sent_hlenCtrl.contains(.ack) {
            let overflowByte = Int32(sent_payload_size) - Int32(UInt16.max - sent_seq_num)
            if overflowByte > 0 {
                sent_seq_num = UInt16.min + UInt16(overflowByte) - 1
            } else {
                sent_seq_num += sent_payload_size
            }
        }
        if sent_hlenCtrl.contains(.syn) || sent_hlenCtrl.contains(.fin) {
            if sent_seq_num == UInt16.max {
                sent_seq_num = UInt16.min
            }
            else {
                sent_seq_num = sent_seq_num + 1
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
        var sent_action: Action!
        if let sent_message_bind = sent_message {
            sent_hlenCtrl = sent_message_bind.header.hlenCtrlByte
            sent_payload_size = UInt16(sent_message_bind.payload.count)
            sent_action = sent_message_bind.header.action
        } else {
            sent_hlenCtrl = HlenCtrlByte(rawValue: 0)
            sent_action = .empty
        }
        
        // parse the message
        
        // the message is SYN (used by peripheral)
        if hlenCtrl.contains(.syn) && !hlenCtrl.contains(.ack) {
            beginHandshakeStepTwo(received_seq_num: received_seq_num)
        }

        // received the ACK in handshake (used by central)
        if hlenCtrl.contains(.ack) && hlenCtrl.contains(.syn) {
            beginHandshakeStepThree(received_seq_num: received_seq_num)
            endHankshakeProcess()
        }

        // the message is ACK (used by peripheral)
        if hlenCtrl.contains(.ack) && !hlenCtrl.contains(.syn) && !isConnectionReady {
            printAndLog("Three Way Handshake succeed.")
            endHankshakeProcess()
            //beginTermination()
        }
        
        // handle regular message with data
        if !hlenCtrl.contains(.ack) && !hlenCtrl.contains(.syn) && isConnectionReady {
            // Check Ack and Seq
            if action == .sendText {
                let receivedText = message.payload.string
                
                //create local messageItem
                let thatChat =  MessageItem(body:"\(receivedText!)" as NSString, user:you, date:Date(), mtype:ChatType.someone)
                
                // add new chat bubble to tableview
                Chats.add(thatChat)
                self.tableView.chatDataSource = self
                self.tableView.reloadData()
                
                // add notification
                addNotification(title: "You have one new message.", subtitle: "", body: receivedText!)
            }
            
            // receive startsign of sendImage
            if action == .sendImageStart {
                let receivedText = message.payload.string
                // record the total size
                willReceiveImageDataSize = Int(receivedText!)!
                
                //create local messageItem
                let thatChat =  MessageItem(body:"Will Send Image. Size:\(receivedText!)" as NSString, user:you, date:Date(), mtype:ChatType.someone)
                
                // add new chat bubble to tableview
                Chats.add(thatChat)
                self.tableView.chatDataSource = self
                self.tableView.reloadData()
            }
            
            
            // put the splitted image data together
            if action == .sendImage {
                let received_dataPart = message.payload
                received_dataSoFar.append(received_dataPart)
                
                // edit in the same bubble: remove and then add
                Chats.removeLastObject()
                let percent = Double(received_dataSoFar.count) / Double(willReceiveImageDataSize) * 100
                let percentStr = String(format: "%.2f", percent) + "%"
                //create local messageItem
                let thatChat =  MessageItem(body:"Sending image :\(percentStr)" as NSString, user:you, date:Date(), mtype:ChatType.someone)
                
                // add new chat bubble to tableview
                Chats.add(thatChat)
                self.tableView.chatDataSource = self
                //self.tableView.reloadData()
                reload(tableView: tableView)
            }
            
            // all chunks have received, and convert to image
            if action == .sendImageEnd {
                let received_image = received_dataSoFar.uiImage
                
                // edit in the same bubble: remove and then add
                Chats.removeLastObject()
                //create local messageItem
                let thatChat =  MessageItem(image: received_image!, user: you, date: Date(), mtype: ChatType.someone)
                //clear
                received_dataSoFar = Data()
                
                // add new chat bubble to tableview
                Chats.add(thatChat)
                self.tableView.chatDataSource = self
                //self.tableView.reloadData()
                reload(tableView: tableView)
                
                // add notification
                addNotification(title: "You have one new message.", subtitle: "", body: "[Image]")
            }
            
            // handle the taking photo message
            if action == .takePhoto {
                launchCamera()
                //create local messageItem
                let thatChat =  MessageItem(body:"[Launch Camera]" as NSString, user:you, date:Date(), mtype:ChatType.someone)
                
                // add new chat bubble to tableview
                Chats.add(thatChat)
                self.tableView.chatDataSource = self
                self.tableView.reloadData()
            }
            
            // handle the downloading image message
            if action == .downloadImage {
                let urlStr = message.payload.string
                downloadImage(urlStr: urlStr!)
                //create local messageItem
                let thatChat =  MessageItem(body:"[Download Image]" as NSString, user:you, date:Date(), mtype:ChatType.someone)
                
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
            printAndLog("Checking ACK: rec_ack:\(received_ack_num), sent_seq:\(sent_seq_num), sent_size:\(sent_payload_size)")
            if received_ack_num != sent_seq_num + sent_payload_size {
                printAndLog("error: received an incorrect ACK number")
                // add error handler
            }
            
            // the message is ACK after send sendImageStart
            if sent_action == .sendImageStart {
                // Work out how big it should be
                amountToSend = imageData!.count - sendDataIndex;
                printAndLog("amountToSend: \(amountToSend)")
                
                // Can't be longer than bluetooth MTU
                if amountToSend > NOTIFY_MTU {
                    amountToSend = NOTIFY_MTU
                }
                
                // Copy out the data we want
                let chunk = imageData!.withUnsafeBytes{(body: UnsafePointer<UInt8>) in
                    return Data(
                        bytes: body + sendDataIndex,
                        count: amountToSend
                    )
                }
                
                // Send it
                sendMessage(payload: chunk, action: .sendImage, control: .none)
            }
            
            // the message is ACK after send SendImage
            if sent_action == .sendImage {
                
                // finish sending image
                if sendDataIndex >= imageData!.count {
                    let amountToSendData = String(amountToSend).data(using: String.Encoding.utf8)
                    sendMessage(payload: amountToSendData!, action: .sendImageEnd, control: .none)
                }
                else {
                // It did send, so update our index
                sendDataIndex += amountToSend;
                
                // Work out how big it should be
                amountToSend = imageData!.count - sendDataIndex;
                
                // Can't be longer than bluetooth MTU
                if amountToSend > NOTIFY_MTU {
                    amountToSend = NOTIFY_MTU
                }
                
                // Copy out the data we want
                let chunk = imageData!.withUnsafeBytes{(body: UnsafePointer<UInt8>) in
                    return Data(
                        bytes: body + sendDataIndex,
                        count: amountToSend
                    )
                }
                
                // Send it
                sendMessage(payload: chunk, action: .sendImage, control: .none)
                }
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
    
    func endHankshakeProcess() {
        timestamp = NSDate().timeIntervalSince1970
        isHandshaking = false
        isConnectionReady = true
        if isCentral {
            self.title = "Central Mode: Connected"
        }
        else {
            self.title = "Peripheral Mode: Connected"
        }
        // set timer for handshake
        timer = Timer.scheduledTimer(withTimeInterval: handshakeInterval, repeats: false) { timer in
            self.isConnectionReady = false
            if self.isCentral {
                self.title = "Central Mode: Need HS"
            }
            else {
                self.title = "Peripheral Mode: Need HS"
            }
        }
    }
    
    func setImagetoSend(selectedImage: UIImage) {
        imageToSend = selectedImage
        imageData = imageToSend?.png
        sendDataIndex = 0
        
        // set MTU
        if !isCentral {
            NOTIFY_MTU = 176
        }
        
        let dataSize = "\(imageData!.count)".data(using: String.Encoding.utf8)
        printAndLog("Image Data size is \(imageData!.count)")
        sendMessage(payload: dataSize!, action: .sendImageStart, control: .none)
        
        //create local messageItem
        let thatChat =  MessageItem(body:"Will Send Image. Size is \(imageData!.count)" as NSString, user:me, date:Date(), mtype:ChatType.mine)
        let thatChat2 =  MessageItem(image:imageToSend!, user:me, date:Date(), mtype:ChatType.mine)
        
        // add new chat bubble to tableview
        Chats.add(thatChat)
        Chats.add(thatChat2)
        self.tableView.chatDataSource = self
        self.tableView.reloadData()
    }
    
    func sendTakingPhotoMessage() {
        printAndLog("Take a Photo")
        let data = "photo".data(using: String.Encoding.utf8)
        sendMessage(payload: data!, action: .takePhoto, control: .none)
        
        //create local messageItem
        let thatChat =  MessageItem(body:"[Will launch the camera and take photo]" as NSString, user:me, date:Date(), mtype:ChatType.mine)
        
        // add new chat bubble to tableview
        Chats.add(thatChat)
        self.tableView.chatDataSource = self
        self.tableView.reloadData()
    }
    
    func sendDownloadImageMessage(urlStr: String) {
        printAndLog("Download a Image")
        let data = urlStr.data(using: String.Encoding.utf8)
        sendMessage(payload: data!, action: .downloadImage, control: .none)
        
        //create local messageItem
        let thatChat =  MessageItem(body:"[Will download and save the image]" as NSString, user:me, date:Date(), mtype:ChatType.mine)
        
        // add new chat bubble to tableview
        Chats.add(thatChat)
        self.tableView.chatDataSource = self
        self.tableView.reloadData()
    }
    
    /** Convert UIImage to a base64 representation
     */
    func convertImageToBase64(image: UIImage) -> String {
        let imageData = image.pngData()!
        return imageData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
    }
    
    /** Convert a base64 representation to a UIImage
     */
    func convertBase64ToImage(imageString: String) -> UIImage {
        let imageData = Data(base64Encoded: imageString, options: Data.Base64DecodingOptions.ignoreUnknownCharacters)!
        return UIImage(data: imageData)!
    }
    
    func addNotification(title: String, subtitle: String, body: String) {
        self.badge += 1
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.badge = NSNumber(value: self.badge)
        content.sound = UNNotificationSound.default // set the default tri-tone
        let tigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "tianli.request", content: content, trigger: tigger)
        UNUserNotificationCenter.current().add(request) { (error) in
            if error == nil{
                print("Time Interval Notification scheduled: \\\\(requestIdentifier)")
            }
        }
    }
    
    func reload(tableView: UITableView) {
        let contentOffset = tableView.contentOffset
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableView.setContentOffset(contentOffset, animated: false)
    }
    
    func printAndLog(_ thisLog: String) {
        //获取当前时间
        let now = Date()
        
        // 创建一个日期格式器
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy/MM/dd  HH:mm:ss.SSSS"
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
            print("Unknown")
        case .resetting:
            print("Resetting")
        case .unsupported:
            print("Unsupported")
        case .unauthorized:
            print("Unauthorized")
        case .poweredOff:
            print("PowerOff")
        case .poweredOn:
            print("PowerOn")
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
        print("Connection succeed")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Connection Fail")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Discoonnect")
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
        print("Write Value")
    }
    
}

extension ChatViewController: CBPeripheralManagerDelegate {
    
    // 蓝牙状态
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            print("Uknwon")
        case .resetting:
            print("Resetting")
        case .unsupported:
            print("Unsupported")
        case .unauthorized:
            print("Unauthorized")
        case .poweredOff:
            print("PowerOff")
        case .poweredOn:
            print("Power On")
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
    
    /** This callback comes in when the PeripheralManager is ready to send the next chunk of data.
     *  This is to ensure that packets will arrive in the order they are sent
     */
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // Start sending again
        //sendData()
    }
    
}
