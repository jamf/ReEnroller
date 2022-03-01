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
    
    var apiQ = DispatchQueue(label: "com.jamf.apiq", qos: DispatchQoS.background)
    
    func jamfSchoolUnenroll(server: String, token: String, completion: @escaping (_ result: [Any]) -> Void) {
        URLCache.shared.removeAllCachedResponses()
        var responseData = ""
        let endpoint = "\(server)/api/devices/\(String(describing: getSystemUUID()))/unenroll".replacingOccurrences(of: "//api", with: "/api")
        let serverUrl = NSURL(string: "\(endpoint)")
        let serverRequest = NSMutableURLRequest(url: serverUrl! as URL)

        serverRequest.httpMethod = "POST"
        let serverConf = URLSessionConfiguration.default
        serverConf.httpAdditionalHeaders = ["Authorization" : "Basic \(token)", "Content-Type" : "Content-Type: application/data-urlencoded; charset=utf-8", "Accept" : "application/json"]
        
        let session = Foundation.URLSession(configuration: serverConf, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: serverRequest as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    if let _ = String(data: data!, encoding: .utf8) {
                        responseData = String(data: data!, encoding: .utf8)!
                        responseData = responseData.replacingOccurrences(of: "\n", with: " ")
                        responseData = responseData.replacingOccurrences(of: "\r", with: " ")
                        print("response code: \(httpResponse.statusCode)")
                        print("response: \(responseData)")
                        completion([httpResponse.statusCode,"\(responseData)"])
                    } else {
//                        print("No data was returned from health check.")
                        completion([httpResponse.statusCode,""])
                    }
                } else {
//                    print("response code: \(httpResponse.statusCode)")
//                    print("response: \(responseData)")
                    completion([httpResponse.statusCode,""])
                }
            } else {
                completion([404, ""])
            }
        })
        task.resume()
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
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
