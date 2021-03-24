//
//  ApiCall.swift
//  ReEnroller
//
//  Created by Leslie N. Helou on 3/18/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Cocoa
import Foundation

class ApiCall: NSViewController, URLSessionDelegate {
    
//    var apiQ = DispatchQueue(label: "com.jamf.apiq", qos: DispatchQoS.background)
    let apiQ = OperationQueue()
    

    func post(theServer: String, token: String, xml: String, theApiObject: String, completion: @escaping (_ result: [Any]) -> Void) {
        URLCache.shared.removeAllCachedResponses()
        var returnValues = [Any]()
        var endpoint     = ""
        var responseCode = 0
        var responseData = ""
        var apiResults   = [String:String]()
        let action       = "POST"
        
        apiQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)
        
        apiQ.addOperation {
            print("[func apiAction] theApiObject: \(theApiObject)")
    //        print("[func apiAction] xml: \(xml)")

            switch theApiObject {
            case "invitation":
                endpoint = "\(theServer)/JSSResource/computerinvitations/id/0"
            case "migrationCheckPolicy", "UnenrollPolicy":
                if action == "POST" {
                    endpoint = "\(theServer)/JSSResource/policies/id/0"
                } else {
                    endpoint = "\(theServer)/JSSResource/policies/name/Migration%20Complete%20v4"
                }
            case "UnenrollCatagory":
                if action == "POST" {
                    endpoint = "\(theServer)/JSSResource/categories/id/0"
                } //else {
                    //print("no need to retry category")
                //}
            case "UnenrollScript":
                if action == "POST" {
                    endpoint = "\(theServer)/JSSResource/scripts/id/0"
                } else {
                    endpoint = "\(theServer)/JSSResource/scripts/name/Migration%20Unenroll"
                }
            default:
                endpoint = ""
            }

            endpoint = endpoint.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")

            let serverUrl = URL(string: "\(endpoint)")
            let serverRequest = NSMutableURLRequest(url: serverUrl! as URL)

            serverRequest.httpMethod = "\(action)"
            serverRequest.httpBody = Data(xml.utf8)
            let serverConf = URLSessionConfiguration.ephemeral
            serverConf.httpAdditionalHeaders = ["Authorization" : "Basic \(token)", "Content-Type" : "application/xml", "Accept" : "application/xml"]

            let session = Foundation.URLSession(configuration: serverConf, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: serverRequest as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                semaphore.signal()
                if let httpResponse = response as? HTTPURLResponse {
                    if let _ = String(data: data!, encoding: .utf8) {
                        responseData = String(data: data!, encoding: .utf8)!
                        responseData = responseData.replacingOccurrences(of: "\n", with: " ")
                        responseCode = httpResponse.statusCode
                        print("[apiAction][\(theApiObject)][\(action)] response code: \(httpResponse.statusCode)")
                        print("[apiAction][\(theApiObject)][\(action)]      response: \(responseData)")
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
                print("objects for the api: \(Xml.objectArray)")
                // move completions here
                if theApiObject == Xml.objectArray.last && (action == "PUT" || (responseCode > 199 && responseCode < 300)) {
                    completion(returnValues)
                    return
                } else {
                    // handle failed create
                    if (responseCode < 200 || responseCode > 299) {
                        if responseCode == 409 && theApiObject != "UnenrollCatagory" && action == "POST" {
//                            print("post failed:\n\(xml)\n")
                            ApiCall().put(theServer: theServer, token: token, xml: xml, theApiObject: theApiObject) {
                                (putResult: [Any]) in
                                semaphore.signal()
                                let putResponseCode = putResult[0] as! Int
                                let putResponseMesage = putResult[1] as! String
                                if (putResponseCode < 200 || putResponseCode > 299) {
                                    apiResults[theApiObject] = "put failed"
                                    print("[\(theApiObject)][PUT] updated policy failed (\(theApiObject)).  Response code \(putResponseCode).")
                                    print("[\(theApiObject)][PUT] Response message:  \(putResponseMesage).")
    //                                Alert().display(header: "Attention", message: "Failed to update the existing policy (\(theApiObject)).\nSee Help to update it manually.\nResponse code: \(responseCode)\n\(putResponseMesage)")
                                } else {
                                    print("updated policy (\(theApiObject)).")
                                }
                                if theApiObject == Xml.objectArray.last {
                                    completion(putResult)
                                    return
                                }
                                let nextObject = Xml.objectArray.firstIndex(of: theApiObject)!+1
                                print("calling next api object[1]: \(String(describing: Xml.objectArray[nextObject])).")
                                ApiCall().post(theServer: theServer, token: token, xml: Xml.objectDict["\(String(describing: Xml.objectArray[nextObject]))"]!, theApiObject: "\(String(describing: Xml.objectArray[nextObject]))") {
                                    (result: [Any]) in
                                    completion(result)
                                }
                            }
                        } else {
                            if responseCode == 409 && theApiObject == "UnenrollCatagory" {
//                                print("category failed with response code \(responseCode)\nxml: \(xml)\n")
                                if theApiObject == Xml.objectArray.last {
                                    completion(returnValues)
                                    return
                                }
                                let nextObject = Xml.objectArray.firstIndex(of: theApiObject)!+1
                                print("calling next api object[2]: \(String(describing: Xml.objectArray[nextObject])).")
                                ApiCall().post(theServer: theServer, token: token, xml: Xml.objectDict["\(String(describing: Xml.objectArray[nextObject]))"]!, theApiObject: "\(String(describing: Xml.objectArray[nextObject]))") {
                                    (result: [Any]) in
                                    completion(result)
                                }
                            } else {
                                print("post failed with response code \(responseCode)\nxml: \(xml)\n")
                            }
    //                        Alert().display(header: "Attention", message: "Failed to create policy (\(theApiObject)).\nSee Help to create it manually.\nResponse code: \(responseCode)")
                        }
                    } else {
                        if action == "POST" {
                            print("Created new policy (\(theApiObject)).")
                        } else {
                            print("Updated policy (\(theApiObject)).")
                        }
    //                    print("\(responseMesage)")
                        let nextObject = Xml.objectArray.firstIndex(of: theApiObject)!+1
                        print("calling next api object[3] (\(String(describing: Xml.objectArray[nextObject]))).")
                        ApiCall().post(theServer: theServer, token: token, xml: Xml.objectDict["\(String(describing: Xml.objectArray[nextObject]))"]!, theApiObject: "\(String(describing: Xml.objectArray[nextObject]))") {
                            (result: [Any]) in
                            completion(result)
                        }
                    }
                }
                semaphore.signal()
            })
            task.resume()
            semaphore.wait()
        }
    }   // func apiAction - end

    
    func put(theServer: String, token: String, xml: String, theApiObject: String, completion: @escaping (_ result: [Any]) -> Void) {
        URLCache.shared.removeAllCachedResponses()
        var returnValues = [Any]()
        var endpoint     = ""
        var responseCode = 0
        var responseData = ""
        var apiResults   = [String:String]()
        let action       = "PUT"
        var putXml       = xml
        
        apiQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)
        
