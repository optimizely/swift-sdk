//
// Copyright 2019-2021, Optimizely, Inc. and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

open class DefaultDatafileHandler: OPTDatafileHandler {
    // endpoint used to get the datafile.  This is settable after you create a OptimizelyClient instance.
    public var endPointStringFormat = "https://cdn.optimizely.com/datafiles/%@.json"
    
    // lazy load the logger from the logger factory.
    lazy var logger = OPTLoggerFactory.getLogger()
    // the timers for all sdk keys are atomic to allow for thread access.
    var timers: AtomicProperty<[String:(timer: Timer?, interval: Int)]> = AtomicProperty(property: [String: (Timer?, Int)]())
    // we will use a simple user defaults datastore
    let dataStore = DataStoreUserDefaults()
    // datastore for Datafile downloads
    var datafileCache = [String: OPTDataStore]()
    // and our download queue to speed things up.
    let downloadQueue = DispatchQueue(label: "DefaultDatafileHandlerQueue")

    public required init() {

    }
    
    public func setPeriodicInterval(sdkKey: String, interval: Int) {
        timers.performAtomic { (timers) in
            if timers[sdkKey] == nil {
                timers[sdkKey] = (nil, interval)
                return
            }
        }
    }
    
    public func hasPeriodicInterval(sdkKey: String) -> Bool {
        var result = true
        self.timers.performAtomic(atomicOperation: { (timers) in
            if !timers.contains(where: { $0.key == sdkKey}) {
                result = false
            }
        })
        
        return result
    }
        
    public func downloadDatafile(sdkKey: String) -> Data? {
        
        var datafile: Data?
        let group = DispatchGroup()
        
        group.enter()
        
        downloadDatafile(sdkKey: sdkKey) { (result) in
            switch result {
            case .success(let data):
                datafile = data
            case .failure(let error):
                self.logger.e(error.reason)
            }
            group.leave()
        }
        
        group.wait()
        
        return datafile
    }
    
