//
//  Process.swift
//  YetAnotherProcessManager
//
//  Created by Vladimir Kukushkin on 3/20/18.
//  Copyright © 2018 kukushechkin. All rights reserved.
//

import Cocoa

@objc class Process: NSObject {
    @objc dynamic var pid: String = "0"
    @objc dynamic var name: String = ""
    
    @objc init(pid: Int, andName name: String) {
        self.pid = String(pid)
        self.name = name
    }

    @objc init(pid: Int) {
        self.pid = String(pid)
        self.name = ""
    }
}
