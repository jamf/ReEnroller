//
//  HelpViewController.swift
//  ReEnroller
//
//  Created by Leslie Helou on 2/12/21
//

import Cocoa
import WebKit

class HelpViewController: NSViewController, WKUIDelegate {

    let fm = FileManager()
    @IBOutlet weak var help_WebView: WKWebView!

    @IBAction func downloadMdmRemoval(_ sender: Any) {
        if fm.fileExists(atPath: NSHomeDirectory()+"/Downloads/apiMDM_remove.txt") {
            do {
                try fm.moveItem(atPath: NSHomeDirectory()+"/Downloads/apiMDM_remove.txt",
                                toPath: NSHomeDirectory()+"/Downloads/apiMDM_remove-\(ViewController().getDateTime(x: 1)).txt")
            } catch {
                Alert.shared.display(header: "Alert",
                                     message: "The script (apiMDM_remove.txt) already exists in Downloads and we couldn't rename it. Either delete/rename the file and download again or copy the script from Help.")
                return
            }
        }

        do {
            try fm.copyItem(atPath: Bundle.main.bundlePath + "/Contents/Resources/apiMDM_remove.txt",
                            toPath: NSHomeDirectory() + "/Downloads/apiMDM_remove.txt")
            Alert.shared.display(header: "-Success-", message: "The script (apiMDM_remove.txt) has been copied to Downloads.")
        } catch {
            Alert.shared.display(header: "-Attention-", message: "Could not copy script to Downloads. Copy manually from Help.")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        help_WebView.uiDelegate = self

        if let url = Bundle.main.url(forResource: "help", withExtension: "html") {
            help_WebView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }

    // MARK: - WKUIDelegate
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures?) -> WKWebView? {
        guard let url = navigationAction.request.url else { return nil }

        // Open external links in a new browser window (Safari)
        if navigationAction.targetFrame == nil {
            NSWorkspace.shared.open(url)
        }

        return nil
    }
}