    open func getSession(resourceTimeoutInterval: Double?) -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        if let resourceTimeoutInterval = resourceTimeoutInterval,
            resourceTimeoutInterval > 0 {
            config.timeoutIntervalForResource = TimeInterval(resourceTimeoutInterval)
        }
        return URLSession(configuration: config)
    }
    
    open func getRequest(sdkKey: String) -> URLRequest? {
        let str = String(format: endPointStringFormat, sdkKey)
        guard let url = URL(string: str) else { return nil }
        
        var request = URLRequest(url: url)
        
        if let lastModified = dataStore.getLastModified(sdkKey: sdkKey), isDatafileSaved(sdkKey: sdkKey) {
            request.setLastModified(lastModified: lastModified)
        }
        
        return request
    }
    
    open func getResponseData(sdkKey: String, response: HTTPURLResponse, url: URL?) -> Data? {
        if let url = url, let data = try? Data(contentsOf: url) {
            self.logger.d { String(data: data, encoding: .utf8) ?? "" }
            self.saveDatafile(sdkKey: sdkKey, dataFile: data)
            if let lastModified = response.getLastModified() {
                self.dataStore.setLastModified(sdkKey: sdkKey, lastModified: lastModified)            }
            
            return data
        }
        
        return nil
    }
    
    open func downloadDatafile(sdkKey: String,
                               returnCacheIfNoChange: Bool,
                               resourceTimeoutInterval: Double?,
                               completionHandler: @escaping DatafileDownloadCompletionHandler) {
        
        downloadQueue.async {
            let session = self.getSession(resourceTimeoutInterval: resourceTimeoutInterval)
            
            guard let request = self.getRequest(sdkKey: sdkKey) else { return }
            
            let task = session.downloadTask(with: request) { (url, response, error) in
                var result = OptimizelyResult<Data?>.failure(.datafileLoadingFailed(sdkKey))

                let returnCached = {
                    if let data = self.loadSavedDatafile(sdkKey: sdkKey) {
                        result = .success(data)
                    }
                }
                
                if error != nil {
                    self.logger.e(error.debugDescription)
                    result = .failure(.datafileDownloadFailed(error.debugDescription))
                    returnCached() // error recovery
                } else if let response = response as? HTTPURLResponse {
                    switch response.statusCode {
                    case 200:
                        if let data = self.getResponseData(sdkKey: sdkKey, response: response, url: url) {
                            result = .success(data)
                        } else {
                            returnCached() // error recovery
                        }
                    case 304:
                        self.logger.d("The datafile was not modified and won't be downloaded again")
                        
                        if returnCacheIfNoChange {
                            returnCached()
                        } else {
                            result = .success(nil)
                        }
                    default:
                        self.logger.i("got response code \(response.statusCode)")
                        returnCached() // error recovery
                    }
                }
                
                completionHandler(result)
            }
            
            task.resume()

            session.finishTasksAndInvalidate()
        }
    }
    
    open func createDataStore(sdkKey: String) -> OPTDataStore {
        return DataStoreFile<Data>(storeName: sdkKey)
    }

    func startPeriodicUpdates(sdkKey: String, updateInterval: Int, datafileChangeNotification: ((Data) -> Void)?) {
        
        let now = Date()
        DispatchQueue.main.async {
            if let timer = self.timers.property?[sdkKey]?.timer, timer.isValid {
                return
            }
            
            let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(updateInterval), repeats: false) { (timer) in
                
                self.performPerodicDownload(sdkKey: sdkKey,
                                            startTime: now,
                                            updateInterval: updateInterval,
                                            datafileChangeNotification: datafileChangeNotification)
                
                timer.invalidate()
            }
            self.timers.performAtomic(atomicOperation: { (timers) in
                if let interval = timers[sdkKey]?.interval {
                    timers[sdkKey] = (timer, interval)
                } else {
                    timers[sdkKey] = (timer, updateInterval)
                }
            })
        }
    }
    
    func performPerodicDownload(sdkKey: String,
                                startTime: Date,
                                updateInterval: Int,
                                datafileChangeNotification: ((Data) -> Void)?) {
        let beginDownloading = Date()
        self.downloadDatafile(sdkKey: sdkKey) { (result) in
            switch result {
            case .success(let data):
                if let data = data,
                    let datafileChangeNotification = datafileChangeNotification {
                    datafileChangeNotification(data)
                }
            case .failure(let error):
                self.logger.e(error.reason)
            }
            
            if self.hasPeriodicInterval(sdkKey: sdkKey) {
                // adjust the next fire time so that events will be fired at fixed interval regardless of the download latency
                // if latency is too big (or returning from background mode), fire the next event immediately once
                
                var interval = self.timers.property?[sdkKey]?.interval ?? updateInterval
                let delay = Int(Date().timeIntervalSince(beginDownloading))
                interval -= delay
                if interval < 0 {
                    interval = 0
                }
                
                self.logger.d("next datafile download is \(interval) seconds \(Date())")
                self.startPeriodicUpdates(sdkKey: sdkKey, updateInterval: interval, datafileChangeNotification: datafileChangeNotification)
            }
        }
    }
    
    func stopPeriodicUpdates(sdkKey: String) {
        timers.performAtomic { (timers) in
            if let timer = timers[sdkKey] {
                logger.i("Stopping timer for datafile updates sdkKey: \(sdkKey)")
                
                timer.timer?.invalidate()
                timers.removeValue(forKey: sdkKey)
            }
        }
    }
    
    func stopPeriodicUpdates() {
        for key in timers.property?.keys ?? [String: (timer: Timer?, interval: Int)]().keys {
            logger.i("Stopping timer for all datafile updates")
            stopPeriodicUpdates(sdkKey: key)
        }
        
    }
    
    public func startUpdates(sdkKey: String, datafileChangeNotification: ((Data) -> Void)?) {
        if let value = timers.property?[sdkKey], !(value.timer?.isValid ?? false) {
            startPeriodicUpdates(sdkKey: sdkKey, updateInterval: value.interval, datafileChangeNotification: datafileChangeNotification)
        }
    }
    
    public func stopUpdates(sdkKey: String) {
        stopPeriodicUpdates(sdkKey: sdkKey)
    }
    
    public func stopAllUpdates() {
        stopPeriodicUpdates()
    }
    
    func getDatafileCache(sdkKey: String) -> OPTDataStore {
        if let cache = datafileCache[sdkKey] {
            return cache
        } else {
            let store = createDataStore(sdkKey: sdkKey)
            datafileCache[sdkKey] = store
            return store
        }
    }
    
    public func saveDatafile(sdkKey: String, dataFile: Data) {
        getDatafileCache(sdkKey: sdkKey).saveItem(forKey: sdkKey, value: dataFile)
    }
    
    public func loadSavedDatafile(sdkKey: String) -> Data? {
        return getDatafileCache(sdkKey: sdkKey).getItem(forKey: sdkKey) as? Data
    }
    
    public func isDatafileSaved(sdkKey: String) -> Bool {
        return getDatafileCache(sdkKey: sdkKey).getItem(forKey: sdkKey) as? Data != nil
    }
    
    public func removeSavedDatafile(sdkKey: String) {
        getDatafileCache(sdkKey: sdkKey).removeItem(forKey: sdkKey)
    }

}

extension DataStoreUserDefaults {
    func getLastModified(sdkKey: String) -> String? {
        return getItem(forKey: "OPTLastModified-" + sdkKey) as? String
    }
    
    func setLastModified(sdkKey: String, lastModified: String) {
        saveItem(forKey: "OPTLastModified-" + sdkKey, value: lastModified)
    }
}

extension URLRequest {
    mutating func setLastModified(lastModified: String?) {
        if let lastModified = lastModified {
            addValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
        }
    }
    
    func getLastModified() -> String? {
        return value(forHTTPHeaderField: "If-Modified-Since")
    }
}

extension HTTPURLResponse {
    func getLastModified() -> String? {
        return allHeaderFields["Last-Modified"] as? String
    }
}
