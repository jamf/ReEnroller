//
//  ViewController.swift
//  ReEnroller
//
//  Created by Leslie Helou on 2/19/17
//  Based on the bash ReEnroller script by Douglas Worley
//
//******************************************************************************************
//
//  Copyright (c) 2017 Jamf.  All rights reserved.
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
//******************************************************************************************

// PI-000524: prevents management account password from being reset if password on
//            client doesn't match password on server.

import Cocoa
import Collaboration
import CryptoKit
import Foundation
import Security
import SystemConfiguration
import WebKit

class ViewController: NSViewController, URLSessionDelegate {

//    @IBOutlet weak var ReEnroller_window: NSWindow!

//    @IBOutlet weak var help_Window: NSWindow!
//    @IBOutlet weak var help_WebView: WKWebView!
//    @IBOutlet weak var reconMode_TabView: NSTabView!

   // @IBOutlet weak var reEnroll_button: NSButton!
   // @IBOutlet weak var enroll_button: NSButton!
    
    @IBOutlet weak var ssid_TextField: NSTextField!
    @IBOutlet weak var ssidKey_TextField: NSSecureTextField!
    @IBOutlet weak var security_Button: NSPopUpButton!
    
    @IBOutlet weak var quickAdd_PathControl: NSPathControl!
    @IBOutlet weak var profile_PathControl: NSPathControl!
    @IBOutlet weak var removeProfile_Button: NSButton!  // removeProfile_Button.state == 1 if checked
    @IBOutlet weak var removeAllProfiles_Button: NSButton!
    @IBOutlet weak var jamfSchool_Button: NSButton!
    @IBOutlet weak var newEnrollment_Button: NSButton!

    // non recon fields
    @IBOutlet weak var jssUrl_TextField: NSTextField!
    @IBOutlet weak var jssUsername_TextField: NSTextField!
    @IBOutlet weak var jssPassword_TextField: NSSecureTextField!
    @IBOutlet weak var mgmtAccount_TextField: NSTextField!
    @IBOutlet weak var mgmtAcctPwd_TextField: NSSecureTextField!
    @IBOutlet weak var mgmtAcctPwd2_TextField: NSSecureTextField!
    @IBOutlet weak var rndPwdLen_TextField: NSTextField?

    // For Jamf School
    @IBOutlet weak var jamfSchoolBgnd_TextField: NSTextField!
    @IBOutlet weak var jamfSchoolHeader_Label: NSTextField!
    @IBOutlet weak var jamfSchoolUrl_Label: NSTextField!
    @IBOutlet weak var jamfSchoolUrl_TextField: NSTextField!
    @IBOutlet weak var networkId_Label: NSTextField!
    @IBOutlet weak var apiKey_Label: NSTextField!
    @IBOutlet weak var networkId_TextField: NSTextField!
    @IBOutlet weak var apiKey_TextField: NSTextField!

    // management account buttons
    @IBOutlet weak var mgmtAcctCreate_button: NSButton!
    @IBOutlet weak var mgmtAcctHide_button: NSButton!
    @IBOutlet weak var randomPassword_button: NSButton!

    @IBOutlet weak var retainSite_Button: NSButton!
    @IBOutlet weak var enableSites_Button: NSButton!
    @IBOutlet weak var site_Button: NSPopUpButton!
    @IBOutlet weak var skipHealthCheck_Button: NSButton!
    @IBOutlet weak var skipMdmCheck_Button: NSButton!
    @IBOutlet weak var createPolicy_Button: NSButton!
    @IBOutlet weak var runPolicy_Button: NSButton!
    @IBOutlet weak var policyId_Textfield: NSTextField!
    @IBOutlet weak var deviceEnrollment_Button: NSButton!
    @IBOutlet weak var markAsMigrated_Button: NSButton!
    @IBOutlet weak var migratedLabel_TextField: NSTextField!
    @IBOutlet weak var migratedAttribute_Button: NSPopUpButton!
    @IBOutlet weak var removeMDM_Button: NSButton!
    @IBOutlet weak var removeMdmWhen_Button: NSPopUpButton!
    @IBOutlet weak var removeReEnroller_Button: NSButton!
    @IBOutlet weak var maxRetries_Textfield: NSTextField!
    @IBOutlet weak var retry_TextField: NSTextField!
    @IBOutlet weak var separatePackage_button: NSButton!

    @IBOutlet weak var processQuickAdd_Button: NSButton!
    @IBOutlet weak var spinner: NSProgressIndicator!

    let origBinary = "/usr/local/jamf/bin/jamf"
    let bakBinary = "/Library/Application Support/JAMF/ReEnroller/backup/jamf.bak"

    let origProfilesDir = "/var/db/ConfigurationProfiles"
    let bakProfilesDir = "/Library/Application Support/JAMF/ReEnroller/backup/ConfigurationProfiles.bak"

    let origKeychainFile = "/Library/Application Support/JAMF/JAMF.keychain"
    let bakKeychainFile  = "/Library/Application Support/JAMF/ReEnroller/backup/JAMF.keychain.bak"

    let jamfPlistPath = "/Library/Preferences/com.jamfsoftware.jamf.plist"
    let bakjamfPlistPath = "/Library/Application Support/JAMF/ReEnroller/backup/com.jamfsoftware.jamf.plist.bak"

    let airportPrefs = "/Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist"
    let bakAirportPrefs = "/Library/Application Support/JAMF/ReEnroller/backup/com.apple.airport.preferences.plist.bak"

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

    var alert_answer: Bool  = false
    var oldURL              = ""
    var newURL              = [String]()
    var newJSSURL           = ""
    var newJSSHostname      = ""
    var newJSSPort          = ""
    var httpProtocol        = ""
    
    var ssid                = ""
    var ssidKey             = ""
    // change the below key and build the app to secure your WiFi passphrase
    let base64SymetricKey   = "weTN8wXVCHux62FyovLeMJs7VuAM49TlIwe1EQEF0Ww="

    let safeCharSet         = CharacterSet.alphanumerics
    var jssUsername         = ""
    var jssPassword         = ""
    var resourcePath        = ""
    var jssCredentials      = ""
    var jssCredsBase64      = ""
    var siteDict            = Dictionary<String, Any>()
    var siteId              = "-1"
    var mgmtAccount         = ""    // manangement account read from plist
    var mgmtAcctPwdXml      = ""    // static management account password
//    var acctMaintPwdXml     = ""    // ensures the managment account password is properly randomized
    var mgmtAcctPwdLen      = 8
    var mgmtAcctCreate      = "true"
    var mgmtAcctHide        = "true"
    var pkgBuildResult:Int8 = 0

    var markAsMigrated      = false
    var migratedAttribute   = "room"

    var removeMDM           = true
    var removeMdmWhen       = "Before"

    var newJssArray         = [String]()
    var shortHostname       = ""

    var newEnrollment       = false

    // read this from Jamf server
    var createConfSwitches  = ""

    var newJssMgmtUrl       = ""
    var theNewInvite        = ""
    var removeReEnroller    = "yes"         // by default delete the ReEnroller folder after enrollment
    var callEnrollment      = "no"          // defaults to not calling automated device enrollment, unless we're Big Sur or above
    
    var retainSite          = "true"        // by default retain site when re-enrolling
    var skipHealthCheck     = "no"          // by default do not skip mdm check
    var skipMdmCheck        = "no"          // by default do not skip mdm check
    var StartInterval       = 1800          // default retry interval is 1800 seconds (30 minutes)
    var includesMsg         = "includes"
    var includesMsg2        = ""
    var policyMsg           = ""
    var postInstallPolicyId  = ""

    var profileUuid         = ""
    var removeConfigProfile = ""
    var removeAllProfiles   = ""

    // Jamf School
    var jamfSchoolMigration = 0
    var jamfSchoolUrl       = ""
    var jamfSchoolToken     = ""

//    var safePackageURL      = ""
    var safeProfileURL      = ""
    var Pipe_pkg            = Pipe()
    var task_pkg            = Process()

    var maxRetries          = -1
    var retryCount          = 0

    let userDefaults = UserDefaults.standard

    // OS version info
    let os = ProcessInfo().operatingSystemVersion

    var startMigrationQ = OperationQueue()
    var enrollmentQ     = OperationQueue()

    @IBAction func jamfSchool_fn(_ sender: Any) {
        if self.jamfSchool_Button.state.rawValue == 1 {
            self.jamfSchoolBgnd_TextField.isHidden = false
            self.jamfSchoolHeader_Label.isHidden   = false
            self.jamfSchoolUrl_Label.isHidden      = false
            self.jamfSchoolUrl_TextField.isHidden  = false
            self.networkId_Label.isHidden          = false
            self.networkId_TextField.isHidden      = false
            self.apiKey_Label.isHidden             = false
            self.apiKey_TextField.isHidden         = false
            newEnrollment_Button.state             = NSControl.StateValue(rawValue: 1)
            newEnrollment_Button.isEnabled         = false
        } else {
            self.jamfSchoolBgnd_TextField.isHidden = true
            self.jamfSchoolHeader_Label.isHidden   = true
            self.jamfSchoolUrl_Label.isHidden      = true
            self.jamfSchoolUrl_TextField.isHidden  = true
            self.networkId_Label.isHidden          = true
            self.networkId_TextField.isHidden      = true
            self.apiKey_Label.isHidden             = true
            self.apiKey_TextField.isHidden         = true
            newEnrollment_Button.state             = NSControl.StateValue(rawValue: 0)
            newEnrollment_Button.isEnabled         = true
        }
        newEnrollment_fn(self)
    }

    @IBAction func localHelp(_ sender: Any) {

        DispatchQueue.main.async {
            var helpIsOpen = false
            var windowsCount = 0
            windowsCount = NSApp.windows.count
            for i in (0..<windowsCount) {
                if NSApp.windows[i].title == "Help" {
                    NSApp.windows[i].makeKeyAndOrderFront(self)
                    helpIsOpen = true
                    break
                }
            }
            if !helpIsOpen {
                let storyboard = NSStoryboard(name: "Main", bundle: nil)
                let helpWindowController = storyboard.instantiateController(withIdentifier: "Help View Controller") as! NSWindowController
                helpWindowController.window?.hidesOnDeactivate = false
                helpWindowController.showWindow(self)
            }
        }
    }

    @IBAction func markAsMigrated_fn(_ sender: Any) {
        if markAsMigrated_Button.state.rawValue == 1 {
            migratedLabel_TextField.isHidden  = false
            migratedAttribute_Button.isHidden = false
        } else {
            migratedLabel_TextField.isHidden  = true
            migratedAttribute_Button.isHidden = true
        }
    }

    @IBAction func newEnrollment_fn(_ sender: Any) {
        if newEnrollment_Button.state.rawValue == 1 {
            retainSite_Button.isEnabled        = false
            retainSite_Button.state            = NSControl.StateValue(rawValue: 0)
//            enableSites_Button.isEnabled       = false
            markAsMigrated_Button.isEnabled    = false
            markAsMigrated_Button.state        = NSControl.StateValue(rawValue: 0)
            migratedLabel_TextField.isHidden   = true
            migratedAttribute_Button.isEnabled = false
            migratedAttribute_Button.isHidden  = true
            removeMDM_Button.isEnabled         = false
            removeMDM_Button.state             = NSControl.StateValue(rawValue: 0)
            removeMdmWhen_Button.isHidden      = true
        } else {
            retainSite_Button.isEnabled        = true
            if enableSites_Button.state.rawValue == 0 {
                retainSite_Button.state        = NSControl.StateValue(rawValue: 1)
            }
//            enableSites_Button.isEnabled       = true
            markAsMigrated_Button.isEnabled    = true
            migratedAttribute_Button.isEnabled = true
            removeMDM_Button.isEnabled         = true
            removeMDM_Button.state             = NSControl.StateValue(rawValue: 1)
            removeMdmWhen_Button.isHidden      = false
        }
    }


