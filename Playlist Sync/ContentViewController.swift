//
//  ContentViewController.swift
//  Playlist Sync
//
//  Created by Benjamin Congdon on 1/11/16.
//  Copyright © 2016 Benjamin Congdon. All rights reserved.
//

import Cocoa

class ContentViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    var playlists = Array<Playlist>()
    
    @IBAction func syncPressed(sender: NSButton) {
        data.append("x")
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
    
    var data = ["test","1","2","3"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.onPlaylistsChanged(nil)

        //Receive notifications from Preferences that playlist list has changed
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onPlaylistsChanged:", name: "playlistsChanged", object: nil)
        
    }
    
    func onPlaylistsChanged(notification:NSNotification?){
        NSUserDefaults.standardUserDefaults().synchronize()
        if let storedPlaylistData = NSUserDefaults.standardUserDefaults().dataForKey("playlists"){
            if let decodedPlaylists = NSKeyedUnarchiver.unarchiveObjectWithData(storedPlaylistData) as? Array<Playlist> {
                playlists = decodedPlaylists
                tableView.reloadData()
            }
        }
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn?.identifier == "playlist"{
            let cellView = tableView.makeViewWithIdentifier("playlist", owner: self) as! NSTableCellView
            cellView.textField?.stringValue = self.playlists[row].title
            return cellView
        }
        else {
            let imgView = tableView.makeViewWithIdentifier("status", owner: self) as! NSTableCellView
            imgView.imageView?.image = NSImage(named: "cog")
            return imgView
        }
    }
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return playlists.count
    }

}
