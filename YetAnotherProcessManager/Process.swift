//
//  Process.swift
//  YetAnotherProcessManager
//
//  Created by Vladimir Kukushkin on 3/20/18.
//  Copyright © 2018 kukushechkin. All rights reserved.
//

import Cocoa

class Process: NSObject {
    @objc dynamic var pid: Int = 0
    @objc dynamic var name: String = ""
    
    override init() {
        self.pid = 42
        self.name = "a name"
    }
}
