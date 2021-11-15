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
    
    // thread-safe lazy logger load (after HandlerRegisterService ready)
    private var loggerInstance: OPTLogger?
    var logger: OPTLogger {
        return OPTLoggerFactory.getLoggerThreadSafe(&loggerInstance)
    }
        
    // the timers for all sdk keys are atomic to allow for thread access.
    var timers = AtomicProperty(property: [String: (timer: Timer?, interval: Int)]())
    
    // a shared user defaults datastore for lastModified storage
    let sharedDataStore = DataStoreUserDefaults()
    // datastore for Datafile downloads
    var datafileCache = AtomicDictionary<String, OPTDataStore>()
    
    // and our download queue to speed things up.
    let downloadQueue = DispatchQueue(label: "DefaultDatafileHandlerQueue")
    
    // network reachability
    let reachability = NetworkReachability(maxContiguousFails: 1)

    public required init() {}
    
    // MARK: - download datafile
    
    open func downloadDatafile(sdkKey: String,
                               returnCacheIfNoChange: Bool,
                               resourceTimeoutInterval: Double?,
                               completionHandler: @escaping DatafileDownloadCompletionHandler) {
        
        downloadQueue.async {
            
            func returnCached(_ result: OptimizelyResult<Data?>? = nil) -> OptimizelyResult<Data?> {
                if let data = self.loadSavedDatafile(sdkKey: sdkKey) {
                    return .success(data)
                } else {
                    return result ?? .failure(.datafileLoadingFailed(sdkKey))
                }
            }
        
            if self.reachability.shouldBlockNetworkAccess() {
                let optError = OptimizelyError.datafileDownloadFailed("NetworkReachability down")
                self.logger.e(optError)

                let result = OptimizelyResult<Data?>.failure(optError)
                completionHandler(returnCached(result))
                return
            }
            
            let session = self.getSession(resourceTimeoutInterval: resourceTimeoutInterval)
            
            guard let request = self.getRequest(sdkKey: sdkKey) else { return }
            
            let task = session.downloadTask(with: request) { (url, response, error) in
                var result = OptimizelyResult<Data?>.failure(.generic)
                
                if error != nil {
                    let optError = OptimizelyError.datafileDownloadFailed(error.debugDescription)
                    self.logger.e(optError)
                    result = returnCached(.failure(optError))  // error recovery
                } else if let response = response as? HTTPURLResponse {
                    switch response.statusCode {
                    case 200:
                        if let data = self.getResponseData(sdkKey: sdkKey, response: response, url: url) {
                            result = .success(data)
                        } else {
                            result = returnCached() // error recovery
                        }
                    case 304:
                        self.logger.d("The datafile was not modified and won't be downloaded again")
                        
                        if returnCacheIfNoChange {
                            result = returnCached()
                        } else {
                            result = .success(nil)
                        }
                    default:
                        self.logger.i("got response code \(response.statusCode)")
                        result = returnCached() // error recovery
                    }
                }
                
                self.reachability.updateNumContiguousFails(isError: (error != nil))
                
                completionHandler(result)
            }
            
            task.resume()
        }
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
        
        if let lastModified = sharedDataStore.getLastModified(sdkKey: sdkKey), isDatafileSaved(sdkKey: sdkKey) {
            request.setLastModified(lastModified: lastModified)
        }
        
        return request
    }
    
    open func getResponseData(sdkKey: String, response: HTTPURLResponse, url: URL?) -> Data? {
        if let url = url, let data = try? Data(contentsOf: url) {
            self.logger.d { String(data: data, encoding: .utf8) ?? "" }
            self.saveDatafile(sdkKey: sdkKey, dataFile: data)
            if let lastModified = response.getLastModified() {
                self.sharedDataStore.setLastModified(sdkKey: sdkKey, lastModified: lastModified)
            }
            
            return data
        }
        
        return nil
    }
    
    // MARK: - periodic updates
    
    public func setPeriodicInterval(sdkKey: String, interval: Int) {
        timers.performAtomic { timers in
            if timers[sdkKey] == nil {
                timers[sdkKey] = (nil, interval)
                return
            }
        }
    }
    
    public func hasPeriodicInterval(sdkKey: String) -> Bool {
        var result = true
        timers.performAtomic { timers in
            result = timers[sdkKey] != nil
        }
        
        return result
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
    
    // MARK: - datafile store
    
    open func createDataStore(sdkKey: String) -> OPTDataStore {
        return DataStoreFile<Data>(storeName: sdkKey)
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

// MARK: - internals

extension DefaultDatafileHandler {
    
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

        let scheduleNextUpdate: () -> Void = {
            guard self.hasPeriodicInterval(sdkKey: sdkKey) else { return }
            
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
            
            scheduleNextUpdate()
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
    
    func getDatafileCache(sdkKey: String) -> OPTDataStore {
        if let cache = datafileCache[sdkKey] {
            return cache
        } else {
            let store = createDataStore(sdkKey: sdkKey)
            datafileCache[sdkKey] = store
            return store
        }
    }
    
}

// MARK: - others

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
