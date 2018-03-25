//
//  Process.swift
//  YetAnotherProcessManager
//
//  Created by Vladimir Kukushkin on 3/20/18.
//  Copyright © 2018 kukushechkin. All rights reserved.
//

import Cocoa

@objc class Process: NSObject {
    @objc dynamic var pid: UInt = 0
    @objc dynamic var name: String = ""
    @objc dynamic var uid: UInt = 0
    
    @objc init(pid: UInt, name: String, andUid uid: UInt) {
        self.pid = pid
        self.name = name
        self.uid = uid
    }

    @objc init(pid: UInt) {
        self.pid = pid
        self.name = ""
    }
}