        apiQ.addOperation {
            print("[func apiAction] theApiObject: \(theApiObject)")

            switch theApiObject {
            case "invitation":
                endpoint = "\(theServer)/JSSResource/computerinvitations/id/0"
            case "migrationCheckPolicy", "UnenrollPolicy":
                endpoint = "\(theServer)/JSSResource/policies/name/Migration%20Complete%20v4"

            case "UnenrollScript":
                endpoint = "\(theServer)/JSSResource/scripts/name/Migration%20Unenroll"
            default:
                endpoint = ""
            }
            
            putXml   = xml.replacingOccurrences(of: "<name>Migration Unenroll</name>\n", with: "")
            endpoint = endpoint.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")

            let serverUrl     = URL(string: "\(endpoint)")
            let serverRequest = NSMutableURLRequest(url: serverUrl! as URL)
            
            serverRequest.httpMethod         = "\(action)"
            serverRequest.httpBody           = Data(putXml.utf8)
            let serverConf                   = URLSessionConfiguration.ephemeral
            serverConf.httpAdditionalHeaders = ["Authorization" : "Basic \(token)", "Content-Type" : "application/xml", "Accept" : "application/xml"]

            let session = Foundation.URLSession(configuration: serverConf, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: serverRequest as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    if let _ = String(data: data!, encoding: .utf8) {
                        responseData = String(data: data!, encoding: .utf8)!
                        responseData = responseData.replacingOccurrences(of: "\n", with: " ")
                        responseCode = httpResponse.statusCode
                        print("[ApiCall][\(theApiObject)][\(action)] response code: \(responseCode)")
                        print("[ApiCall][\(theApiObject)][\(action)]      response: \(responseData)")
//                        if httpResponse.statusCode == 409 {
//                            print("xml: \(xml)")
//                        }
    //                    completion([httpResponse.statusCode,"\(responseData)"])
                        returnValues = [httpResponse.statusCode,"\(responseData)"]
                    } else {
                        print("[apiAction] No data was returned from \(action).")
                        returnValues = [httpResponse.statusCode,""]
                    }

                } else {
    //                completion([404,""])
                    returnValues = [404,""]
                }
                semaphore.signal()
                completion(returnValues)
            })
            task.resume()
            semaphore.wait()
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }

}
