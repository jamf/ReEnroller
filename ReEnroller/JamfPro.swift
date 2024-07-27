//
//  JamfPro.swift
//  prune
//
//  Created by Leslie Helou on 12/11/19.
//  Copyright © 2019 Leslie Helou. All rights reserved.
//

import Foundation

class JamfPro: NSObject, URLSessionDelegate {
        
    func getToken(serverUrl: String, base64creds: String, completion: @escaping (_ authResult: (Int,String)) -> Void) {
        //       print("[getToken] serverUrl: \(serverUrl)")
        URLCache.shared.removeAllCachedResponses()
        
        var tokenUrlString = "\(serverUrl)/api/v1/auth/token"
        
        tokenUrlString     = tokenUrlString.replacingOccurrences(of: "//api", with: "/api")
        //        print("[TokenDelegate] tokenUrlString: \(tokenUrlString)")
        
        let tokenUrl       = URL(string: "\(tokenUrlString)")
        guard let _ = tokenUrl else {
            WriteToLog.shared.message(theMessage: "[TokenDelegate.getToken] Problem constructing the URL from \(tokenUrlString)")
            completion((500, "failed"))
            return
        }
        
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: tokenUrl!)
        request.httpMethod = "POST"
        
        
        WriteToLog.shared.message(theMessage: "[TokenDelegate.getToken] Attempting to retrieve token from \(String(describing: tokenUrl!)) for version look-up")
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(base64creds)", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
        
