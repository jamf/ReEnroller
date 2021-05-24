//
//  CasperJxmlDelegate.swift
//  ReEnroller
//
//  Created by Leslie Helou on 2/15/21
//

import Cocoa

class CasperJxmlDelegate: NSObject, URLSessionDelegate {
    
    
    let userDefaults = UserDefaults.standard

    var httpStatusCode = 0

    let theFetchQ  = OperationQueue() // queue to fetch ids and names of the packages
    
    func casperJxmlGet(server: String, username: String, password: String, completion: @escaping (_ result: String) -> Void) {
        
        WriteToLog().message(theMessage: "[CasperJxmlDelegate.casperJxmlGet] server: \(server)\n")
        WriteToLog().message(theMessage: "[CasperJxmlDelegate.casperJxmlGet] user: \(username)\n")
//        WriteToLog().message(theMessage: "[CasperJxmlDelegate.casperJxmlGet] password: \(password)\n")
       
//        theFetchQ.addOperation {
        let semaphore = DispatchSemaphore(value: 0)

        var casperJxmlNode = "\(server)/casper.jxml"
        casperJxmlNode = casperJxmlNode.replacingOccurrences(of: "//casper.jxml", with: "/casper.jxml")

        theFetchQ.addOperation {
            let encodedURL = NSURL(string: casperJxmlNode)
            let request = NSMutableURLRequest(url: encodedURL! as URL)

            request.httpBody = "source=jamfCPR&username=\(username)&password=\(password)".data(using: String.Encoding.utf8)
            request.httpMethod = "POST"
            let configuration = URLSessionConfiguration.default
//            configuration.httpAdditionalHeaders = ["Content-Type" : "application/x-www-form-urlencoded"]
            configuration.httpAdditionalHeaders = ["Content-Type" : "application/xml"]
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
//                  print("httpResponse: \(String(describing: response))")

                    WriteToLog().message(theMessage: "[CasperJxmlDelegate.casperJxmlGet] response code for connection to \(server): \(httpResponse.statusCode)\n")
                    if httpResponse.statusCode > 199 && httpResponse.statusCode <= 299 {

                        let rawXml = String(data: data!, encoding: .utf8)
                        print("[CasperJxmlDelegate.casperJxmlGet] raw fileServerXml: \(String(describing: rawXml!))")
                        var sslVerification = ""
                        sslVerification = self.betweenTags(xmlString: rawXml!, startTag: "<verifySSLCert>", endTag: "</verifySSLCert>")

                        WriteToLog().message(theMessage: "[CasperJxmlDelegate.casperJxmlGet] completion\n")
                        completion(sslVerification)
                    } else {
                        // something went wrong
                        //self.writeToHistory(stringOfText: "**** \(self.getName(endpoint: endpointType, objectXML: endPointXML)) - Failed\n")
                        print("\n\n---------- status code ----------")
                        print(httpResponse.statusCode)
                        self.httpStatusCode = httpResponse.statusCode
                        print("---------- status code ----------")
                        print("\n\n---------- response ----------")
                        print(httpResponse)
                        print("---------- response ----------\n\n")
                        switch self.httpStatusCode {
                        case 401:
                            print("[casperJxmlGet] Authentication Failure.  Please verify username and password for the source server.")
                            WriteToLog().message(theMessage: "[CasperJxmlDelegate.casperJxmlGet] Authentication Failure.  Please verify username and password for the source server: \(server)\n")

                        default:
                            print("Unknown error.")
                            WriteToLog().message(theMessage: "[CasperJxmlDelegate.casperJxmlGet] Authentication Failure.  Please verify username and password for the source server: \(server)\n")
                            //self.alert_dialog(header: "Error", message: "An unknown error occured trying to query the source server.")
                        }
                        //                        401 - wrong username and/or password
                        //                        409 - unable to create object; already exists or data missing or xml error
                        //                        self.spinner.stopAnimation(self)
                        completion("")
                    }   // if httpResponse/else - end
                } else {  // if let httpResponse - end
                    completion("")
                }
                semaphore.signal()
//                    if error != nil {
//                        completion("")
//                    }
            })  // let task = session - end
            //print("GET")
            task.resume()
            semaphore.wait()
        }   // theFetchQ - end
    }
    
    // extract the value between (different) tags - start
    func betweenTags(xmlString:String, startTag:String, endTag:String) -> String {
        var rawValue = ""
        if let start = xmlString.range(of: startTag),
            let end  = xmlString.range(of: endTag, range: start.upperBound..<xmlString.endIndex) {
            rawValue.append(String(xmlString[start.upperBound..<end.lowerBound]))
        } else {
            print("[betweenTags] Start, \(startTag), and end, \(endTag), not found.\n")
        }
        return rawValue
    }
    //  extract the value between (different) tags - end
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
}
