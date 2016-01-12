//
//  YoutubeClient.swift
//  Playlist Sync
//
//  Created by Benjamin Congdon on 1/11/16.
//  Copyright © 2016 Benjamin Congdon. All rights reserved.
//

import Cocoa
import Python

class YoutubeClient: NSObject {

    
    var options:NSMutableDictionary
    var authenticated:Bool = false

    
    override init(){
        //Initializes Client
        options = NSMutableDictionary()
        super.init()
    }
    
    //Tries to authenticate with cookie
    func authenticate() -> Bool{
        return false
    }
    
    func authenticate(username:String, password: String, twoFA:String) -> Bool{
        options.setValue(username, forKey: " -u")
        options.setValue(password, forKey: " -p")
        options.setValue(twoFA, forKey: " -2")
        return false
    }
    
    //Runs YoutubeDL with current options and returns output
    func runYoutubeDL(){
        print("calling")
        let task = NSTask()
        let filePath = NSBundle.mainBundle().pathForResource("Authenticate", ofType: "py")! as String
        task.launchPath = filePath
        //task.arguments = [filePath]
        task.standardOutput = NSPipe()
        task.launch()
        task.waitUntilExit()
        let response = task.standardOutput?.fileHandleForReading.readDataToEndOfFile()
        let str = NSString(data: response!, encoding: NSUTF8StringEncoding)!
        print(str)
    }
    
    func readCompleted(notification:NSNotification){
        print("log")
        print(notification.valueForKey(NSFileHandleNotificationDataItem))
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func clearCookies(){
        
    }
    
    static func validCookie() -> Bool {
        return false
        //FIXME
    }
    
}
