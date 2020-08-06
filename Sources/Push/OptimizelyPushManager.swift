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

import UIKit

public class OptimizelyPushManager {
    
    static var logger = OPTLoggerFactory.getLogger()

    public static func process(userInfo: [AnyHashable: Any],
                               completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        logger.d("[PushExp] didReceiveRemoteNotification: \(userInfo)")
        
        guard let optimizelyInfo = userInfo["optimizely"] as? [String: Any] else {
            logger.e("[PushExp] Received Push Notification without OptimizelyInfo")
            completionHandler(.failed)
            return
        }
        
        do {
            let optimizelyData = try JSONSerialization.data(withJSONObject: optimizelyInfo, options: .prettyPrinted)
            let messageModel = try JSONDecoder().decode(OptimizelyMessage.self, from: optimizelyData)

            processOptimizelyMessage(message: messageModel) { result in
                if result {
                    completionHandler(.newData)
                } else {
                    completionHandler(.failed)
                }
            }
        } catch {
            logger.e("[PushExp] Received push message process failed: \(error)")
            completionHandler(.failed)
        }
    }
    
    static func processOptimizelyMessage(message: OptimizelyMessage,
                                         completionHandler: @escaping (Bool) -> Void) {
        switch message.type {
        case .update:
            if case .update(let value) = message.info {
                let sdkKey = value.sdkKey
                downloadDatafileSilent(sdkKey: sdkKey, completionHandler: completionHandler)
            } else {
                logger.e("[PushExp] OptimizelyMessage fomrat is not valid")
                completionHandler(true)
            }
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
                    self.logger.d("[PushExp] datafile revision downloaded silently for sdkKey: \(sdkKey)")
                    
                    NotificationCenter.default.post(name: .didDownloadNewDatafile, object: sdkKey)
                    
                    // extra delay for project config before notify completion to iOS
                    DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
                        completionHandler(true)
                    }
                    
                    return
                }
            case .failure(let error):
                self.logger.e("[PushExp] The datafile download failed: \(error)")
            }
            
            completionHandler(true)
        }
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
                self.logger.e("[PushExp] Project config update failed with a new datafile")
            }
        }
        
        // keep to remove all observers when deinit
        notificationObservers.append(observer)
    }
        
}
