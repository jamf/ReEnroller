//
//  Globals.swift
//  ReEnroller
//
//  Created by Leslie Helou on 2/14/21
//

import Foundation

struct param {
    static var bundlePath    = Bundle.main.bundlePath
    static var settingsFile  = "\(bundlePath.dropLast(15))/settings.plist"
    static var localhostname = Host.current().localizedName ?? "localhost"
    static var runAsDaemon   = true
}
