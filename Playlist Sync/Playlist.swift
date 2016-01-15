//
//  Playlist.swift
//  
//
//  Created by Benjamin Congdon on 1/13/16.
//
//

import Cocoa

class Playlist: NSObject,NSCoding {
    
    var url:String!
    var title:String!
    var enabled:Bool!
    //Key - URL; Value - Filename
    var entries:Dictionary<String,String>!
    var progress:Double!
    
    override init(){
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playlistUpdate:", name: "playlistFileDownloaded", object: nil)
    }
    
    func playlistUpdate(notification:NSNotification){
        var progressCounter:Int = 0
        if let update = notification.object as? Array<String>{
            for entry in entries{
                if !entry.1.isEmpty {
                    progressCounter += 1
                }
                if entry.0 == update[0]{
                    self.entries[entry.0] = update[1]
                    progressCounter += 1
                    print("New filename " + update[1])
                }
            }
            self.progress = Double(progressCounter) / Double(entries.count)
            print(progress)
        }
    }
    
    required convenience init(coder decoder:NSCoder){
        self.init()
        self.url = decoder.decodeObjectForKey("url") as! String
        self.title = decoder.decodeObjectForKey("title") as! String
        self.enabled = decoder.decodeObjectForKey("enabled") as! Bool
        self.entries = decoder.decodeObjectForKey("entries") as! Dictionary<String,String>
        self.progress = decoder.decodeObjectForKey("progress") as! Double
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
