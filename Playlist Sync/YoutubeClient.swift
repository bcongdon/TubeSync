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

    static let defaultClient = YoutubeClient()
    
    var options:NSMutableDictionary
    internal private(set) var authenticated:Bool = false
    //var busy = false
    var currentDownloads = 0
    let MAX_CONCURRENT_DOWNLOADS = 1
    var downloadQueue = Array<(String,String)>()

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
        let logFileHandle = logOut.fileHandleForReading
        let errFileHandle = errOut.fileHandleForReading
        task.standardOutput = logOut
        task.standardError = errOut
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receivedData:", name: NSFileHandleDataAvailableNotification, object: logFileHandle)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "terminated", name:
            NSTaskDidTerminateNotification, object: task)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receivedError", name: NSFileHandleReadCompletionNotification, object: errFileHandle)
        
        logFileHandle.waitForDataInBackgroundAndNotify()
        errFileHandle.waitForDataInBackgroundAndNotify()
        
        task.launch()

        task.waitUntilExit()
        let logResponse = NSString(data: logOut.fileHandleForReading.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)!
        let errResponse = NSString(data: errOut.fileHandleForReading.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)!
        return (logResponse as String, errResponse as String)
    }
    
    func receivedData(notification:NSNotification){
        let handle = notification.object as! NSFileHandle
        let data = handle.availableData
        if data.length != 0 {
            print(String(data: data, encoding: NSUTF8StringEncoding)!)
        }
        handle.waitForDataInBackgroundAndNotify()
    }
    
    func terminated(){
        NSNotificationCenter.defaultCenter().removeObserver(self)
        //busy = false
    }
    
    func receivedError(notification:NSNotification){
        let handle = notification.object as! NSFileHandle
        let data = handle.availableData
        if data.length != 0 {
            print(String(data: data, encoding: NSUTF8StringEncoding)!)
        }
        handle.waitForDataInBackgroundAndNotify()
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
    
    func isValidPlaylist(url:String) -> YoutubeResponse {
        let result = runYTDLTask([url], scriptName: "Playlist")
        if result.errResult == "" {
            //No error in getting result
            let jsonResult = JSON(string:result.logResult)
            for(k,v) in jsonResult{
                if k as! String == "_type" && v.asString == "playlist"{
                    return YoutubeResponse.ValidPlaylist
                }
            }
            return YoutubeResponse.NotPlaylist
        }
        else if result.errResult.containsString("Error 404"){
            return YoutubeResponse.InvalidPlaylist
        }
        else if result.errResult.containsString("playlist doesn't exist or is private") {
            return YoutubeResponse.NeedCredentials
        }
        return YoutubeResponse.InvalidPlaylist
    }
    
    func youtubeInfo(url:String) -> JSON {
        let result = runYTDLTask([url], scriptName: "Playlist")
        return JSON(string:result.logResult)
    }
    
    func playlistInfo(url:String) -> (title:String?, entries:Array<String>){
        let jsonResult = youtubeInfo(url)
        guard let title = jsonResult["title"].asString
            else{
                print(jsonResult["title"].asError)
                return(nil,[""])
        }
        guard let entries = jsonResult["entries"].asArray
            else{
                print(jsonResult["entries"].asError)
                return(nil,[""])
        }
        return(title,extractIDs(entries))
    }
    
    //Returns filename
    func downloadVideo(url:String, path:String) -> String{
        //Blocks until acceptable # of downloads
        while(currentDownloads >= MAX_CONCURRENT_DOWNLOADS){
        }
        return internalDownload(url, path: path)
    }
    
    private func internalDownload(url:String, path:String) -> String {
        self.currentDownloads += 1
        
        //Actually download video
        let result = runYTDLTask([url,path], scriptName: "Download")
        
        self.currentDownloads -= 1
        
        NSNotificationCenter.defaultCenter().postNotificationName("videoFinished", object: result.logResult)
        
        //Extract file name from output
        let logResultArray = result.logResult.characters.split{$0 == "\n"}.map(String.init)
        for line in logResultArray {
            let beginString = "[download] Destination: "
            let endString = " has already been downloaded"
            if line.hasPrefix(beginString){
                let fileName = line.substringFromIndex(line.startIndex.advancedBy(beginString.characters.count))
                return fileName
            }
            else if line.hasSuffix(endString) {
                var fileName = line.substringFromIndex(line.startIndex.advancedBy("[download] ".characters.count))
                fileName = fileName.substringToIndex(fileName.endIndex.advancedBy(-1 * endString.characters.count))
                return fileName
            }
        }
        return ""
    }
    
    func extractIDs(entries:[JSON]) -> Array<String>{
        var entryIDList = Array<String>()
        for jsonEntry in entries{
            guard let title = jsonEntry["id"].asString
                else{ continue }
            entryIDList.append(title)
        }
        return entryIDList
    }
    
}

enum YoutubeResponse{
    case AuthSuccess, NeedCredentials, IncorrectCredentials, ValidPlaylist, InvalidPlaylist, NotPlaylist, DuplicatePlaylist
}

//    private func runAsyncYTDLTask(options:Array<String>, scriptName:String){
//        let task = NSTask()
//        task.launchPath = NSBundle.mainBundle().pathForResource(scriptName, ofType: "py")! as String
//        task.arguments = options
//        let logOutPipe = NSPipe()
//        let errOutPipe = NSPipe()
//        task.standardOutput = logOutPipe
//        task.standardError = errOutPipe
//        let logOut = logOutPipe.fileHandleForReading
//        let errOut = errOutPipe.fileHandleForReading
//        errOut.waitForDataInBackgroundAndNotify()
//        busy = true
//        task.launch()
//
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receivedData:", name: NSFileHandleDataAvailableNotification, object: logOut)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "terminated", name:
//            NSTaskDidTerminateNotification, object: task)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receivedError", name: NSFileHandleReadCompletionNotification, object: errOut)
//        logOut.waitForDataInBackgroundAndNotify()
//        errOut.waitForDataInBackgroundAndNotify()
//    }
