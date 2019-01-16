/****************************************************************************
 * Copyright 2019, Optimizely, Inc. and contributors                        *
 *                                                                          *
 * Licensed under the Apache License, Version 2.0 (the "License");          *
 * you may not use this file except in compliance with the License.         *
 * You may obtain a copy of the License at                                  *
 *                                                                          *
 *    http://www.apache.org/licenses/LICENSE-2.0                            *
 *                                                                          *
 * Unless required by applicable law or agreed to in writing, software      *
 * distributed under the License is distributed on an "AS IS" BASIS,        *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
 * See the License for the specific language governing permissions and      *
 * limitations under the License.                                           *
 ***************************************************************************/

import Foundation

class DefaultDatafileHandler : OPTDatafileHandler {
    static public var endPointStringFormat = "https://cdn.optimizely.com/datafiles/%@.json"
    let logger = DefaultLogger.createInstance(logLevel: .debug)
    var timers:[String:Timer] = [String:Timer]()
    let dataStore = DataStoreUserDefaults()
    
    static func createInstance() -> OPTDatafileHandler? {
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
            var request = URLRequest(url: url)
            
            if let lastModified = dataStore.getItem(forKey: "OPTLastModified-" + sdkKey) {
                request.addValue(lastModified as! String, forHTTPHeaderField: "If-Modified-Since")
            }
            
            let task = session.downloadTask(with: request) { (url, response, error) in
                var result = Result<Data, DatafileDownloadError>.failure(DatafileDownloadError(description: "Failed to parse"))
                
                if let _ = error {
                    self.logger?.log(level: .error, message: error.debugDescription)
                    let datafiledownloadError = DatafileDownloadError(description: error.debugDescription)
                    result = Result.failure(datafiledownloadError)
                }
                else if let response = response as? HTTPURLResponse {
                    if response.statusCode == 200 {
                        if let url = url, let data = try? Data(contentsOf: url) {
                            if let str = String(data: data, encoding: .utf8) {
                                self.logger?.log(level: .debug, message: str)
                            }
                            self.saveDatafile(sdkKey: sdkKey, dataFile: data)
                            if let lastModified = response.allHeaderFields["Last-Modified"] {
                                self.dataStore.saveItem(forKey: "OPTLastModified-" + sdkKey, value: lastModified)
                            }
                            
                            result = Result.success(data)
                        }
                    }
                    else if response.statusCode == 304 {
                        self.logger?.log(level: .debug, message: "The datafile was not modified and won't be downloaded again")
                        if let data = self.loadSavedDatafile(sdkKey: sdkKey) {
                            result = Result.success(data)
                        }
                    }
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
        if #available(iOS 10.0, tvOS 10.0, *) {
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
                try dataFile.write(to: fileURL, options: .atomic)
            }
            catch {/* error handling here */
                logger?.log(level: .error, message: "Problem saving datafile for key " + sdkKey)
            }
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
            catch {/* error handling here */
                logger?.log(level: .error, message: "Problem loading datafile for key " + sdkKey)
            }
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
