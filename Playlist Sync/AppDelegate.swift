//
//  AppDelegate.swift
//  Playlist Sync
//
//  Created by Benjamin Congdon on 1/10/16.
//  Copyright © 2016 Benjamin Congdon. All rights reserved.
//

import Cocoa
import CocoaLumberjack

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {

    @IBOutlet weak var preferencesViewController: PreferencesViewController!
    @IBOutlet weak var window:NSWindow!
    @IBOutlet weak var rightClickMenu:NSMenu!
    
    let statusItem:NSStatusItem
    let popover:NSPopover
    var popoverMonitor:AnyObject?
    var preferencesWindowController:PreferencesWindowController
    let youtubeClient:YoutubeClient
    var syncHelper = SyncHelper(outputDir:"")
    let dummyControl = DummyControl()
    var syncActive = false
    
    internal private(set) var timer = NSTimer()
    internal private(set) var interval:Double? = nil
    
    internal var playlists:Array<Playlist> = fetchPlaylistsFromDefaults()
    
    override init(){
        
        DDLog.addLogger(DDTTYLogger.sharedInstance()) // TTY = Xcode console
        DDLog.addLogger(DDASLLogger.sharedInstance()) // ASL = Apple System Logs
        
        //Setup Loggers (from CocoaLumberjack)
        let fileLogger: DDFileLogger = DDFileLogger() // File Logger
        fileLogger.rollingFrequency = 60*60*24  // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.addLogger(fileLogger)
        
        //Initialize and try to authenticate Youtube Client
        youtubeClient = YoutubeClient.defaultClient
        youtubeClient.authenticate()
        
        
        self.interval = NSUserDefaults.standardUserDefaults().doubleForKey("syncFrequency")
        
        popover = NSPopover()
        popover.contentViewController = ContentViewController(nibName:"ContentViewController",bundle:nil)
        statusItem =  NSStatusBar.systemStatusBar().statusItemWithLength(24)
        preferencesWindowController = PreferencesWindowController(windowNibName: "Preferences")
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playlistUpdate:", name: PlaylistFileDownloadedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playlistUpdate:", name: PlaylistListUpdate, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onSyncCompletion:", name: SyncCompletionNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onSyncStart:", name: SyncInitiatedNotification, object: nil)
        
        setupStatusButton()
        NSApplication.sharedApplication().delegate = self
    }
    
    func onSyncCompletion(notification:NSNotification){
        syncActive = false
        for playlist in self.playlists {
            youtubeClient.deleteStaleFiles(playlist, path: self.syncHelper.outputDir)
        }
    }
    
    func onSyncStart(notification:NSNotification){
        syncActive = true
    }
    
    func playlistUpdate(notification:NSNotification){
        writePlaylistsToDefaults()
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
        preferencesViewController.switchToAbout()
        openPreferences()
    }
    
    @IBAction func preferencesClicked(sender: AnyObject) {
        openPreferences()
    }
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        self.preferencesViewController.setupFreqUI(self.interval)
        self.enableTimer()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
        //Sync @ termination w/ UserDefaults
        writePlaylistsToDefaults()
    }
    
    func writePlaylistsToDefaults(){
        let playlistData = NSKeyedArchiver.archivedDataWithRootObject(playlists)
        NSUserDefaults.standardUserDefaults().setObject(playlistData, forKey: "playlists")
        NSUserDefaults.standardUserDefaults().synchronize()
        print("Wrote playlists to user defaults")
        DDLogInfo("Writing playlist data to user defaults.")
    }

    func setSyncInterval(seconds:Double){
        if let currInterval = self.interval{
            if currInterval == seconds{
                return
            }
        }
        self.interval = seconds
        print(self.interval)
        DDLogInfo("Setting Sync interval to \(self.interval)")
        if let newInterval = self.interval {
            NSUserDefaults.standardUserDefaults().setDouble(newInterval, forKey: "syncFrequency")
        }
        if(timer.valid){
            disableTimer()
            enableTimer()
        }
    }
    
    func setSyncEnabled(shouldBeOn:Bool){
        NSUserDefaults.standardUserDefaults().setValue(shouldBeOn, forKey: "syncEnabled")
        NSUserDefaults.standardUserDefaults().synchronize()
        preferencesViewController.syncEnabledButton.state = shouldBeOn ? NSOnState : NSOffState
        
        if shouldBeOn {
            enableTimer()
        }
        else{
            disableTimer()
            if self.syncActive{
                syncHelper.haltSync()
            }
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
        DDLogInfo("Initiating Sync")
        if(playlists.count == 0){
            return
        }
        if let outputDir = NSUserDefaults.standardUserDefaults().URLForKey("OutputDirectory"){
            syncHelper = SyncHelper(outputDir: outputDir.path!)
            dispatch_async(GlobalBackgroundQueue){
                self.syncHelper.syncPlaylists(self.playlists)
            }
        }
        NSNotificationCenter.defaultCenter().postNotificationName(SyncInitiatedNotification, object: nil)
    }

}

