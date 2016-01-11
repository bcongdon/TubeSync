//
//  DummyControl.swift
//  Playlist Sync
//
//  Created by Benjamin Congdon on 1/11/16.
//  Copyright © 2016 Benjamin Congdon. All rights reserved.
//

import Cocoa

class DummyControl: NSControl {

    override func mouseDown(theEvent: NSEvent) {
        superview!.mouseDown(theEvent)
        sendAction(action, to: target)
    }
    
}
