//
//  Header.swift
//  bleproject
//
//  Created by Tianli Feng on 4/14/19.
//  Copyright © 2019 Tianli Feng. All rights reserved.
//

import Foundation

struct Header {
    let seq_num: UInt16
    let ack_num: UInt16
    let hlenCtrlByte: HlenCtrlByte
    let action: UInt8
}

struct HlenCtrlByte: OptionSet {
    let rawValue: UInt8
    
    static let hlen1 = HlenCtrlByte(rawValue: 1 << 7)
    static let hlen2 = HlenCtrlByte(rawValue: 1 << 6)
    static let hlen3 = HlenCtrlByte(rawValue: 1 << 5)
    static let hlen4 = HlenCtrlByte(rawValue: 1 << 4)
    static let ack = HlenCtrlByte(rawValue: 1 << 3)
    static let rst = HlenCtrlByte(rawValue: 1 << 2)
    static let syn = HlenCtrlByte(rawValue: 1 << 1)
    static let fin = HlenCtrlByte(rawValue: 1 << 0)
    
    static func getHeaderLength(hlenCtrlByte: HlenCtrlByte) -> UInt8 {
        var headerLength: UInt8 = 0;
        if hlenCtrlByte.contains(.hlen1) {
            headerLength += 8
        }
        if hlenCtrlByte.contains(.hlen2) {
            headerLength += 4
        }
        if hlenCtrlByte.contains(.hlen3) {
            headerLength += 2
        }
        if hlenCtrlByte.contains(.hlen4) {
            headerLength += 1
        }
        
        return headerLength
    }
}

struct Message {
    let header: Header
    let payload: Data
    
    struct ArchivedHeader {
        let seq_num: UInt16
        let ack_num: UInt16
        let hlenCtrl: UInt8
        let action: UInt8
    }
    
    func archive() -> Data {
        
        var archivedHeader = ArchivedHeader(seq_num: self.header.seq_num, ack_num: self.header.ack_num, hlenCtrl: self.header.hlenCtrlByte.rawValue, action: self.header.action)
        
        var archivedData = Data(
            bytes: &archivedHeader,
            count: MemoryLayout.size(ofValue: archivedHeader)
        )
        
        archivedData.append(payload)
        
        return archivedData
    }
    
    static func unarchive(data: Data!) -> Message {
        
        let seq_numData = data.subdata(in: 0 ..< 2)
        let ack_numData = data.subdata(in: 2 ..< 4)
        let hlenCtrlData = data.subdata(in: 4 ..< 5)
        let actionData = data.subdata(in: 5 ..< 6)
        
        let hlenCtrlByte = HlenCtrlByte(rawValue: hlenCtrlData.uint8)
        let headerLength = HlenCtrlByte.getHeaderLength(hlenCtrlByte: hlenCtrlByte)
        
        let payloadData = data.subdata(in: Data.Index(headerLength) ..< data.count)
        
        let header = Header(seq_num: seq_numData.uint16, ack_num: ack_numData.uint16, hlenCtrlByte: hlenCtrlByte, action: actionData.uint8)
        let message = Message(header: header, payload: payloadData)
        
        return message
    }
}

extension Data {
    var integer: Int {
        return withUnsafeBytes { $0.pointee }
    }
    var uint8: UInt8 {
        return withUnsafeBytes { $0.pointee }
    }
    var uint16: UInt16 {
        return withUnsafeBytes { $0.pointee }
    }
    var string: String? {
        return String(data: self, encoding: .utf8)
    }
}
