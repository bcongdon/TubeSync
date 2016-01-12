//
//  AppDelegate.swift
//  Playlist Sync
//
//  Created by Benjamin Congdon on 1/10/16.
//  Copyright © 2016 Benjamin Congdon. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {

    @IBOutlet weak var window:NSWindow!
    
    let statusItem:NSStatusItem
    let popover:NSPopover
    var popoverMonitor:AnyObject?
    var preferencesWindowController:PreferencesWindowController
    
    override init(){
        popover = NSPopover()
        popover.contentViewController = ContentViewController(nibName:"ContentViewController",bundle:nil)
        statusItem =  NSStatusBar.systemStatusBar().statusItemWithLength(24)
        preferencesWindowController = PreferencesWindowController(windowNibName: "Preferences")
        super.init()
        setupStatusButton()
        NSApplication.sharedApplication().delegate = self
    }
    
    func openPreferences(){
        closePopover()
        self.window.orderFront(self)
    }
    
    func setupStatusButton(){
        if let statusButton = statusItem.button {
            statusButton.image = NSImage(named: "youtube")
            
            let dummyControl = DummyControl()
            dummyControl.frame = statusButton.bounds
            statusButton.addSubview(dummyControl)
            statusButton.superview!.subviews = [statusButton, dummyControl]
            dummyControl.action = "onPress:"
            dummyControl.target = self
        }
    }
    
    func onPress(sender: AnyObject){
        if popover.shown == false{
            openPopover()
        }
        else{
            closePopover()
        }
    }
    
    func openPopover(){
        if let statusButton = statusItem.button{
            statusButton.highlight(true)
            popover.showRelativeToRect(NSZeroRect, ofView: statusButton, preferredEdge: NSRectEdge.MinY)
            popoverMonitor = NSEvent.addGlobalMonitorForEventsMatchingMask(.LeftMouseDownMask, handler: { (event:NSEvent!) -> Void in self.closePopover()})
            
        }
    }
    func closePopover(){
        popover.close()
        if let statusButton = statusItem.button{
            statusButton.highlight(false)
        }
        if let monitor : AnyObject = popoverMonitor {
            NSEvent.removeMonitor(monitor)
            popoverMonitor = nil
        }
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your applicatio
        let client = YoutubeClient()
        client.runYoutubeDL()
        
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