    // process function - start
    @IBAction func process(_ sender: Any) {
        // get invitation code - start
//        var jssUrl = jssUrl_TextField.stringValue.baseUrl
        JamfProServer.destination = jssUrl_TextField.stringValue.baseUrl
        if "\(JamfProServer.destination)" == "" {
            Alert.shared.display(header: "Alert", message: "Please provide the URL for the new server.")
            return
        }
//        jssUrl = dropTrailingSlash(theSentString: jssUrl)

        let mgmtAcct = mgmtAccount_TextField.stringValue
        if "\(mgmtAcct)" == "" {
            Alert.shared.display(header: "Attention", message: "You must supply a management account username.")
            mgmtAccount_TextField.becomeFirstResponder()
            return
        }

        // fix special characters in management account name
        let mgmtAcctNameXml = xmlEncode(rawString: mgmtAcct)

        if randomPassword_button.state.rawValue == 0 {
            // known password
            let mgmtAcctPwd = mgmtAcctPwd_TextField.stringValue
            let mgmtAcctPwd2 = mgmtAcctPwd2_TextField.stringValue
            if "\(mgmtAcctPwd)" == "" {
                Alert.shared.display(header: "Attention", message: "Password cannot be left blank.")
                mgmtAccount_TextField.becomeFirstResponder()
                return
            }
            if "\(mgmtAcctPwd)" != "\(mgmtAcctPwd2)" {
                Alert.shared.display(header: "Attention", message: "Management account passwords do not match.")
                mgmtAcctPwd_TextField.becomeFirstResponder()
                return
            }

            // fix special characters in management account password
            let mgmtAcctPwdEncode = xmlEncode(rawString: mgmtAcctPwd)
            mgmtAcctPwdXml = "<ssh_password>\(mgmtAcctPwdEncode)</ssh_password>"
//            mgmtAcctPwdXml = "<ssh_password>\(mgmtAcctPwd)</ssh_password>"

            // can't use this to (re)set management account password, receive the following
//            Executing Policy Change Password
//            Error: The Managed Account Password could not be changed.
            // acctMaintPwdXml = "<account_maintenance><management_account><action>specified</action><managed_password>\(mgmtAcctPwd)</managed_password></management_account></account_maintenance>"
        } else {
            // random password
            // like to get rid of this - find way to change password when client and JPS differ
//          check the local system for the existance of the management account
            if ( userOperation(mgmtUser: mgmtAcct, operation: "find") != "" ) {
                Alert.shared.display(header: "Attention:", message: "Account \(mgmtAcct) cannot be used with a random password as it exists on this system.")
                return
            }
            /*
            // verify random password lenght is an integer - start
            let pattern = "(^[0-9]*$)"
            let regex1 = try! NSRegularExpression(pattern: pattern, options: [])
            let matches = regex1.matches(in: (rndPwdLen_TextField?.stringValue)!, options: [], range: NSRange(location: 0, length: (rndPwdLen_TextField?.stringValue.count)!))
            if matches.count != 0 {
                //                print("valid")
                mgmtAcctPwdLen = Int((rndPwdLen_TextField?.stringValue)!)!
//                print("pwd len: \(mgmtAcctPwdLen)")
                if (mgmtAcctPwdLen) > 255 || (mgmtAcctPwdLen) < 8 {
                    Alert.shared.display(header: "Attention:", message: "Verify an random password length is between 8 and 255.")
                    return
                }
            } else {
                Alert.shared.display(header: "Attention:", message: "Verify an interger value was entered for the random password length.")
                return
            }
            // verify random password lenght is an integer - end
            // create a random password
            mgmtAcctPwdXml = myExitValue(cmd: "/bin/bash", args: "-c", "/usr/bin/uuidgen")[0]
             acctMaintPwdXml = "<account_maintenance><management_account><action>random</action><managed_password_length>\(mgmtAcctPwdLen)</managed_password_length></management_account></account_maintenance>"
            */
            mgmtAcctPwdXml = ""
            
        }

        // Jamf School check - start
        if jamfSchool_Button.state.rawValue == 1 {
            if networkId_TextField.stringValue == "" || apiKey_TextField.stringValue == "" {
                Alert.shared.display(header: "Attention:", message: "Migrating from Jamf School requires the server URL, the Network ID, and API key.")
                return
            } else {
               // generate token for Jamf School API
                let jamfSchoolCreds = "\(networkId_TextField.stringValue):\(apiKey_TextField.stringValue)"
                jamfSchoolToken     = jamfSchoolCreds.data(using: .utf8)?.base64EncodedString() ?? ""
//                self.plistData["jamfSchoolUrl"]   = jamfSchoolUrl_TextField.stringValue as AnyObject
//                self.plistData["jamfSchoolToken"] = jamfSchoolBase64Creds as AnyObject
           }
        }
        // Jamf School check - start

        self.spinner.startAnimation(self)

        healthCheck(server: JamfProServer.destination) {
            (result: [String]) in
            print("health check result: \(result)")
            if ( result[1] != "[]" ) {
                let lightFormat = self.removeTag(xmlString: result[1].replacingOccurrences(of: "><", with: ">\n<"))
                Alert.shared.display(header: "Attention", message: "The new server, \(JamfProServer.destination), does not appear ready for enrollments.\nResult of healthCheck: \(lightFormat)\nResponse code: \(result[0])")
                self.spinner.stopAnimation(self)
                return
            } else {
                // server is reachable
                self.jssUsername = self.jssUsername_TextField.stringValue
                self.jssPassword = self.jssPassword_TextField.stringValue
                
                if "\(self.jssUsername)" == "" || "\(self.jssPassword))" == "" {
                    Alert.shared.display(header: "Alert", message: "Please provide both a username and password for the server.")
                    self.spinner.stopAnimation(self)
                    return
                }
                
                // save Jamf Pro URL and user
                self.userDefaults.set("\(self.jssUrl_TextField.stringValue.baseUrl)", forKey: "jamfProUrl")
                self.userDefaults.set("\(self.jssUsername_TextField.stringValue)", forKey: "jamfProUser")
                self.userDefaults.synchronize()

                let jpsCredentials = "\(self.jssUsername):\(self.jssPassword)"
                let jpsBase64Creds = jpsCredentials.data(using: .utf8)?.base64EncodedString() ?? ""

                
                JamfPro().getToken(serverUrl: JamfProServer.destination, base64creds: jpsBase64Creds) {
                    authResult in
                    
                    let (statusCode,theResult) = authResult
                    switch theResult {
                    case "success":
                        print("jpversion: \(JamfProServer.version)")
                        
                        let verifySslSetting = "<verifySSLCert>always</verifySSLCert>"
                    
                        switch verifySslSetting {
                        case "failedCredentials":
                            self.spinner.stopAnimation(self)
                            return
                        case "":
                            Alert.shared.display(header: "Alert", message: "Unable to determine verifySSLCert setting on server, setting to always_except_during_enrollment")
                            self.plistData["createConfSwitches"] = "always_except_during_enrollment" as AnyObject
                        default:
                            self.plistData["createConfSwitches"] = verifySslSetting as AnyObject
                            print("verifySSLCert setting from server: \(verifySslSetting)")
                        }
                        // get SSL verification settings from new server - end

                        self.retainSite_Button.state.rawValue == 1 ? (self.retainSite = "true") : (self.retainSite = "false")
                        self.mgmtAcctCreate_button.state.rawValue == 1 ? (self.mgmtAcctCreate = "true") : (self.mgmtAcctCreate = "false")
                        self.mgmtAcctHide_button.state.rawValue == 1 ? (self.mgmtAcctHide = "true") : (self.mgmtAcctHide = "false")

                        self.theNewInvite = ""

                        let invite_request = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><computer_invitation><lifetime>2147483647</lifetime><multiple_uses_allowed>true</multiple_uses_allowed><ssh_username>" + mgmtAcctNameXml + "</ssh_username><ssh_password_method>\(convertFromNSControlStateValue(self.randomPassword_button.state))</ssh_password_method>\(self.mgmtAcctPwdXml)<enroll_into_site><id>" + self.siteId + "</id></enroll_into_site><keep_existing_site_membership>" + self.retainSite + "</keep_existing_site_membership><create_account_if_does_not_exist>\(self.mgmtAcctCreate)</create_account_if_does_not_exist><hide_account>\(self.mgmtAcctHide)</hide_account><lock_down_ssh>false</lock_down_ssh></computer_invitation>"
        //                print("invite request: " + invite_request)

                        Xml.objectDict["invitation"] = "\(invite_request)"
                        Xml.objectArray.append("invitation")

                        // get invitation code
                        self.apiAction(action: "POST", xml: Xml.objectDict["invitation"]!, theApiObject: "invitation") {
                            (result: [Any]) in
                            let responseCode = result[0] as! Int
                            let responseMesage = result[1] as! String
                            if !(responseCode > 199 && responseCode < 300) {
                                let lightFormat = self.removeTag(xmlString: responseMesage.replacingOccurrences(of: "><", with: ">\n<"))
                                Alert.shared.display(header: "Attention", message: "Failed to create invitation code.\nMessage: \(lightFormat)\nResponse code: \(responseCode)")
                                self.spinner.stopAnimation(self)
                                return
                            } else {
                                print("full reply for invitation code request:\n\t\(responseMesage)\n")
                                if let start = responseMesage.range(of: "<invitation>"),
                                    let end  = responseMesage.range(of: "</invitation>", range: start.upperBound..<(responseMesage.endIndex)) {
                                    self.theNewInvite.append((String(responseMesage[start.upperBound..<end.lowerBound])))
                                    if "\(self.theNewInvite)" == "" {
                                        Alert.shared.display(header: "Alert", message: "Unable to create invitation.  Verify the account, \(self.jssUsername), has been assigned permissions to do so.")
                                        self.spinner.stopAnimation(self)
                                        return
                                    } else {
                                        print("Found invitation code: \(self.theNewInvite)")

                                        Xml.objectDict.removeAll()
                                        Xml.objectArray.removeAll()

                                        if self.createPolicy_Button.state.rawValue == 1 {

                                            Xml.objectDict["migrationCheckPolicy"] = "\(JPServer.migrationCheckPolicy)"
                                            Xml.objectArray.append("migrationCheckPolicy")

                                        }   // if self.createPolicy_Button.state.rawvalue == 1 - end

                                        if self.jamfSchool_Button.state.rawValue == 1 {
                                            self.jamfSchoolUrl    = "\(self.jamfSchoolUrl_TextField.stringValue)"
                                            var unenrollPolicyXml = JamfSchool.policy.replacingOccurrences(of: "<parameter4>----jamfSchoolUrl----</parameter4>", with: "<parameter4>\(self.jamfSchoolUrl)</parameter4>")
                                            unenrollPolicyXml = unenrollPolicyXml.replacingOccurrences(of: "<parameter5>---jamfSchoolToken---</parameter5>", with: "<parameter5>\(self.jamfSchoolToken)</parameter5>")

                                            Xml.objectDict["UnenrollCatagory"] = JamfSchool.catagory
                                            Xml.objectArray.append("UnenrollCatagory")
                                            Xml.objectDict["UnenrollScript"]   = JamfSchool.script
                                            Xml.objectArray.append("UnenrollScript")
                                            Xml.objectDict["UnenrollPolicy"]   = unenrollPolicyXml
                                            Xml.objectArray.append("UnenrollPolicy")
                                        }   // if self.jamfSchool_Button.state.rawvalue == 1 - end

                                        if Xml.objectArray.count > 0 {
                                            self.apiAction(action: "POST", xml: Xml.objectDict["\(String(describing: Xml.objectArray.first!))"]!, theApiObject: "\(String(describing: Xml.objectArray.first!))") {
                                                (result: [Any]) in
                                                let responseCode = result[0] as! Int
                                                let responseMesage = result[1] as! String
                                                if !(responseCode > 199 && responseCode < 300) {
                                                    if responseCode == 409 {
                                                        print("Migration complete policy already exists")
                                                    } else {
                                                        Alert.shared.display(header: "Attention", message: "Failed to create the migration complete policy.\nSee Help to create it manually.\nResponse code: \(responseCode)")
                                                    }
                                                } else {
                                                    print("Created new enrollment complete policy")
                                                    print("\(responseMesage)")
                                                }
                                                self.buildPackage(jssUrl1: "\(JamfProServer.destination)")
                                            }   // self.apiAction - end
                                        } else {
                                            self.buildPackage(jssUrl1: "\(JamfProServer.destination)")
                                        }

                                    }
                                } else {
                                    print("invalid reply from the Jamf server when requesting an invitation code.")
                                    self.spinner.stopAnimation(self)
                                    return
                                }
                            }
                        }
                    default:
                        break
                    }
                    
                }
            }   // healthcheck - server is reachable - end
        }   // healthCheck(server: JamfProServer.destination) - end

    }

    @IBAction func randomPassword(_ sender: Any) {
        if randomPassword_button.state.rawValue == 1 {
            mgmtAcctPwd_TextField.isEnabled = false
            mgmtAcctPwd2_TextField.isEnabled = false
            rndPwdLen_TextField?.isEnabled = true
            mgmtAcctPwd_TextField.stringValue = ""
            mgmtAcctPwd2_TextField.stringValue = ""
            Alert.shared.display(header: "Attention:", message: "A new account must be used when utilizing a random password.  Using an existing account will result in a mismatch between the client and server.\n\nThe new account will be created automatically during enrollment.")
        } else {
            mgmtAcctPwd_TextField.isEnabled = true
            mgmtAcctPwd2_TextField.isEnabled = true
            createPolicy_Button.isEnabled = true
            rndPwdLen_TextField?.isEnabled = false
        }
    }

    @IBAction func removeMDM_fn(_ sender: Any) {
        if removeMDM_Button.state.rawValue == 1 {
            removeMdmWhen_Button.isHidden = false
        } else {
            removeMdmWhen_Button.isHidden = true
        }
    }

    @IBAction func runPolicy_Function(_ sender: Any) {
        if runPolicy_Button.state.rawValue == 1 {
            policyId_Textfield.isEnabled = true
        } else {
            policyId_Textfield.isEnabled = false
        }
    }

    func apiAction(action: String, xml: String, theApiObject: String, completion: @escaping (_ result: [Any]) -> Void) {
        URLCache.shared.removeAllCachedResponses()
        var returnValues = [Any]()
        var endpoint     = ""
        var responseData = ""

        print("[func apiAction] endpoint: \(endpoint)")
        print("[func apiAction] xml: \(xml)")

        switch theApiObject {
        case "invitation":
            endpoint = "\(JamfProServer.destination)/JSSResource/computerinvitations/id/0"
        case "migrationCheckPolicy", "UnenrollPolicy":
            endpoint = "\(JamfProServer.destination)/JSSResource/policies/id/0"
        case "UnenrollCatagory":
            endpoint = "\(JamfProServer.destination)/JSSResource/categories/id/0"
        case "UnenrollScript":
            endpoint = "\(JamfProServer.destination)/JSSResource/scripts/id/0"
        default:
            endpoint = ""
        }

        endpoint = endpoint.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")

        let serverUrl = NSURL(string: "\(endpoint)")
        let serverRequest = NSMutableURLRequest(url: serverUrl! as URL)

        serverRequest.httpMethod = "\(action)"
        serverRequest.httpBody = Data(xml.utf8)
        let serverConf = URLSessionConfiguration.default
        
        switch JamfProServer.authType {
        case "Basic":
            print("[apiAction] using basic auth")
//            serverConf.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType) \(JamfProServer.authCreds)", "Content-Type" : "application/xml", "Accept" : "application/xml"]
        default:
            print("[apiAction] using token auth")
        }
        serverConf.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType) \(JamfProServer.authCreds)", "Content-Type" : "application/xml", "Accept" : "application/xml"]

