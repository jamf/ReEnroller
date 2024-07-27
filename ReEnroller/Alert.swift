//
//  Alert.swift
//  ReEnroller
//
//  Created by Leslie Helou on 2/15/21
//

import Cocoa

class Alert: NSObject {
    
    static let shared = Alert()
    private override init() { }
    
    func display(header: String, message: String) {
        if !param.runAsDaemon {
            let dialog: NSAlert = NSAlert()
            dialog.messageText = header
            dialog.informativeText = message
            dialog.alertStyle = NSAlert.Style.warning
            if header == "Process Complete" {
                let viewButton = dialog.addButton(withTitle: "View")
                viewButton.keyEquivalent = "\r"
            }
            let okButton  = dialog.addButton(withTitle: "OK")
            okButton.keyEquivalent = "o"
            let theButton = dialog.runModal()
            switch theButton {
            case .alertFirstButtonReturn:
                let thePath = NSString(string: "~/Downloads/\(fullPackageName)").expandingTildeInPath
                if FileManager.default.fileExists(atPath: thePath) {
                    let theApp = [URL(fileURLWithPath: thePath)]
                    NSWorkspace.shared.activateFileViewerSelecting(theApp)
                }
            default:
                break
            }
        }
    }
}
