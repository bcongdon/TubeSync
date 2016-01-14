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


    
    override init(){
        //Initialize and try to authenticate Youtube Client
        youtubeClient = YoutubeClient()
        self.youtubeClient.authenticate()
        
        popover = NSPopover()
        popover.contentViewController = ContentViewController(nibName:"ContentViewController",bundle:nil)
        statusItem =  NSStatusBar.systemStatusBar().statusItemWithLength(24)
        preferencesWindowController = PreferencesWindowController(windowNibName: "Preferences")
        super.init()
        
        dispatch_async(GlobalMainQueue,{
            print(self.youtubeClient.isValidPlaylist("https://www.youtube.com/watch?v=5jDiqeoh8no"))
            self.youtubeClient.downloadVideo("https://www.youtube.com/watch?v=0i-9D92bzu8", path: "/Users/bencongdon/Documents")
        })
        setupStatusButton()
        NSApplication.sharedApplication().delegate = self
        
    }
    
    func openPreferences(){
        if(popover.shown){
            closePopover()
        }
        self.window.makeKeyAndOrderFront(self)
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
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