        let session = Foundation.URLSession(configuration: serverConf, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: serverRequest as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                if let _ = String(data: data!, encoding: .utf8) {
                    responseData = String(data: data!, encoding: .utf8)!
                    responseData = responseData.replacingOccurrences(of: "\n", with: " ")
                    print("[apiAction] response code: \(httpResponse.statusCode)")
                    print("[apiAction] response: \(responseData)")
//                    completion([httpResponse.statusCode,"\(responseData)"])
                    returnValues = [httpResponse.statusCode,"\(responseData)"]
                } else {
                    print("[apiAction] No data was returned from \(action).")
//                    completion([httpResponse.statusCode,""])
                    returnValues = [httpResponse.statusCode,""]
                }

            } else {
//                completion([404,""])
                returnValues = [404,""]
            }
            // move completions here
            if theApiObject == Xml.objectArray.last {
                completion(returnValues)
            } else {
                // call next item in list
                let nextObject = Xml.objectArray.firstIndex(of: theApiObject)!+1
                self.apiAction(action: "POST", xml: Xml.objectDict["\(String(describing: Xml.objectArray[nextObject]))"]!, theApiObject: "\(String(describing: Xml.objectArray[nextObject]))") {
                    (result: [Any]) in
                    completion(result)
                }
            }
        })
        task.resume()
    }   // func apiAction - end

    func beginMigration() {

        var binaryExists     = false
        var binaryDownloaded = false

        if retryCount > maxRetries && maxRetries > -1 {
            // retry count has been met, stop retrying and remove the app
            WriteToLog.shared.message(theMessage: "Retry count: \(retryCount)")
            WriteToLog.shared.message(theMessage: "Maximum retries: \(maxRetries)")
            WriteToLog.shared.message(theMessage: "Retry count has been met, stop retrying and remove the app and related files")
            userDefaults.set(0, forKey: "retryCount")
            self.verifiedCleanup(type: "partial")
            NSApplication.shared.terminate(self)
        }
        
        retryCount += 1
        userDefaults.set(retryCount, forKey: "retryCount")

        WriteToLog.shared.message(theMessage: "Starting the enrollment process for the new Jamf Pro server.  Attempt: \(retryCount)")
        startMigrationQ.maxConcurrentOperationCount = 1
        startMigrationQ.addOperation {
            // ensure we still have network connectivity - start
            var connectivityCounter = 0
            while !self.connectedToNetwork() {
                sleep(2)
                if connectivityCounter > 30 {
                   WriteToLog.shared.message(theMessage: "There was a problem after removing old MDM configuration, network connectivity was lost. Will attempt to fall back to old settings and exiting!")
                    self.unverifiedFallback()
                    exit(1)
                }
                connectivityCounter += 1
                WriteToLog.shared.message(theMessage: "Waiting for network connectivity.")
            }
            // ensure we still have network connectivity - end

            // connectivity to new Jamf Pro server - start
            WriteToLog.shared.message(theMessage: "Attempting to connect to new Jamf Server (\(self.newJSSHostname)) and download the jamf binary.")

            self.healthCheck(server: self.newJssMgmtUrl) {
                (result: [String]) in
                if ( result[1] != "[]" ) {
                    let lightFormat = self.removeTag(xmlString: result[1].replacingOccurrences(of: "><", with: ">\n<"))
                    WriteToLog.shared.message(theMessage: "The new server, \(self.newJssMgmtUrl), does not appear ready for enrollments.\n\t\tResult of healthCheck: \(lightFormat)\n\t\tResponse code: \(result[0])")
                    //              remove config profile if one was installed
                    if self.profileUuid != "" {
                        if !self.profileRemove() {
                            WriteToLog.shared.message(theMessage: "Unable to remove included configuration profile")
                        }
                    }
                    if Command.shared.myExitCode(cmd: "/usr/local/jamf/bin/jamf", args: "mdm") == 0 {
                        WriteToLog.shared.message(theMessage: "Re-enabled MDM.")
                    }
                    exit(1)
                } else {
                    // run recon and mark device as migrated
                    if self.markAsMigrated {
                        WriteToLog.shared.message(theMessage: "Using \(self.migratedAttribute) to track migration.")
                        if Command.shared.myExitCode(cmd: "/usr/local/jamf/bin/jamf", args: "recon", "-\(self.migratedAttribute)", "migrated - \(self.getDateTime(x: 1))") == 0 {
                            WriteToLog.shared.message(theMessage: "Marked machine as migrated. Updated \(self.migratedAttribute) attribute.")
                        } else {
                            WriteToLog.shared.message(theMessage: "Unable to update attribute \(self.migratedAttribute) noting migration.")
                        }
                    } else {
                        WriteToLog.shared.message(theMessage: "Migrated devices are not being tracked.")
                    }
                    // passed health check, let's migrate
                    WriteToLog.shared.message(theMessage: "health check result: \(result[1]), looks good.")

                    if !self.fm.fileExists(atPath: "/usr/local/jamf/bin/jamf") {
                        WriteToLog.shared.message(theMessage: "Existing jamf binary found: /usr/local/jamf/bin/jamf")
                        binaryExists = true
                    }

                    // get jamf binary from new server and replace current binary - start
                    self.download(source: "\(self.newJssMgmtUrl)/bin/jamf.gz", destination: "/Library/Application%20Support/JAMF/ReEnroller/jamf.gz") {
                        (result: String) in
                        WriteToLog.shared.message(theMessage: "download result: \(result)")

                        if ( "\(result)" == "binary downloaded" ) {
                            if self.fm.fileExists(atPath: "/Library/Application Support/JAMF/ReEnroller/jamf.gz") {
                                WriteToLog.shared.message(theMessage: "Downloaded jamf binary from new server (\(self.newJssMgmtUrl)).")
                                binaryDownloaded = true
                                if self.backup(operation: "move", source: self.origBinary, destination: self.bakBinary) {
                                    if Command.shared.myExitCode(cmd: "/bin/bash", args: "-c", "gunzip -f '/Library/Application Support/JAMF/ReEnroller/jamf.gz'") == 0 {
                                        do {
                                            _ = Command.shared.myExitCode(cmd: "/bin/bash", args: "-c", "killall jamf")
                                            try self.fm.moveItem(atPath: "/Library/Application Support/JAMF/ReEnroller/jamf", toPath: self.origBinary)
                                            WriteToLog.shared.message(theMessage: "Using jamf binary from the new server.")
                                            // set permissions to read and execute
                                            self.attributes[.posixPermissions] = 0o555
                                            // remove existing symlink to jamf binary if present
                                            if self.fm.fileExists(atPath: "/usr/local/bin/jamf") {
                                                try self.fm.removeItem(atPath: "/usr/local/bin/jamf")
                                            }
                                            // create new sym link to jamf binary
                                            if Command.shared.myExitCode(cmd: "/bin/bash", args: "-c", "ln -s /usr/local/jamf/bin/jamf /usr/local/bin/jamf") == 0 {
                                                WriteToLog.shared.message(theMessage: "Re-created alias for jamf binary in /usr/local/bin.")
                                            } else {
                                                WriteToLog.shared.message(theMessage: "Failed to re-created alias for jamf binary in /usr/local/bin.")
                                            }
                                            do {
                                                try self.fm.setAttributes(self.attributes, ofItemAtPath: self.origBinary)
                                            }
                                            if self.fm.fileExists(atPath: "/usr/local/jamf/bin/jamfAgent") {
                                                try self.fm.removeItem(atPath: "/usr/local/jamf/bin/jamfAgent")
                                            }
                                            binaryExists = true
                                        } catch {
                                            WriteToLog.shared.message(theMessage: "Unable to remove existing jamf binary, will rely on existing one.")
                                        }
                                    } else {
                                        WriteToLog.shared.message(theMessage: "Unable to unzip new jamf binary.")
                                    }
                                } else {
                                    WriteToLog.shared.message(theMessage: "Unable to backup existing jamf binary.")
                                }
                            }
                        }

                        if binaryExists {
                            if !binaryDownloaded {
                                WriteToLog.shared.message(theMessage: "Failed to download new jamf binary.  Attempting migration with existing binary.")
                            }
                            WriteToLog.shared.message(theMessage: "Start backing up items.")
                            self.backupAndEnroll()
                        } else {
                            self.unverifiedFallback()
                            exit(1)
                        }
                    }  //self.download(source: - end
//                    } else {
//                        // jamf binary already exists - start backup and re-enrollment process
//                        self.backupAndEnroll()
//                    }

                }   // passed health check, let's migrate - end
            }   // healthCheck(server: newJssMgmtUrl) - end
        }   // startMigrationQ.addOperation - end
    }   // func beginMigration() - end

    // backupAndEnroll - start
    func backupAndEnroll() {
        // backup existing jamf keychain - start
        if self.backup(operation: "copy", source: self.origKeychainFile, destination: self.bakKeychainFile) {
            WriteToLog.shared.message(theMessage: "Successfully backed up jamf keychain")
        } else {
            WriteToLog.shared.message(theMessage: "Failed to backup jamf keychain")
            self.unverifiedFallback()
            exit(1)
        }
        // backup existing jamf keychain - end

        // backup existing jamf plist, if it exists - start
        if self.backup(operation: "copy", source: self.jamfPlistPath, destination: self.bakjamfPlistPath) {
            WriteToLog.shared.message(theMessage: "Successfully backed up jamf plist")
        } else {
            WriteToLog.shared.message(theMessage: "Failed to backup jamf plist, rollback is not possible")
            //            unverifiedFallback()
            //            exit(1)
        }
        // backup existing jamf plist, if it exists - end

        // backup existing ConfigurationProfiles dir, if present - start
        if self.os.majorVersion == 10 && self.os.minorVersion < 13 {
            if self.backup(operation: "copy", source: self.origProfilesDir, destination: self.bakProfilesDir) {
                WriteToLog.shared.message(theMessage: "Successfully backed up current ConfigurationProfiles")
            } else {
                WriteToLog.shared.message(theMessage: "Failed to backup current ConfigurationProfiles")
                self.unverifiedFallback()
                exit(1)
            }
        } else {
            WriteToLog.shared.message(theMessage: "ConfigurationProfiles is not backed up on machines with High Sierra or later due to SIP.")
        }
        // backup existing ConfigurationProfiles dir, if present - end

        // rename management account if present - start

        // rename management account if present - end

        // Let's enroll
        if !newEnrollment || jamfSchoolMigration == 1 {
            WriteToLog.shared.message(theMessage: "MDM Profile will be removed \(removeMdmWhen) enrollment in the new Jamf Pro server.")
        }
        if removeMdmWhen == "Before" {
            self.removeMDMProfile(when: "Before") {
                (result: String) in
                if ( result != "Before - failed") {
                    self.enrollNewJps(newServer: self.newJssMgmtUrl, newInvite: self.theNewInvite) {
                        (enrolled: String) in
                        if ( enrolled == "failed" ) {
                            self.unverifiedFallback()
                            exit(1)
                        } else {
                            self.verifyNewEnrollment()
                        }
                    }
                } else {
                    self.unverifiedFallback()
                    exit(1)
                }
            }
        } else {
            self.enrollNewJps(newServer: self.newJssMgmtUrl, newInvite: self.theNewInvite) {
                (enrolled: String) in
                if ( enrolled == "failed" ) {
                    self.unverifiedFallback()
                    exit(1)
                } else {
                    self.removeMDMProfile(when: "After") {
                        (result: String) in
                        if ( result != "After - failed" ) {
                            self.verifyNewEnrollment()
                        } else {
                            self.unverifiedFallback()
                            exit(1)
                        }
                    }
                }
            }
        }
    }
    // backupAndEnroll - end

    // backup up item - start
    func backup(operation: String, source: String, destination: String) -> Bool {
        var success = true
        let backupDate = getDateTime(x: 1)
        if fm.fileExists(atPath: source) {
            if !newEnrollment {
                if fm.fileExists(atPath: destination) {
                    do {
                        try fm.moveItem(atPath: destination, toPath: destination+"-"+backupDate)
                        WriteToLog.shared.message(theMessage: "Backed up existing, \(destination), to "+destination+"-"+backupDate)
                    } catch {
                        Alert.shared.display(header: "Alert", message: "Unable to rename existing item, \(destination).")
                        WriteToLog.shared.message(theMessage: "Failed to rename \(destination).")
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
                        WriteToLog.shared.message(theMessage: "\(source) backed up to \(destination).")
                    } catch {
                        WriteToLog.shared.message(theMessage: "Unable to backup current item, \(source).")
                        success = false
                    }
                }
            } else {
                // delete existing item
                do {
                    try fm.removeItem(atPath: source)
                } catch {
                    WriteToLog.shared.message(theMessage: "Unable to backup current item, \(source).  Will continue to try and enroll.")
                }
            }
        } else {
            WriteToLog.shared.message(theMessage: "\(source), was not found - no backup created.")
        }
        return success
    }
    // backup item - end

    func buildPackage(jssUrl1: String) {
        var jssUrl = jssUrl1
        // set variables and build the package
        self.plistData["theNewInvite"] = self.theNewInvite as AnyObject

        // determine if we're communicating securely
        self.httpProtocol = (jssUrl.lowercased().prefix(5) == "https") ? "https":"http"
        self.plistData["httpProtocol"] = self.httpProtocol as AnyObject

        jssUrl = jssUrl.lowercased().replacingOccurrences(of: "https://", with: "")
        jssUrl = jssUrl.lowercased().replacingOccurrences(of: "http://", with: "")
        (self.newJSSHostname, self.newJSSPort) = self.getHost_getPort(theURL: jssUrl)
        //        print("newJSSHostname: \(newJSSHostname)")

        // get server hostname for use in the package name
        self.newJssArray = self.newJSSHostname.components(separatedBy: ".")
        self.newJssArray[0] == "" ? (self.shortHostname = "new") : (self.shortHostname = self.newJssArray[0])

        //        print("newJSSPort: \(newJSSPort)")

        self.newJssMgmtUrl = "\(self.httpProtocol)://\(self.newJSSHostname):\(self.newJSSPort)"
        //        print("newJssMgmtUrl: \(newJssMgmtUrl)")

        self.plistData["newJSSHostname"] = self.newJSSHostname as AnyObject
        self.plistData["newJSSPort"] = self.newJSSPort as AnyObject
        //plistData["createConfSwitches"] = newURL_array[1] as AnyObject

        self.plistData["mgmtAccount"] = self.mgmtAccount_TextField.stringValue as AnyObject

        if markAsMigrated_Button.state.rawValue == 1 {
            self.plistData["markAsMigrated"] = true as AnyObject
            switch "\(migratedAttribute_Button.titleOfSelectedItem!)" {
            case "Asset Tag":
                self.plistData["migratedAttribute"] = "assetTag" as AnyObject
            case "User Name":
                self.plistData["migratedAttribute"] = "endUsername" as AnyObject
            default:
                self.plistData["migratedAttribute"] = migratedAttribute_Button.titleOfSelectedItem!.lowercased() as AnyObject
            }
        } else {
            self.plistData["markAsMigrated"] = false as AnyObject
            self.plistData["migratedAttribute"] = "" as AnyObject
        }

        if removeMDM_Button.state.rawValue == 1 {
            self.plistData["removeMDM"] = true as AnyObject
            self.plistData["removeMdmWhen"] = removeMdmWhen_Button.titleOfSelectedItem! as AnyObject
        } else {
                self.plistData["removeMDM"] = false as AnyObject
                self.plistData["removeMdmWhen"] = "Custom" as AnyObject
        }

        // put app in place
        let buildFolder = "/private/tmp/reEnroller-"+self.getDateTime(x: 1)

        let _ = Command.shared.myExitCode(cmd: "/bin/rm", args: "/private/tmp/reEnroller*")

        var buildFolderd = "" // build folder for launchd items, may be outside build folder if separating app from launchd
        let settingsPlistPath = buildFolder+"/Library/Application Support/JAMF/ReEnroller/settings.plist"

        // create build location and place items
        do {
            try self.fm.createDirectory(atPath: buildFolder+"/Library/Application Support/JAMF/ReEnroller/tmp", withIntermediateDirectories: true, attributes: nil)

            // copy the app into the pkg building location
            do {
                print("copying ReEnroller.app from \(self.myBundlePath)")
                try self.fm.copyItem(atPath: self.myBundlePath, toPath: buildFolder+"/Library/Application Support/JAMF/ReEnroller/tmp/ReEnroller.app")
            } catch {
                Alert.shared.display(header: "-Attention-", message: "Could not copy app to build folder - exiting.")
                exit(1)
            }
            // put settings.plist into place
            do {
                try self.fm.copyItem(atPath: self.blankSettingsPlistPath, toPath: settingsPlistPath)
            } catch {
                Alert.shared.display(header: "-Attention-", message: "Could not copy settings.plist to build folder - exiting.")
                exit(1)
            }

        } catch {
            Alert.shared.display(header: "-Attention-", message: "Could not create build folder - exiting.")
            exit(1)
        }

        // create folder to hold backups of exitsing files/folders - start
        do {
            try self.fm.createDirectory(atPath: buildFolder+"/Library/Application Support/JAMF/ReEnroller/backup", withIntermediateDirectories: true, attributes: nil)
        } catch {
            Alert.shared.display(header: "-Attention-", message: "Could not create backup folder - exiting.")
            exit(1)
        }
        // create folder to hold backups of exitsing files/folders - end

        if ssid_TextField.stringValue != "" {
            ssid = ssid_TextField.stringValue
            plistData["security"] = security_Button.titleOfSelectedItem as AnyObject
            let tmpKey = ssidKey_TextField.stringValue.data(using: .utf8)!
            let symmetricKey = SymmetricKey(base64EncodedString: base64SymetricKey)!
            let encryptedSealedBox = try! AES.GCM.seal(tmpKey, using: symmetricKey, nonce: nil)
            do {
                ssidKey = try sealedBoxToString(encryptedSealedBox)
            } catch {
                WriteToLog.shared.message(theMessage: "[startToMigrate] Failed to encode SSID passphrase")
            }

            plistData["ssid"] = ssid as AnyObject
            plistData["ssidKey"] = ssidKey as AnyObject
            if self.removeProfile_Button.state.rawValue == 0 {
                plistData["removeProfile"] = "false" as AnyObject
            } else {
                plistData["removeProfile"] = "true" as AnyObject
            }
        }
        
        /*
        // if a config profile is present copy it to the pkg building location
        if let profileURL = self.profile_PathControl.url {
            self.safeProfileURL = "\(profileURL)".replacingOccurrences(of: "%20", with: " ")
            self.safeProfileURL = self.safeProfileURL.replacingOccurrences(of: "file://", with: "")
            //            print("safeProfileURL: \(safeProfileURL)")

            if self.safeProfileURL != "/" {
                do {
                    try self.fm.copyItem(atPath: self.safeProfileURL, toPath: buildFolder+"/Library/Application Support/JAMF/ReEnroller/profile.mobileconfig")
                } catch {
                    Alert.shared.display(header: "-Attention-", message: "Could not copy config profile.  If there are spaces in the profile name try removing them. Unable to create pkg - exiting.")
                    WriteToLog.shared.message(theMessage: "Could not copy config profile.  If there are spaces in the profile name try removing them. Unable to create pkg - exiting.")
                    exit(1)
                }
                // add config profile values to settings - start
                do {
                    var cleanedProfile = ""
                    var payloadUUID    = ""
                    let one = try String(contentsOf: self.profile_PathControl.url! as URL, encoding: String.Encoding.ascii)
                    let regexClean  = try! NSRegularExpression(pattern: "<array>(.|\n|\r)*?</array>", options:.caseInsensitive)
                    cleanedProfile  = regexClean.stringByReplacingMatches(in: one, options: [], range: NSRange(0..<one.utf16.count), withTemplate: "")
                    let regexClean2 = try! NSRegularExpression(pattern: "</key>(.|\n|\r)*?<string>", options:.caseInsensitive)
                    cleanedProfile  = regexClean2.stringByReplacingMatches(in: cleanedProfile, options: [], range: NSRange(0..<cleanedProfile.utf16.count), withTemplate: "</key><string>")
                    let textArray   = cleanedProfile.components(separatedBy: "<key>PayloadUUID</key><string>")
                    payloadUUID     = "\(textArray[1].prefix(36))"
                    self.plistData["profileUUID"] = "\(payloadUUID)" as AnyObject
//                                                self.plistData["profileUUID"] = "\(PayloadUUID[1])" as AnyObject
                    if self.removeProfile_Button.state.rawValue == 0 {
                        self.plistData["removeProfile"] = "false" as AnyObject
                    } else {
                        self.plistData["removeProfile"] = "true" as AnyObject
                    }
                } catch {
                    print("unable to read file")
                }
            }
        }   // add config profile values to settings - end
        */

        // configure all profile removal - start
//        if self.removeAllProfiles_Button.state.rawValue == 0 {
//            self.plistData["removeAllProfiles"] = "false" as AnyObject
//        } else {
//            self.plistData["removeAllProfiles"] = "true" as AnyObject
//        }
        // configure all profile removal - end

        // configure device enrollment call - start
        if self.deviceEnrollment_Button.state.rawValue == 0 {
            self.plistData["callEnrollment"] = "no" as AnyObject
        } else {
            self.plistData["callEnrollment"] = "yes" as AnyObject
        }
        // configure device enrollment call - end

        // configure ReEnroller folder removal - start
        if self.removeReEnroller_Button.state.rawValue == 0 {
            self.plistData["removeReEnroller"] = "no" as AnyObject
        } else {
            self.plistData["removeReEnroller"] = "yes" as AnyObject
        }
        // configure ReEnroller folder removal - end

        // Jamf School migration check - start
        if self.jamfSchool_Button.state.rawValue == 0 {
            self.plistData["jamfSchool"] = 0 as AnyObject
        } else {
            self.plistData["jamfSchool"] = 1 as AnyObject
        }
        // Jamf School migration check - end

        // configure new enrollment check - start
        if self.newEnrollment_Button.state.rawValue == 0 && self.jamfSchool_Button.state.rawValue == 0 {
            self.plistData["newEnrollment"] = 0 as AnyObject
        } else {
            self.plistData["newEnrollment"] = 1 as AnyObject
        }
        // configure new enrollment check - end

        // configure healthCheck - start
        if self.skipHealthCheck_Button.state.rawValue == 0 {
            self.plistData["skipHealthCheck"] = "no" as AnyObject
        } else {
            self.plistData["skipHealthCheck"] = "yes" as AnyObject
        }
        // configure healthCheck - end

        // configure mdm check - start
        if self.skipMdmCheck_Button.state.rawValue == 0 {
            self.plistData["skipMdmCheck"] = "no" as AnyObject
        } else {
            self.plistData["skipMdmCheck"] = "yes" as AnyObject
        }
        // configure mdm - end

        // postInstallPolicyId - start
        if self.runPolicy_Button.state.rawValue == 0 {
            self.plistData["postInstallPolicyId"] = "" as AnyObject
        } else {
            let policyId = self.policyId_Textfield.stringValue
            // verify we have a valid number
            if policyId.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil {
                self.plistData["postInstallPolicyId"] = "" as AnyObject
            } else {
                self.plistData["postInstallPolicyId"] = self.policyId_Textfield.stringValue as AnyObject
            }
        }
        // postInstallPolicyId - end

        // max retries -  start
        let maxRetriesString = self.maxRetries_Textfield.stringValue
        // verify we have a valid number or it was left blank
        if maxRetriesString != "" {
            if maxRetriesString.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil {
                self.spinner.stopAnimation(self)
                Alert.shared.display(header: "-Attention-", message: "Invalid value entered for the maximum number of retries.")
                return
            } else {
                self.plistData["maxRetries"] = self.maxRetries_Textfield.stringValue as AnyObject
            }
        } else {
            self.plistData["maxRetries"] = "-1" as AnyObject
        }
        // max retries - end

        // set retry interval in launchd - start
        if let retryInterval = Int(self.retry_TextField.stringValue) {
            if retryInterval >= 5 {
                self.StartInterval = retryInterval*60    // convert minutes to seconds
                //                print("Setting custon retry interval: \(StartInterval)")
            }
        } else {
            self.spinner.stopAnimation(self)
            Alert.shared.display(header: "-Attention-", message: "Invalid value entered for the retry interval.")
            return
        }
        // set retry interval in launchd - end

        // prepare postinstall script if option is checked - start
        if self.separatePackage_button.state.rawValue == 0 {
            buildFolderd = buildFolder
        } else {
            buildFolderd = "/private/tmp/reEnrollerd-"+self.getDateTime(x: 1)
            self.includesMsg = "does not include"
            self.includesMsg2 = "  The launch daemons are packaged in: ReEnrollerDaemon-\(self.shortHostname).pkg."
        }

        do {
            try self.fm.createDirectory(atPath: buildFolderd+"/Library/LaunchDaemons", withIntermediateDirectories: true, attributes: nil)
            do {
                try self.fm.copyItem(atPath: self.myBundlePath+"/Contents/Resources/com.jamf.ReEnroller.plist", toPath: buildFolderd+"/Library/LaunchDaemons/com.jamf.ReEnroller.plist")
            } catch {
                WriteToLog.shared.message(theMessage: "Could not copy launchd, unable to create pkg")
                Alert.shared.display(header: "-Attention-", message: "Could not copy launchd to build folder - exiting.")
                exit(1)
            }

        } catch {
            WriteToLog.shared.message(theMessage: "Unable to place launch daemon.")
            Alert.shared.display(header: "-Attention-", message: "Could not LaunchDeamons folder in build folder - exiting.")
            exit(1)
        }
        // put launch daemon in place - end

        let launchdFile = buildFolderd+"/Library/LaunchDaemons/com.jamf.ReEnroller.plist"
        if self.fm.fileExists(atPath: launchdFile) {
            let launchdPlistXML = self.fm.contents(atPath: launchdFile)!
            do{
                WriteToLog.shared.message(theMessage: "Reading settings from: \(launchdFile)")
                self.launchdPlistData = try PropertyListSerialization.propertyList(from: launchdPlistXML,
                                                                                   options: .mutableContainersAndLeaves,
                                                                                   format: &self.format)
                    as! [String : AnyObject]
            }
            catch{
                WriteToLog.shared.message(theMessage: "Error launchd plist: \(error), format: \(self.format)")
            }
        }

        self.launchdPlistData["StartInterval"] = self.StartInterval as AnyObject

        // Write values to launchd plist - start
        (self.launchdPlistData as NSDictionary).write(toFile: launchdFile, atomically: false)
        // Write values to launchd plist - end

        // Write settings from GUI to settings.plist
        (self.plistData as NSDictionary).write(toFile: settingsPlistPath, atomically: false)

        let packageName = (self.newEnrollment_Button.state.rawValue == 1) ? "Enroller":"ReEnroller"

        // rename existing ReEnroller.pkg if it exists - start
        if self.fm.fileExists(atPath: NSHomeDirectory()+"/Downloads/\(packageName)-\(self.shortHostname).pkg") {
            do {
                try self.fm.moveItem(atPath: NSHomeDirectory()+"/Downloads/\(packageName)-\(self.shortHostname).pkg", toPath: NSHomeDirectory()+"/Downloads/\(packageName)-\(self.shortHostname)-"+self.getDateTime(x: 1)+".pkg")
            } catch {
                Alert.shared.display(header: "Alert", message: "Unable to rename an existing \(packageName)-\(self.shortHostname).pkg file in Downloads.  Try renaming/removing it manually: sudo mv ~/Downloads/\(packageName)-\(self.shortHostname).pkg ~/Downloads/\(packageName)-\(self.shortHostname)-old.pkg.")
                exit(1)
            }
        }
        // rename existing ReEnroller.pkg if it exists - end

        // Create pkg of app and launchd - start
        if self.separatePackage_button.state.rawValue == 0 {
            print("building single package")
            self.pkgBuildResult = Command.shared.myExitCode(cmd: "/usr/bin/pkgbuild", args: "--identifier", "com.jamf.ReEnroller", "--root", buildFolder, "--scripts", self.myBundlePath+"/Contents/Resources/1", "--component-plist", self.myBundlePath+"/Contents/Resources/ReEnroller-component.plist", NSHomeDirectory()+"/Downloads/\(packageName)-\(self.shortHostname).pkg")

        } else {
            print("building two packages")
            self.pkgBuildResult = Command.shared.myExitCode(cmd: "/usr/bin/pkgbuild", args: "--identifier", "com.jamf.ReEnroller", "--root", buildFolder, "--scripts", self.myBundlePath+"/Contents/Resources/2", "--component-plist", self.myBundlePath+"/Contents/Resources/ReEnroller-component.plist", NSHomeDirectory()+"/Downloads/\(packageName)-\(self.shortHostname).pkg")
            self.pkgBuildResult = Command.shared.myExitCode(cmd: "/usr/bin/pkgbuild", args: "--identifier", "com.jamf.ReEnrollerd", "--root", buildFolderd, "--scripts", self.myBundlePath+"/Contents/Resources/1", NSHomeDirectory()+"/Downloads/\(packageName)Daemon-\(self.shortHostname).pkg")
        }
        
        // remove build folder
        let _ = Command.shared.myExitCode(cmd: "/bin/bash", args: "-c", "/bin/rm -fr /private/tmp/reEnroller-*")
        
        if self.pkgBuildResult != 0 {
            Alert.shared.display(header: "-Attention-", message: "Could not create the \(packageName)(Daemon) package - exiting.")
            exit(1)
        }
        // Create pkg of app and launchd - end

        self.spinner.stopAnimation(self)
        
        if self.createPolicy_Button.state.rawValue == 1 {
            self.policyMsg = "\n\nVerify the Migration Complete policy was created on the new server.  "
            if self.randomPassword_button.state.rawValue == 0 {
                self.policyMsg.append("The policy should contain a 'Files and Processes' payload.  Modify if needed.")
            } else {
                self.policyMsg.append("The policy should contain a 'Files and Processes' payload along with a 'Management Account' payload.  Modify if needed.")
            }
        } else {
            self.policyMsg = "\n\nBe sure to create a migration complete policy before starting to migrate, see help or more information."
        }

        fullPackageName = "\(packageName)-\(self.shortHostname).pkg"
        // alert the user, we're done
        Alert.shared.display(header: "Process Complete", message: "A package (\(packageName)-\(self.shortHostname).pkg) has been created in Downloads which is ready to be deployed with your current Jamf server.\n\nThe package \(self.includesMsg) a postinstall script to load the launch daemon and start the \(packageName) app.\(self.includesMsg2)\(self.policyMsg)")

    }

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

    // func download - start
    func download(source: String, destination: String, completion: @escaping (_ result: String) -> Void) {

        WriteToLog.shared.message(theMessage: "download URL: \(source)")

        // Location to store the file
        let destinationFileUrl:URL = URL(string: "file://\(destination)")!

        var filePath = "\(destinationFileUrl)"
        filePath = String(filePath.dropFirst(7))
        filePath = filePath.replacingOccurrences(of: "%20", with: " ")

        let exists = FileManager.default.fileExists(atPath: filePath)
        if exists {
            do {
                try FileManager.default.removeItem(atPath: filePath)
                WriteToLog.shared.message(theMessage: "removed existing file")
            } catch {
                WriteToLog.shared.message(theMessage: "failed to remove existing file")
                exit(0)
            }
        }

        //Create URL to the source file you want to download
        let fileURL = URL(string: "\(source)")

        let sessionConfig = URLSessionConfiguration.default
        let session = Foundation.URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue.main)

        let request = URLRequest(url:fileURL!)

        URLCache.shared.removeAllCachedResponses()
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    WriteToLog.shared.message(theMessage: "Response from server - Status code: \(statusCode)")
                } else {
                    WriteToLog.shared.message(theMessage: "No response from the server.")
                    completion("No response from the server.")
                }

                switch (response as? HTTPURLResponse)?.statusCode {
                case 200:
                    WriteToLog.shared.message(theMessage: "File successfully downloaded.")
                case 401:
                    WriteToLog.shared.message(theMessage: "Authentication failed.")
                    completion("Authentication failed.")
                case 404:
                    WriteToLog.shared.message(theMessage: "server / file not found.")
                    completion("not found")
                default:
                    WriteToLog.shared.message(theMessage: "An error took place while downloading a file. Error description: \(String(describing: error!.localizedDescription))")
                    completion("unknown error")
                }

                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
                } catch (let writeError) {
                    WriteToLog.shared.message(theMessage: "Error creating a file \(destinationFileUrl) : \(writeError)")
                    completion("Error creating file.")
                }

                completion("binary downloaded")
            } else {
                WriteToLog.shared.message(theMessage: "An error took place while downloading a file. Error description: \(String(describing: error!.localizedDescription))")
                completion("Error took place while downloading a file.")
            }
        }
        task.resume()
    }
    // func download - end

    func dropTrailingSlash(theSentString: String) -> String {
        var theString = theSentString
        if ( theString.last == "/" ) {
            theString = "\(theString.dropLast())"
        }
        return theString
    }

    func enrollNewJps(newServer: String, newInvite: String, completion: @escaping (_ enrolled: String) -> Void) {
        WriteToLog.shared.message(theMessage: "Starting the new enrollment.")
        // Install profile if present - start
        if !profileInstall() {
            completion("failed")
        }
        // Install profile if present - end

        // ensure we still have network connectivity - start
        var connectivityCounter = 0
        while !connectedToNetwork() {
            sleep(2)
            if connectivityCounter > 30 {
                WriteToLog.shared.message(theMessage: "There was a problem after removing old MDM configuration, network connectivity was lost. Will attempt to fall back to old settings and exiting!")
                //                    unverifiedFallback()
                //                    exit(1)
                completion("failed")
            }
            connectivityCounter += 1
            WriteToLog.shared.message(theMessage: "Waiting for network connectivity.")
        }
        // ensure we still have network connectivity - end

        // create a conf file for the new server
        WriteToLog.shared.message(theMessage: "Running: /usr/local/bin/jamf createConf -verifySSLCert \(createConfSwitches) -url \(newServer)")

        if Command.shared.myExitCode(cmd: "/usr/local/bin/jamf", args: "createConf", "-verifySSLCert", "\(createConfSwitches)", "-url", "\(newServer)") == 0 {
            WriteToLog.shared.message(theMessage: "Created JAMF config file for \(newServer)")
        } else {
            WriteToLog.shared.message(theMessage: "There was a problem creating JAMF config file for \(newServer). Falling back to old settings and exiting.")
            completion("failed")
        }

        // enroll with the new server using an invitation
        WriteToLog.shared.message(theMessage: "Using enrollment invitation to enroll into Jamf Server: \(newServer)")
        var enrolled = false
        var enrollCounter = 1
        if !enrolled && enrollCounter < 4 {
            if Command.shared.myExitCode(cmd: "/usr/local/bin/jamf", args: "enroll", "-invitation", "\(newInvite)", "-noRecon", "-noPolicy", "-noManage") == 0 {
                WriteToLog.shared.message(theMessage: "/usr/local/bin/jamf enroll -invitation xxxxxxxx -noRecon -noPolicy -noManage")
                WriteToLog.shared.message(theMessage: "Enrolled to new Jamf Server: \(newServer)")
                enrolled = true
            } else {
                WriteToLog.shared.message(theMessage: "Enrollment attempt \(enrollCounter) failed.")
                enrollCounter += 1
                sleep(5)
            }
        }
        if !enrolled {
            WriteToLog.shared.message(theMessage: "There was a problem enrolling to new Jamf Server: \(newServer). Falling back to old settings and exiting!")
            completion("failed")
            return
        }

        // verity connectivity to the new Jamf Pro server
        if Command.shared.myExitCode(cmd: "/usr/local/bin/jamf", args: "checkjssconnection") == 0 {
            WriteToLog.shared.message(theMessage: "checkjssconnection for \(newServer) was successful")
        } else {
            WriteToLog.shared.message(theMessage: "There was a problem checking the Jamf Server Connection to \(newServer). Falling back to old settings and exiting!")
            completion("failed")
            return
        }

        // Handle MDM operations - start
       // check if we're migrating from Jamf School
        if jamfSchoolMigration == 1 {
            var counter = 0
            while mdmInstalled(cmd: "/bin/bash", args: "-c", "/usr/bin/profiles -C | grep com.apple.mdm | wc -l", message: "looking for Jamf School Profile") {
                counter+=1
                _ = Command.shared.myExitCode(cmd: "/bin/bash", args: "-c", "killall jamf;/usr/local/bin/jamf policy -trigger jamfSchoolUnenroll")
                sleep(10)
                if counter > 6 {
                    WriteToLog.shared.message(theMessage: "Failed to remove Jamf School MDM through remote command - exiting")
                    completion("failed")
                    return
                } else {
                    WriteToLog.shared.message(theMessage: "Attempt \(counter) to remove Jamf School MDM through remote command.")
                }
            }   // while mdmInstalled - end
            WriteToLog.shared.message(theMessage: "Jamf School MDM removed through remote command.")
        }

        if !(( os.majorVersion > 10 ) || ( os.majorVersion == 10 && os.minorVersion > 15 )) {
            if skipMdmCheck == "no" && removeMDM {
                // enable mdm
                if Command.shared.myExitCode(cmd: "/usr/local/bin/jamf", args: "mdm") == 0 {
                    WriteToLog.shared.message(theMessage: "MDM Enrolled - getting MDM profiles from new JPS.")
                } else {
                    WriteToLog.shared.message(theMessage: "There was a problem getting MDM profiles from new JPS.")
                }
                sleep(2)
            } else {
                WriteToLog.shared.message(theMessage: "Skipping MDM check.")
            }
            WriteToLog.shared.message(theMessage: "Calling jamf manage to update framework.")
            if Command.shared.myExitCode(cmd: "/usr/local/bin/jamf", args: "manage") == 0 {
                WriteToLog.shared.message(theMessage: "Enrolled - received management framework from new JPS.")
                completion("succeeded")
            } else {
                WriteToLog.shared.message(theMessage: "There was a problem getting the management framework from new JPS.")
                if newEnrollment {
                    WriteToLog.shared.message(theMessage: "New enrollment - continuing")
                    completion("succeeded")
                } else {
                    WriteToLog.shared.message(theMessage: "Falling back to old settings and exiting!")
                    completion("failed")
                }

            }
        } else {
            WriteToLog.shared.message(theMessage: "macOS v\(os.majorVersion).\(os.minorVersion).\(os.patchVersion) - Skipping enabling of MDM.")
            completion("succeeded")
        }
        // Handle MDM operations - end
    }

    //    @IBAction func fetchSites_Button(_ sender: Any) {
    func fetchSites() {
        if enableSites_Button.state.rawValue == 1 {
            // get site info - start
            var siteArray = [String]()
            let jssUrl = jssUrl_TextField.stringValue.baseUrl
            jssUsername = jssUsername_TextField.stringValue
            jssPassword = jssPassword_TextField.stringValue

            if "\(jssUrl)" == "" {
                Alert.shared.display(header: "Attention:", message: "Jamf server is required.")
                enableSites_Button.state = convertToNSControlStateValue(0)
                return
            }

            if "\(jssUsername)" == "" || "\(jssPassword)" == "" {
                Alert.shared.display(header: "Attention:", message: "Jamf server username and password are required in order to use Sites.")
                enableSites_Button.state = convertToNSControlStateValue(0)
                return
            }
            jssCredentials = "\(jssUsername):\(jssPassword)"
            let jssCredentialsUtf8 = jssCredentials.data(using: String.Encoding.utf8)
            jssCredsBase64 = (jssCredentialsUtf8?.base64EncodedString())!

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

    func getSystemUUID() -> String? {
        let dev = IOServiceMatching("IOPlatformExpertDevice")
        let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, dev)
        let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)
        IOObjectRelease(platformExpert)
        let ser: CFTypeRef = serialNumberAsCFString?.takeUnretainedValue() as CFTypeRef
        if let result = ser as? String {
            return result
        }
        return nil
    }

    func healthCheck(server: String, completion: @escaping (_ result: [String]) -> Void) {
        if skipHealthCheck == "no" {
            URLCache.shared.removeAllCachedResponses()
            var responseData = ""
            var healthCheckUrl = "\(server)/healthCheck.html"
            healthCheckUrl     = healthCheckUrl.replacingOccurrences(of: "//healthCheck.html", with: "/healthCheck.html")

            let serverUrl = NSURL(string: "\(healthCheckUrl)")
            let serverRequest = NSMutableURLRequest(url: serverUrl! as URL)

            serverRequest.httpMethod = "GET"
            let serverConf = URLSessionConfiguration.default

            WriteToLog.shared.message(theMessage: "Performing a health check against: \(healthCheckUrl)")
            let session = Foundation.URLSession(configuration: serverConf, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: serverRequest as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    if let _ = String(data: data!, encoding: .utf8) {
                        responseData = String(data: data!, encoding: .utf8)!
                        responseData = responseData.replacingOccurrences(of: "\n", with: "")
                        responseData = responseData.replacingOccurrences(of: "\r", with: "")
                        WriteToLog.shared.message(theMessage: "healthCheck response code: \(httpResponse.statusCode)")
                        WriteToLog.shared.message(theMessage: "healthCheck response: \(responseData)")
                        completion(["\(httpResponse.statusCode)","\(responseData)"])
                    } else {
                        WriteToLog.shared.message(theMessage: "No data was returned from health check.")
                        completion(["\(httpResponse.statusCode)",""])
                    }

                } else {
                    completion(["Unable to reach server.",""])
                }
            })
            task.resume()
        } else {
            WriteToLog.shared.message(theMessage: "Skipping health check on \(server).")
            WriteToLog.shared.message(theMessage: "Marking the server as reachable.")
            completion(["200","[]"])
        }
    }

    func getDateTime(x: Int8) -> String {
        let date = Date()
        let date_formatter = DateFormatter()
        if x == 1 {
            date_formatter.dateFormat = "YYYYMMdd_HHmmss"
        } else {
            date_formatter.dateFormat = "E MMM d HH:mm:ss"
        }
        let stringDate = date_formatter.string(from: date)

        return stringDate
    }

    func getHost_getPort(theURL: String) -> (String, String) {
        var local_theHost = ""
        var local_thePort = ""

        let local_URL_array = theURL.components(separatedBy: ":")
        local_theHost = local_URL_array[0]

        if local_URL_array.count > 1 {
            local_thePort = local_URL_array[1]
        } else {
            local_thePort = "443"
        }
        // remove trailing / in url and port if present
        if local_theHost.last == "/" {
            local_theHost = String(local_theHost.dropLast())
        }
        if local_thePort.last == "/" {
            local_thePort = String(local_thePort.dropLast())
        }

        return(local_theHost, local_thePort)
    }

    func getSites(completion: @escaping ([String:Int]) -> [String:Int]) {
        print("[getSites] enter")
        var local_allSites = [String:Int]()
        JamfProServer.destination = jssUrl_TextField.stringValue.baseUrl
//        var serverURL = jssUrl_TextField.stringValue
//        serverURL = dropTrailingSlash(theSentString: serverURL)
        
        let jpsCredentials = "\(jssUsername_TextField.stringValue):\(jssPassword_TextField.stringValue)"
        let jpsBase64Creds = jpsCredentials.data(using: .utf8)?.base64EncodedString() ?? ""
        spinner.startAnimation(self)
        JamfPro().getToken(serverUrl: JamfProServer.destination, base64creds: jpsBase64Creds) { [self]
            authResult in
            print("[getSites] authResult: \(authResult)")
            spinner.stopAnimation(self)
            let (statusCode,theResult) = authResult
            switch theResult {
            case "failedToAuthenticate":
                Alert.shared.display(header: "Attention:", message: "Failed to authenticate.")
                enableSites_Button.state = convertToNSControlStateValue(0)
                return
            case "success":
                print("jpversion: \(JamfProServer.version)")
                print("authType: \(JamfProServer.authType)")
                
                let serverEncodedURL = NSURL(string: resourcePath)
                let serverRequest = NSMutableURLRequest(url: serverEncodedURL! as URL)
                //        print("serverRequest: \(serverRequest)")
                serverRequest.httpMethod = "GET"
                let serverConf = URLSessionConfiguration.default
                
    //            switch JamfProServer.authType {
    //            case "Basic":
    //                serverConf.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType) \(JamfProServer.authCreds)", "Content-Type" : "application/json", "Accept" : "application/json"]
    //            default:
    //                serverConf.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType) \(JamfProServer.authCreds)", "Content-Type" : "application/json", "Accept" : "application/json"]
    //            }
                serverConf.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType) \(JamfProServer.authCreds)", "Content-Type" : "application/json", "Accept" : "application/json"]
                
                let serverSession = Foundation.URLSession(configuration: serverConf, delegate: self, delegateQueue: OperationQueue.main)
                let task = serverSession.dataTask(with: serverRequest as URLRequest, completionHandler: {
                    (data, response, error) -> Void in
                    if let httpResponse = response as? HTTPURLResponse {
            //                print("[getSites] httpResponse: \(String(describing: response))")
                            let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                            //                    print("\(json)")
                            if let endpointJSON = json as? [String: Any] {
                                if let siteEndpoints = endpointJSON["sites"] as? [Any] {
                                    let siteCount = siteEndpoints.count
                                    if siteCount > 0 {
                                        for i in (0..<siteCount) {
                                            let theSite = siteEndpoints[i] as! [String:Any]
                                            let theSiteName = theSite["name"] as! String
                                            local_allSites[theSiteName] = theSite["id"] as? Int
                                        }
                                    }
                                }
                            }   // if let serverEndpointJSON - end

                        if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {

                            self.site_Button.isEnabled = true
            //                    print("[getSites] local_allSites: \(String(describing: local_allSites))")
                            completion(local_allSites)
                        } else {
                            // something went wrong
                            print("Sile lookup response code: \(httpResponse.statusCode)")
                                Alert.shared.display(header: "Alert", message: "Unable to look up Sites.  Verify the account being used is able to login and view Sites.\nStatus Code: \(httpResponse.statusCode)")

                            self.enableSites_Button.state = convertToNSControlStateValue(0)
                            self.site_Button.isEnabled = false
                            completion([:])

                        }   // if httpResponse/else - end
                    }   // if let httpResponse - end
                    //            semaphore.signal()
                })  // let task = - end
                task.resume()
            default:
                break
            }
        }
    }

    // function to return mdm status - start
    func mdmInstalled(cmd: String, args: String..., message: String) -> Bool {
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

        WriteToLog.shared.message(theMessage: "\(message)")
        if message != "" {
            WriteToLog.shared.message(theMessage: "Found existing MDM profile")
        }

        let mdmCount = Int(profileList.trimmingCharacters(in: .whitespacesAndNewlines))!

        if mdmCount == 0 {
            mdm = false
        }
        return mdm
    }

    // function to return exit code of bash command - start
