//
//  HelpViewController.swift
//  ReEnroller
//
//  Created by Leslie Helou on 2/12/21
//

import Cocoa
import WebKit

class HelpViewController: NSViewController {

    let fm = FileManager()

    @IBOutlet weak var help_WebView: WKWebView!

    @IBAction func downloadMdmRemoval(_ sender: Any) {
        if fm.fileExists(atPath: NSHomeDirectory()+"/Desktop/apiMDM_remove.txt") {
            do {
                try fm.moveItem(atPath: NSHomeDirectory()+"/Desktop/apiMDM_remove.txt", toPath: NSHomeDirectory()+"/Desktop/apiMDM_remove-"+ViewController().getDateTime(x: 1)+".txt")
            } catch {
                Alert().display(header: "Alert", message: "The script (apiMDM_remove.txt) already exists on your Desktop and we couldn't rename it.  Either delete/rename the file and download again or copy the script from Help.")
                return
            }
        }
        do {
            try fm.copyItem(atPath: Bundle.main.bundlePath+"/Contents/Resources/apiMDM_remove.txt", toPath: NSHomeDirectory()+"/Desktop/apiMDM_remove.txt")
            Alert().display(header: "-Attention-", message: "The script (apiMDM_remove.txt) has been copied to your Desktop.")
        } catch {
            Alert().display(header: "-Attention-", message: "Could not copy scipt to the Desktop.  Copy manually from Help.")
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        if let url = Bundle.main.url(forResource: "help", withExtension: "html") {
            help_WebView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }
    
}