        let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
            (data, response, error) -> Void in
            //                let dataString = String(data: data!, encoding: .utf8)
            session.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                if httpSuccess.contains(httpResponse.statusCode) {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json! as? [String: Any] {
                        JamfProServer.validToken  = true
                        JamfProServer.authCreds   = (endpointJSON["token"] as? String ?? "")!
                        
                        JamfProServer.authType    = "Bearer"
                        JamfProServer.base64Creds = base64creds
                        
                        tokenTimeCreated = Date()
                        
                        //                      print("[JamfPro] result of token request: \(endpointJSON)")
                        WriteToLog.shared.message(theMessage: "[TokenDelegate.getToken] new token created for \(serverUrl)")
                        
                        if JamfProServer.version.isEmpty {
                            // get Jamf Pro version - start
                            self.getVersion(serverUrl: serverUrl, endpoint: "jamf-pro-version", apiData: [:], id: "", token: JamfProServer.authCreds, method: "GET") {
                                (result: [String:Any]) in
                                if let versionString = result["version"] as? String {
                                    
                                    if !versionString.isEmpty {
                                        WriteToLog.shared.message(theMessage: "[TokenDelegate.getVersion] Jamf Pro Version: \(versionString)")
                                        JamfProServer.version = versionString
                                        let tmpArray = versionString.components(separatedBy: ".")
                                        if tmpArray.count > 2 {
                                            for i in 0...2 {
                                                switch i {
                                                case 0:
                                                    JamfProServer.majorVersion = Int(tmpArray[i]) ?? 0
                                                case 1:
                                                    JamfProServer.minorVersion = Int(tmpArray[i]) ?? 0
                                                case 2:
                                                    let tmp = tmpArray[i].components(separatedBy: "-")
                                                    JamfProServer.patchVersion = Int(tmp[0]) ?? 0
                                                    if tmp.count > 1 {
                                                        JamfProServer.build = tmp[1]
                                                    }
                                                default:
                                                    break
                                                }
                                            }
                                            if JamfProServer.majorVersion >= 10 || ( JamfProServer.majorVersion > 9 && JamfProServer.minorVersion > 34 ) {
                                                JamfProServer.authType = "Bearer"
                                                JamfProServer.validToken = true
                                                WriteToLog.shared.message(theMessage: "[TokenDelegate.getVersion] \(serverUrl) set to use Bearer Token")
                                                
                                            } else {
                                                JamfProServer.authType  = "Basic"
                                                JamfProServer.validToken = false
                                                JamfProServer.authCreds = base64creds
                                                WriteToLog.shared.message(theMessage: "[TokenDelegate.getVersion] \(serverUrl) set to use Basic Authentication")
                                            }
                                            if JamfProServer.authType == "Bearer" {
                                                //                                                    self.refresh(server: serverUrl, b64Creds: JamfProServer.base64Creds)
                                            }
                                            completion((200, "success"))
                                            return
                                        }
                                    }
                                } else {   // if let versionString - end
                                    WriteToLog.shared.message(theMessage: "[TokenDelegate.getToken] failed to get version information from \(String(describing: serverUrl))")
                                    JamfProServer.validToken = false
                                    Alert.shared.display(header: "Attention", message: "Failed to get version information from \(String(describing: serverUrl))")
                                    completion((httpResponse.statusCode, "failed"))
                                    return
                                }
                            }
                            // get Jamf Pro version - end
                        } else {
                            if JamfProServer.authType == "Bearer" {
                                WriteToLog.shared.message(theMessage: "[TokenDelegate.getVersion] call token refresh process for \(serverUrl)")
                            }
                            completion((200, "success"))
                            return
                        }
                    } else {    // if let endpointJSON error
                        WriteToLog.shared.message(theMessage: "[TokenDelegate.getToken] JSON error.\n\(String(describing: json))")
                        JamfProServer.validToken  = false
                        completion((httpResponse.statusCode, "failed"))
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                    JamfProServer.validToken = false
                    completion((httpResponse.statusCode, "failedToAuthenticate"))
                    return
                }
            } else {
                JamfProServer.validToken = false
                completion((0, "failedToConnect"))
                return
            }
        })
        task.resume()
    }

    func getVersion(serverUrl: String, endpoint: String, apiData: [String:Any], id: String, token: String, method: String, completion: @escaping (_ returnedJSON: [String: Any]) -> Void) {
        
        if method.lowercased() == "skip" {
            let JPAPI_result = (endpoint == "auth/invalidate-token") ? "no valid token":"failed"
            completion(["JPAPI_result":JPAPI_result, "JPAPI_response":000])
            return
        }
        
        URLCache.shared.removeAllCachedResponses()
        var path = ""
        
        switch endpoint {
        case  "buildings", "csa/token", "icon", "jamf-pro-version", "auth/invalidate-token":
            path = "v1/\(endpoint)"
        default:
            path = "v2/\(endpoint)"
        }
        
        var urlString = "\(serverUrl)/api/\(path)"
        urlString     = urlString.replacingOccurrences(of: "//api", with: "/api")
        if !id.isEmpty && id != "0" {
            urlString = urlString + "/\(id)"
        }
        //        print("[Jpapi] urlString: \(urlString)")
        
        let url            = URL(string: "\(urlString)")
        let configuration  = URLSessionConfiguration.default
        var request        = URLRequest(url: url!)
        switch method.lowercased() {
        case "get":
            request.httpMethod = "GET"
        case "create", "post":
            request.httpMethod = "POST"
        default:
            request.httpMethod = "PUT"
        }
        
        if apiData.count > 0 {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: apiData, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
        WriteToLog.shared.message(theMessage: "[Jpapi.action] Attempting \(method) on \(urlString).")
        //        print("[Jpapi.action] Attempting \(method) on \(urlString).")
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(token)", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
        
        let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            session.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json as? [String:Any] {
                        completion(endpointJSON)
                        return
                    } else {    // if let endpointJSON error
                        if httpResponse.statusCode == 204 && endpoint == "auth/invalidate-token" {
                            completion(["JPAPI_result":"token terminated", "JPAPI_response":httpResponse.statusCode])
                        } else {
                            completion(["JPAPI_result":"failed", "JPAPI_response":httpResponse.statusCode])
                        }
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                    WriteToLog.shared.message(theMessage: "[TokenDelegate.getVersion] Response error: \(httpResponse.statusCode).")
                    completion(["JPAPI_result":"failed", "JPAPI_method":request.httpMethod ?? method, "JPAPI_response":httpResponse.statusCode, "JPAPI_server":urlString, "JPAPI_token":token])
                    return
                }
            } else {
                WriteToLog.shared.message(theMessage: "[TokenDelegate.getVersion] GET response error.  Verify url and port.")
                completion([:])
                return
            }
        })
        task.resume()
    }   // func getVersion - end
    
    
    
    
    /*
    var renewQ = DispatchQueue(label: "com.jamfpse.token_refreshQ", qos: DispatchQoS.background)   // running background process for refreshing token
    
    func getVersion(jpURL: String, basicCreds: String, completion: @escaping (_ jpversion: (String,String)) -> Void) {
        print("[getVersion] jpURL: \(jpURL)")
        var versionString  = ""
        let semaphore      = DispatchSemaphore(value: 0)
        
        OperationQueue().addOperation {
            let encodedURL     = NSURL(string: "\(jpURL)/JSSCheckConnection")
            let request        = NSMutableURLRequest(url: encodedURL! as URL)
            request.httpMethod = "GET"
            let configuration  = URLSessionConfiguration.default
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
                (data, response, error) -> Void in
//                if let httpResponse = response as? HTTPURLResponse {
                    versionString = String(data: data!, encoding: .utf8) ?? ""
//                    print("httpResponse: \(httpResponse)")
//                    print("raw versionString: \(versionString)")
                    if versionString != "" {
                        let tmpArray = versionString.components(separatedBy: ".")
                        if tmpArray.count > 2 {
                            for i in 0...2 {
                                switch i {
                                case 0:
                                    JamfProServer.majorVersion = Int(tmpArray[i]) ?? 0
                                case 1:
                                    JamfProServer.minorVersion = Int(tmpArray[i]) ?? 0
                                case 2:
                                    let tmp = tmpArray[i].components(separatedBy: "-")
                                    JamfProServer.patchVersion = Int(tmp[0]) ?? 0
                                    if tmp.count > 1 {
                                        JamfProServer.build = tmp[1]
                                    }
                                default:
                                    break
                                }
                            }
                        }
                    }
//                }
                WriteToLog.shared.message(theMessage: "[JamfPro.getVersion] Jamf Pro Version: \(versionString)")
                if ( JamfProServer.majorVersion > 10 || (JamfProServer.majorVersion > 9 && JamfProServer.minorVersion > 34) ) {
                    getToken(serverUrl: jpURL, whichServer: "source", base64creds: basicCreds) {
                        (returnedToken: String) in
                        JamfProServer.authType  = "Bearer"
                        completion(("\(JamfProServer.majorVersion).\(JamfProServer.minorVersion).\(JamfProServer.patchVersion)",returnedToken))
                    }
                } else {
                    JamfProServer.authType  = "Basic"
                    JamfProServer.authCreds = basicCreds
                    completion(("\(JamfProServer.majorVersion).\(JamfProServer.minorVersion).\(JamfProServer.patchVersion)","success"))
                }
            })  // let task = session - end
            task.resume()
            semaphore.wait()
        }
    }
    
//    func get(serverUrl: String, whichServer: String, base64creds: String) {
    func getToken(serverUrl: String, whichServer: String, base64creds: String, completion: @escaping (_ returnedToken: String) -> Void) {
        
//        print("\(serverUrl.prefix(4))")
        if serverUrl.prefix(4) != "http" {
            completion("skipped")
            return
        }
        URLCache.shared.removeAllCachedResponses()
                
        var tokenUrlString = "\(serverUrl)/api/v1/auth/token"
        tokenUrlString     = tokenUrlString.replacingOccurrences(of: "//api", with: "/api")
    //        print("\(tokenUrlString)")
        
        let tokenUrl       = URL(string: "\(tokenUrlString)")
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: tokenUrl!)
        request.httpMethod = "POST"
        
        WriteToLog.shared.message(theMessage: "[JamfPro.getToken] Attempting to retrieve token from \(String(describing: tokenUrl!)).")
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(base64creds)", "Content-Type" : "application/json", "Accept" : "application/json"]
        let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json! as? [String: Any], let _ = endpointJSON["token"], let _ = endpointJSON["expires"] {
                        token.sourceServer = endpointJSON["token"] as! String
                        token.sourceExpires  = "\(endpointJSON["expires"] ?? "")"
//                      print("\n[JamfPro] token for \(serverUrl): \(token.sourceServer)")
                        
//                      print("[JamfPro] result of token request: \(endpointJSON)")
                        WriteToLog.shared.message(theMessage: "[JamfPro.getToken] new token created.")
                        if JamfProServer.authType == "Bearer" {
                            self.refresh(server: serverUrl, whichServer: whichServer, b64Creds: base64creds)
                        }
                        completion("success")
                        return
                    } else {    // if let endpointJSON error
                        WriteToLog.shared.message(theMessage: "[JamfPro.getToken] JSON error.\n\(String(describing: json))")
                        completion("failed")
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                    WriteToLog.shared.message(theMessage: "[JamfPro.getToken] response error: \(httpResponse.statusCode).")
                    completion("failed")
                    return
                }
            } else {
                WriteToLog.shared.message(theMessage: "[JamfPro.getToken] token response error.  Verify url and port.")
                completion("failed")
                return
            }
        })
        task.resume()
    }
    
    func refresh(server: String, whichServer: String, b64Creds: String) {
        renewQ.async { [self] in
        sleep(1200) // 20 minutes
            sleep(token.refreshInterval)
            getToken(serverUrl: server, whichServer: whichServer, base64creds: b64Creds) {
                (result: String) in
//                print("[JamfPro.refresh] returned: \(result)")
            }
        }
    }
    */
}
