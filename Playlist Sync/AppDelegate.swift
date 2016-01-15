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

    @IBOutlet weak var prefViewController: PreferencesViewController!
    @IBOutlet weak var window:NSWindow!
    @IBOutlet weak var rightClickMenu:NSMenu!
    
    let statusItem:NSStatusItem
    let popover:NSPopover
    var popoverMonitor:AnyObject?
    var preferencesWindowController:PreferencesWindowController
    let youtubeClient:YoutubeClient
    let dummyControl = DummyControl()
    internal private(set) var timer = NSTimer()
    internal private(set) var interval:Double? = nil
    
    override init(){
        //Initialize and try to authenticate Youtube Client
        youtubeClient = YoutubeClient()
        self.youtubeClient.authenticate()
        
        self.interval = NSUserDefaults.standardUserDefaults().doubleForKey("syncFrequency")
        
        
        popover = NSPopover()
        popover.contentViewController = ContentViewController(nibName:"ContentViewController",bundle:nil)
        statusItem =  NSStatusBar.systemStatusBar().statusItemWithLength(24)
        preferencesWindowController = PreferencesWindowController(windowNibName: "Preferences")
        super.init()
        
        
        setupStatusButton()
        NSApplication.sharedApplication().delegate = self
    }
    
    
    func openPreferences(){
        if(popover.shown){
            closePopover()
        }
        self.window.makeKeyAndOrderFront(self)
        NSApp.activateIgnoringOtherApps(true)
        self.window.makeKeyWindow()
    }
    
    func setupStatusButton(){
        if let statusButton = statusItem.button {
            statusButton.image = NSImage(named: "youtube")
            
            dummyControl.frame = statusButton.bounds
            statusButton.addSubview(dummyControl)
            statusButton.superview!.subviews = [statusButton, dummyControl]
            dummyControl.action = "onPress:"
            dummyControl.target = self
        }
    }
    
    func onPress(sender: AnyObject){
        if dummyControl.currentClickIsLeft {
            if popover.shown == false{
                openPopover()
            }
            else{
                closePopover()
            }
        }
        else{
            statusItem.popUpStatusItemMenu(rightClickMenu)
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

    @IBAction func aboutClicked(sender: AnyObject) {
        prefViewController.switchToAbout()
        openPreferences()
    }
    
    @IBAction func preferencesClicked(sender: AnyObject) {
        openPreferences()
    }
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        self.prefViewController.setupFreqUI(self.interval)

    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func setSyncInterval(seconds:Double){
        if let currInterval = self.interval{
            if currInterval == seconds{
                return
            }
        }
        self.interval = seconds
        if let newInterval = self.interval {
            NSUserDefaults.standardUserDefaults().setDouble(newInterval, forKey: "syncFrequency")
        }
        if(timer.valid){
            disableTimer()
            enableTimer()
        }
    }
    
    func enableTimer(){
        if let seconds = self.interval{
            timer = NSTimer.scheduledTimerWithTimeInterval(seconds, target: self, selector: "syncTimerFired", userInfo: nil, repeats: true)
        }
    }
    
    func disableTimer(){
        timer.invalidate()
    }

    func syncTimerFired(){
        //TODO: Sync when timer fires
        
    }

}

