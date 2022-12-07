//
//  Alert.swift
//  ReEnroller
//
//  Created by Leslie Helou on 2/15/21
//

import Cocoa

class Alert: NSObject {
    func display(header: String, message: String) {
        if !param.runAsDaemon {
            let dialog: NSAlert = NSAlert()
            dialog.messageText = header
            dialog.informativeText = message
            dialog.alertStyle = NSAlert.Style.warning
            let okButton   = dialog.addButton(withTitle: "OK")
            if header == "Process Complete" {
                let viewButton = dialog.addButton(withTitle: "View")
                okButton.keyEquivalent = "o"
                viewButton.keyEquivalent = "\r"
            }
            let theButton = dialog.runModal()
            switch theButton {
            case .alertFirstButtonReturn:
                break
            default:
                let thePath = NSString(string: "~/Downloads/\(fullPackageName)").expandingTildeInPath
                if FileManager.default.fileExists(atPath: thePath) {
                    let theApp = [URL(fileURLWithPath: thePath)]
                    NSWorkspace.shared.activateFileViewerSelecting(theApp)
                }
            }
        }
    }
}
