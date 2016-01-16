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
    var downloadQueue = Array<(String,String)>()
    var handlesForPlaylists = Dictionary<Playlist,[NSFileHandle]>()
    
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
        //let logFileHandle = logOut.fileHandleForReading
        //let errFileHandle = errOut.fileHandleForReading
        task.standardOutput = logOut
        task.standardError = errOut
        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receivedData:", name: NSFileHandleDataAvailableNotification, object: logFileHandle)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "terminated", name:
//            NSTaskDidTerminateNotification, object: task)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receivedError", name: NSFileHandleReadCompletionNotification, object: errFileHandle)
//        
//        logFileHandle.waitForDataInBackgroundAndNotify()
//        errFileHandle.waitForDataInBackgroundAndNotify()
        
        task.launch()

        task.waitUntilExit()
        let logResponse = NSString(data: logOut.fileHandleForReading.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)!
        let errResponse = NSString(data: errOut.fileHandleForReading.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)!
        dispatch_async(GlobalMainQueue){
            print(logResponse as String, errResponse as String)
        }
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
        print("Going forward with download: " + url)
        return internalDownload(url, path: path)
    }
    
    func makeFoldersToPath(path:String){
        do {
            print("path to " + path)
            try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("ERROR: " + error.localizedDescription);
        }
    }
    
    private func internalDownload(url:String, path:String) -> String {
        
        makeFoldersToPath(path)
        
        //Actually download video
        let result = runYTDLTask([url,path], scriptName: "Download")
        
        NSNotificationCenter.defaultCenter().postNotificationName("videoFinished", object: result.logResult)
        
        //Extract file name from output
        let logResultArray = result.logResult.characters.split{$0 == "\n"}.map(String.init)
        for line in logResultArray {
            let beginString = "[download] Destination: "
            let endString = " has already been downloaded"
            var fileName:String = ""
            if line.hasPrefix(beginString){
                fileName = line.substringFromIndex(line.startIndex.advancedBy(beginString.characters.count))
            }
            else if line.hasSuffix(endString) {
                fileName = line.substringFromIndex(line.startIndex.advancedBy("[download] ".characters.count))
                fileName = fileName.substringToIndex(fileName.endIndex.advancedBy(-1 * endString.characters.count))
            }
            if fileName != ""{
                print("returning file name: " + fileName)
                return fileName
            }
            
        }
        print("ERROR: Returning null filename:")
        print(result.logResult)
        print(result.errResult)
        return ""
    }
    
    func deleteStaleFiles(playlist:Playlist, path:String){
        let playlistPath = NSString(string: path).stringByAppendingPathComponent(playlist.title)
        let folderList = SyncHelper.listFolder(playlistPath)
        for file in folderList{
            if file.hasSuffix(".mp4") && !playlist.entries.values.contains(file){
                let filePath = NSString(string: playlistPath).stringByAppendingPathComponent(file)
                deleteFile(filePath)
            }
        }
    }
    func deleteFile(path:String){
        let fileManager = NSFileManager.defaultManager()
        print("NOTE: would remove: " + path)
//        do {
//            try fileManager.removeItemAtPath(path)
//            print("Removed file: " + path)
//        }
//        catch let error as NSError {
//            print("Something went wrong deleting file: \(error)")
//        }
    }
    
    func refreshPlaylist(playlist:Playlist){
        let info = YoutubeClient.defaultClient.playlistInfo(playlist.url)
        var entryDict = Dictionary<String,String>()
        for entry in info.entries {
            entryDict[entry] = ""
        }
        //Add new videos to entry
        for newEntry in entryDict {
            if !playlist.entries.keys.contains(newEntry.0){
                playlist.entries[newEntry.0] = ""
            }
        }
        //Delete stale videos from dictionary
        for oldEntry in playlist.entries {
            if !entryDict.keys.contains(oldEntry.0) {
                playlist.entries.removeValueForKey(oldEntry.0)
            }
        }
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