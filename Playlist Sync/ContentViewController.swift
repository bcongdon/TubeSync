//
//  ContentViewController.swift
//  Playlist Sync
//
//  Created by Benjamin Congdon on 1/11/16.
//  Copyright © 2016 Benjamin Congdon. All rights reserved.
//

import Cocoa

class ContentViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    var delegate:AppDelegate?
    
    @IBOutlet weak var downloadProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var spinningActivityIndicator: NSProgressIndicator!
    @IBOutlet weak var lastSyncLabel: NSTextField!
    @IBOutlet weak var downloadProgressTextField: NSTextField!
    @IBOutlet weak var downloadingStaticLabel: NSTextField!
    @IBAction func syncPressed(sender: NSButton) {
        
        delegate?.syncTimerFired()
        
        tableView.reloadData()
        
    }
    
    @IBAction func goToPreferences(sender: AnyObject) {
//        let menu = NSMenu(title: "Sync")
//        menu.insertItem(NSMenuItem(title: "Test", action: "preferences", keyEquivalent: ""), atIndex: 0)
//        NSMenu.popUpContextMenu(menu, withEvent: NSApplication.sharedApplication().currentEvent!, forView: self.view)
        preferences()
    }
    
    func preferences(){
        let delegate:AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        delegate.openPreferences()
    }
    
    @IBOutlet weak var tableView: NSTableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = (NSApp.delegate as! AppDelegate)
        
        self.onPlaylistsChanged(nil)
        
        print(self.delegate!.playlists)
        tableView.reloadData()


        //Receive notifications from Preferences that playlist list has changed
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onPlaylistsChanged:", name: PlaylistListUpdate, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onDownloadUpdate:", name: PlaylistDownloadProgressNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onSyncStart:", name: SyncInitiatedNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onSyncEnd:", name: SyncCompletionNotification, object: nil)
        
    }
    
    func onSyncStart(notification:NSNotification){
        print("starting")
        lastSyncLabel.stringValue = "In progress..."
        spinningActivityIndicator.startAnimation(self)
        downloadingStaticLabel.hidden = false
        downloadProgressIndicator.hidden = false
        spinningActivityIndicator.hidden = false
    }
    
    func onSyncEnd(notification:NSNotification){
        print("ending")
        lastSyncLabel.stringValue = NSDate().description
        spinningActivityIndicator.stopAnimation(self)
        downloadProgressTextField.stringValue = ""
        downloadingStaticLabel.hidden = true
        downloadProgressIndicator.hidden = true
        spinningActivityIndicator.hidden = true
    }
    
    func onDownloadUpdate(notification:NSNotification){
        if let playlist = notification.object as? Playlist{
            print(playlist.entries.count, playlist.progress!)

            downloadProgressIndicator.maxValue = Double(playlist.entries.count)
            downloadProgressIndicator.doubleValue = Double(playlist.progress!)
            
            downloadProgressTextField.stringValue = "\(playlist.title) (\(playlist.progress!) of \(playlist.entries.count))"
        }
    }
    
    func onPlaylistsChanged(notification:NSNotification?){
        tableView.reloadData()
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let delegate = self.delegate {
            if tableColumn?.identifier == "playlist"{
                let cellView = tableView.makeViewWithIdentifier("playlist", owner: self) as! NSTableCellView
                cellView.textField?.stringValue = delegate.playlists[row].title
                return cellView
            }
            else {
                let imgView = tableView.makeViewWithIdentifier("status", owner: self) as! NSTableCellView
                imgView.imageView?.image = NSImage(named: "cog")
                return imgView
            }
        }
        return NSView()
    }
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        if let delegate = self.delegate{
            return delegate.playlists.count
        }
        return 0
    }

}
