/****************************************************************************
 * Copyright 2020, Optimizely, Inc. and contributors                        *
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
import BackgroundTasks

@available(iOSApplicationExtension 13.0, *)
public class OptimizelyBackgroundManager {
    
    public static let fetchTaskId = "com.optimizely.bgfetch"
    private static var optimizelyClients = [OptimizelyClient?]()
    static var logger = OPTLoggerFactory.getLogger()
    
    public static func scheduleBackgroundDatafileFetch() {
        let fetchTask = BGAppRefreshTaskRequest(identifier: fetchTaskId)
        fetchTask.earliestBeginDate = Date(timeIntervalSinceNow: 1*60)
        
        do {
            try BGTaskScheduler.shared.submit(fetchTask)
            NSLog("[BGPoll] scheduling background task: \(fetchTaskId)")
        } catch {
            NSLog("[BGPoll] Unable to submit task: \(error.localizedDescription)")
        }
    }
    
    public static func handleBackgroundDatafileFetchTask(task: BGAppRefreshTask) {
        guard let sdkKey = sdkKeyCached else {
            task.setTaskCompleted(success: true)
            return
        }

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        scheduleBackgroundDatafileFetch()
        
        logger.d("[BGPoll] fetching datafile")
        downloadDatafileSilent(sdkKey: sdkKey) { _ in
            task.setTaskCompleted(success: true)
        }
    }
    
    static func registerOptimizelyClient(_ client: OptimizelyClient?) {
        guard let client = client else { return }
        guard optimizelyClients.filter({ $0?.sdkKey == client.sdkKey }).first == nil else { return }
        
        weak var weakClient = client
        optimizelyClients.append(weakClient)
    }
    
}

@available(iOSApplicationExtension 13.0, *)
extension OptimizelyBackgroundManager {
    static let idForSdkKeyCached = "com.optimizely.sdkKeyCached"
    
    static var sdkKeyCached: String? {
        get {
            return UserDefaults.standard.string(forKey: idForSdkKeyCached)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: idForSdkKeyCached)
        }
    }
    
    static func downloadDatafileSilent(sdkKey: String, completionHandler: @escaping (Bool) -> Void) {
        // use existing datafileHandler for save-load datafile synchronization
        guard let datafileHandler = HandlerRegistryService.shared.injectDatafileHandler(sdkKey: sdkKey) else {
            completionHandler(true)  // always return true to get fair share from iOS
            return
        }
        
        datafileHandler.downloadDatafile(sdkKey: sdkKey, returnCacheIfNoChange: false, resourceTimeoutInterval: 30.0) { result in
            switch result {
            case .success(let data):
                if data != nil {
                    self.logger.d("[BGPoll] datafile revision downloaded silently for sdkKey: \(sdkKey)")
                    
                    NotificationCenter.default.post(name: .didDownloadNewDatafile, object: sdkKey)
                    
                    // extra delay for project config before notify completion to iOS
                    DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
                        completionHandler(true)
                    }
                    
                    return
                }
            case .failure(let error):
                self.logger.e("[BGPoll] The datafile download failed: \(error)")
            }
            
            completionHandler(true)
        }
    }
   
    static func registerSdkKeyCache(sdkKey: String) {
        sdkKeyCached = sdkKey
    }
}

// MARK: - OptimizelyClient

extension Notification.Name {
    static let didDownloadNewDatafile = Notification.Name("didDownloadNewDatafile")
}

extension OptimizelyClient {

    func addObserversForDidDownloadNewDatafileBackground() {
        let observer = NotificationCenter.default.addObserver(forName: .didDownloadNewDatafile, object: nil, queue: nil) { [weak self] notif in

            guard let self = self else { return }
            guard let sdkKey = notif.object as? String, !sdkKey.isEmpty, sdkKey == self.sdkKey else { return }
            guard let cachedDatafile = self.datafileHandler?.loadSavedDatafile(sdkKey: sdkKey) else { return }

            do {
                try self.configSDK(datafile: cachedDatafile)
            } catch {
                self.logger.e("[BGPoll] Project config update failed with a new datafile")
            }
        }

        // keep to remove all observers when deinit
        notificationObservers.append(observer)
    }

}
