//
//  Utils.swift
//  Playlist Sync
//
//  Created by Benjamin Congdon on 1/13/16.
//  Copyright © 2016 Benjamin Congdon. All rights reserved.
//

import Foundation

var GlobalMainQueue: dispatch_queue_t {
    return dispatch_get_main_queue()
}

var GlobalUserInteractiveQueue: dispatch_queue_t {
    return dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
}

var GlobalUserInitiatedQueue: dispatch_queue_t {
    return dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
}

var GlobalUtilityQueue: dispatch_queue_t {
    return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
}

var GlobalBackgroundQueue: dispatch_queue_t {
    return dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
}



let SecondsInMinute:Double = 60
let SecondsInHour:Double = 3600
let SecondsInDay:Double = 86400

//func pushPlaylistData(playlists:Array<Playlist>){
//    let playlistData = NSKeyedArchiver.archivedDataWithRootObject(playlists)
//    NSUserDefaults.standardUserDefaults().setObject(playlistData, forKey: "playlists")
//    NSUserDefaults.standardUserDefaults().synchronize()
//}

func fetchPlaylistsFromDefaults() -> Array<Playlist>{
    if let storedPlaylistData = NSUserDefaults.standardUserDefaults().dataForKey("playlists"){
        if let decodedPlaylists = NSKeyedUnarchiver.unarchiveObjectWithData(storedPlaylistData) as? Array<Playlist>{
            return decodedPlaylists
        }
    }
    print("Warning: Couldn't fetch playlists from user defaults")
    return Array<Playlist>()
}


let PlaylistDownloadCompletionNotification = "PlaylistDownloadCompletionNotification"
let PlaylistFileDownloadedNotification = "PlaylistFileDownloadedNotification"
let PlaylistDownloadProgressNotification = "PlaylistDownloadProgressNotification"
let SyncInitiatedNotification = "SyncInitiatedNotification"