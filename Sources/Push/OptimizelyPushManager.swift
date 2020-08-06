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
                
                DefaultDatafileHandler().downloadDatafileSilent(sdkKey: sdkKey,
                                                                resourceTimeoutInterval: 30.0,
                                                                completionHandler: completionHandler)
            } else {
                logger.e("[PushExp] OptimizelyMessage fomrat is not valid")
                completionHandler(true)
            }
        }
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
                var result = false
                
                if error != nil {
                    self.logger.e(error.debugDescription)
                } else if let response = response as? HTTPURLResponse {
                    switch response.statusCode {
                    case 200:
                        if self.getResponseData(sdkKey: sdkKey, response: response, url: url) != nil {
                            result = true
                            self.logger.d("[PushExp] datafile revision downloaded silently for sdkKey: \(sdkKey)")
                        }
                    case 304:
                        self.logger.d("[PushExp] The datafile was not modified and won't be downloaded again")
                        result = true
                    default:
                        self.logger.i("[PushExp] got response code \(response.statusCode)")
                    }
                }
                
                completionHandler(result)
            }
            
            task.resume()
        }
    }
    
}
