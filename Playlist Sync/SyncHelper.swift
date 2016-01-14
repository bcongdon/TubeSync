//
//  SyncHelper.swift
//  Playlist Sync
//
//  Created by Benjamin Congdon on 1/14/16.
//  Copyright © 2016 Benjamin Congdon. All rights reserved.
//

import Cocoa

class SyncHelper: NSObject {
    
    let outputDir:String
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
    
    func downloadPlaylist(playlist:Playlist){
        //Loop through playlist videos
        for entry in playlist.entries {
            let folderList = listOutputDirectory()
            
            //Download video is filename is unknown, or if the video file isn't in outputDir
            if entry.1.isEmpty || !folderList.contains(entry.1){
                dispatch_async(GlobalBackgroundQueue){
                    let fileName = self.youtubeClient.downloadVideo(entry.0, path: self.outputDir)
                    //Inform playlist of the resulting file name
                    playlist.entries[entry.0] = fileName
                }
            }
        }
    }
    
}
