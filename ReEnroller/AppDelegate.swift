//
//  AppDelegate.swift
//  ReEnroller
//
//  Created by Leslie Helou on 2/19/17.
//  Based on the bash ReEnroller script by Douglas Worley
//  Copyright © 2017 Leslie Helou. All rights reserved.
//
//////////////////////////////////////////////////////////////////////////////////////////
//
//Copyright (c) 2017 Jamf.  All rights reserved.
//
//      Redistribution and use in source and binary forms, with or without
//      modification, are permitted provided that the following conditions are met:
//              * Redistributions of source code must retain the above copyright
//                notice, this list of conditions and the following disclaimer.
//              * Redistributions in binary form must reproduce the above copyright
//                notice, this list of conditions and the following disclaimer in the
//                documentation and/or other materials provided with the distribution.
//              * Neither the name of the Jamf nor the names of its contributors may be
//                used to endorse or promote products derived from this software without
//                specific prior written permission.
//
//      THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
//      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//      WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//      DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
//      DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//      (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//      LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//      ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//      SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//////////////////////////////////////////////////////////////////////////////////////////

import Cocoa
import Collaboration
import Foundation
import SystemConfiguration
import WebKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, URLSessionDelegate {
    
    @IBOutlet weak var ReEnroller_window: NSWindow!
    
    @IBOutlet weak var help_Window: NSWindow!
    @IBOutlet weak var help_WebView: WebView!
    
    @IBOutlet weak var quickAdd_PathControl: NSPathControl!
    @IBOutlet weak var profile_PathControl: NSPathControl!
    @IBOutlet weak var removeProfile_Button: NSButton!  // removeProfile_Button.state == 1 if checked
    @IBOutlet weak var removeAllProfiles_Button: NSButton!
    
    // non recon fields
    @IBOutlet weak var jssUrl_TextField: NSTextField!
    @IBOutlet weak var jssUsername_TextField: NSTextField!
    @IBOutlet weak var jssPassword_TextField: NSSecureTextField!
    @IBOutlet weak var mgmtAccount_TextField: NSTextField!
    @IBOutlet weak var mgmtAcctPwd_TextField: NSSecureTextField!
    @IBOutlet weak var mgmtAcctPwd2_TextField: NSSecureTextField!
    @IBOutlet weak var randomPassword_button: NSButton!
    @IBOutlet weak var rndPwdLen_TextField: NSTextField?
    @IBOutlet weak var createPolicy_Button: NSButton!
    @IBOutlet weak var skipMdmCheck_Button: NSButton!
    @IBOutlet weak var removeReEnroller_Button: NSButton!
    @IBOutlet weak var retainSite_Button: NSButton!
    @IBOutlet weak var enableSites_Button: NSButton!
    @IBOutlet weak var site_Button: NSPopUpButton!
    @IBOutlet weak var separatePackage_button: NSButton!
    
    @IBOutlet weak var processQuickAdd_Button: NSButton!
    @IBOutlet weak var spinner: NSProgressIndicator!
    @IBOutlet weak var retry_TextField: NSTextField!
    
    let origBinary = "/usr/local/jamf/bin/jamf"
    let bakBinary = "/Library/Application Support/JAMF/ReEnroller/backup/jamf.bak"
    
    let origProfilesDir = "/var/db/ConfigurationProfiles"
    let bakProfilesDir = "/Library/Application Support/JAMF/ReEnroller/backup/ConfigurationProfiles.bak"

    let origKeychainFile = "/Library/Application Support/JAMF/JAMF.keychain"
    let bakKeychainFile  = "/Library/Application Support/JAMF/ReEnroller/backup/JAMF.keychain.bak"
    
    let jamfPlistPath = "/Library/Preferences/com.jamfsoftware.jamf.plist"
    let bakjamfPlistPath = "/Library/Application Support/JAMF/ReEnroller/backup/com.jamfsoftware.jamf.plist.bak"
    
    let configProfilePath = "/Library/Application Support/JAMF/ReEnroller/profile.mobileconfig"
    let verificationFile = "/Library/Application Support/JAMF/ReEnroller/Complete"
    var plistData:[String:AnyObject] = [:]  //our plist data format
    var jamfPlistData:[String:AnyObject] = [:]  //jamf plist data format
    var launchdPlistData:[String:AnyObject] = [:]  //com.jamf.ReEnroller plist data format
    var format = PropertyListSerialization.PropertyListFormat.xml //format of the property list file
    
    let fm = FileManager()
    var attributes = [FileAttributeKey : Any]()
    
    let myBundlePath = Bundle.main.bundlePath
    let blankSettingsPlistPath = Bundle.main.bundlePath+"/Contents/Resources/settings.plist"
    let logFilePath = "/private/var/log/jamf.log"
    var LogFileW: FileHandle?  = FileHandle(forUpdatingAtPath: "")
    
    var alert_answer: Bool = false
    var oldURL = ""
    var newURL = [String]()
    var newJSSURL = ""
    var newJSSHostname = ""
    var newJSSPort = ""
    
    let safeCharSet = CharacterSet.alphanumerics
    var jssUsername = ""
    var jssPassword = ""
    var resourcePath = ""
    var jssCredentials = ""
    var jssCredentialsBase64 = ""
    var siteDict = Dictionary<String, Any>()
    var siteId = "-1"
    var mgmtAcctPwdXml = ""
    var rndPwdXml = ""  // if using a random management account password this adds xml to the migration complete policy
    var mgmtAcctPwdLen = 8
    var pkgBuildResult: Int8 = 0
    
    var newJssArray = [String]()
    var shortHostname = ""
    
    // read this from Jamf server
    var createConfSwitches = ""
    
    var newJssMgmtUrl = ""
    var theNewInvite = ""
    var removeReEnroller = "yes" // by default delete the ReEnroller folder after enrollment
    var retainSite = "true" // by default retain site when re-enrolling
    var skipMdmCheck = "no" // by default do not skip mdm check
    var StartInterval = 1800    // default retry interval is 1800 seconds (30 minutes)
    var includesMsg = "includes"
    var includesMsg2 = ""
    var policyMsg = ""
    
    var profileUuid = ""
    var removeConfigProfile = ""
    var removeAllProfiles = ""
    
    var safePackageURL = ""
    var safeProfileURL = ""
    var Pipe_pkg = Pipe()
    var task_pkg = Process()
    
    // OS version info
    let os = ProcessInfo().operatingSystemVersion
    
    // migration check policy

    @IBAction func myHelp(_ sender: Any) {
        let helpFilePath = Bundle.main.path(forResource: "index", ofType: "html")
        help_WebView.mainFrameURL = helpFilePath
        help_Window.setIsVisible(true)
    }
    
    
    @IBAction func randomPassword(_ sender: Any) {
        if randomPassword_button.state == 1 {
            mgmtAcctPwd_TextField.isEnabled = false
            mgmtAcctPwd2_TextField.isEnabled = false
            createPolicy_Button.state = 1
            createPolicy_Button.isEnabled = false
            rndPwdLen_TextField?.isEnabled = true
            mgmtAcctPwd_TextField.stringValue = ""
            mgmtAcctPwd2_TextField.stringValue = ""
            alert_dialog(header: "Attention:", message: "A new account must be used when utilizing a random password.  Using an existing account will result in a mismatch between the client and server.\n\nThe new account will be created automatically during enrollment.")
        } else {
            mgmtAcctPwd_TextField.isEnabled = true
            mgmtAcctPwd2_TextField.isEnabled = true
            createPolicy_Button.isEnabled = true
            rndPwdLen_TextField?.isEnabled = false
        }
    }
    
//    @IBAction func fetchSites_Button(_ sender: Any) {
    func fetchSites() {
        if enableSites_Button.state == 1 {
            // get site info - start
            var siteArray = [String]()
//            let safeCharSet = CharacterSet.alphanumerics
            let jssUrl = jssUrl_TextField.stringValue
            jssUsername = jssUsername_TextField.stringValue
            jssPassword = jssPassword_TextField.stringValue.addingPercentEncoding(withAllowedCharacters: safeCharSet)!
            
            if "\(jssUrl)" == "" {
                alert_dialog(header: "Attention:", message: "Jamf server is required.")
                enableSites_Button.state = 0
                return
            }
            
            if "\(jssUsername)" == "" || "\(jssPassword)" == "" {
                alert_dialog(header: "Attention:", message: "Jamf server username and password are required in order to use Sites.")
                enableSites_Button.state = 0
                return
            }
            jssCredentials = "\(jssUsername):\(jssPassword)"
            let jssCredentialsUtf8 = jssCredentials.data(using: String.Encoding.utf8)
            jssCredentialsBase64 = (jssCredentialsUtf8?.base64EncodedString())!
            
            resourcePath = "\(jssUrl)/JSSResource/sites"
            resourcePath = resourcePath.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            // get all the sites - start
            getSites() {
                (result: Dictionary) in
                self.siteDict = result
                for (key, _) in self.siteDict {
                    siteArray.append(key)
                    siteArray = siteArray.sorted()
                }
//                print("sorted sites: \(siteArray)")
                for theSite in siteArray {
                    self.site_Button.addItems(withTitles: [theSite])
                }
                return [:]
            }
            // get all the sites - end
            
        } else {
            site_Button.isEnabled = false
        }
    }
    
    @IBAction func selectSite_Button(_ sender: Any) {
//        print("selected site: \(site_Button.titleOfSelectedItem ?? "None")")
        let siteKey = "\(site_Button.titleOfSelectedItem ?? "None")"
        "\(site_Button.titleOfSelectedItem ?? "None")" == "None" ? (siteId = "-1") : (siteId = "\(siteDict[siteKey] ?? "-1")")
//        print("selected site id: \(siteId)")
    }
    
    @IBAction func siteToggle_button(_ sender: NSButton) {
//        print("\(String(describing: sender.identifier!))")
        if (sender.identifier! == "selectSite") && (enableSites_Button.state == 1) {
            retainSite_Button.state = 0
            fetchSites()
        } else if (sender.identifier! == "existingSite") && (retainSite_Button.state == 1) {
            enableSites_Button.state = 0
            self.site_Button.isEnabled = false
        } else if (enableSites_Button.state == 0) {
            self.site_Button.isEnabled = false
        }
    }
    
    
    
    // process function - start
    @IBAction func process(_ sender: Any) {
        // get invitation code - start
        var jssUrl = jssUrl_TextField.stringValue
        if "\(jssUrl)" == "" {
            alert_dialog(header: "Alert", message: "Please provide the URL for the new server.")
            return
        }
        jssUrl = dropTrailingSlash(theSentString: jssUrl)
        
        let mgmtAcct = mgmtAccount_TextField.stringValue
        if "\(mgmtAcct)" == "" {
            self.alert_dialog(header: "Attention", message: "You must supply the existing management account username.")
            mgmtAccount_TextField.becomeFirstResponder()
            return
        }
        if randomPassword_button.state == 0 {
            let mgmtAcctPwd = mgmtAcctPwd_TextField.stringValue.addingPercentEncoding(withAllowedCharacters: safeCharSet)!
            let mgmtAcctPwd2 = mgmtAcctPwd2_TextField.stringValue.addingPercentEncoding(withAllowedCharacters: safeCharSet)!
            if "\(mgmtAcctPwd)" == "" {
                self.alert_dialog(header: "Attention", message: "Password cannot be left blank.")
                mgmtAccount_TextField.becomeFirstResponder()
                return
            }
            if "\(mgmtAcctPwd)" != "\(mgmtAcctPwd2)" {
                self.alert_dialog(header: "Attention", message: "Management account passwords do not match.")
                mgmtAcctPwd_TextField.becomeFirstResponder()
                return
            }
            mgmtAcctPwdXml = "<ssh_password>\(mgmtAcctPwd)</ssh_password>"
        } else {
            // check the local system for the existance of the management account
            if findAllUsers().contains(mgmtAcct) {
                alert_dialog(header: "Attention:", message: "Account \(mgmtAcct) cannot be used with a random password as it exists on this system.")
                return
            }
            // verify random password lenght is an integer - start
            let pattern = "(^[0-9]*$)"
            let regex1 = try! NSRegularExpression(pattern: pattern, options: [])
            let matches = regex1.matches(in: (rndPwdLen_TextField?.stringValue)!, options: [], range: NSRange(location: 0, length: (rndPwdLen_TextField?.stringValue.characters.count)!))
            if matches.count != 0 {
                //                print("valid")
                mgmtAcctPwdLen = Int((rndPwdLen_TextField?.stringValue)!)!
//                print("pwd len: \(mgmtAcctPwdLen)")
                if (mgmtAcctPwdLen) > 255 || (mgmtAcctPwdLen) < 8 {
                    alert_dialog(header: "Attention:", message: "Verify an random password length is between 8 and 255.")
                    return
                }
            } else {
                alert_dialog(header: "Attention:", message: "Verify an interger value was entered for the random password length.")
                return
            }
            // verify random password lenght is an integer - end
            mgmtAcctPwdXml = ""
            rndPwdXml = "<account_maintenance><management_account><action>random</action><managed_password_length>\(mgmtAcctPwdLen)</managed_password_length></management_account></account_maintenance>"
        }
        
        // server is reachable - start
        if !(checkURL(theUrl: jssUrl) == 0) {
            self.alert_dialog(header: "Attention", message: "The new server, \(jssUrl), could not be contacted.")
            return
        }
        // server is reachable - end
        
        jssUsername = jssUsername_TextField.stringValue.addingPercentEncoding(withAllowedCharacters: safeCharSet)!
        jssPassword = jssPassword_TextField.stringValue.addingPercentEncoding(withAllowedCharacters: safeCharSet)!
        
        if "\(jssUsername)" == "" || "\(jssPassword))" == "" {
            alert_dialog(header: "Alert", message: "Please provide both a username and password for the server.")
            return
        }
        
        spinner.startAnimation(self)
        
        // get SSL verification settings from new server - start
        plistData["createConfSwitches"] = getSslVerify(server: jssUrl, name: jssUsername, password: jssPassword) as AnyObject
        // get SSL verification settings from new server - end
        
        // get site info - start
        let process_site = Process()
        let pipe_site = Pipe()
        
        var resourcePath = "\(jssUrl))/JSSResource/sites"
        resourcePath = resourcePath.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        
        process_site.launchPath = "/usr/bin/curl"
        process_site.arguments = ["-sku", "\(jssUsername):\(jssPassword)", resourcePath, "-H", "Accept: application/json"]
        process_site.standardOutput = pipe_site
        
        process_site.launch()
        
        process_site.waitUntilExit()
        
        let site_handle = pipe_site.fileHandleForReading
        let site_data = site_handle.readDataToEndOfFile()
        // get site info - end

        
        let process_invite = Process()
        let pipe_invite = Pipe()
        
        retainSite_Button.state == 1 ? (retainSite = "true") : (retainSite = "false")
        
        let invite_request = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><computer_invitation><lifetime>2147483647</lifetime><multiple_uses_allowed>true</multiple_uses_allowed><ssh_username>" + mgmtAcct + "</ssh_username><ssh_password_method>\(randomPassword_button.state)</ssh_password_method>\(mgmtAcctPwdXml)<enroll_into_site><id>" + siteId + "</id></enroll_into_site><keep_existing_site_membership>" + retainSite + "</keep_existing_site_membership><create_account_if_does_not_exist>true</create_account_if_does_not_exist><hide_account>true</hide_account><lock_down_ssh>false</lock_down_ssh></computer_invitation>"
//        print("invite request: " + invite_request)
        
        process_invite.launchPath = "/bin/bash"
//        process_invite.arguments = ["-c", "/usr/bin/curl", "-m", "20", "fku", jssUsername + ":" + jssPassword, jssUrl + "/JSSResource/computerinvitations/id/0", "-d", invite_request, "-X", "POST", "-H", "Content-Type: text/xml"]
        process_invite.arguments = ["-c", "/usr/bin/curl -m 20 -sku \(jssUsername):\(jssPassword) \(jssUrl)/JSSResource/computerinvitations/id/0 -d '\(invite_request)' -X POST -H Content-Type: text/xml"]
        process_invite.standardOutput = pipe_invite
        
        process_invite.launch()
        
        process_invite.waitUntilExit()
        
        let handle = pipe_invite.fileHandleForReading
        let data = handle.readDataToEndOfFile()
        let postResponse = String(data:data, encoding: String.Encoding.utf8)
        
        if let start = postResponse?.range(of: "<invitation>"),
            let end  = postResponse?.range(of: "</invitation>", range: start.upperBound..<(postResponse?.endIndex)!) {
            theNewInvite.append((postResponse?[start.upperBound..<end.lowerBound])!)
        } else {
            print("invalid input")
        }
        
        if "\(theNewInvite)" == "" {
            alert_dialog(header: "Alert", message: "Unable to create invitation.  Verify the account, \(jssUsername), has been assigned permissions to do so.")
            spinner.stopAnimation(self)
            return
        } //else {

        //}
        
        if createPolicy_Button.state == 1 {
            // create migration complete policy - start
            let process_policy = Process()
            let pipe_policy = Pipe()
            
            let migrationCheckPolicy = "<?xml version='1.0' encoding='UTF-8' standalone='no'?><policy><general><name>Migration Complete</name><enabled>true</enabled><trigger>EVENT</trigger><trigger_checkin>false</trigger_checkin><trigger_enrollment_complete>false</trigger_enrollment_complete><trigger_login>false</trigger_login><trigger_logout>false</trigger_logout><trigger_network_state_changed>false</trigger_network_state_changed><trigger_startup>false</trigger_startup><trigger_other>jssmigrationcheck</trigger_other><frequency>Ongoing</frequency><location_user_only>false</location_user_only><target_drive>/</target_drive><offline>false</offline><network_requirements>Any</network_requirements><site><name>None</name></site></general><scope><all_computers>true</all_computers></scope>\(rndPwdXml)<files_processes><run_command>touch /Library/Application\\ Support/JAMF/ReEnroller/Complete</run_command></files_processes></policy>"
            
            process_policy.launchPath = "/usr/bin/curl"
            process_policy.arguments = ["-m", "20", "-sku", jssUsername + ":" + jssPassword, jssUrl + "/JSSResource/policies/id/0", "-d", migrationCheckPolicy, "-X", "POST", "-H", "Content-Type: text/xml"]
//            print("curl: /usr/bin/curl -m 20 -vfku \(jssUsername):\(jssPassword) \(jssUrl)/JSSResource/policies/id/0 -d \(migrationCheckPolicy) -X POST -H \"Content-Type: text/xml\"\n")
            process_policy.standardOutput = pipe_policy
            // create migration complete policy - end
            
            process_policy.launch()
            
            process_policy.waitUntilExit()
            
//            let policyHandle = pipe_policy.fileHandleForReading
//            let policyData = policyHandle.readDataToEndOfFile()
//            let policyPostResponse = String(data:policyData, encoding: String.Encoding.utf8)
            
//            print("policyPostResponse: \(String(describing: policyPostResponse))")
            // create migration complete policy - start
        }
        
        plistData["theNewInvite"] = theNewInvite as AnyObject
        
        jssUrl = jssUrl.lowercased().replacingOccurrences(of: "https://", with: "")
        jssUrl = jssUrl.lowercased().replacingOccurrences(of: "http://", with: "")
        (newJSSHostname, newJSSPort) = getHost_getPort(theURL: jssUrl)
//        print("newJSSHostname: \(newJSSHostname)")
        
        // get server hostname for use in the package name
        newJssArray = newJSSHostname.components(separatedBy: ".")
        newJssArray[0] == "" ? (shortHostname = "new") : (shortHostname = newJssArray[0])
        
//        print("newJSSPort: \(newJSSPort)")
        newJssMgmtUrl = "https://\(newJSSHostname):\(newJSSPort)"
//        print("newJssMgmtUrl: \(newJssMgmtUrl)")
        
        plistData["newJSSHostname"] = newJSSHostname as AnyObject
        plistData["newJSSPort"] = newJSSPort as AnyObject
        //plistData["createConfSwitches"] = newURL_array[1] as AnyObject
        
        
        //exit(0)
        
        // get invitation code - end
        
        
        // put app in place
        
        let buildFolder = "/private/tmp/reEnroller-"+getDateTime(x: 1)
        var buildFolderd = "" // build folder for launchd items, may be outside build folder if separating app from launchd
        let settingsPlistPath = buildFolder+"/Library/Application Support/JAMF/ReEnroller/settings.plist"
        
        // create build location and place items
        do {
            try fm.createDirectory(atPath: buildFolder+"/Library/Application Support/JAMF/ReEnroller", withIntermediateDirectories: true, attributes: nil)
            // copy the app into the pkg building location
            do {
                try fm.copyItem(atPath: myBundlePath, toPath: buildFolder+"/Library/Application Support/JAMF/ReEnroller/ReEnroller.app")
            } catch {
                alert_dialog("-Attention-", message: "Could not copy app to build folder - exiting.")
                exit(1)
            }
            // put settings.plist into place
            do {
                try fm.copyItem(atPath: blankSettingsPlistPath, toPath: settingsPlistPath)
            } catch {
                alert_dialog("-Attention-", message: "Could not copy settings.plist to build folder - exiting.")
                exit(1)
            }
            
        } catch {
            alert_dialog("-Attention-", message: "Could not create build folder - exiting.")
            exit(1)
        }
        
        // create folder to hold backups of exitsing files/folders - start
        do {
            try fm.createDirectory(atPath: buildFolder+"/Library/Application Support/JAMF/ReEnroller/backup", withIntermediateDirectories: true, attributes: nil)
        } catch {
            alert_dialog("-Attention-", message: "Could not create backup folder - exiting.")
            exit(1)
        }
        // create folder to hold backups of exitsing files/folders - end
        
        // if a config profile is present copy it to the pkg building location
        if let profileURL = profile_PathControl.url {
            safeProfileURL = "\(profileURL)".replacingOccurrences(of: "%20", with: " ")
            safeProfileURL = safeProfileURL.replacingOccurrences(of: "file://", with: "")
//            print("safeProfileURL: \(safeProfileURL)")

            if safeProfileURL != "/" {
                do {
                    try fm.copyItem(atPath: safeProfileURL, toPath: buildFolder+"/Library/Application Support/JAMF/ReEnroller/profile.mobileconfig")
                } catch {
                    alert_dialog("-Attention-", message: "Could not copy config profile.  If there are spaces in the profile name try removing them. Unable to create pkg - exiting.")
                        writeToLog(theMessage: "Could not copy config profile.  If there are spaces in the profile name try removing them. Unable to create pkg - exiting.")
                        exit(1)
                }
                // add config profile values to settings - start
                do {
                    let one = try String(contentsOf: profile_PathControl.url! as URL, encoding: String.Encoding.ascii).components(separatedBy: "</string><key>PayloadType</key>")
                    let PayloadUUID = one[0].components(separatedBy: "<key>PayloadUUID</key><string>")
//                    print ("\(PayloadUUID[1])")
                    plistData["profileUUID"] = "\(PayloadUUID[1])" as AnyObject
                    if removeProfile_Button.state == 0 {
                        plistData["removeProfile"] = "false" as AnyObject
                    } else {
                        plistData["removeProfile"] = "true" as AnyObject
                    }
                } catch {
                    print("unable to read file")
                }
            }
        }   // add config profile values to settings - end
        
        // configure all profile removal - start
        if removeAllProfiles_Button.state == 0 {
            plistData["removeAllProfiles"] = "false" as AnyObject
        } else {
            plistData["removeAllProfiles"] = "true" as AnyObject
        }
        // configure all profile removal - end
        
        // configure ReEnroller folder removal - start
        if removeReEnroller_Button.state == 0 {
            plistData["removeReEnroller"] = "no" as AnyObject
        } else {
            plistData["removeReEnroller"] = "yes" as AnyObject
        }
        // configure ReEnroller folder removal - end

//        // configure retainSite - start
//        if retainSite_Button.state == 0 {
//            plistData["remtainSite"] = "no" as AnyObject
//        } else {
//            plistData["remtainSite"] = "yes" as AnyObject
//        }
//        // configure retainSite - end
        
        // configure mdm check - start
        if skipMdmCheck_Button.state == 0 {
            plistData["skipMdmCheck"] = "no" as AnyObject
        } else {
            plistData["skipMdmCheck"] = "yes" as AnyObject
        }
        // configure mdm - end
        
        // set retry interval in launchd - start
        if let retryInterval = Int(retry_TextField.stringValue) {
            if retryInterval >= 5 {
                StartInterval = retryInterval*60    // convert minutes to seconds
//                print("Setting custon retry interval: \(StartInterval)")
            }
        } else {
            spinner.stopAnimation(self)
            alert_dialog("-Attention-", message: "Invalid value entered for the retry interval.")
            return
        }
        // set retry interval in launchd - end
        
        // prepare postinstall script if option is checked - start
        if separatePackage_button.state == 0 {
            buildFolderd = buildFolder
        } else {
            buildFolderd = "/private/tmp/reEnrollerd-"+getDateTime(x: 1)
            includesMsg = "does not include"
            includesMsg2 = "  The launch daemons are packaged in: ReEnrollerDaemon-\(shortHostname).pkg."
        }

        do {
            try fm.createDirectory(atPath: buildFolderd+"/Library/LaunchDaemons", withIntermediateDirectories: true, attributes: nil)
            do {
                try fm.copyItem(atPath: myBundlePath+"/Contents/Resources/com.jamf.ReEnroller.plist", toPath: buildFolderd+"/Library/LaunchDaemons/com.jamf.ReEnroller.plist")
            } catch {
                writeToLog(theMessage: "Could not copy launchd, unable to create pkg")
                alert_dialog("-Attention-", message: "Could not copy launchd to build folder - exiting.")
                exit(1)
            }
            
        } catch {
            writeToLog(theMessage: "Unable to place launch daemon.")
            alert_dialog("-Attention-", message: "Could not LaunchDeamons folder in build folder - exiting.")
            exit(1)
        }
        // put launch daemon in place - end
        
        let launchdFile = buildFolderd+"/Library/LaunchDaemons/com.jamf.ReEnroller.plist"
        if fm.fileExists(atPath: launchdFile) {
            let launchdPlistXML = fm.contents(atPath: launchdFile)!
            do{
                writeToLog(theMessage: "Reading settings from: \(launchdFile)")
                launchdPlistData = try PropertyListSerialization.propertyList(from: launchdPlistXML,
                                                                              options: .mutableContainersAndLeaves,
                                                                              format: &format)
                    as! [String : AnyObject]
            }
            catch{
                writeToLog(theMessage: "Error launchd plist: \(error), format: \(format)")
            }
        }

        launchdPlistData["StartInterval"] = StartInterval as AnyObject
    
        // Write values to launchd plist - start
        (launchdPlistData as NSDictionary).write(toFile: launchdFile, atomically: false)
        // Write values to launchd plist - end
    
        do {
            try fm.createDirectory(atPath: buildFolderd+"/Library/Application Support/JAMF/ReEnroller/scripts", withIntermediateDirectories: true, attributes: nil)
            do {
                try fm.copyItem(atPath: myBundlePath+"/Contents/Resources/postinstall", toPath: buildFolderd+"/Library/Application Support/JAMF/ReEnroller/scripts/postinstall")
            } catch {
                writeToLog(theMessage: "Could not copy postinstall script.")
                alert_dialog("-Attention-", message: "Could not copy post install script to build location - exiting.")
                exit(1)
            }
            
        } catch {
            writeToLog(theMessage: "Unable to place postinstall script.")
            alert_dialog("-Attention-", message: "Could not create scripts directory for post install task in build location - exiting.")
            exit(1)
        }
        // prepare postinstall script if option is checked - end
        
        // Write settings from GUI to settings.plist
        (plistData as NSDictionary).write(toFile: settingsPlistPath, atomically: false)
        
        // rename existing ReEnroller.pkg if it exists - start
        if fm.fileExists(atPath: NSHomeDirectory()+"/Desktop/ReEnroller-\(shortHostname).pkg") {
            do {
                try fm.moveItem(atPath: NSHomeDirectory()+"/Desktop/ReEnroller-\(shortHostname).pkg", toPath: NSHomeDirectory()+"/Desktop/ReEnroller-\(shortHostname)-"+getDateTime(x: 1)+".pkg")
            } catch {
                alert_dialog("Alert", message: "Unable to rename an existing ReEnroller-\(shortHostname).pkg file on the Desktop.  Try renaming/removing it manually: sudo mv ~/Desktop/ReEnroller-\(shortHostname).pkg ~/Desktop/ReEnroller-\(shortHostname)-old.pkg.")
                exit(1)
            }
        }
        // rename existing ReEnroller.pkg if it exists - end
        
        
        // Create pkg of app and launchd - start
        if separatePackage_button.state == 0 {
            pkgBuildResult = myExitCode(cmd: "/usr/bin/pkgbuild", args: "--identifier", "com.jamf.ReEnroller", "--root", buildFolder, "--scripts", buildFolder+"/Library/Application Support/JAMF/ReEnroller/scripts", NSHomeDirectory()+"/Desktop/ReEnroller-\(shortHostname).pkg")
        } else {
            pkgBuildResult = myExitCode(cmd: "/usr/bin/pkgbuild", args: "--identifier", "com.jamf.ReEnroller", "--root", buildFolder, NSHomeDirectory()+"/Desktop/ReEnroller-\(shortHostname).pkg")
            pkgBuildResult = myExitCode(cmd: "/usr/bin/pkgbuild", args: "--identifier", "com.jamf.ReEnrollerd", "--root", buildFolderd, "--scripts", buildFolderd+"/Library/Application Support/JAMF/ReEnroller/scripts", NSHomeDirectory()+"/Desktop/ReEnrollerDaemon-\(shortHostname).pkg")
        }
        if pkgBuildResult != 0 {
            alert_dialog("-Attention-", message: "Could not create the ReEnroller(Daemon) package - exiting.")
            exit(1)
        }
        // Create pkg of app and launchd - end

        spinner.stopAnimation(self)
        
        if createPolicy_Button.state == 1 {
            policyMsg = "\n\nVerify the Migration Complete policy was created on the new server.  "
            if randomPassword_button.state == 0 {
                policyMsg.append("The policy should contain a 'Files and Processes' payload.  Modify if needed.")
            } else {
                policyMsg.append("The policy should contain a 'Files and Processes' payload along with a 'Management Account' payload.  Modify if needed.")
            }
        } else {
            policyMsg = "\n\nBe sure to create a migration complete policy before starting to migrate, see help or more information."
        }
        
        // alert the user, we're done
       alert_dialog("Attention:", message: "A package (ReEnroller-\(shortHostname).pkg) has been created on your desktop which is ready to be deployed with your current Jamf server.\n\nThe package \(includesMsg) a postinstall script to load the launch daemon and start the ReEnroller app.\(includesMsg2)\(policyMsg)")
        // Create pkg of app and launchd - end

        exit(0)
    }
    // process function - end
    
    // func alert_dialog - start
    func alert_dialog(_ header: String, message: String) {
        let dialog: NSAlert = NSAlert()
        dialog.messageText = header
        dialog.informativeText = message
        dialog.alertStyle = NSAlertStyle.warning
        dialog.addButton(withTitle: "OK")
        dialog.runModal()
//        return true
    }
    // func alert_dialog - end
    
// -------------------------  Start the migration  ------------------------- //
    
    func beginMigration() {
        writeToLog(theMessage: "Starting the enrollment process for the new Jamf Pro server.")
        
//        // Install profile if present - start
//        if !profileInstall() {
//            unverifiedFallback()
//            exit(1)
//        }
//        // Install profile if present - end
        
        // ensure we still have network connectivity - start
        var connectivityCounter = 0
        while !connectedToNetwork() {
            sleep(2)
            if connectivityCounter > 30 {
                writeToLog(theMessage: "There was a problem after removing old MDM configuration, network connectivity was lost. Will attempt to fall back to old settings and exiting!")
                unverifiedFallback()
                exit(1)
            }
            connectivityCounter += 1
            writeToLog(theMessage: "Waiting for network connectivity.")
        }
        // ensure we still have network connectivity - end
        
        // connectivity to new Jamf Pro server - start
        writeToLog(theMessage: "Attempting to connect to new Jamf Server at "+newJSSHostname)
        
        if myExitCode(cmd: "/usr/bin/nc", args: "-z", "-G", "10", "\(newJSSHostname)", "\(newJSSPort)") == 0 {
            writeToLog(theMessage: "Success connecting to new Jamf Server URL at \(newJSSHostname) on port \(newJSSPort)")
        } else {
            writeToLog(theMessage: "There was a problem connecting to new Jamf Server URL at \(newJSSHostname) on port \(newJSSPort). Exiting.")
            // remove config profile if one was installed
            if profileUuid != "" {
                if !profileRemove() {
                    writeToLog(theMessage: "Unable to remove included configuration profile")
                }
            }
            exit(1)
        }
        // connectivity to new Jamf Pro server - end
        

        // get jamf binary from new server and replace current binary - start
//        print("curl -m 20 -sk \(newJssMgmtUrl)/bin/jamf.gz -o '/Library/Application Support/JAMF/ReEnroller/jamf.gz'")
        if myExitCode(cmd: "/bin/bash", args: "-c", "curl -m 20 -sk \(newJssMgmtUrl)/bin/jamf.gz -o '/Library/Application Support/JAMF/ReEnroller/jamf.gz'") != 0 {
            writeToLog(theMessage: "Could not copy jamf binary from new server, will rely on existing jamf binary.")
        } else {
            if fm.fileExists(atPath: "/Library/Application Support/JAMF/ReEnroller/jamf.gz") {
                if backup(operation: "copy", source: origBinary, destination: bakBinary) {
                    if myExitCode(cmd: "/bin/bash", args: "-c", "gunzip /Library/Application\\ Support/JAMF/ReEnroller/jamf.gz") == 0 {
                        do {
                            try fm.moveItem(atPath: "/Library/Application Support/JAMF/ReEnroller/jamf", toPath: origBinary)
                            writeToLog(theMessage: "Using jamf binary from the new server.")
                            // set permissions to read and execute
                            attributes[.posixPermissions] = 0o555
                            do {
                                try fm.setAttributes(attributes, ofItemAtPath: origBinary)
                            }
                            if fm.fileExists(atPath: "/usr/local/jamf/bin/jamfAgent") {
                                try fm.removeItem(atPath: "/usr/local/jamf/bin/jamfAgent")
                            }
                        } catch {
                            writeToLog(theMessage: "Unable to replace existing jamf binary, will rely on existing one.")
                        }
                    }
                } else {
                    writeToLog(theMessage: "Unable to replace existing jamf binary, will rely on existing one.")
                }
            }
        }
        // get jamf binary from new server and replace current binary - end
        
        
        //exit(0)   // for testing
        
        // backup existing jamf keychain - start
        if backup(operation: "copy", source: origKeychainFile, destination: bakKeychainFile) {
            writeToLog(theMessage: "Successfully backed up jamf keychain")
        } else {
            writeToLog(theMessage: "Failed to backup jamf keychain")
            unverifiedFallback()
            exit(1)
        }
        // backup existing jamf keychain - end
        
        // backup existing jamf plist, if it exists - start
        if backup(operation: "copy", source: jamfPlistPath, destination: bakjamfPlistPath) {
            writeToLog(theMessage: "Successfully backed up jamf plist")
        } else {
            writeToLog(theMessage: "Failed to backup jamf plist, rollback is not possible")
//            unverifiedFallback()
//            exit(1)
        }
        // backup existing jamf plist, if it exists - end
        
        // backup existing ConfigurationProfiles dir, if present - start
        if os.minorVersion < 13 {
            if backup(operation: "copy", source: origProfilesDir, destination: bakProfilesDir) {
                writeToLog(theMessage: "Successfully backed up current ConfigurationProfiles")
            } else {
                writeToLog(theMessage: "Failed to backup current ConfigurationProfiles")
                unverifiedFallback()
                exit(1)
            }
        } else {
            writeToLog(theMessage: "ConfigurationProfiles is not backed up on machines with High Sierra or later due to SIP.")
        }

        // backup existing ConfigurationProfiles dir, if present - end
        
        // Let's enroll
        enrollNewJss(newServer: newJssMgmtUrl, newInvite: theNewInvite)
        
        // Verify the enrollment
        verifyNewEnrollment()
        
        // verify cleanup
        verifiedCleanup()
        exit(0)
        
    }
    
    // backup up item - start
    func backup(operation: String, source: String, destination: String) -> Bool {
        var success = true
        let backupDate = getDateTime(x: 1)
        if fm.fileExists(atPath: source) {
            if fm.fileExists(atPath: destination) {
                do {
                    try fm.moveItem(atPath: destination, toPath: destination+"-"+backupDate)
                    writeToLog(theMessage: "Backed up existing, \(destination), to "+destination+"-"+backupDate)
                } catch {
                    alert_dialog("Alert", message: "Unable to rename existing item, \(destination).")
                    writeToLog(theMessage: "Failed to rename \(destination).")
                    success = false
                }
            } else {
                do {
                    switch operation {
                        case "move":
                            try fm.moveItem(atPath: source, toPath: destination)
                        case "copy":
                            try fm.copyItem(atPath: source, toPath: destination)
                        default: break
                    }
                    writeToLog(theMessage: "\(source) backed up to \(destination).")
                } catch {
                    writeToLog(theMessage: "Unable to backup current item, \(source).")
                    success = false
                }
            }
        } else {
            writeToLog(theMessage: "\(source), was not found - no backup created.")
        }
        return success
    }
    // backup item - end
    
    func connectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
    
    func findAllUsers()->[String] {
        let defaultAuthority    = CSGetLocalIdentityAuthority().takeUnretainedValue()
        let identityClass       = kCSIdentityClassUser
        
        let query = CSIdentityQueryCreate(nil, identityClass, defaultAuthority).takeRetainedValue()
        
        var error : Unmanaged<CFError>? = nil
        
        CSIdentityQueryExecute(query, 2, &error)
        
        let results = CSIdentityQueryCopyResults(query).takeRetainedValue()
        
        let resultsCount = CFArrayGetCount(results)
        
        var allUsersArray = [String]()
        var allGeneratedUID = [String]()
        
        for idx in 0..<resultsCount {
            let identity    = unsafeBitCast(CFArrayGetValueAtIndex(results,idx),to: CSIdentity.self)
            let uuidString  = CFUUIDCreateString(nil, CSIdentityGetUUID(identity).takeUnretainedValue())
            allGeneratedUID.append(uuidString! as String)
            
            if let uuidNS = NSUUID(uuidString: uuidString! as String), let identityObject = CBIdentity(uniqueIdentifier: uuidNS as UUID, authority: CBIdentityAuthority.default()) {
                let username = identityObject.posixName
                allUsersArray.append(username)
            }
        }
        return allUsersArray
    }
    
    func getDateTime(x: Int8) -> String {
        let date = Date()
        let date_formatter = DateFormatter()
        if x == 1 {
            date_formatter.dateFormat = "YYYYMMdd_HHmmss"
        } else {
            date_formatter.dateFormat = "E d MMM yyyy HH:mm:ss"
        }
        let stringDate = date_formatter.string(from: date)
        
        return stringDate
    }
    
    func getHost_getPort(theURL: String) -> (String, String) {
        var local_theHost = ""
        var local_thePort = ""

        var local_URL_array = theURL.components(separatedBy: ":")
        local_theHost = local_URL_array[0]

        if local_URL_array.count > 1 {
            local_thePort = local_URL_array[1]
        } else {
            local_thePort = "443"
        }
        // remove trailing / in url and port if present
        if local_theHost.substring(from: local_theHost.index(before: local_theHost.endIndex)) == "/" {
            local_theHost = local_theHost.substring(to: local_theHost.index(before: local_theHost.endIndex))
        }
        if local_thePort.substring(from: local_thePort.index(before: local_thePort.endIndex)) == "/" {
            local_thePort = local_thePort.substring(to: local_thePort.index(before: local_thePort.endIndex))
        }

        return(local_theHost, local_thePort)
    }
    
    // get verify SSL settings from new server - start
    func getSslVerify(server: String, name: String, password: String) -> String {
        var returnString = "always_except_during_enrollment"
        var node = server + "/casper.jxml"
        node = node.replacingOccurrences(of: "//casper.jxml", with: "/casper.jxml")
        let pipe    = Pipe()
        let task    = Process()
        
        task.launchPath     = "/bin/bash"
        task.arguments      = ["-c", "/usr/bin/curl -m 20 -sk \(node) -H 'Content-Type: application/x-www-form-urlencoded' -d 'source=ReEnroller&username=\(name)&password=\(password)' -X POST | xpath '//verifySSLCert/text()'"]
        task.standardOutput = pipe
        let outputHandle    = pipe.fileHandleForReading
        
        outputHandle.readabilityHandler = { pipe in
            if let testResult = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                returnString = testResult.replacingOccurrences(of: "\n", with: "")
            } else {
                self.writeToLog(theMessage: "unknown error while attempting check SSL verification settings.")
            }
        }
        
        task.launch()
        task.waitUntilExit()
        
        return returnString
    }
    // get verify SSL settings from new server - end
    
    // configure verify SSL settings based on jamf binary version - start --> unused function, reads setting from server
    func verifySsl(veritySetting: String) -> String {
        var returnString = "-k"
        let pipe    = Pipe()
        let task    = Process()
        
        task.launchPath     = "/usr/local/bin/jamf"
        task.arguments      = ["version"]
        task.standardOutput = pipe
        let outputHandle    = pipe.fileHandleForReading
        
        outputHandle.readabilityHandler = { pipe in
            if let testResult = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                let theString = testResult.replacingOccurrences(of: "\n", with: "")
                let theStringArray = theString.components(separatedBy: "=")
                let theVersionArray = theStringArray[1].components(separatedBy: ".")
                let major = Int(theVersionArray[0])
                let minor = Int(theVersionArray[1])
                if (major! < 10) && (minor! < 98) {
                    returnString = "-k"
                } else {
                    returnString = "-verifySSLCert always_except_during_enrollment"
                }
            } else {
                self.writeToLog(theMessage: "unknown error while attempting jamf binary version check")
            }
        }
        
        task.launch()
        task.waitUntilExit()

        return returnString
    }
    // configure verify SSL settings based on jamf binary version - start

    // function to return exit code of bash command - start
    func myExitCode(cmd: String, args: String...) -> Int8 {
        //var pipe_pkg = Pipe()
        let task_pkg = Process()
        
        task_pkg.launchPath = cmd
        task_pkg.arguments = args
        //task_pkg.standardOutput = pipe_pkg
        //var test = task_pkg.standardOutput
        
        task_pkg.launch()
        task_pkg.waitUntilExit()
        let result = task_pkg.terminationStatus
        
        return(Int8(result))
        
    }
    // function to return exit code of bash command - end
    
    // function to perform nslookup of server and log results - start
    func myNslookup(server: String...) {
        var lookupResult  = ""
        let pipe    = Pipe()
        let task    = Process()
        
        task.launchPath     = "/usr/bin/nslookup"
        task.arguments      = server
        task.standardOutput = pipe
        let outputHandle    = pipe.fileHandleForReading
        
        outputHandle.readabilityHandler = { pipe in
            if let testResult = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                lookupResult = testResult.replacingOccurrences(of: "\n", with: "\n\t   ")
                self.writeToLog(theMessage: "nslookup results for \(server):\n\t   \(lookupResult)")
            } else {
                self.writeToLog(theMessage: "unknown error while attempting nslookup")
            }
        }
        
        task.launch()
        task.waitUntilExit()
        
    }
    // function to perform nslookup of server and log results - end
    
    // function to return mdm status - start
    func mdmInstalled(cmd: String, args: String...) -> Bool {
        var mdm = true
        var profileList = ""
        let mdmPipe    = Pipe()
        let mdmTask    = Process()
        
        mdmTask.launchPath     = cmd
        mdmTask.arguments      = args
        mdmTask.standardOutput = mdmPipe
        
        mdmTask.launch()
        mdmTask.waitUntilExit()
        
        let data = mdmPipe.fileHandleForReading.readDataToEndOfFile()
        profileList = String(data: data, encoding: String.Encoding.utf8)!
        
        writeToLog(theMessage: "profile list: \n\(String(describing: profileList))")
        
        let mdmCount = Int(profileList.trimmingCharacters(in: .whitespacesAndNewlines))!
        
//        if profileList?.range(of: "00000000-0000-0000-A000-4A414D460003") == nil {
        if mdmCount == 0 {
            mdm = false
        }
        return mdm
    }
    
    // function to mdm status - end
    
    func enrollNewJss(newServer: String, newInvite: String) {
        writeToLog(theMessage: "Starting the new enrollment.")
        
        // remove mdm profile - start
        if os.minorVersion < 13 {
            if removeAllProfiles == "false" {
                writeToLog(theMessage: "Attempting to remove mdm")
                if myExitCode(cmd: "/usr/local/bin/jamf", args: "removemdmprofile") == 0 {
                    writeToLog(theMessage: "Removed old MDM profile")
                } else {
                    writeToLog(theMessage: "There was a problem removing old MDM info. Falling back to old settings and Falling back to old settings and exiting!")
                    unverifiedFallback()
                    exit(1)
                }
            } else {
                // os.minorVersion < 13 {
                if myExitCode(cmd: "/bin/rm", args: "-fr", "/private/var/db/ConfigurationProfiles") == 0 {
                    writeToLog(theMessage: "Removed all configuration profiles")
                } else {
                    writeToLog(theMessage: "There was a problem removing all configuration profiles. Falling back to old settings and Falling back to old settings and exiting!")
                    unverifiedFallback()
                    exit(1)
                }
            }
        } else {
            writeToLog(theMessage: "High Sierra (10.13) or later.  Checking MDM status.")
            var counter = 0
            // try to remove mdm with jamf command
            if myExitCode(cmd: "/usr/local/bin/jamf", args: "removemdmprofile") == 0 {
                writeToLog(theMessage: "Removed old MDM profile")
            } else {
                writeToLog(theMessage: "There was a problem removing current MDM profile. Attempting remote command.")
            }
            while mdmInstalled(cmd: "/bin/bash", args: "-c", "/usr/bin/profiles -C | grep 00000000-0000-0000-A000-4A414D460003 | wc -l") {
                counter+=1
                _ = myExitCode(cmd: "/bin/bash", args: "-c", "killall jamf;/usr/local/bin/jamf policy -trigger apiMDM_remove")
                sleep(10)
                if counter > 6 {
                    writeToLog(theMessage: "Failed to remove MDM through remote command - exiting")
                    unverifiedFallback()
                    exit(1)
                } else {
                    writeToLog(theMessage: "Attempt \(counter) to remove MDM through remote command.")
                }
            }
            if counter == 0 {
                writeToLog(theMessage: "High Sierra (10.13) or later.  Checking MDM status shows no MDM.")
            } else {
                writeToLog(theMessage: "High Sierra (10.13) or later.  MDM has been removed.")
            }
        }
        // remove mdm profile - end
        
        // Install profile if present - start
        if !profileInstall() {
            unverifiedFallback()
            exit(1)
        }
        // Install profile if present - end
        
        // ensure we still have network connectivity - start
        var connectivityCounter = 0
        while !connectedToNetwork() {
            sleep(2)
            if connectivityCounter > 30 {
                writeToLog(theMessage: "There was a problem after removing old MDM configuration, network connectivity was lost. Will attempt to fall back to old settings and exiting!")
                unverifiedFallback()
                exit(1)
            }
            connectivityCounter += 1
            writeToLog(theMessage: "Waiting for network connectivity.")
        }
        // ensure we still have network connectivity - end
        
        // create a conf file for the new server
        writeToLog(theMessage: "Running: /usr/local/bin/jamf createConf -url \(newServer) -verifySSLCert \(createConfSwitches)")
        //        if myExitCode(cmd: "/usr/local/bin/jamf", args: "createConf", "-url", "\(newServer)", "\(createConfSwitches)") == 0 {
        if myExitCode(cmd: "/usr/local/bin/jamf", args: "createConf", "-url", "\(newServer)", "-verifySSLCert", createConfSwitches) == 0 {
            writeToLog(theMessage: "Created JAMF config file for \(newServer)")
        } else {
            writeToLog(theMessage: "There was a problem creating JAMF config file for \(newServer). Falling back to old settings and exiting.")
            unverifiedFallback()
            exit(1)
        }
        
        // verify the new server is listening
        if myExitCode(cmd: "/usr/bin/nc", args: "-z", "-G", "10", "\(newJSSHostname)", "\(newJSSPort)") == 0 {
            writeToLog(theMessage: "New server: \(newJSSHostname) is listening on port: \(newJSSPort)")
        } else {
            writeToLog(theMessage: "Unable to connect to new server: \(newServer) on port: \(newJSSPort)")
            writeToLog(theMessage: "Failure to enroll looks highly probable.")
            // perform nslookup on new server
            myNslookup(server: newJSSHostname)
        }

        // enroll with the new server using an invitation
        if myExitCode(cmd: "/usr/local/bin/jamf", args: "enroll", "-invitation", "\(newInvite)", "-noRecon", "-noPolicy", "-noManage") == 0 {
            writeToLog(theMessage: "Enrolled to new Jamf Server: \(newServer)")
        } else {
            writeToLog(theMessage: "There was a problem enrolling to new Jamf Server: \(newServer). Falling back to old settings and exiting!")
            unverifiedFallback()
            exit(1)
        }
        
        // verity connectivity to the new Jamf Pro server
        if myExitCode(cmd: "/usr/local/bin/jamf", args: "checkjssconnection") == 0 {
            writeToLog(theMessage: "Created JAMF config file for \(newServer)")
        } else {
            writeToLog(theMessage: "There was a problem checking the Jamf Server Connection to \(newServer). Falling back to old settings and exiting!")
            unverifiedFallback()
            exit(1)
        }
        
        // enable mdm
        if skipMdmCheck == "no" {
            if myExitCode(cmd: "/usr/local/bin/jamf", args: "mdm") == 0 {
                writeToLog(theMessage: "Enrolled - getting mdm profiles from new JSS.")
            } else {
                writeToLog(theMessage: "There was a problem getting mdm profiles from new JSS.")
                //unverifiedFallback()
                //exit(1)
            }
            sleep(2)
        } else {
            writeToLog(theMessage: "Skipping MDM check.")
        }
        if myExitCode(cmd: "/usr/local/bin/jamf", args: "manage") == 0 {
            writeToLog(theMessage: "Enrolled - getting management framework from new JSS.")
        } else {
            writeToLog(theMessage: "There was a problem getting management framework from new JSS. Falling back to old settings and exiting!")
            unverifiedFallback()
            exit(1)
        }
        
    }
    
    func profileInstall() -> Bool {
        if profileUuid != "" {
            if myExitCode(cmd: "/usr/bin/profiles", args: "-I", "-F", configProfilePath) == 0 {
                writeToLog(theMessage: "Installed config profile")
                return true
            } else {
                writeToLog(theMessage: "There was a problem installing the config profile. Falling back to old settings and exiting!")
                return false
                //unverifiedFallback()
                //exit(1)
            }
        }
        return true
    }
    
    func profileRemove() -> Bool {
        if profileUuid != "" {
            for i in 1...3 {
                if myExitCode(cmd: "/usr/bin/profiles", args: "-R", "-p", profileUuid) == 0 {
                    writeToLog(theMessage: "Configuration Profile was removed.")
                    sleep(2)
                    // verify we have connectivity - if not, try to add manual profile back
                    var connectivityCounter = 0
                    while !connectedToNetwork() {
                        sleep(2)
                        if connectivityCounter > 20 {
                            writeToLog(theMessage: "There was a problem after removing manually added MDM configuration, network connectivity could not be established without it. Will attempt to re-add and continue.")
                            if profileInstall() {
                              writeToLog(theMessage: "Manual profile has been re-installed.")
                            }
                            if i < 3 {
                                sleep(10)
                                if myExitCode(cmd: "/usr/bin/profiles", args: "-R", "-p", profileUuid) == 0 {
                                    writeToLog(theMessage: "Manual profile has been removed.")
                                }
                            } else {
                                return true
                            }
                        }
                        connectivityCounter += 1
                        writeToLog(theMessage: "Waiting for network connectivity.")
                    }
                return true
                } else {
                    writeToLog(theMessage: "There was a problem removing the Configuration Profile.")
                    return false
                    //exit(1)
                }
            }
        }
        return false
    }
    
    func unverifiedFallback() {
        // only roll back if there is something to roll back to
        // add back in when ready to to use app on machines not currrently enrolled
//        if oldURL != "" {
        writeToLog(theMessage: "Alert - There was a problem with enrolling your Mac to the new Jamf Server URL at \(newJSSHostname):\(newJSSPort). We are rolling you back to the old Jamf Server URL at \(oldURL)")

        // restore backup jamf binary - start
        do {
            // check for existing jamf plist, remove if it exists
            if fm.fileExists(atPath: origBinary) && fm.fileExists(atPath: bakBinary) {
                do {
                    try fm.removeItem(atPath: origBinary)
                } catch {
                    writeToLog(theMessage: "Unable to remove jamf binary.")
                    //exit(1)
                }
            }
            if fm.fileExists(atPath: bakBinary) {
                try fm.moveItem(atPath: bakBinary, toPath: origBinary)
                writeToLog(theMessage: "Moved the backup jamf binary back into place.")
            }
        }
        catch let error as NSError {
            writeToLog(theMessage: "There was a problem moving the backup jamf binary back into place. Error: \(error)")
            //exit(1)
        }
        // restore backup jamf binary - end
        
        // restore original ConfigurationProfiles directory - start
        if os.minorVersion < 13 {
            if fm.fileExists(atPath: origProfilesDir) {
                do {
                    try fm.removeItem(atPath: origProfilesDir)
                    do {
                        try fm.moveItem(atPath: bakProfilesDir, toPath: origProfilesDir)
                    } catch {
                        writeToLog(theMessage: "There was a problem restoring original ConfigurationProfiles")
                    }
                } catch {
                    writeToLog(theMessage: "There was a problem removing original ConfigurationProfiles")
                }
            }
            if fm.fileExists(atPath: bakProfilesDir) {
                do {
                    try fm.moveItem(atPath: bakProfilesDir, toPath: origProfilesDir)
                    } catch {
                        writeToLog(theMessage: "There was a problem restoring original ConfigurationProfiles")
                    }
            }
        }
        // restore original ConfigurationProfiles directory - end
        
        // restore backup jamf keychain - start
        do {
            // check for existing jamf.keychain, remove if it exists
            if fm.fileExists(atPath: origKeychainFile)  && fm.fileExists(atPath: bakKeychainFile) {
                do {
                    try fm.removeItem(atPath: origKeychainFile)
                } catch {
                    writeToLog(theMessage: "Unable to remove jamf.keychain for new Jamf server")
                    //exit(1)
                }
            }
            if fm.fileExists(atPath: bakKeychainFile) {
                try fm.moveItem(atPath: bakKeychainFile, toPath: origKeychainFile)
                writeToLog(theMessage: "Moved the backup keychain back into place.")
            }
        }
        catch let error as NSError {
            writeToLog(theMessage: "There was a problem moving the backup keychain back into place. Error: \(error)")
            //exit(1)
        }
        // restore backup jamf keychain - end
        
        // restore backup jamf plist - start
        do {
            // check for existing jamf plist, remove if it exists
            if fm.fileExists(atPath: jamfPlistPath) && fm.fileExists(atPath: bakjamfPlistPath) {
                do {
                    try fm.removeItem(atPath: jamfPlistPath)
                } catch {
                    writeToLog(theMessage: "Unable to remove jamf plist.")
                    //exit(1)
                }
            }
            if fm.fileExists(atPath: bakjamfPlistPath) {
                try fm.moveItem(atPath: bakjamfPlistPath, toPath: jamfPlistPath)
                writeToLog(theMessage: "Moved the backup jamf plist back into place.")
            }
        }
        catch let error as NSError {
            writeToLog(theMessage: "There was a problem moving the backup jamf plist back into place. Error: \(error)")
            //exit(1)
        }
        // restore backup jamf plist - end
        
        // re-enable mdm management from old server on the system - end
        writeToLog(theMessage: "Exiting failback.")
        exit(1)
    }
    
    func verifyNewEnrollment() {
        for i in 1...10 {
            // test for a policy on the new Jamf Pro server and that it ran successfully
            if myExitCode(cmd: "/usr/local/bin/jamf", args: "policy", "-trigger", "jssmigrationcheck") == 0 && fm.fileExists(atPath: verificationFile) {
                writeToLog(theMessage: "Verified migration with sample policy using jssmigrationcheck trigger.")
                writeToLog(theMessage: "Policy created the check file.")
                return
            } else {
                writeToLog(theMessage: "Attempt \(i): There was a problem verifying migration with sample policy using jssmigrationcheck trigger.")
                writeToLog(theMessage: "/usr/local/bin/jamf policy -trigger jssmigrationcheck")
                if i == 10 {
                    writeToLog(theMessage: "Falling back to old settings and exiting!")
                    unverifiedFallback()
                    exit(1)
                }
                sleep(5)
            }
        }   // for i in 1...10 - end
    }
    
    func verifiedCleanup() {
        do {
            try fm.removeItem(atPath: bakBinary)
            writeToLog(theMessage: "Removed backup jamf binary.")
        }
        catch let error as NSError {
            writeToLog(theMessage: "There was a problem removing backup jamf binary.  Error: \(error)")
            //exit(1)
        }
        do {
            try fm.removeItem(atPath: bakKeychainFile)
            writeToLog(theMessage: "Removed backup jamf keychain.")
        }
        catch let error as NSError {
            writeToLog(theMessage: "There was a problem removing backup jamf keychain.  Error: \(error)")
            //exit(1)
        }
        do {
            try fm.removeItem(atPath: bakjamfPlistPath)
            writeToLog(theMessage: "Removed backup jamf plist.")
        }
        catch let error as NSError {
            writeToLog(theMessage: "There was a problem removing backup jamf plist.  Error: \(error)")
            //exit(1)
        }
        if os.minorVersion < 13 {
            do {
                try fm.removeItem(atPath: bakProfilesDir)
                writeToLog(theMessage: "Removed backup ConfigurationProfiles dir.")
            }
            catch let error as NSError {
                writeToLog(theMessage: "There was a problem removing backup ConfigurationProfiles dir.  Error: \(error)")
                //exit(1)
            }
        }
        
        // remove config profile if marked as such - start
        writeToLog(theMessage: "Checking if config profile removal is required...")
        if removeConfigProfile == "true" {
            if !profileRemove() {
                writeToLog(theMessage: "Unable to remove configuration profile")
            }
        } else {
            writeToLog(theMessage: "Configuration profile is not marked for removal.")
        }
        // remove config profile if marked as such - end
        
        // update inventory - start
        writeToLog(theMessage: "Launching Recon...")
        if myExitCode(cmd: "/usr/local/bin/jamf", args: "recon") == 0 {
            writeToLog(theMessage: "Submitting full recon to \(newJSSHostname):\(newJSSPort).")
        } else {
            writeToLog(theMessage: "There was a problem submitting full recon to \(newJSSHostname):\(newJSSPort).")
            //exit(1)
        }
        // update inventory - end
        
        // Remove ..JAMF/ReEnroller folder - start
        if removeReEnroller == "yes" {
            do {
                try fm.removeItem(atPath: "/Library/Application Support/JAMF/ReEnroller")
                writeToLog(theMessage: "Removed ReEnroller folder.")
            }
            catch let error as NSError {
                writeToLog(theMessage: "There was a problem removing ReEnroller folder.  Error: \(error)")
            }
        } else {
            writeToLog(theMessage: "ReEnroller folder is left intact.")
        }
        // Remove ..JAMF/ReEnroller folder - end
        
        // remove a previous launchd, if it exists, from /private/tmp
        if fm.fileExists(atPath: "/private/tmp/com.jamf.ReEnroller.plist") {
            do {
                try fm.removeItem(atPath: "/private/tmp/com.jamf.ReEnroller.plist")
            } catch {
                writeToLog(theMessage: "Unable to remove existing plist in /private/tmp")
            }
        }
        
        //  move and unload launchd to finish up.
        if fm.fileExists(atPath: "/Library/LaunchDaemons/com.jamf.ReEnroller.plist") {
            do {
                try fm.moveItem(atPath: "/Library/LaunchDaemons/com.jamf.ReEnroller.plist", toPath: "/private/tmp/com.jamf.ReEnroller.plist")
                writeToLog(theMessage: "Moved launchd to /private/tmp.")
                
                // unload the launchd
                if myExitCode(cmd: "/bin/launchctl", args: "unload", "/tmp/com.jamf.ReEnroller.plist") != 0 {
                    writeToLog(theMessage: "There was a problem unloading the launchd.")
                } else {
                    writeToLog(theMessage: "Launchd unloaded.")
                }
                
            } catch {
                writeToLog(theMessage: "Could not move launchd")
            }
        }
    }
    
    
    
    func alert_dialog(header: String, message: String) {
        let dialog: NSAlert = NSAlert()
        dialog.messageText = header
        dialog.informativeText = message
        dialog.alertStyle = NSAlertStyle.warning
        dialog.addButton(withTitle: "OK")
        dialog.runModal()
        //return true
    }   // func alert_dialog - end
    
    func checkURL(theUrl: String) -> Int8 {
        
        var port = ""
        let task_telnet = Process()
        var str = theUrl.lowercased().replacingOccurrences(of: "https://", with: "")
        str = str.lowercased().replacingOccurrences(of: "http://", with: "")
        
        var str_array = str.components(separatedBy: ":")
        
        var fqdn = str_array[0]
        
        if str_array.count > 1 {
            let port_array = str_array[1].components(separatedBy: "/")
            port = port_array[0]
        } else {
            port = "443"
            // for multi-context jamf server
            var fqdn_array = fqdn.components(separatedBy: "/")
            fqdn = fqdn_array[0]
        }
        
        task_telnet.launchPath = "/bin/bash"
        task_telnet.arguments = ["-c", "nc -z -G 10 \(fqdn) \(port)"]
        
        task_telnet.launch()
        task_telnet.waitUntilExit()
        let result = task_telnet.terminationStatus
        
        return(Int8(result))
    }   // func checkURL - end
    
    func dropTrailingSlash(theSentString: String) -> String {
        var theString = theSentString
        if theString.substring(from: theString.index(before: theString.endIndex)) == "/" {
            theString = theString.substring(to: theString.index(before: theString.endIndex))
        }
        return theString
    }
    
    func writeToLog(theMessage: String) {
        LogFileW?.seekToEndOfFile()
        let fullMessage = getDateTime(x: 2) + " [ReEnroller]:    " + theMessage + "\n"
        let LogText = (fullMessage as NSString).data(using: String.Encoding.utf8.rawValue)
        LogFileW?.write(LogText!)
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        
        LogFileW = FileHandle(forUpdatingAtPath: (logFilePath))
        
        var basePlistPath = myBundlePath
        // remove /ReEnroller.app from the basePlistPath to get path to folder
        basePlistPath = basePlistPath.substring(to: basePlistPath.index(basePlistPath.startIndex, offsetBy: (basePlistPath.characters.count-15)))

        let settingsFile = basePlistPath+"/settings.plist"
        
        //print("path to configured settings file: \(settingsFile)")
        if fm.fileExists(atPath: settingsFile) {
            // hide the icon from the Dock when running
            //NSApplication.shared().setActivationPolicy(NSApplicationActivationPolicy.prohibited)

            let settingsPlistXML = fm.contents(atPath: settingsFile)!
            do{
                writeToLog(theMessage: "Reading settings from: \(settingsFile)")
                plistData = try PropertyListSerialization.propertyList(from: settingsPlistXML,
                                                                       options: .mutableContainersAndLeaves,
                                                                       format: &format)
                    as! [String : AnyObject]
            }
            catch{
                writeToLog(theMessage: "Error reading plist: \(error), format: \(format)")
            }
            
            if plistData["newJSSHostname"] != nil && plistData["newJSSPort"] != nil && plistData["theNewInvite"] != nil {
                writeToLog(theMessage: "Found configuration for new Jamf Pro server: \(String(describing: plistData["newJSSHostname"])), begin migration")
                
                // Parameters for the new emvironment
                newJSSHostname = plistData["newJSSHostname"]! as! String
                newJSSPort = plistData["newJSSPort"]! as! String

                theNewInvite = plistData["theNewInvite"]! as! String
                newJssMgmtUrl = "https://\(newJSSHostname):\(newJSSPort)"
                writeToLog(theMessage: "newServer: \(newJSSHostname)\nnewPort: \(newJSSPort)")
                
                // read config profile vars
                if plistData["profileUUID"] != nil {
                    profileUuid = plistData["profileUUID"]! as! String
                    writeToLog(theMessage: "UDID of included profile is: \(profileUuid)")
                } else {
                    writeToLog(theMessage: "No configuration profiles included for install.")
                }
                if plistData["removeProfile"] != nil {
                    removeConfigProfile = plistData["removeProfile"]! as! String
                }
                if plistData["removeAllProfiles"] != nil {
                    removeAllProfiles = plistData["removeAllProfiles"]! as! String
                }
                if plistData["removeReEnroller"] != nil {
                    removeReEnroller = plistData["removeReEnroller"]! as! String
                }
                if plistData["createConfSwitches"] != nil {
                    createConfSwitches = plistData["createConfSwitches"]! as! String
                }
                if plistData["skipMdmCheck"] != nil {
                    skipMdmCheck = plistData["skipMdmCheck"]! as! String
                }
                
                
                // look for an existing jamf plist file
                if fm.fileExists(atPath: jamfPlistPath) {
                    // need to convert jamf plist to xml (plutil -convert xml1 some.plist)
                    if myExitCode(cmd: "/usr/bin/plutil", args: "-convert", "xml1", jamfPlistPath) != 0 {
                        writeToLog(theMessage: "Unable to read current jamf configuration.  It is either corrupt or client is not enrolled.")
                        //exit(1)
                    } else {
                    
                        let plistXML = FileManager.default.contents(atPath: jamfPlistPath)!
                        do{
                            jamfPlistData = try PropertyListSerialization.propertyList(from: plistXML,
                                                                                       options: .mutableContainersAndLeaves,
                                                                                       format: &format)
                                as! [String:AnyObject]
                        } catch {
                            writeToLog(theMessage: "Error reading plist: \(error), format: \(format)")
                        }
                        if jamfPlistData["jss_url"] != nil {
                            oldURL = jamfPlistData["jss_url"]! as! String
                        }
                        writeToLog(theMessage: "Found old Jamf Pro server: \(oldURL)")
                        // convert the jamf plist back to binary (plutil -convert binary1 some.plist)
                        if myExitCode(cmd: "/usr/bin/plutil", args: "-convert", "binary1", jamfPlistPath) != 0 {
                            writeToLog(theMessage: "There was an error converting the jamf.plist back to binary")
                        }
                    }
                } else {
                    oldURL = ""
                    writeToLog(theMessage: "Machine is not currently enrolled, exitting.")
                    exit(0)
                }
                
                beginMigration()
            } else {
                writeToLog(theMessage: "Configuration not found, launching GUI.")
                
                retry_TextField.stringValue = "30"
                removeReEnroller_Button.state = 1
                rndPwdLen_TextField?.isEnabled = false
                rndPwdLen_TextField?.stringValue = "8"
                
                ReEnroller_window.backgroundColor = NSColor(red: 0x9F/255.0, green:0xB9/255.0, blue:0xCC/255.0, alpha: 1.0)
                NSApplication.shared().setActivationPolicy(NSApplicationActivationPolicy.regular)
                ReEnroller_window.setIsVisible(true)
            }
            
        } else {
            writeToLog(theMessage: "Configuration not found, launching GUI.")
            
            retry_TextField.stringValue = "30"
            removeReEnroller_Button.state = 1
            rndPwdLen_TextField?.isEnabled = false
            rndPwdLen_TextField?.stringValue = "8"

            ReEnroller_window.backgroundColor = NSColor(red: 0x9F/255.0, green:0xB9/255.0, blue:0xCC/255.0, alpha: 1.0)
            NSApplication.shared().setActivationPolicy(NSApplicationActivationPolicy.regular)
            ReEnroller_window.setIsVisible(true)
        }
        
    }
    
    //    --------------------------------------- grab sites - start ---------------------------------------
    
    func getSites(completion: @escaping (Dictionary<String, Int>) -> Dictionary<String, Int>) {
        var local_allSites = Dictionary<String, Int>()
        
        let serverEncodedURL = NSURL(string: resourcePath)
        let serverRequest = NSMutableURLRequest(url: serverEncodedURL! as URL)
        //        print("serverRequest: \(serverRequest)")
        serverRequest.httpMethod = "GET"
        let serverConf = URLSessionConfiguration.default
        serverConf.httpAdditionalHeaders = ["Authorization" : "Basic \(jssCredentialsBase64)", "Content-Type" : "application/json", "Accept" : "application/json"]
        let serverSession = Foundation.URLSession(configuration: serverConf, delegate: self, delegateQueue: OperationQueue.main)
        let task = serverSession.dataTask(with: serverRequest as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                // print("httpResponse: \(String(describing: response))")
                do {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    //                    print("\(json)")
                    if let endpointJSON = json as? [String: Any] {
                        if let siteEndpoints = endpointJSON["sites"] as? [Any] {
                            let siteCount = siteEndpoints.count
                            if siteCount > 0 {
                                for i in (0..<siteCount) {
                                    // print("site \(i): \(siteEndpoints[i])")
                                    let theSite = siteEndpoints[i] as! [String:Any]
                                    // print("theSite: \(theSite))")
                                    // print("site \(i) name: \(String(describing: theSite["name"]))")
                                    let theSiteName = theSite["name"] as! String
                                    local_allSites[theSiteName] = theSite["id"] as? Int
                                }
                            }
                        }
                    }   // if let serverEndpointJSON - end
                    
                } catch {
                    print("[- debug -] Existing endpoints: error serializing JSON: \(error)\n")
                }   // end do/catch
                
                if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                    //print(httpResponse.statusCode)
                    
                    self.site_Button.isEnabled = true
                    completion(local_allSites)
                } else {
                    // something went wrong
                    print("status code: \(httpResponse.statusCode)")
                        self.alert_dialog(header: "Alert", message: "Unable to look up Sites.  Verify the account being used is able to login and view Sites.\nStatus Code: \(httpResponse.statusCode)")
                    
                    self.enableSites_Button.state = 0
                    self.site_Button.isEnabled = false
                    completion([:])
                    
                }   // if httpResponse/else - end
            }   // if let httpResponse - end
            //            semaphore.signal()
        })  // let task = - end
        task.resume()
    }
    
    //    --------------------------------------- grab sites - end ---------------------------------------

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        // bring app to the foreground
        jssUrl_TextField.becomeFirstResponder()

        NSApplication.shared().activate(ignoringOtherApps: true)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
}
