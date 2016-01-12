//
//  PreferencesViewController.swift
//  Playlist Sync
//
//  Created by Benjamin Congdon on 1/11/16.
//  Copyright © 2016 Benjamin Congdon. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    
    @IBOutlet weak var syncFrequency: NSPopUpButtonCell!
    @IBOutlet weak var syncEnabledButton: NSButton!
    @IBOutlet weak var usernameField: NSTextFieldCell!
    @IBOutlet weak var passwordField: NSView!
    @IBOutlet weak var outputDirTextField: NSTextField!
    
    var outputDir:NSURL
    
    override init(nibName: String?, bundle: NSBundle?){
        outputDir = NSURL()
        super.init(nibName: nibName, bundle: bundle)!
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func onChangeEnabled(sender: NSButton) {
        let state = (sender.state == NSOnState)
        NSUserDefaults.standardUserDefaults().setValue(state, forKey: "syncEnabled")
        NSUserDefaults.standardUserDefaults().synchronize()
        //TODO: Probably need to call something to tell it to enable/disable
        
    }
    
    func getURL() -> NSURL{
        let panel:NSOpenPanel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() != NSModalResponseOK {return NSURL()}
        return(panel.URLs.last)!
    }
    
    @IBAction func promptNewOutputDir(sender: AnyObject) {
        outputDir = getURL()
        outputDirTextField.stringValue = outputDir.path!
    }
    
    @IBAction func onSubmitCredentials(sender: AnyObject) {
        print("Click!")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return nil
        //TODO: Display list of playlists
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return 0
        //TODO: Return number of playlists
    }
    
}
