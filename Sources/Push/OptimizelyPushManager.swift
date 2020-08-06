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
    
    static var unprocessedMessage: [AnyHashable: Any]?
    static var logger = OPTLoggerFactory.getLogger()

    public static func process(userInfo: [AnyHashable: Any],
                               completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        logger.d("[PushExp] didReceiveRemoteNotification: \(userInfo)")
        
        guard let optimizelyInfo = userInfo["optimizely"] as? [String: Any] else {
            logger.e("[PushExp] Received Push Notification without OptimizelyInfo")
            completionHandler(.failed)
            return
        }
        
        unprocessedMessage = nil
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
    
    // This new API can be added to FullStack SDK API for general-message processing
    
    static func processOptimizelyMessage(message: OptimizelyMessage,
                                         completionHandler: @escaping (Bool) -> Void) {
        switch message.type {
        case .update:
            if case .update(let value) = message.info {
                let sdkKey = value.sdkKey
                
                if let datafileHandler = HandlerRegistryService.shared.injectDatafileHandler(sdkKey: sdkKey) as? DefaultDatafileHandler {
                
                    datafileHandler.downloadDatafileSilent(sdkKey: sdkKey,
                                                                resourceTimeoutInterval: 30.0,
                                                                completionHandler: completionHandler)
                }
            } else {
                logger.e("[PushExp] OptimizelyMessage fomrat is not valid")
                completionHandler(true)
            }
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
                self.logger.d("[PushExp] Project config updated with a new datafile")
            } catch {
                self.logger.e("[PushExp] Project config update failed with a new datafile")
            }
        }
        
        // keep to remove all observers when deinit
        notificationObservers.append(observer)
    }
        
}

// MARK: - DefaultDatafileHandler

extension DefaultDatafileHandler {
    
    func downloadDatafileSilent(sdkKey: String,
                                resourceTimeoutInterval: Double?,
                                completionHandler: @escaping (Bool) -> Void) {
        
        downloadQueue.async {
            let session = self.getSession(resourceTimeoutInterval: resourceTimeoutInterval)
            
            guard let request = self.getRequest(sdkKey: sdkKey) else {
                self.logger.e("[PushExp] OptimizelyMessage update is failed with getRequest error")
                completionHandler(false)
                return
            }
            
            let task = session.downloadTask(with: request) { (url, response, error) in
                
                if error != nil {
                    self.logger.e(error.debugDescription)
                } else if let response = response as? HTTPURLResponse {
                    switch response.statusCode {
                    case 200:
                        if self.getResponseData(sdkKey: sdkKey, response: response, url: url) != nil {
                            self.logger.d("[PushExp] datafile revision downloaded silently for sdkKey: \(sdkKey)")
                            
                            NotificationCenter.default.post(name: .didDownloadNewDatafile, object: sdkKey)
                            
                            // extra delay for project config before notify completion to iOS
                            DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
                                completionHandler(true)
                            }
                            
                            return
                        }
                    case 304:
                        self.logger.d("[PushExp] The datafile was not modified and won't be downloaded again")
                    default:
                        self.logger.i("[PushExp] got response code \(response.statusCode)")
                    }
                }
                
                completionHandler(true)   // always return true to get fair share from iOS
            }
            
            task.resume()
        }
    }
    
}
