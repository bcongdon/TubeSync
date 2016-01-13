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
    
    
    required convenience init(coder decoder:NSCoder){
        self.init()
        self.url = decoder.decodeObjectForKey("url") as! String
        self.title = decoder.decodeObjectForKey("title") as! String
    }
    convenience init(url:String,title:String){
        self.init()
        self.url = url
        self.title = title
    }
    func encodeWithCoder(coder:NSCoder){
        if let url = url {coder.encodeObject(url, forKey:"url")}
        if let title = title {coder.encodeObject(title, forKey:"title")}
    }
}
