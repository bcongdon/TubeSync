//
//  SyncHelper.swift
//  Playlist Sync
//
//  Created by Benjamin Congdon on 1/14/16.
//  Copyright © 2016 Benjamin Congdon. All rights reserved.
//

import Cocoa

class SyncHelper: NSObject {
    
    static let defaultHelper = SyncHelper(outputDir: "")
    
    var outputDir:String
    var outstandingTasks:Int = 0
    
    private let fileManager = NSFileManager.defaultManager()
    let youtubeClient = YoutubeClient()
    
    init(outputDir:String){
        self.outputDir = outputDir
    }
    
    private func listFolder(directory:String) -> Array<String>{
        let enumerator = fileManager.enumeratorAtPath(directory)
        var fileList = Array<String>()
        while let element = enumerator?.nextObject() as? String{
            fileList.append(element)
        }
        return fileList
    }
    
    private func deleteFile(path:String) -> Bool{
        do{
            try fileManager.removeItemAtPath(path)
            return true
        }
        catch let error as NSError {
            print(error)
            return false
        }
    }
    
    //NOT a blocking function
    func downloadPlaylist(playlist:Playlist){
        playlist.progress = 0
        
        let playlistFolderPath = NSString(string: outputDir).stringByAppendingPathComponent(playlist.title
        )

        
        let folderList = listFolder(playlistFolderPath)
        print("Folder list")
        print(folderList)
        
        for entry in playlist.entries {
            if entry.1 != "" && !folderList.contains(entry.1){
                print("Folder doesn't contain: " + entry.1)
                playlist.entries[entry.0] = ""
            }
        }
        for entry in playlist.entries {
            //print(folderList)
            
            //Download video is filename is unknown, or if the video file isn't in outputDir
            if entry.1.isEmpty {
                self.outstandingTasks += 1
                dispatch_sync(GlobalBackgroundQueue){
                    print("Downloading: " + entry.0)
                    let fileName = self.youtubeClient.downloadVideo(entry.0, path: playlistFolderPath)
                    NSNotificationCenter.defaultCenter().postNotificationName("playlistDownloadProgress", object: playlist)
                    //Inform playlist of the resulting file name
                    NSNotificationCenter.defaultCenter().postNotificationName("playlistFileDownloaded", object: [entry.0, fileName])
                    self.outstandingTasks -= 1
                    print("Outstanding tasks: \(self.outstandingTasks)")
                }
            }
            else{
                NSNotificationCenter.defaultCenter().postNotificationName("playlistFileDownloaded", object: playlist)
                print("found completed file")
            }
        }
    }
    func syncPlaylists(playlists:Array<Playlist>){
        if(outputDir == "") {
            print("Warning: Not syncing because outputDir is blank.")
            return
        }
        if outstandingTasks > 0{
            print("returning because outstanding tasks is \(self.outstandingTasks)")
            return
        }
        for playlist in playlists{
            if playlist.enabled! {
                print(playlist)
                self.downloadPlaylist(playlist)
                NSNotificationCenter.defaultCenter().postNotificationName("playlistDownloadComplete", object: playlist)
            }
            
        }
    }
}