//    func myExitCode(cmd: String, args: String...) -> Int8 {
//        var pipe_pkg = Pipe()
//        let task_pkg = Process()
//
//        task_pkg.launchPath = cmd
//        task_pkg.arguments = args
//        task_pkg.standardOutput = pipe_pkg
//        //var test = task_pkg.standardOutput
//
//        task_pkg.launch()
//        
//        let outdata = pipe_pkg.fileHandleForReading.readDataToEndOfFile()
//        if var string = String(data: outdata, encoding: .utf8) {
//            WriteToLog.shared.message(theMessage: "command result: \(string)")
//        }
//        
//        task_pkg.waitUntilExit()
//        let result = task_pkg.terminationStatus
//
//        return(Int8(result))
//    }
    // function to return exit code of bash command - end

    // function to return value of bash command - start
    func myExitValue(cmd: String, args: String...) -> [String] {
        var status  = [String]()
        let pipe    = Pipe()
        let task    = Process()

        task.launchPath     = cmd
        task.arguments      = args
        task.standardOutput = pipe
//        let outputHandle    = pipe.fileHandleForReading

        task.launch()

        let outdata = pipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: outdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            status = string.components(separatedBy: "\n")
        }

        task.waitUntilExit()

//        print("status: \(status)")
        return(status)
    }
    // function to return value of bash command - end

    func profileInstall() -> Bool {
        let en = myExitValue(cmd: "/bin/bash", args: "-c", "/usr/sbin/networksetup -listallhardwareports | grep -A1 Wi-Fi | grep Device | awk '{ print $2 }'")[0]
        
        WriteToLog.shared.message(theMessage: "[profileInstall]       en: \(en)")
        WriteToLog.shared.message(theMessage: "[profileInstall]     ssid: \(ssid)")
        
        var security = "None"
        if plistData["security"] != nil {
            security = plistData["security"] as! String
            if security == "None" { security = "OPEN" }
        }
        security = security.replacingOccurrences(of: " Personal", with: "")
        WriteToLog.shared.message(theMessage: "[profileInstall] security: \(security)")
        
        let _ = Command.shared.myExitCode(cmd: "/bin/bash", args: "-c", "/usr/sbin/networksetup -addpreferredwirelessnetworkatindex \(en) '\(ssid)' 0 \(security) '\(ssidKey)'")
        let reply = Command.shared.myExitCode(cmd: "/bin/bash", args: "-c", "/usr/sbin/networksetup -setairportnetwork \(en) '\(ssid)' '\(ssidKey)'")
        WriteToLog.shared.message(theMessage: "[profileInstall] connection reply: \(reply)")
        
        return true
    }

    func profileRemove() -> Bool {
        if profileUuid != "" {
            // backup existing airport preferences plist - start
            if backup(operation: "copy", source: airportPrefs, destination: bakAirportPrefs) {
                WriteToLog.shared.message(theMessage: "Successfully backed up airport preferences plist")
            } else {
                WriteToLog.shared.message(theMessage: "Failed to backup airport preferences plist.")
            }
            // backup existing airport preferences plist - end

            // remove the manually added profile
            if Command.shared.myExitCode(cmd: "/usr/bin/profiles", args: "-R", "-p", profileUuid) == 0 {
                WriteToLog.shared.message(theMessage: "Configuration Profile was removed.")
                toggleWiFi()
                sleep(2)
                // verify we have connectivity - if not, try to add manual profile back
                var connectivityCounter = 1
                while !connectedToNetwork() && connectivityCounter < 56 {
                    if connectivityCounter == 2 {
                        do {
                            let plistURL = URL(string: "file:///Library/Application%20Support/JAMF/ReEnroller/profile.mobileconfig")
                            let ssid = stringFromPlist(plistURL: plistURL!, startString: "<key>SSID_STR</key><string>", endString: "</string><key>Interface</key><string>")
                            let ssidPwd = stringFromPlist(plistURL: plistURL!, startString: "<key>Password</key><string>", endString: "</string><key>EncryptionType</key>")
                            let encrypt = stringFromPlist(plistURL: plistURL!, startString: "<key>EncryptionType</key><string>", endString: "</string><key>AutoJoin</key>")
                            let en = myExitValue(cmd: "/bin/bash", args: "-c", "/usr/sbin/networksetup -listallhardwareports | grep -A1 Wi-Fi | grep Device | awk '{ print $2 }'")[0]

                            let _ = Command.shared.myExitCode(cmd: "/bin/bash", args: "-c", "/usr/sbin/networksetup -addpreferredwirelessnetworkatindex \(en) \"\(ssid)\" 0 \(encrypt) \"\(ssidPwd)\"")
                        } catch {
                            WriteToLog.shared.message(theMessage: "Problem extracting data from profile.")
                        }
                        // Add to keychain
                    }

                    if (connectivityCounter % 15) == 0 {
                        WriteToLog.shared.message(theMessage: "No connectivity for 30 seconds, power cycling WiFi.")
                        toggleWiFi()
                    }
                    sleep(2)
                    connectivityCounter += 1
                    WriteToLog.shared.message(theMessage: "Waiting for network connectivity.")
                }
                if !connectedToNetwork() && connectivityCounter > 55 {
                    WriteToLog.shared.message(theMessage: "There was a problem after removing manually added MDM configuration, network connectivity could not be established without it. Will attempt to re-add and continue.")
                    if profileInstall() {
                        WriteToLog.shared.message(theMessage: "Manual WiFi has been re-installed.")
                    }
                    return false
                }   // if connectivityCounter - end
                return true
            } else {
                WriteToLog.shared.message(theMessage: "There was a problem removing the Configuration Profile.")
                return false
                //exit(1)
            }
        }
        return false
    }

    func removeMDMProfile(when: String, completion: @escaping (_ result: String) -> Void) {
        var removeResult = "success"
        if removeMDM {
            // check if MDM profile exists
            if mdmInstalled(cmd: "/bin/bash", args: "-c", "/usr/bin/profiles -C | grep 00000000-0000-0000-A000-4A414D460003 | wc -l", message: "looking for MDM Profile") {
                // remove mdm profile - start
                if os.majorVersion == 10 && os.minorVersion < 13 {
                    if removeAllProfiles == "false" {
                        WriteToLog.shared.message(theMessage: "Attempting to remove mdm")
                        if Command.shared.myExitCode(cmd: "/usr/local/jamf/bin/jamf", args: "removemdmprofile") == 0 {
                            WriteToLog.shared.message(theMessage: "Removed old MDM profile using the jamf binary")
                        } else {
                            WriteToLog.shared.message(theMessage: "There was a problem removing old MDM profile.")
        //                    unverifiedFallback()
        //                    exit(1)
                            removeResult = "failed"
//                          completion("\(when) - failed")
                        }
                    } else {
                        // macOS < 10.13 - remove all profiles
                        if Command.shared.myExitCode(cmd: "/bin/rm", args: "-fr", "/private/var/db/ConfigurationProfiles") == 0 {
                            WriteToLog.shared.message(theMessage: "Removed all configuration profiles")
                        } else {
                            WriteToLog.shared.message(theMessage: "There was a problem removing all configuration profiles.")
                            removeResult = "failed"
//                            completion("\(when) - failed")
                        }
                    }
                } else {
                    WriteToLog.shared.message(theMessage: "High Sierra (10.13) or later.  Checking MDM status.")
                    var counter = 0
                    // try to remove mdm with jamf command
                    if os.majorVersion < 11 {
                        _ = Command.shared.myExitCode(cmd: "/usr/local/bin/jamf", args: "removemdmprofile")
                    }
                    if !mdmInstalled(cmd: "/bin/bash", args: "-c", "/usr/bin/profiles -C | grep 00000000-0000-0000-A000-4A414D460003 | wc -l", message: "looking for MDM Profile") {
                        counter+=1
                        WriteToLog.shared.message(theMessage: "Removed existing MDM profile using the jamf binary.")
                    } else {
                        var attempt = 1
                        WriteToLog.shared.message(theMessage: "Unable to remove MDM using the jamf binary, attempting remote command.")
                        while mdmInstalled(cmd: "/bin/bash", args: "-c", "/usr/bin/profiles -C | grep 00000000-0000-0000-A000-4A414D460003 | wc -l", message: "looking for MDM Profile") {

                            counter+=1
                            if (counter-1) % 20 == 0 {
                                WriteToLog.shared.message(theMessage: "Attempt \(attempt) to remove MDM through remote command.")
                                _ = Command.shared.myExitCode(cmd: "/bin/bash", args: "-c", "killall jamf")
                                _ = Command.shared.myExitCode(cmd: "/bin/bash", args: "-c", "/usr/local/bin/jamf policy -trigger apiMDM_remove")
                                attempt+=1
                            }

                            sleep(4)
                            if attempt > 5 {
                                WriteToLog.shared.message(theMessage: "Failed to remove MDM through remote command.")
                                removeResult = "failed"
                                completion("\(when) - failed")
                                return
                            }
                        }   // while mdmInstalled - end
                        WriteToLog.shared.message(theMessage: "Attempt \(attempt-1) removed the MDM profile.")
                        sleep(5)
                    }

                    if counter == 0 {
                        WriteToLog.shared.message(theMessage: "Check of MDM status shows no MDM.")
                    } else {
                        WriteToLog.shared.message(theMessage: "MDM has been removed.")
                    }
//                    completion("\(when) - succcess")
                }
                completion("\(when) - \(removeResult)")
                // remove mdm profile - end
            } else {
                WriteToLog.shared.message(theMessage: "Checking MDM status shows no MDM Profile.")
                completion("\(when) - succcess")
            }
        } else {
            if !newEnrollment {
                WriteToLog.shared.message(theMessage: "Leaving MDM Profile intact - removal will be handled outside ReEnroller.")
            }
            completion("\(when) - \(removeResult)")
        }
    }

    func removeTag(xmlString: String) -> String {
        let newString = xmlString.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        return newString
    }

    func toggleWiFi() {
        var interface = ""
        var power = ""

        // get Wi-Fi interface
        let interfaceArray = myExitValue(cmd: "/bin/bash", args: "-c", "/usr/sbin/networksetup -listallhardwareports | egrep -A 1 \"(Airport|Wi-Fi)\" | awk '/Device:/ { print $2 }'")
        if interfaceArray.count > 0 {
            interface = interfaceArray[0]

            // check airport power
            let powerArray = myExitValue(cmd: "/bin/bash", args: "-c", "/usr/sbin/networksetup -getairportpower \(interface) | awk -F': ' '{ print $2 }'")
            if powerArray.count > 0 {
                power = powerArray[0]

                if power == "On" {
                    if Command.shared.myExitCode(cmd: "/bin/bash", args: "-c", "/usr/sbin/networksetup -setairportpower \(interface) off") == 0 {
                        WriteToLog.shared.message(theMessage: "WiFi (\(interface)) has been turned off.")
                        usleep(100000)  // 0.1 seconds
                        if Command.shared.myExitCode(cmd: "/bin/bash", args: "-c", "/usr/sbin/networksetup -setairportpower \(interface) on") == 0 {
                            WriteToLog.shared.message(theMessage: "WiFi (\(interface)) has been turned on.")
                        }
                    }
                } else {
                    WriteToLog.shared.message(theMessage: "Note: Wi-Fi is currently disabled, not changing the setting.")
                }   // power == "On" - end
            }   // if powerArray.count - end
        }
    }

    func unverifiedFallback() {
        // only roll back if there is something to roll back to
        // add back in when ready to to use app on machines not currrently enrolled
        WriteToLog.shared.message(theMessage: "Alert - There was a problem with enrolling your Mac to the new Jamf Server URL at \(newJSSHostname):\(newJSSPort). We are rolling you back to the old Jamf Server URL at \(oldURL)")

        // restore backup jamf binary - start
        do {
            // check for existing jamf plist, remove if it exists
            if fm.fileExists(atPath: origBinary) && fm.fileExists(atPath: bakBinary) {
                do {
                    try fm.removeItem(atPath: origBinary)
                } catch {
                    WriteToLog.shared.message(theMessage: "Unable to remove jamf binary.")
                    //exit(1)
                }
            }
            if fm.fileExists(atPath: bakBinary) {
                try fm.moveItem(atPath: bakBinary, toPath: origBinary)
                WriteToLog.shared.message(theMessage: "Moved the backup jamf binary back into place.")
            }
        }
        catch let error as NSError {
            WriteToLog.shared.message(theMessage: "There was a problem moving the backup jamf binary back into place. Error: \(error)")
            //exit(1)
        }
        // restore backup jamf binary - end

        // restore original ConfigurationProfiles directory - start
        if os.minorVersion < 13 && os.majorVersion < 11 {
            if fm.fileExists(atPath: origProfilesDir) {
                do {
                    try fm.removeItem(atPath: origProfilesDir)
                    do {
                        try fm.moveItem(atPath: bakProfilesDir, toPath: origProfilesDir)
                    } catch {
                        WriteToLog.shared.message(theMessage: "There was a problem restoring original ConfigurationProfiles")
                    }
                } catch {
                    WriteToLog.shared.message(theMessage: "There was a problem removing original ConfigurationProfiles")
                }
            } else {
                if Command.shared.myExitCode(cmd: "/usr/local/bin/jamf", args: "manage") == 0 {
                    WriteToLog.shared.message(theMessage: "Restored the management framework/mdm from old JSS.")
                } else {
                    WriteToLog.shared.message(theMessage: "There was a problem restoring the management framework/mdm from old JSS.")
                }
            }
            if fm.fileExists(atPath: bakProfilesDir) {
                do {
                    try fm.moveItem(atPath: bakProfilesDir, toPath: origProfilesDir)
                    } catch {
                        WriteToLog.shared.message(theMessage: "There was a problem restoring original ConfigurationProfiles")
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
                    WriteToLog.shared.message(theMessage: "Unable to remove jamf.keychain for new Jamf server")
                    //exit(1)
                }
            }
            if fm.fileExists(atPath: bakKeychainFile) {
                try fm.moveItem(atPath: bakKeychainFile, toPath: origKeychainFile)
                WriteToLog.shared.message(theMessage: "Moved the backup keychain back into place.")
            }
        }
        catch let error as NSError {
            WriteToLog.shared.message(theMessage: "There was a problem moving the backup keychain back into place. Error: \(error)")
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
                    WriteToLog.shared.message(theMessage: "Unable to remove jamf plist.")
                    //exit(1)
                }
            }
            if fm.fileExists(atPath: bakjamfPlistPath) {
                try fm.moveItem(atPath: bakjamfPlistPath, toPath: jamfPlistPath)
                WriteToLog.shared.message(theMessage: "Moved the backup jamf plist back into place.")
            }
        }
        catch let error as NSError {
            WriteToLog.shared.message(theMessage: "There was a problem moving the backup jamf plist back into place. Error: \(error)")
            //exit(1)
        }
        // restore backup jamf plist - end

        if os.majorVersion < 11 {
            // re-enable mdm management from old server on the system - start
            if Command.shared.myExitCode(cmd: "/usr/local/bin/jamf", args: "mdm") == 0 {
                WriteToLog.shared.message(theMessage: "MDM Enrolled - getting MDM profiles from old JSS.")
            } else {
                WriteToLog.shared.message(theMessage: "There was a problem getting MDM profiles from old JSS.")
            }
            // re-enable mdm management from old server on the system - end
        }

        // try to run recon and update migration state, if tracking
        if self.markAsMigrated {
            if Command.shared.myExitCode(cmd: "/usr/local/jamf/bin/jamf", args: "recon", "-\(self.migratedAttribute)", "migration failed - \(self.getDateTime(x: 1))") == 0 {
                WriteToLog.shared.message(theMessage: "Marked machine as not migrated. Updated \(self.migratedAttribute) attribute.")
            } else {
                WriteToLog.shared.message(theMessage: "Unable to update attribute \(self.migratedAttribute) noting failed migration.")
            }
        }
        WriteToLog.shared.message(theMessage: "Exiting failback.")
        exit(1)
    }

    func userOperation(mgmtUser: String, operation: String) -> String {
        var returnVal           = ""
        var userUuid            = ""
        let defaultAuthority    = CSGetLocalIdentityAuthority().takeUnretainedValue()
        let identityClass       = kCSIdentityClassUser

        let query = CSIdentityQueryCreate(nil, identityClass, defaultAuthority).takeRetainedValue()

        var error : Unmanaged<CFError>? = nil

        CSIdentityQueryExecute(query, 2, &error)

        let results = CSIdentityQueryCopyResults(query).takeRetainedValue()

        let resultsCount = CFArrayGetCount(results)

//        var allUsersArray = [String]()
        var allGeneratedUID = [String]()

        for idx in 0..<resultsCount {
            let identity    = unsafeBitCast(CFArrayGetValueAtIndex(results,idx),to: CSIdentity.self)
            let uuidString  = CFUUIDCreateString(nil, CSIdentityGetUUID(identity).takeUnretainedValue())
            allGeneratedUID.append(uuidString! as String)

            if let uuidNS = NSUUID(uuidString: uuidString! as String), let identityObject = CBIdentity(uniqueIdentifier: uuidNS as UUID, authority: CBIdentityAuthority.default()) {

                let regex = try! NSRegularExpression(pattern: "<CSIdentity(.|\n)*?>", options:.caseInsensitive)
                var trimmedIdentityObject = regex.stringByReplacingMatches(in: "\(identityObject)", options: [], range: NSRange(0..<"\(identityObject)".utf16.count), withTemplate: "")
                trimmedIdentityObject = trimmedIdentityObject.replacingOccurrences(of: " = ", with: " : ")
                trimmedIdentityObject = String(trimmedIdentityObject.dropFirst())
                trimmedIdentityObject = String(trimmedIdentityObject.dropLast())
                //        print("trimmed: \(trimmedIdentityObject)")
                let userAttribArray   = trimmedIdentityObject.split(separator: ",")

                let posixIdArray = userAttribArray.last!.split(separator: " ")
                let posixId = "\(String(describing: posixIdArray.last))"
                let username = identityObject.posixName
                userUuid = "\(identityObject.uniqueIdentifier)"

//                allUsersArray.append(username)
                if ( mgmtUser.lowercased() == username.lowercased() ) {
                    switch operation {
                    case "find":
                        returnVal = userUuid
                    case "id":
                        returnVal = posixId
                    default:
                        break
                    }   // switch operation - end
                }   // if ( mgmtUser.lowercased() == username.lowercased() ) - end
            }
        }
//        return allUsersArray
        return returnVal
    }

    func verifiedCleanup(type: String) {
        WriteToLog.shared.message(theMessage: "Starting cleanup...")
        if type == "full" {
            do {
                if fm.fileExists(atPath: bakBinary) {
                    try fm.removeItem(atPath: bakBinary)
                    WriteToLog.shared.message(theMessage: "Removed backup jamf binary.")
                }
            }
            catch let error as NSError {
                WriteToLog.shared.message(theMessage: "There was a problem removing backup jamf binary.  Error: \(error)")
                //exit(1)
            }
            do {
                if fm.fileExists(atPath: bakKeychainFile) {
                    try fm.removeItem(atPath: bakKeychainFile)
                    WriteToLog.shared.message(theMessage: "Removed backup jamf keychain.")
                }
            }
            catch let error as NSError {
                WriteToLog.shared.message(theMessage: "There was a problem removing backup jamf keychain.  Error: \(error)")
                //exit(1)
            }
            do {
                if fm.fileExists(atPath: bakjamfPlistPath) {
                    try fm.removeItem(atPath: bakjamfPlistPath)
                    WriteToLog.shared.message(theMessage: "Removed backup jamf plist.")
                }
            }
            catch let error as NSError {
                WriteToLog.shared.message(theMessage: "There was a problem removing backup jamf plist.  Error: \(error)")
                //exit(1)
            }
            if os.majorVersion == 10 && os.minorVersion < 13 {
                do {
                    if fm.fileExists(atPath: bakProfilesDir) {
                        try fm.removeItem(atPath: bakProfilesDir)
                        WriteToLog.shared.message(theMessage: "Removed backup ConfigurationProfiles dir.")
                    }
                }
                catch let error as NSError {
                    WriteToLog.shared.message(theMessage: "There was a problem removing backup ConfigurationProfiles dir.  Error: \(error)")
                    //exit(1)
                }
            }

//            var uid: uid_t = 0
//            var gid: gid_t = 0
            var currentUser = ""
            if let theResult = SCDynamicStoreCopyConsoleUser(nil, nil, nil) {
                currentUser = theResult as String
            } else {
                WriteToLog.shared.message(theMessage: "No user logged in.")
            }
//            let currentUser = NSUserName()
            // update inventory - start
            WriteToLog.shared.message(theMessage: "Launching Recon...")
            if Command.shared.myExitCode(cmd: "/usr/local/bin/jamf", args: "recon", "-endUsername", "\(currentUser)") == 0 {
                WriteToLog.shared.message(theMessage: "Submitting full recon for user \(currentUser) to \(newJSSHostname):\(newJSSPort).")
                _ = Command.shared.myExitCode(cmd: "/usr/local/bin/jamf", args: "manage")
                sleep(10)
            } else {
                WriteToLog.shared.message(theMessage: "There was a problem submitting full recon to \(newJSSHostname):\(newJSSPort).")
                //exit(1)
            }
            do {
                if self.fm.fileExists(atPath: "/usr/local/bin/jamfAgent") {
                    try self.fm.removeItem(atPath: "/usr/local/bin/jamfAgent")
                }
                if Command.shared.myExitCode(cmd: "/bin/bash", args: "-c", "ln -s /usr/local/jamf/bin/jamfAgent /usr/local/bin/jamfAgent") == 0 {
                    WriteToLog.shared.message(theMessage: "Re-created alias for jamfAgent binary in /usr/local/bin.")
                } else {
                    WriteToLog.shared.message(theMessage: "Failed to re-created alias for jamfAgent binary in /usr/local/bin.")
                }
            } catch {
                if self.fm.fileExists(atPath: "/usr/local/bin/jamfAgent") {
                    WriteToLog.shared.message(theMessage: "Alias for jamfAgent binary in /usr/local/bin is ok.")
                } else {
                    WriteToLog.shared.message(theMessage: "Alias for jamfAgent binary in /usr/local/bin could not be created.")
                }
            }
            // update inventory - end

            if callEnrollment == "yes" {
                // see if device is scoped to a prestage enrollment
                _ = Command.shared.myExitCode(cmd: "/usr/bin/profiles", args: "status", "-type", "enrollment")
                // launch profiles renew -type enrollment to initiate ADE process
                if Command.shared.myExitCode(cmd: "/usr/bin/profiles", args: "renew", "-type", "enrollment") == 0 {
                    WriteToLog.shared.message(theMessage: "Successfully called profiles renew -type enrollment")
                } else {
                    WriteToLog.shared.message(theMessage: "call to profiles renew -type enrollment failed")
                    //exit(1)
                }
            } else {
                WriteToLog.shared.message(theMessage: "not calling profiles renew -type enrollment")
            }

            // remove config profile if marked as such - start
            WriteToLog.shared.message(theMessage: "Checking if config profile removal is required...")
            if removeConfigProfile == "true" {
                if !profileRemove() {
                    WriteToLog.shared.message(theMessage: "Unable to remove configuration profile")
                }
            } else {
                WriteToLog.shared.message(theMessage: "Configuration profile is not marked for removal.")
            }
            // remove config profile if marked as such - end

            // run policy if marked to do so - start
            if postInstallPolicyId.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil {
                WriteToLog.shared.message(theMessage: "There was a problem with the value for the policy id: \(postInstallPolicyId)")
            } else {
                if  postInstallPolicyId != "" {
                    WriteToLog.shared.message(theMessage: "Running policy id \(postInstallPolicyId)")
                    if Command.shared.myExitCode(cmd: "/usr/local/bin/jamf", args: "policy", "-id", "\(postInstallPolicyId)") == 0 {
                        WriteToLog.shared.message(theMessage: "Successfully called policy id \(postInstallPolicyId)")
                    } else {
                        WriteToLog.shared.message(theMessage: "There was an error calling policy id \(postInstallPolicyId)")
                        //exit(1)
                    }
                } else {
                    WriteToLog.shared.message(theMessage: "No post migration policy is set to be called.")
                }
            }
            // run policy if marked to do so - end

            // Remove ..JAMF/ReEnroller folder - start
            if removeReEnroller == "yes" {
                do {
                    try fm.removeItem(atPath: "/Library/Application Support/JAMF/ReEnroller")
                    WriteToLog.shared.message(theMessage: "Removed ReEnroller folder.")
                }
                catch let error as NSError {
                    WriteToLog.shared.message(theMessage: "There was a problem removing ReEnroller folder.  Error: \(error)")
                }
            } else {
                WriteToLog.shared.message(theMessage: "ReEnroller folder is left intact.")
            }
            // Remove ..JAMF/ReEnroller folder - end
        }   // if type == "full" - end

        // remove plist containing userDefaults, like the retryCount
        if fm.fileExists(atPath: "/private/var/root/Library/Preferences/com.jamf.pse.ReEnroller.plist") {
            do {
                try fm.removeItem(atPath: "/private/var/root/Library/Preferences/com.jamf.pse.ReEnroller.plist")
            } catch {
                WriteToLog.shared.message(theMessage: "Unable to remove /private/var/root/Library/Preferences/com.jamf.pse.ReEnroller.plist")
            }
        }
        userDefaults.set(0, forKey: "retryCount")


        // remove a previous launchd, if it exists, from /private/tmp
        if fm.fileExists(atPath: "/private/tmp/com.jamf.ReEnroller.plist") {
            do {
                try fm.removeItem(atPath: "/private/tmp/com.jamf.ReEnroller.plist")
            } catch {
                WriteToLog.shared.message(theMessage: "Unable to remove existing plist in /private/tmp")
            }
        }

        //  move and unload launchd to finish up.
        if fm.fileExists(atPath: "/Library/LaunchDaemons/com.jamf.ReEnroller.plist") {
            do {
                try fm.moveItem(atPath: "/Library/LaunchDaemons/com.jamf.ReEnroller.plist", toPath: "/private/tmp/com.jamf.ReEnroller.plist")
                WriteToLog.shared.message(theMessage: "Moved launchd to /private/tmp.")

                // migration complete - unload the launchd
                if type == "full" {
                    WriteToLog.shared.message(theMessage: "===================================================================")
                    WriteToLog.shared.message(theMessage: "= ReEnrollment Complete - this should be the last message logged! =")
                    WriteToLog.shared.message(theMessage: "===================================================================")
                }
                if os.majorVersion >= 11 {
                    //bootout system /Library/LaunchDaemons/com.jamf.ReEnroller.plist
                    if Command.shared.myExitCode(cmd: "/bin/launchctl", args: "bootout", "system", "/tmp/com.jamf.ReEnroller.plist") != 0 {
                        WriteToLog.shared.message(theMessage: "There was a problem unloading the launchd.")
                    }
                } else {
                    if Command.shared.myExitCode(cmd: "/bin/launchctl", args: "unload", "/tmp/com.jamf.ReEnroller.plist") != 0 {
                        WriteToLog.shared.message(theMessage: "There was a problem unloading the launchd.")
                    }
                }

            } catch {
                WriteToLog.shared.message(theMessage: "Could not move launchd")
            }
        }
    }

    func verifyNewEnrollment() {
        DispatchQueue.main.async {
            WriteToLog.shared.message(theMessage: "Verifying enrollment...")
            for i in 1...4 {
                // test for a policy on the new Jamf Pro server and that it ran successfully
                let policyExitCode = Command.shared.myExitCode(cmd: "/usr/local/bin/jamf", args: "policy", "-trigger", "jpsmigrationcheck")
                var loopCount = 0
                while loopCount < 30 && !self.fm.fileExists(atPath: self.verificationFile) {
                    sleep(1)
                    loopCount+=1
                }
                if policyExitCode == 0 && self.fm.fileExists(atPath: self.verificationFile) {
                    WriteToLog.shared.message(theMessage: "Verified migration with sample policy using jpsmigrationcheck trigger.")
                    WriteToLog.shared.message(theMessage: "Policy created the check file.")
                    break
                } else {
                    WriteToLog.shared.message(theMessage: "Attempt \(i): There was a problem verifying migration with sample policy using jpsmigrationcheck trigger.")
                    WriteToLog.shared.message(theMessage: "/usr/local/bin/jamf policy -trigger jpsmigrationcheck")
                    WriteToLog.shared.message(theMessage: "Exit code: \(policyExitCode)")
                    if i > 3 {
                        WriteToLog.shared.message(theMessage: "Falling back to old settings and exiting!")
                        self.unverifiedFallback()
                        exit(1)
                    }
                }
            }   // for i in 1...4 - end
            // verify cleanup
            self.verifiedCleanup(type: "full")
            exit(0)
        }
    }

    func xmlEncode(rawString: String) -> String {
        var encodedString = rawString
        encodedString     = encodedString.replacingOccurrences(of: "&", with: "&amp;")
        encodedString     = encodedString.replacingOccurrences(of: "\"", with: "&quot;")
        encodedString     = encodedString.replacingOccurrences(of: "'", with: "&apos;")
        encodedString     = encodedString.replacingOccurrences(of: ">", with: "&gt;")
        encodedString     = encodedString.replacingOccurrences(of: "<", with: "&lt;")
        return encodedString
    }


    func stringFromPlist(plistURL: URL, startString: String, endString: String) -> String {
        WriteToLog.shared.message(theMessage: "reading from \(plistURL)")
        var xmlValue = ""
        do {
            let one = try String(contentsOf: plistURL, encoding: String.Encoding.ascii).components(separatedBy: endString)
            let _string = one[0].components(separatedBy: startString)
            xmlValue = _string[1]
        } catch {
            WriteToLog.shared.message(theMessage: "unable to read file")
        }
        return xmlValue
    }

