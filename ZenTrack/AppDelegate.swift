//
//  AppDelegate.swift
//  ZenTrack
//
//  Created by Supratim on 2019-11-12.
//  Copyright © 2019 Supratim Chakraborty. All rights reserved.
//

import Cocoa
import SwiftUI
import AppKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var mainWindow: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let contentView = ContentView()
        mainWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered, defer: false)
        mainWindow.center()
        mainWindow.setFrameAutosaveName("Main Window")
        mainWindow.contentView = NSHostingView(rootView: contentView)
        mainWindow.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

