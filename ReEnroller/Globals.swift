//
//  Globals.swift
//  ReEnroller
//
//  Created by Leslie Helou on 2/14/21
//

import Foundation

var fullPackageName = ""
let httpSuccess     = 200...299
var tokenTimeCreated: Date?

struct AppInfo {
    static let dict        = Bundle.main.infoDictionary!
    static let version     = dict["CFBundleShortVersionString"] as! String
    static let build       = dict["CFBundleVersion"] as! String
    static let name        = dict["CFBundleExecutable"] as! String

    static let userAgentHeader = "\(String(describing: AppInfo.name.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!))/\(AppInfo.version)"
}

struct JamfProServer {
    static var destination  = ""
    static var majorVersion = 0
    static var minorVersion = 0
    static var patchVersion = 0
    static var build        = ""
    static var authType     = "Bearer"
    static var authCreds    = ""
    static var base64Creds  = ""
    static var validToken   = false
    static var version      = ""
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

