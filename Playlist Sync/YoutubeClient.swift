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
    private func authYoutubeDL(options:Array<String>) -> YoutubeResponse {
        let response = runYTDLTask(options, scriptName: "Authenticate")
        let str = response.errResult
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
            return YoutubeResponse.AuthSuccess
        }
    }
    
    private func runYTDLTask(options:Array<String>, scriptName:String) -> (logResult:String, errResult:String){
        let task = NSTask()
        task.launchPath = NSBundle.mainBundle().pathForResource(scriptName, ofType: "py")! as String
        task.arguments = options
        let logOut = NSPipe()
        let errOut = NSPipe()
        task.standardOutput = logOut
        task.standardError = errOut
        task.launch()
        task.waitUntilExit()
        let logResponse = NSString(data: logOut.fileHandleForReading.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)!
        let errResponse = NSString(data: errOut.fileHandleForReading.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)!
        return (logResponse as String, errResponse as String)
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
    func getPlaylistItems() -> Array<String> {
        return []
        //FIXME: Need to implement
    }
    
    func isValidPlaylist(url:String) -> YoutubeResponse {
        let result = runYTDLTask([url], scriptName: "Playlist")
        if result.errResult == "" {
            return YoutubeResponse.ValidPlaylist
        }
        else if result.errResult.containsString("Error 404"){
            return YoutubeResponse.InvalidPlaylist
        }
        else if result.errResult.containsString("playlist doesn't exist or is private") {
            return YoutubeResponse.NeedCredentials
        }
        return YoutubeResponse.InvalidPlaylist
    }
    
    func playlistInfo(url:String) -> (title:String?, entries:[JSON]?){
        let result = runYTDLTask([url], scriptName: "Playlist")
        let jsonResult = JSON(string:result.logResult)
        //print(jsonResult)
        guard let title = jsonResult["title"].asString
            else{
                print(jsonResult["title"].asError)
                return(nil,nil)
        }
        guard let entries = jsonResult["entries"].asArray
            else{
                print(jsonResult["entries"].asError)
                return(nil,nil)
        }
        return(title,entries)
    }
}

enum YoutubeResponse{
    case AuthSuccess, NeedCredentials, IncorrectCredentials, ValidPlaylist, InvalidPlaylist
}
