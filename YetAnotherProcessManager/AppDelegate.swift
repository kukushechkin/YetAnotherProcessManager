//
//  AppDelegate.swift
//  YetAnotherProcessManager
//
//  Created by Vladimir Kukushkin on 3/20/18.
//  Copyright © 2018 kukushechkin. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var arrayController: NSArrayController!
    @IBOutlet weak var processManager: ProcessManager!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func killProcess(_ sender: NSView) {
        for case let process as Process in arrayController.selectedObjects {
            // TODO: default selection should not exist or be highlighted in table view
            print("another selected object with pid: \(process.pid)");
            processManager.killProcess(withPid: pid_t(process.pid))
        }
    }

}

