//
//  AppDelegate.swift
//  ReEnroller
//
//  Created by Leslie Helou on 2/12/21.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBAction func showHelp(_ sender: NSMenuItem) {

        DispatchQueue.main.async {
            var helpIsOpen = false
            var windowsCount = 0
            print("[localHelp] show/bring to front help window")
            windowsCount = NSApp.windows.count
            print("[localHelp] window count: \(windowsCount)")
            for i in (0..<windowsCount) {
                if NSApp.windows[i].title == "Help" {
                    print("[localHelp] window title: \(NSApp.windows[i].title)")
                    NSApp.windows[i].makeKeyAndOrderFront(self)
                    helpIsOpen = true
                    print("[localHelp] bring to front help window")
                    break
                }
            }
            if !helpIsOpen {
                let storyboard = NSStoryboard(name: "Main", bundle: nil)
                let helpWindowController = storyboard.instantiateController(withIdentifier: "Help View Controller") as! NSWindowController
                helpWindowController.window?.hidesOnDeactivate = false
                helpWindowController.showWindow(self)
                print("[localHelp] show help window")
            }
        }
//        ViewController().localHelp(self)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        if !FileManager.default.fileExists(atPath: param.settingsFile) {
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            let mainWindowController = storyboard.instantiateController(withIdentifier: "Main") as! NSWindowController
            mainWindowController.window?.hidesOnDeactivate = false

            NSApplication.shared.setActivationPolicy(NSApplication.ActivationPolicy.regular)
            mainWindowController.showWindow(self)
            NSApplication.shared.activate(ignoringOtherApps: true)
        } else {
            ViewController().startToMigrate()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // quit the app if the window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        return true
    }

}

