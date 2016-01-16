//
//  PreferencesViewController.swift
//  Playlist Sync
//
//  Created by Benjamin Congdon on 1/11/16.
//  Copyright © 2016 Benjamin Congdon. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate {

    
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var syncFrequency: NSPopUpButton!
    @IBOutlet weak var syncFrequencyModifierField: NSTextFieldCell!
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
    @IBOutlet weak var playlistAddSpinningIndicator: NSProgressIndicator!
    @IBOutlet weak var mainMenu: NSMenu!
    @IBOutlet weak var playlistTable: NSTableView!
    
    var outputDir:NSURL
    let delegate = (NSApp.delegate as! AppDelegate)
    
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
        alert.addButtonWithTitle("Add")
        alert.addButtonWithTitle("Cancel")
        let field = NSTextField(frame: NSMakeRect(0,0,200,24))
        field.cell!.scrollable = false
        field.cell!.wraps = false
        field.stringValue = ""
        alert.accessoryView = field
        alert.icon = NSImage(byReferencingFile: "youtube")
        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        let result = alert.runModal()
        //'Add' Pressed
        if result == NSAlertFirstButtonReturn {
            guard let url = NSURL(string: field.stringValue)
                else{
                    print("Error converting \(field.stringValue) to NSURL")
                    alertForInvalidPlaylist(YoutubeResponse.InvalidPlaylist)
                    return
            }
            //Check to make sure the new playlist isn't already being tracked
            for playlist in self.delegate.playlists{
                if url.absoluteString.rangeOfString(playlist.url) != nil {
                    alertForInvalidPlaylist(YoutubeResponse.DuplicatePlaylist)
                    return
                }
            }
            self.playlistAddSpinningIndicator.startAnimation(self)
            dispatch_async(GlobalMainQueue){
                let response = YoutubeClient.defaultClient.isValidPlaylist(url.absoluteString)
                if response == YoutubeResponse.ValidPlaylist{
                    let info = YoutubeClient.defaultClient.playlistInfo(url.absoluteString)
                    var entryDict = Dictionary<String,String>()
                    for entry in info.entries {
                        entryDict[entry] = ""
                    }
                    self.delegate.playlists.append(Playlist(url: url.description, title: info.title!,enabled:true,entries:entryDict))
                    self.playlistTable.reloadData()
                    self.synchronizePlaylistData()
                }
                else{
                    //Alert user to failed playlist lookup
                    self.alertForInvalidPlaylist(response)
                }
                self.playlistAddSpinningIndicator.stopAnimation(self)
            }
        }
    }
    
    @IBAction func deletePlaylist(sender: AnyObject){
        let row = playlistTable.selectedRow
        if row > -1 {
            
            //If in middle of sync, halt and restart sync
            if delegate.syncActive {
                delegate.syncHelper.haltSync()

                delegate.playlists.removeAtIndex(row)

                delegate.syncTimerFired()
            }
            else{
                delegate.playlists.removeAtIndex(row)
            }
            
            
            synchronizePlaylistData()
        }
    }
    
    func synchronizePlaylistData(){
        delegate.writePlaylistsToDefaults()
        NSNotificationCenter.defaultCenter().postNotificationName(PlaylistListUpdate, object: nil)
        self.playlistTable.reloadData()
    }
    
    @IBAction func playlistShouldSyncChanged(sender: NSTableView) {
        let row = sender.clickedRow
        self.delegate.playlists[row].enabled = !self.delegate.playlists[row].enabled
        synchronizePlaylistData()
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
        else if response == YoutubeResponse.NotPlaylist{
            alert.informativeText = "Specified URL does not reference a Youtube Playlist (perhaps it's a link to a video?)"
        }
        else if response == YoutubeResponse.DuplicatePlaylist {
            alert.informativeText = "Playlist is already being synced."
        }
        else{
            print("Error type not handled: ",response)
        }
        alert.runModal()
    }
    
    @IBAction func onChangeEnabled(sender: NSButton) {
        let state = (sender.state == NSOnState)
        delegate.setSyncEnabled(state)
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
        let directory = getURL()
        if directory.description != ""{
            outputDir = directory
            outputDirTextField.stringValue = outputDir.path!
        }
        NSUserDefaults.standardUserDefaults().setURL(outputDir, forKey: "OutputDirectory")
    }
        
    @IBAction func onSubmitCredentials(sender: AnyObject?) {
        let delegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let client = delegate.youtubeClient
        
        //Submit credentials
        if submitDisconnectButton.title == "Submit" {
            if client.authenticated {
                lockInAccount()
            }
            spinningStatusIndicator.startAnimation(self)

            dispatch_async(GlobalMainQueue){
                let response = client.authenticate(self.usernameField.stringValue, password: self.passwordField.stringValue, twoFA: self.twoFAField.stringValue)
                NSUserDefaults.standardUserDefaults().setObject(self.usernameField.stringValue, forKey: "accountName")
                if response == YoutubeResponse.AuthSuccess{
                    self.statusLabel.stringValue = "Account Linked"
                    self.lockInAccount()
                }
                else{
                    self.statusLabel.stringValue = "Authentication failure."
                }
                self.spinningStatusIndicator.stopAnimation(self)

            }
        }
        //Disconnect account
        else{
            NSUserDefaults.standardUserDefaults().removeObjectForKey("accountName")
            client.deauthenticate()
            unlockAccount()
        }
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
        playlistTable.reloadData()
        let delegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let client = delegate.youtubeClient
        if client.authenticated{
            lockInAccount()
            resetPasswordField()
            if let username = NSUserDefaults.standardUserDefaults().valueForKey("accountName"){
                usernameField.stringValue = username as! String
            }
            else{
                //Account name lost from NSUserDefaults
                usernameField.stringValue = "Account Linked"
            }
        }
        
        //Get current output directory
        if let directory = NSUserDefaults.standardUserDefaults().URLForKey("OutputDirectory") {
            outputDir = directory
        }
        else{
            outputDir = NSFileManager.defaultManager().URLsForDirectory(.MoviesDirectory, inDomains: .UserDomainMask).first! as NSURL
        }
        outputDirTextField.stringValue = outputDir.path!
        self.synchronizePlaylistData()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        //Status dissappears when view goes away
        statusLabel.stringValue = ""
        syncIntervalChanged()
    }

    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        let cell = tableColumn?.dataCell as! NSButtonCell
        cell.title = self.delegate.playlists[row].title
        cell.state = self.delegate.playlists[row].enabled! ? NSOnState : NSOffState
        return cell
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.delegate.playlists.count
    }
    
    func control(control: NSControl, textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool {
        if commandSelector == "insertNewline:" {
            onSubmitCredentials(self)
            return true
        }
        return false
    }
    
    @IBAction func syncMultiplierChanged(sender: AnyObject) {
        syncIntervalChanged()
    }
    
    @IBAction func syncUnitChanged(sender: AnyObject) {
        syncIntervalChanged()
    }
    
    func syncIntervalChanged(){
        let delegate = NSApp.delegate! as! AppDelegate
        var interval = syncFrequencyModifierField.doubleValue
        switch syncFrequency.indexOfSelectedItem{
        case 0:
            //Minutes
            interval *= SecondsInMinute
            break
        case 1:
            //Hours
            interval *= SecondsInHour
            break
        case 2:
            //Days
            interval *= SecondsInDay
            break
        default:
            //??
            break
        }
        print(interval)
        if interval <= 1 {
            syncFrequencyModifierField.stringValue = ""
            return
        }
        delegate.setSyncInterval(interval)
    }
    
    //TODO: Remove at some point
    func resetDefaults(){
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
        print("WARNING: Cleared NSUserDefaults")
    }
    func switchToAbout(){
        tabView.selectTabViewItemAtIndex(2)
    }
    func setupFreqUI(interval:Double?){
        var cleanInterval:Double = 0
        if let safeInterval = interval{
            if safeInterval / SecondsInDay >= 1 {
                syncFrequency.selectItemAtIndex(2)
                syncFrequencyModifierField.doubleValue = safeInterval / SecondsInDay
            }
            else if safeInterval / SecondsInHour >= 1 {
                syncFrequency.selectItemAtIndex(1)
                syncFrequencyModifierField.doubleValue = safeInterval / SecondsInHour
            }
            else {
                syncFrequency.selectItemAtIndex(0)
                syncFrequencyModifierField.doubleValue = safeInterval / SecondsInMinute
            }
            cleanInterval = safeInterval
        }
        if cleanInterval == 0 {
            //Setup defaults if interval sent by delegate is 0
            syncFrequency.selectItemAtIndex(1)
            syncFrequencyModifierField.doubleValue = 1
            self.syncIntervalChanged()
        }
    }
}
