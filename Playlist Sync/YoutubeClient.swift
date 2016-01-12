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
    func authenticate() -> YoutubeResponse{
        return authYoutubeDL([])
    }
    
    //Tries to authenticate with username + password + (optional) 2fa key
    func authenticate(username:String, password: String, twoFA:String) -> YoutubeResponse{
        return authYoutubeDL([username, password, twoFA])
    }
    
    //Runs YoutubeDL with current options and returns output
    private func authYoutubeDL(options:Array<String>) -> YoutubeResponse{
        let task = NSTask()
        task.launchPath = NSBundle.mainBundle().pathForResource("Authenticate", ofType: "py")! as String
        task.arguments = options
        print(options)
        let out = NSPipe()
        task.standardError = out
        task.launch()
        task.waitUntilExit()
        let response = out.fileHandleForReading.readDataToEndOfFile()
        let str = NSString(data: response, encoding: NSUTF8StringEncoding)!
        
        //No credentials provided
        if str.containsString("The playlist doesn't exist or is private, use --username or --netrc"){
            return YoutubeResponse.NeedCredentials
        }
        //Credential check failed
        else if str.containsString("Please use your account password"){
            return YoutubeResponse.IncorrectCredentials
        }
        //Able to login
        else{
            authenticated = true
            print(str)

            return YoutubeResponse.Success
        }
    }
    func deauthenticate(){
        authenticated = false
        deleteCookie()
    }
    func deleteCookie(){
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.removeItemAtPath(".cookie.txt")
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
    }
}

enum YoutubeResponse{
    case Success, NeedCredentials, IncorrectCredentials
}
