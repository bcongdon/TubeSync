//
//  PreferencesViewController.swift
//  Playlist Sync
//
//  Created by Benjamin Congdon on 1/11/16.
//  Copyright © 2016 Benjamin Congdon. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate {

    
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var syncFrequency: NSPopUpButtonCell!
    @IBOutlet weak var syncEnabledButton: NSButton!
    @IBOutlet weak var usernameField: NSTextFieldCell!
    @IBOutlet weak var passwordField: NSSecureTextField!
    @IBOutlet weak var outputDirTextField: NSTextField!
    @IBOutlet weak var twoFAField: NSTextField!
    @IBOutlet weak var submitDisconnectButton: NSButton!
    @IBOutlet weak var usernameLabel: NSTextField!
    @IBOutlet weak var passwordLabel: NSTextField!
    @IBOutlet weak var twoFALabel: NSTextField!
    @IBOutlet weak var spinningStatusIndicator: NSProgressIndicator!
    @IBOutlet weak var mainMenu: NSMenu!
    @IBOutlet weak var playlistTable: NSTableView!
    
    var outputDir:NSURL
    var playlists:Array<NSURL> = [NSURL(string: "watchlater")!]
    var playlistButtons = Array<NSButtonCell>()
    
    override init(nibName: String?, bundle: NSBundle?){
        outputDir = NSURL()
        NSApp.mainMenu = mainMenu
        super.init(nibName: nibName, bundle: bundle)!
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func newPlaylist(sender: AnyObject) {
        let alert = NSAlert()
        alert.messageText = "Add new playlist:"
        alert.informativeText = "Enter the URL of a valid Youtube playlist."
        alert.addButtonWithTitle("Cancel")
        alert.addButtonWithTitle("Add")
        let field = NSTextField(frame: NSMakeRect(0,0,200,24))
        field.cell!.scrollable = false
        field.cell!.wraps = false
        field.stringValue = ""
        alert.accessoryView = field
        alert.icon = NSImage(byReferencingFile: "youtube")
        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        let result = alert.runModal()
        //'Add' Pressed
        if result == NSAlertSecondButtonReturn {
            guard let url = NSURL(string: field.stringValue)
                else{
                    print("Error converting \(field.stringValue) to NSURL")
                    alertForInvalidPlaylist(YoutubeResponse.InvalidPlaylist)
                    return
            }
            let response = YoutubeClient().isValidPlaylist(url.absoluteString)
            if response == YoutubeResponse.ValidPlaylist{
                playlists.append(url)
                playlistTable.reloadData()
            }
            else{
                //Alert user to failed playlist lookup
                alertForInvalidPlaylist(response)
            }
        }
    }
    
    @IBAction func playlistShouldSyncChanged(sender: NSTableView) {
        let row = sender.clickedRow
        let cell = playlistButtons[row]
        cell.state = (cell.state == NSOnState) ? NSOffState : NSOnState
    }
    
    func alertForInvalidPlaylist(response:YoutubeResponse){
        let alert = NSAlert()
        alert.messageText = "Unable to add new playlist!"
        alert.addButtonWithTitle("OK")
        alert.alertStyle = NSAlertStyle.CriticalAlertStyle
        if response == YoutubeResponse.NeedCredentials {
            alert.informativeText = "Could not find playlist, or need Google credentials to access (Private Playlist)."
        }
        else if response == YoutubeResponse.InvalidPlaylist{
            alert.informativeText = "Playlist URL is invalid."
        }
        alert.runModal()
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
        NSUserDefaults.standardUserDefaults().setURL(outputDir, forKey: "OutputDirectory")
    }
        
    @IBAction func onSubmitCredentials(sender: AnyObject?) {
        spinningStatusIndicator.startAnimation(self)
        let delegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let client = delegate.youtubeClient
        
        //Submit credentials
        if submitDisconnectButton.title == "Submit" {
            if client.authenticated {
                lockInAccount()
            }
            let response = client.authenticate(usernameField.stringValue, password: passwordField.stringValue, twoFA: twoFAField.stringValue)
            NSUserDefaults.standardUserDefaults().setObject(usernameField.stringValue, forKey: "accountName")
            if response == YoutubeResponse.AuthSuccess{
                statusLabel.stringValue = "Account Linked"
                lockInAccount()
            }
            else{
                statusLabel.stringValue = "Authentication failure."
            }
        }
        //Disconnect account
        else{
            NSUserDefaults.standardUserDefaults().removeObjectForKey("accountName")
            client.deauthenticate()
            unlockAccount()
        }
        spinningStatusIndicator.stopAnimation(self)
    }
    
    func lockInAccount(){
        resetPasswordField()
        passwordField.enabled = false
        usernameField.enabled = false
        twoFAField.enabled = false
        twoFAField.stringValue = ""
        submitDisconnectButton.title = "Disconnect"
        usernameLabel.textColor = NSColor.disabledControlTextColor()
        passwordLabel.textColor = NSColor.disabledControlTextColor()
        twoFALabel.textColor = NSColor.disabledControlTextColor()
    }
    
    func unlockAccount(){
        passwordField.enabled = true
        passwordField.stringValue = ""
        usernameField.enabled = true
        usernameField.stringValue = ""
        twoFAField.enabled = true
        twoFAField.stringValue = ""
        submitDisconnectButton.title = "Submit"
        usernameLabel.textColor = NSColor.controlTextColor()
        passwordLabel.textColor = NSColor.controlTextColor()
        twoFALabel.textColor = NSColor.controlTextColor()
        statusLabel.stringValue = "Account unlinked."
    }
    
    func resetPasswordField(){
        passwordField.stringValue = "**********"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let delegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let client = delegate.youtubeClient
        if client.authenticated{
            lockInAccount()
            resetPasswordField()
            if let username = NSUserDefaults.standardUserDefaults().valueForKey("accountName"){
                usernameField.stringValue = username as! String
            }
        }
        
        if let outputDir = NSUserDefaults.standardUserDefaults().URLForKey("OutputDirectory") {
            outputDirTextField.stringValue = outputDir.path!
        }
        
        if let storedPlaylists = NSUserDefaults.standardUserDefaults().arrayForKey("playlists"){
            playlists = storedPlaylists as! Array<NSURL>
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        //Status dissappears when view goes away
        statusLabel.stringValue = ""
    }

    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        let cell = tableColumn?.dataCell as! NSButtonCell
        cell.title = playlists[row].absoluteString
        playlistButtons.insert(cell, atIndex: row)
        return cell
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return playlists.count
    }
    
    func control(control: NSControl, textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool {
        if commandSelector == "insertNewline:" {
            onSubmitCredentials(self)
            return true
        }
        return false
    }
    
}
