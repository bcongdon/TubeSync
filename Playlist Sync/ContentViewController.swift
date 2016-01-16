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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onPlaylistsChanged:", name: "playlistsChanged", object: nil)
        
    }
    
    func onPlaylistsChanged(notification:NSNotification?){
//        NSUserDefaults.standardUserDefaults().synchronize()
//        if let storedPlaylistData = NSUserDefaults.standardUserDefaults().dataForKey("playlists"){
//            if let decodedPlaylists = NSKeyedUnarchiver.unarchiveObjectWithData(storedPlaylistData) as? Array<Playlist> {
//                playlists = decodedPlaylists
//                tableView.reloadData()
//            }
//        }
        //print(playlists)
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
