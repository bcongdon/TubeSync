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
    
    private let fileManager = NSFileManager.defaultManager()
    let youtubeClient = YoutubeClient()
    
    init(outputDir:String){
        self.outputDir = outputDir
    }
    
    func listOutputDirectory() -> Array<String>{
        return listFolder(outputDir)
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
        
        let folderList = listOutputDirectory()
        for entry in playlist.entries {
            if !folderList.contains(entry.1){
                print(entry.1)
                playlist.entries[entry.0] = ""
            }
        }
        for entry in playlist.entries {
            //print(folderList)
            
            //Download video is filename is unknown, or if the video file isn't in outputDir
            if entry.1.isEmpty {
                dispatch_async(GlobalBackgroundQueue){
                    let fileName = self.youtubeClient.downloadVideo(entry.0, path: self.outputDir)
                    NSNotificationCenter.defaultCenter().postNotificationName("playlistDownloadProgress", object: playlist)
                    //Inform playlist of the resulting file name
                    NSNotificationCenter.defaultCenter().postNotificationName("playlistFileDownloaded", object: [entry.0, fileName])
                    print(playlist.progress)
                }
            }
            else{
                playlist.progress = playlist.progress + (1 / Double(playlist.entries.count))
                NSNotificationCenter.defaultCenter().postNotificationName("playlistDownloadProgress", object: playlist)
                print("found completed file")
                //print(playlist.progress)
            }
        }
    }
    func syncPlaylists(playlists:Array<Playlist>){
        for playlist in playlists{
            dispatch_async(GlobalBackgroundQueue){
                print(playlist)
                self.downloadPlaylist(playlist)
                NSNotificationCenter.defaultCenter().postNotificationName("playlistDownloadComplete", object: playlist)
            }
        }
    }
}
