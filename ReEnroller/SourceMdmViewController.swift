//
//  SourceMdmViewController.swift
//  ReEnroller
//
//  Created by Leslie Helou on 3/13/21.
//

import Cocoa

class SourceMdmViewController: NSViewController {
    
    @IBOutlet var sourceMDM_View: NSView!
    @IBOutlet weak var sourceTitle_textfield: NSTextField!
    @IBOutlet weak var sourceMdmUrl_label: NSTextField!
    @IBOutlet weak var tenantNetwork_label: NSTextField!
    @IBOutlet weak var tokenKey_label: NSTextField!
    @IBOutlet weak var sourceMdmUrl_textfield: NSTextField!
    @IBOutlet weak var tenantNetwork_textfield: NSTextField!
    @IBOutlet weak var tokenKey_textfield: NSTextField!
    
    @IBAction func set_action(_ sender: Any) {
        userDefaults.set("\(sourceMdmUrl_textfield.stringValue)", forKey: "sourceMdmUrl")
        userDefaults.set("\(tenantNetwork_textfield.stringValue)", forKey: "tenantNetwork")
        userDefaults.set("\(tokenKey_textfield.stringValue)", forKey: "tokenKey")
        userDefaults.synchronize()
        sourceMDM_View.window?.close()
    }
    
    let userDefaults = UserDefaults.standard
    var sourceTitle  = ""
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        if sourceTitle == "Jamf Pro" {
            sourceMDM_View.window?.close()
        }
        
        sourceMdmUrl_textfield.stringValue  = userDefaults.string(forKey: "sourceMdmUrl") ?? ""
        tenantNetwork_textfield.stringValue = userDefaults.string(forKey: "tenantNetwork") ?? ""
        tokenKey_textfield.stringValue      = userDefaults.string(forKey: "tokenKey") ?? ""
        DispatchQueue.main.async { [self] in
            sourceTitle_textfield.stringValue = sourceTitle
            self.view.layer?.backgroundColor  = param.backgroundColor
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        // Do view setup here.
        
        sourceMDM_View.window?.styleMask.remove(.resizable)
        
        switch sourceTitle {
        case "Jamf School":
            sourceMdmUrl_textfield.placeholderString  = "https://your.jamfcloud.com"
            tenantNetwork_textfield.placeholderString = "Devices -> Enroll Device(s)"
            tokenKey_textfield.placeholderString      = "Org -> Settings -> API"
        case "Workspace ONE":
            sourceMdmUrl_label.stringValue            = "API URL:"
            sourceMdmUrl_textfield.placeholderString  = "https://as420.awmdm.com"
            tenantNetwork_textfield.placeholderString = "L48Sa/bBkzZAqTpPXsaUpCY3nKxaBnAMMTPwWxpVtmI="
            tokenKey_textfield.placeholderString      = "CugQ28Skd2EtcEuFEXBA5yM7TYYXMe9w"
            
            tenantNetwork_label.stringValue = "Tenant:"
            tokenKey_label.stringValue = "Token:"
        default:
            sourceMDM_View.window?.close()
        }
    }
    
    override func viewWillDisappear() {
        let application = NSApplication.shared
        application.stopModal()
    }
    
}
