//
//  Globals.swift
//  ReEnroller
//
//  Created by Leslie Helou on 2/14/21
//

import Foundation

struct param {
    static var bundlePath    = Bundle.main.bundlePath
    static var settingsFile  = "\(bundlePath.dropLast(15))/settings.plist" // drop /ReEnroller.app from path
    static var localhostname = Host.current().localizedName ?? "localhost"
    static var runAsDaemon   = true
    static var backgroundColor = CGColor(red: 0x6c/255.0, green:0x82/255.0, blue:0x94/255.0, alpha: 1.0)
}
