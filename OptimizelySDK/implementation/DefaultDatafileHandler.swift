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
    let logger = DefaultLogger.createInstance(logLevel: .debug)
    var timers:[String:Timer] = [String:Timer]()
    
    static func createInstance() -> DatafileHandler? {
        return DefaultDatafileHandler()
    }
    
    internal init() {
        
    }
    
    func downloadDatafile(sdkKey: String) -> Data? {
        
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        let str = String(format: DefaultDatafileHandler.endPointStringFormat, sdkKey)
        var result:Data?
        let group = DispatchGroup()
        
        group.enter()
        
        if let url = URL(string: str) {
            let task = session.downloadTask(with: url){ (url, response, error) in
                self.logger?.log(level: .debug, message: response.debugDescription)
                if let url = url, let projectConfig = try? Data(contentsOf: url) {
                    result = projectConfig
                    self.saveDatafile(sdkKey: sdkKey, dataFile: projectConfig)
                }
                group.leave()
            }
            
            task.resume()
            
            group.wait()
            
        }
        return result
    }
    
    func downloadDatafile(sdkKey: String, completionHandler: @escaping (Result<Data, DatafileDownloadError>) -> Void) {
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        let str = String(format: DefaultDatafileHandler.endPointStringFormat, sdkKey)
        if let url = URL(string: str) {
            let task = session.downloadTask(with: url) { (url, response, error) in
                var result = Result<Data, DatafileDownloadError>.failure(DatafileDownloadError(description: "Failed to parse"))
                
                if let _ = error {
                    self.logger?.log(level: .error, message: error.debugDescription)
                    let datafiledownloadError = DatafileDownloadError(description: error.debugDescription)
                    result = Result.failure(datafiledownloadError)
                }
                else if let url = url, let data = try? Data(contentsOf: url) {
                    if let str = String(data: data, encoding: .utf8) {
                        self.logger?.log(level: .debug, message: str)
                    }
                    self.saveDatafile(sdkKey: sdkKey, dataFile: data)
                    result = Result.success(data)
                }

                completionHandler(result)
                
                self.logger?.log(level: .debug, message: response.debugDescription)
                
            }
            
            task.resume()
        }

    }
    
    func startPeriodicUpdates(sdkKey: String, updateInterval: Int) {
        if let _ = timers[sdkKey] {
            logger?.log(level: .info, message: "Timer already started for datafile updates")
            return
        }
        if #available(iOS 10.0, *) {
            let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(updateInterval), repeats: true) { (timer) in
                self.downloadDatafile(sdkKey: sdkKey) { (result) in
                 // background download saves to cache
                }
            }
            timers[sdkKey] = timer
        } else {
            // Fallback on earlier versions
        }
    }
    
    func stopPeriodicUpdates(sdkKey: String) {
        if let timer = timers[sdkKey] {
            logger?.log(level: .info, message: "Stopping timer for datafile updates sdkKey:" + sdkKey)
            
            timer.invalidate()
            timers.removeValue(forKey: sdkKey)
        }

    }
    
    func stopPeriodicUpdates() {
        for key in timers.keys {
            logger?.log(level: .info, message: "Stopping timer for all datafile updates")
            stopPeriodicUpdates(sdkKey: key)
        }
        
    }

    
    func saveDatafile(sdkKey: String, dataFile: Data) {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(sdkKey)
            
            //writing
            do {
                try? dataFile.write(to: fileURL, options: .atomic)
            }
            catch {/* error handling here */}
        }
    }
    
    func loadSavedDatafile(sdkKey: String) -> Data? {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(sdkKey)
            
            //reading
            do {
                let data = try Data(contentsOf: fileURL)
                return data
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
