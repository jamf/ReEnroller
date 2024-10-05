//
//  command.swift
//  ReEnroller
//
//  Created by Leslie Helou on 9/27/18.
//  Copyright © 2018 Leslie Helou. All rights reserved.
//

import Foundation

class Command: NSObject {
    
    static let shared = Command()
    private override init() { }
    
    // function to return exit code of bash command - start
    func myExitCode(cmd: String, args: String...) -> Int8 {
        var theCmd = cmd
        for theArg in args {
            theCmd.append(" \(theArg)")
        }
        WriteToLog.shared.message(theMessage: "running command: \(theCmd)")
        
        var pipe_pkg = Pipe()
        let task_pkg = Process()

        task_pkg.launchPath = cmd
        task_pkg.arguments = args
        task_pkg.standardOutput = pipe_pkg
        task_pkg.standardError = pipe_pkg

        task_pkg.launch()
        
        let outdata = pipe_pkg.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: outdata, encoding: .utf8) {
            var currentEnrollment = betweenTags(xmlString: string, startTag: "ConfigurationURL = \"", endTag: "\";")
            if currentEnrollment == "" { currentEnrollment = string }
            WriteToLog.shared.message(theMessage: "command result: \(currentEnrollment)")
        }
        
        task_pkg.waitUntilExit()
        let result = task_pkg.terminationStatus

        return(Int8(result))
    }
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
    
}

func betweenTags(xmlString:String, startTag:String, endTag:String) -> String {
    var rawValue = ""
    if let start = xmlString.range(of: startTag),
        let end  = xmlString.range(of: endTag, range: start.upperBound..<xmlString.endIndex) {
        rawValue.append(String(xmlString[start.upperBound..<end.lowerBound]))
    } else {
//            WriteToLog.shared.message(stringOfText: "[ListPackages.betweenTags] Nothing found between \(startTag) and \(endTag).")
    }
    return rawValue
}
