//
//  Playlist.swift
//  
//
//  Created by Benjamin Congdon on 1/13/16.
//
//

import Cocoa
import CocoaLumberjack

class Playlist: NSObject,NSCoding {
    
    var url:String!
    var title:String!
    var enabled:Bool!
    //Key - URL; Value - Filename
    var entries:Dictionary<String,String>!
    var progress:Int!
    
    override init(){
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playlistUpdate:", name: PlaylistFileDownloadedNotification, object: nil)
    }
    
    func playlistUpdate(notification:NSNotification){
        var progressCounter:Int = 0
        if let update = notification.object as? Array<String>{

            for entry in entries{
                //Filename found in update
                if entry.0 == update[0]{
                    if update[1] == ""{
                        print("invalid file name for url " + entry.0)
                        break
                    }
                    self.entries[entry.0] = update[1]
                    progressCounter += 1
                    print("New filename " + update[1])
                    break
                }
            }
            self.progress! += progressCounter
            dispatch_async(GlobalMainQueue){
                print("\(self.progress) out of \(self.entries.count)")
                DDLogInfo("Sync Progress: \(self.progress) out of \(self.entries.count)")
            }
        }
        if self.progress! >= entries.count {
            NSNotificationCenter.defaultCenter().postNotificationName(PlaylistDownloadCompletionNotification, object: self)
        }
    }
    
    required convenience init(coder decoder:NSCoder){
        self.init()
        self.url = decoder.decodeObjectForKey("url") as! String
        self.title = decoder.decodeObjectForKey("title") as! String
        self.enabled = decoder.decodeObjectForKey("enabled") as! Bool
        self.entries = decoder.decodeObjectForKey("entries") as! Dictionary<String,String>
        self.progress = decoder.decodeObjectForKey("progress") as! Int
    }
    
    convenience init(url:String,title:String,enabled:Bool,entries:Dictionary<String,String>){
        self.init()
        self.url = url
        self.title = title
        self.enabled = enabled
        self.entries = entries
        self.progress = 0
    }
    
    func encodeWithCoder(coder:NSCoder){
        if let url = url {coder.encodeObject(url, forKey:"url")}
        if let title = title {coder.encodeObject(title, forKey:"title")}
        if let enabled = enabled {coder.encodeObject(enabled, forKey:"enabled")}
        if let entries = entries {coder.encodeObject(entries, forKey: "entries")}
        if let progress = progress {coder.encodeObject(progress, forKey: "progress")}
    }
}