//    func writeToLog(theMessage: String) {
//        LogFileW?.seekToEndOfFile()
//        let fullMessage = getDateTime(x: 2) + " \(param.localhostname) [ReEnroller]:    " + theMessage + "\n"
//        let LogText = (fullMessage as NSString).data(using: String.Encoding.utf8.rawValue)
//        LogFileW?.write(LogText!)
//    }
    
    @IBAction func selectSite_Button(_ sender: Any) {
//        print("selected site: \(site_Button.titleOfSelectedItem ?? "None")")
        let siteKey = "\(site_Button.titleOfSelectedItem ?? "None")"
        "\(site_Button.titleOfSelectedItem ?? "None")" == "None" ? (siteId = "-1") : (siteId = "\(siteDict[siteKey] ?? "-1")")
//        print("selected site id: \(siteId)")
    }

    @IBAction func siteToggle_button(_ sender: NSButton) {
//        print("\(String(describing: sender.identifier!))")
        if (convertFromOptionalNSUserInterfaceItemIdentifier(sender.identifier)! == "selectSite") && (enableSites_Button.state.rawValue == 1) {
            retainSite_Button.state = convertToNSControlStateValue(0)
            fetchSites()
        } else if (convertFromOptionalNSUserInterfaceItemIdentifier(sender.identifier)! == "existingSite") && (retainSite_Button.state.rawValue == 1) {
            enableSites_Button.state = convertToNSControlStateValue(0)
            self.site_Button.isEnabled = false
        } else if (enableSites_Button.state.rawValue == 0) {
            self.site_Button.isEnabled = false
        }
    }

    func startToMigrate() {
        WriteToLog.shared.message(theMessage: "[startToMigrate]")


        let appInfo = Bundle.main.infoDictionary!
        let version = appInfo["CFBundleShortVersionString"] as! String

        LogFileW = FileHandle(forUpdatingAtPath: (logFilePath))

        retryCount = userDefaults.integer(forKey: "retryCount")
        WriteToLog.shared.message(theMessage: "initial retry count: \(retryCount)")
        
        var isDir: ObjCBool = true
        if !fm.fileExists(atPath: "/usr/local/jamf/bin", isDirectory: &isDir) {
            do {
                try fm.createDirectory(atPath: "/usr/local/jamf/bin", withIntermediateDirectories: true, attributes: nil)
                NSLog("Created jamf binary directory: /usr/local/jamf/bin")
            } catch {
                NSLog("failed to create jamf binary directory")
            }
        }
        if !fm.fileExists(atPath: "/usr/local/bin", isDirectory: &isDir) {
            do {
                try fm.createDirectory(atPath: "/usr/local/bin", withIntermediateDirectories: true, attributes: nil)
                NSLog("Created binary directory: /usr/local/bin")
            } catch {
                NSLog("failed to create /usr/local/bin directory")
            }
        }

        // create jamf log file if not present
        if !fm.fileExists(atPath: logFilePath) {
            print("create \(logFilePath)")
            let _ = fm.createFile(atPath: logFilePath, contents: nil, attributes: [FileAttributeKey(rawValue: "ownerAccountID"):0, FileAttributeKey(rawValue: "groupOwnerAccountID"):80, FileAttributeKey(rawValue: "posixPermissions"):0o755])
        }

        print("read settings from: \( param.settingsFile)")

        let settingsPlistXML = fm.contents(atPath:  param.settingsFile)!
        do{
            WriteToLog.shared.message(theMessage: "Reading settings from: \( param.settingsFile)")
            plistData = try PropertyListSerialization.propertyList(from: settingsPlistXML,
                                                                   options: .mutableContainersAndLeaves,
                                                                   format: &format)
                as! [String : AnyObject]
        }
        catch{
            WriteToLog.shared.message(theMessage: "Error reading plist: \(error), format: \(format)")
        }

        // read new enrollment setting
        if plistData["newEnrollment"] != nil {
            newEnrollment = plistData["newEnrollment"] as! Bool
        } else {
            newEnrollment = false
        }
        WriteToLog.shared.message(theMessage: "================================")
        WriteToLog.shared.message(theMessage: "ReEnroller Version: \(version)")
        WriteToLog.shared.message(theMessage: "     macOS Version: \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)")
        WriteToLog.shared.message(theMessage: "================================")
        WriteToLog.shared.message(theMessage: "New enrollment: \(newEnrollment)")


        // read max retries setting
        // maxRetries was written as a string so it's value could be nil
        if plistData["maxRetries"] != nil {
            maxRetries = Int(plistData["maxRetries"] as! String)!
        } else {
            maxRetries = -1
        }
        WriteToLog.shared.message(theMessage: "Maximum number of retries: \(maxRetries)")

        if plistData["newJSSHostname"] != nil && plistData["newJSSPort"] != nil && plistData["theNewInvite"] != nil {
            WriteToLog.shared.message(theMessage: "Found configuration for new Jamf Pro server: \(String(describing: plistData["newJSSHostname"]!)), begin migration")

            // Parameters for the new emvironment
            newJSSHostname = plistData["newJSSHostname"]! as! String
            newJSSPort     = plistData["newJSSPort"]! as! String

            // read management account
            if plistData["mgmtAccount"] != nil {
                mgmtAccount = plistData["mgmtAccount"]! as! String
            }

            /*
            // read config profile vars - replaced with ssid and key
            if plistData["profileUUID"] != nil {
                profileUuid = plistData["profileUUID"]! as! String
                WriteToLog.shared.message(theMessage: "UDID of included profile is: \(profileUuid)")
            } else {
                WriteToLog.shared.message(theMessage: "No configuration profiles included for install.")
            }
            */
            if plistData["ssid"] != nil {
                ssid = plistData["ssid"]! as! String
                let encodedKey = plistData["ssidKey"] as! String
                let symmetricKey = SymmetricKey(base64EncodedString: base64SymetricKey)!
                
                do {
                    let tmpSealedBox = try stringToSealedBox(encodedKey)
                    let decriptSealedBox = try! AES.GCM.open(tmpSealedBox, using: symmetricKey)
                    ssidKey = String(data: decriptSealedBox, encoding: .utf8)!
                } catch {
                    WriteToLog.shared.message(theMessage: "[startToMigrate] Failed reading SSID passphrase")
                }
                
                WriteToLog.shared.message(theMessage: "[startToMigrate] SSID is set to \(ssid)")
                
            } else {
                WriteToLog.shared.message(theMessage: "No WiFi configuration found.")
            }
            if plistData["removeProfile"] != nil {
                removeConfigProfile = plistData["removeProfile"]! as! String
            }
            if plistData["removeAllProfiles"] != nil {
                removeAllProfiles = plistData["removeAllProfiles"]! as! String
            }
            if plistData["callEnrollment"] != nil {
                callEnrollment = plistData["callEnrollment"]! as! String
            }
            if plistData["removeReEnroller"] != nil {
                removeReEnroller = plistData["removeReEnroller"]! as! String
            }
            if plistData["createConfSwitches"] != nil {
                createConfSwitches = plistData["createConfSwitches"]! as! String
            }
            if plistData["skipHealthCheck"] != nil {
                skipHealthCheck = plistData["skipHealthCheck"]! as! String
            }
            if plistData["skipMdmCheck"] != nil {
                skipMdmCheck = plistData["skipMdmCheck"]! as! String
            }
            if plistData["postInstallPolicyId"] != nil {
                postInstallPolicyId = plistData["postInstallPolicyId"]! as! String
            }
            if plistData["httpProtocol"] != nil {
                httpProtocol = self.plistData["httpProtocol"] as! String
            } else {
                httpProtocol = "https"
            }

//                jamfSchoolMigration = (plistData["jamfSchool"] ?? "" as AnyObject) as! String
            jamfSchoolMigration = plistData["jamfSchool"]! as? Int ?? 0

            markAsMigrated    = plistData["markAsMigrated"] as? Bool ?? false
            migratedAttribute = plistData["migratedAttribute"] as? String ?? "room"

            removeMDM         = plistData["removeMDM"] as? Bool ?? true
            if jamfSchoolMigration == 0 {
                removeMdmWhen = plistData["removeMdmWhen"] as? String ?? "Before"
            } else {
                removeMdmWhen = "After"
            }

            WriteToLog.shared.message(theMessage: "jamfSchoolMigration: \(jamfSchoolMigration)")

//                jamfSchoolUrl       = plistData["jamfSchoolUrl"]! as? String ?? ""
//                jamfSchoolToken     = plistData["jamfSchoolToken"]! as? String ?? ""

            theNewInvite = plistData["theNewInvite"]! as! String
            newJssMgmtUrl = "\(httpProtocol)://\(newJSSHostname):\(newJSSPort)"
            WriteToLog.shared.message(theMessage: "newServer: \(newJSSHostname)\tnewPort: \(newJSSPort)")


            // look for an existing jamf plist file
            if fm.fileExists(atPath: jamfPlistPath) {
                // need to convert jamf plist to xml (plutil -convert xml1 some.plist)
                if Command.shared.myExitCode(cmd: "/usr/bin/plutil", args: "-convert", "xml1", jamfPlistPath) != 0 {
                    WriteToLog.shared.message(theMessage: "Unable to read current jamf configuration.  It is either corrupt or client is not enrolled.")
                    //exit(1)
                } else {

                    let plistXML = FileManager.default.contents(atPath: jamfPlistPath)!
                    do{
                        jamfPlistData = try PropertyListSerialization.propertyList(from: plistXML,
                                                                                   options: .mutableContainersAndLeaves,
                                                                                   format: &format)
                            as! [String:AnyObject]
                    } catch {
                        WriteToLog.shared.message(theMessage: "Error reading plist: \(error), format: \(format)")
                    }
                    if jamfPlistData["jss_url"] != nil {
                        oldURL = jamfPlistData["jss_url"]! as! String
                    }
                    WriteToLog.shared.message(theMessage: "Found old Jamf Pro server: \(oldURL)")
                    // convert the jamf plist back to binary (plutil -convert binary1 some.plist)
                    if Command.shared.myExitCode(cmd: "/usr/bin/plutil", args: "-convert", "binary1", jamfPlistPath) != 0 {
                        WriteToLog.shared.message(theMessage: "There was an error converting the jamf.plist back to binary")
                    }
                }
            } else {
                oldURL = ""
                if !newEnrollment {
                    WriteToLog.shared.message(theMessage: "Machine is not currently enrolled, exitting.")
                    exit(0)
                } else {
                    WriteToLog.shared.message(theMessage: "Machine is not currently enrolled, starting new enrollment.")
                }
            }

            beginMigration()
        } else {
            WriteToLog.shared.message(theMessage: "Configuration data can not be found.")
            WriteToLog.shared.message(theMessage: "Current data:\n\(plistData)")

            NSApplication.shared.terminate(self)
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        jssUrl_TextField.stringValue      = userDefaults.string(forKey: "jamfProUrl") ?? ""
        jssUsername_TextField.stringValue = userDefaults.string(forKey: "jamfProUser") ?? ""
        migratedAttribute_Button.selectItem(withTitle: "Room")

        WriteToLog.shared.message(theMessage: "Configuration not found, launching GUI.")
        param.runAsDaemon = false
        
        retry_TextField.stringValue = "30"
        newEnrollment_Button.state = convertToNSControlStateValue(0)
        removeReEnroller_Button.state = convertToNSControlStateValue(1)
        rndPwdLen_TextField?.isEnabled = false
        rndPwdLen_TextField?.stringValue = "8"
        if (( os.majorVersion > 10 ) || ( os.majorVersion == 10 && os.minorVersion > 15 )) {
            deviceEnrollment_Button.state = convertToNSControlStateValue(1)
        }

        // bring app to the foreground
        jssUrl_TextField.becomeFirstResponder()

        // set tab order for text fields
        jssUrl_TextField.nextKeyView       = jssUsername_TextField
        jssUsername_TextField.nextKeyView  = jssPassword_TextField
        jssPassword_TextField.nextKeyView  = mgmtAccount_TextField
        mgmtAccount_TextField.nextKeyView  = mgmtAcctPwd_TextField
        mgmtAcctPwd_TextField.nextKeyView  = mgmtAcctPwd2_TextField
        mgmtAcctPwd2_TextField.nextKeyView = maxRetries_Textfield
        maxRetries_Textfield.nextKeyView   = retry_TextField

        DispatchQueue.main.async {
//            self.view.layer?.backgroundColor = CGColor(red: 0x6c/255.0, green:0x82/255.0, blue:0x94/255.0, alpha: 1.0)
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    
    struct SealedBoxCodable: Codable {
        let nonce: [UInt8]
        let ciphertext: [UInt8]
        let tag: [UInt8]

        init(sealedBox: AES.GCM.SealedBox) {
            nonce = sealedBox.nonce.withUnsafeBytes { Array($0.bindMemory(to: UInt8.self)) }
            ciphertext = sealedBox.ciphertext.withUnsafeBytes { Array($0.bindMemory(to: UInt8.self)) }
            tag = sealedBox.tag.withUnsafeBytes { Array($0.bindMemory(to: UInt8.self)) }
        }

        func toSealedBox() throws -> AES.GCM.SealedBox {
            return try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: Data(nonce)),
                                         ciphertext: Data(ciphertext),
                                         tag: Data(tag))
        }
    }
    func sealedBoxToString(_ sealedBox: AES.GCM.SealedBox) throws -> String {
        let sealedBoxCodable = SealedBoxCodable(sealedBox: sealedBox)
        let encoder = JSONEncoder()
        let data = try encoder.encode(sealedBoxCodable)
        return data.base64EncodedString()
    }
    func stringToSealedBox(_ string: String) throws -> AES.GCM.SealedBox {
        guard let data = Data(base64Encoded: string) else {
            throw NSError(domain: "InvalidBase64String", code: 0, userInfo: nil)
        }

        let decoder = JSONDecoder()
        let sealedBoxCodable = try decoder.decode(SealedBoxCodable.self, from: data)
        return try sealedBoxCodable.toSealedBox()
    }
}

extension String {
    var baseUrl: String {
        get {
            var fqdn = ""
            let nameArray = self.components(separatedBy: "/")
            if nameArray.count > 2 {
                fqdn = nameArray[2]
            } else {
                fqdn =  self
            }
            return "\(nameArray[0])//\(fqdn)"
        }
    }
}

extension SymmetricKey {

    /// Creates a `SymmetricKey` from a Base64-encoded `String`.
    ///
    /// - Parameter base64EncodedString: The Base64-encoded string from which to generate the `SymmetricKey`.
    init?(base64EncodedString: String) {
        guard let data = Data(base64Encoded: base64EncodedString) else {
            return nil
        }

        self.init(data: data)
    }

    /// Serializes a `SymmetricKey` to a Base64-encoded `String`.
    func serialize() -> String {
        return self.withUnsafeBytes { body in
            Data(body).base64EncodedString()
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSControlStateValue(_ input: Int) -> NSControl.StateValue {
    return NSControl.StateValue(rawValue: input)
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromOptionalNSUserInterfaceItemIdentifier(_ input: NSUserInterfaceItemIdentifier?) -> String? {
    guard let input = input else { return nil }
    return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSControlStateValue(_ input: NSControl.StateValue) -> Int {
    return input.rawValue
}
