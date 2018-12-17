//
//  DefaultDatafileHandler.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/14/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class DefaultDatafileHandler : DatafileHandler {
    static public var endPointStringFormat = "https://cdn.optimizely.com/datafiles/%@.json"
    let logger = DefaultLogger.createInstance(logLevel: .OptimizelyLogLevelDebug)
    
    static func createInstance() -> DatafileHandler? {
        return DefaultDatafileHandler()
    }
    
    internal init() {
        
    }
    
    func downloadDatafile(sdkKey: String) -> String? {
        
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        let str = String(format: DefaultDatafileHandler.endPointStringFormat, sdkKey)
        var result:String?
        let semp = DispatchSemaphore(value: 0)
        
        if let url = URL(string: str) {
            let task = session.downloadTask(with: url, completionHandler: { (url, response, error) in
                self.logger?.log(level: OptimizelyLogLevel.OptimizelyLogLevelDebug, message: response.debugDescription)
                if let url = url, let projectConfig = try? String(contentsOf: url) {
                    result = projectConfig
                }
            })
            
            task.resume()
            
            semp.wait()
            
        }
        return result
    }
    
    func downloadDatafile(sdkKey: String, completionHandler: @escaping (Result<String, DatafileDownloadError>) -> Void) {
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        let str = String(format: DefaultDatafileHandler.endPointStringFormat, sdkKey)
        if let url = URL(string: str) {
            let task = session.downloadTask(with: url, completionHandler: { (url, response, error) in
                if let _ = error {
                    self.logger?.log(level: OptimizelyLogLevel.OptimizelyLogLevelError, message: error.debugDescription)
                    let datafiledownloadError = DatafileDownloadError(description: error.debugDescription)
                    completionHandler(Result.failure(datafiledownloadError))
                    return
                }
                if let url = url, let string = try? String(contentsOf: url) {
                        print(string)
                        completionHandler(Result.success(string))
                }
                self.logger?.log(level: OptimizelyLogLevel.OptimizelyLogLevelDebug, message: response.debugDescription)
            })
            
            task.resume()
        }

    }
    
    func startBackgroundUpdates(sdkKey: String, updateInterval: Int) {
        
    }
    
    func stopBackgroundUpdates(sdkKey: String) {
        
    }
    
    func saveDatafile(sdkKey: String, dataFile: String) {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(sdkKey)
            
            //writing
            do {
                try dataFile.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {/* error handling here */}
        }
    }
    
    func loadSavedDatafile(sdkKey: String) -> String? {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(sdkKey)
            
            //reading
            do {
                let text = try String(contentsOf: fileURL, encoding: .utf8)
                return text
            }
            catch {/* error handling here */}
        }
        
        return nil
    }
    
    func isDatafileSaved(sdkKey: String) -> Bool {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(sdkKey)
            return FileManager.default.fileExists(atPath:fileURL.absoluteString)
        }
        
        return false
    }
    
    func removeSavedDatafile(sdkKey: String) {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(sdkKey)
            if FileManager.default.fileExists(atPath:fileURL.absoluteString) {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }

    }
    
    
}
