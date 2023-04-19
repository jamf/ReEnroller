//
//  WriteToLog.swift
//  ReEnroller
//
//  Created by Leslie Helou on 2/15/21.
//

import Foundation
class WriteToLog {

    let fileManager = FileManager.default
    let logPath     = "/var/log/jamf.log"

    var writeToLogQ = DispatchQueue(label: "com.jamf.writeToLogQ", qos: DispatchQoS.utility)

    func message(theMessage: String) {

        var logFileW: FileHandle? = FileHandle(forUpdatingAtPath: logPath)
        if !fileManager.fileExists(atPath: logPath) {
            fileManager.createFile(atPath: logPath, contents: nil, attributes: [.ownerAccountID:0, .groupOwnerAccountID:80, .posixPermissions:0o664])
        }
//        writeToLogQ.sync {

            logFileW = FileHandle(forUpdatingAtPath: logPath)

            logFileW?.seekToEndOfFile()
            let fullMessage = ViewController().getDateTime(x: 2) + " \(param.localhostname) [ReEnroller]:    " + theMessage + "\n"
            let historyText = (fullMessage as NSString).data(using: String.Encoding.utf8.rawValue)
            logFileW?.write(historyText!)
//            self.logFileW?.closeFile()
//        }
    }
}
