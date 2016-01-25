//
//  DummyControl.swift
//  Playlist Sync
//
//  Created by Benjamin Congdon on 1/11/16.
//  Copyright © 2016 Benjamin Congdon. All rights reserved.
//

import Cocoa

class DummyControl: NSControl {
    var currentClickIsLeft = false

    override func mouseDown(theEvent: NSEvent) {
        currentClickIsLeft = true
        superview!.mouseDown(theEvent)
        sendAction(action, to: target)
    }
    override func rightMouseDown(theEvent: NSEvent) {
        currentClickIsLeft = false
        superview!.rightMouseDown(theEvent)
        sendAction(action, to: target)
    }
    
}
