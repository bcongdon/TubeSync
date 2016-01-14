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
    
    
    required convenience init(coder decoder:NSCoder){
        self.init()
        self.url = decoder.decodeObjectForKey("url") as! String
        self.title = decoder.decodeObjectForKey("title") as! String
        self.enabled = decoder.decodeObjectForKey("enabled") as! Bool
        self.entries = decoder.decodeObjectForKey("entries") as! Dictionary<String,String>
    }
    convenience init(url:String,title:String,enabled:Bool,entries:Dictionary<String,String>){
        self.init()
        self.url = url
        self.title = title
        self.enabled = enabled
        self.entries = entries
    }
    func encodeWithCoder(coder:NSCoder){
        if let url = url {coder.encodeObject(url, forKey:"url")}
        if let title = title {coder.encodeObject(title, forKey:"title")}
        if let enabled = enabled {coder.encodeObject(enabled, forKey:"enabled")}
        if let entries = entries {coder.encodeObject(entries, forKey: "entries")}
    }
    
    func addFileName(){
        
    }
}
