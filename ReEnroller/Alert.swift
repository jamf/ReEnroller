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
            dialog.addButton(withTitle: "OK")
            dialog.runModal()
        }
    }
}
