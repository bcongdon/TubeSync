//
//  SyncHelper.swift
//  Playlist Sync
//
//  Created by Benjamin Congdon on 1/14/16.
//  Copyright © 2016 Benjamin Congdon. All rights reserved.
//

import Cocoa
import Foundation

class SyncHelper: NSObject {
    
    var outputDir:String
    let downloadQueue = NSOperationQueue()
    let playlistQueue = NSOperationQueue()
    
    static private let fileManager = NSFileManager.defaultManager()
    
    let youtubeClient = YoutubeClient.defaultClient
    
    init(outputDir:String){
        self.outputDir = outputDir
        
        downloadQueue.maxConcurrentOperationCount = 3
        downloadQueue.qualityOfService = .Background
        
        playlistQueue.maxConcurrentOperationCount = 1
        playlistQueue.qualityOfService = .Background
    }
    
    static func listFolder(directory:String) -> Array<String>{
        let enumerator = fileManager.enumeratorAtPath(directory)
        var fileList = Array<String>()
        while let element = enumerator?.nextObject() as? String{
            fileList.append(element)
        }
        return fileList
    }
    
    private func deleteFile(path:String) -> Bool{
        do{
            try SyncHelper.fileManager.removeItemAtPath(path)
            return true
        }
        catch let error as NSError {
            print(error)
            return false
        }
    }
    
    //NOT a blocking function
    func downloadPlaylist(playlist:Playlist){
        
        let playlistFolderPath = NSString(string: outputDir).stringByAppendingPathComponent(playlist.title
        )
        
        youtubeClient.refreshPlaylist(playlist)
        
        playlist.progress = 0
        
        let folderList = SyncHelper.listFolder(playlistFolderPath)
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
                let downloadOp = NSBlockOperation(block: {
                    print("Downloading: " + entry.0)
                    let fileName = self.youtubeClient.downloadVideo(entry.0, path: playlistFolderPath)
                    //Inform playlist of the resulting file name
                    NSNotificationCenter.defaultCenter().postNotificationName(PlaylistFileDownloadedNotification, object: [entry.0, fileName])
                    NSNotificationCenter.defaultCenter().postNotificationName(PlaylistDownloadProgressNotification, object: playlist)
                })
                downloadQueue.addOperation(downloadOp)
                print("Operation count: \(downloadQueue.operationCount)")
            }
            else{
                NSNotificationCenter.defaultCenter().postNotificationName(PlaylistFileDownloadedNotification, object: [entry.0,entry.1])
                NSNotificationCenter.defaultCenter().postNotificationName(PlaylistDownloadProgressNotification, object: playlist)
                print("found completed file")
            }
        }
        downloadQueue.waitUntilAllOperationsAreFinished()
    }
    
    func syncPlaylists(playlists:Array<Playlist>){
        if(downloadQueue.operationCount > 0){
            return
        }
        else if(outputDir == "") {
            print("Warning: Not syncing because outputDir is blank.")
            return
        }
        for playlist in playlists{
            if playlist.enabled! {
                let downloadPlaylistOp = NSBlockOperation(block: {
                    self.downloadPlaylist(playlist)
                })
                downloadPlaylistOp.completionBlock = {
                    print("**** FINISHED DOWNLOADING " + playlist.title)
                }
                playlistQueue.addOperation(downloadPlaylistOp)
            }
        }
    }
}
