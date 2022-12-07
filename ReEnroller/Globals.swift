//
//  Globals.swift
//  ReEnroller
//
//  Created by Leslie Helou on 2/14/21
//

import Foundation

var fullPackageName = ""

struct JamfProServer {
    static var majorVersion = 0
    static var minorVersion = 0
    static var patchVersion = 0
    static var build        = ""
    static var authType     = "Basic"
    static var authCreds    = ""
}

struct param {
    static var bundlePath    = Bundle.main.bundlePath
    static var settingsFile  = "\(bundlePath.dropLast(15))/settings.plist"
    static var localhostname = Host.current().localizedName ?? "localhost"
    static var runAsDaemon   = true
}

struct token {
    static var refreshInterval:UInt32 = 20*60  // 20 minutes
    static var sourceServer  = ""
    static var sourceExpires = ""
}

