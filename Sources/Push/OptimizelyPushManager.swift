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

public class OptimizelyPushManager {
    
    static var unprocessedMessage: [AnyHashable: Any]?

    public static func processPushMessage(userInfo: [AnyHashable: Any]?) {
        guard let userInfo = userInfo,
            let optimizelyInfo = userInfo["optimizely"] as? [String: Any] else {
                NSLog("[PushExp] Received Push Notification Without OptimizelyInfo")
                return
        }
        
        if let prettyData = try? JSONSerialization.data(withJSONObject: optimizelyInfo, options: .prettyPrinted) {
            let prettyString = String(bytes: prettyData, encoding: .utf8)!
            NSLog("[PushExp] Received Push Notification With OptimizelyInfo:\n\n\(prettyString)")
        }

        unprocessedMessage = nil
        do {
            try processOptimizelyMessage(optimizelyInfo)
        } catch OptimizelyError.sdkNotReady {
            NSLog("[PushExp] SDK is not ready yet. Processing OptimizelyMessage has been deferred")
            unprocessedMessage = userInfo
       } catch {
            NSLog("[PushExp] Received push message process failed: \(error)")
        }
    }
    
    // This new API can be added to FullStack SDK API for general-message processing
    
    static func processOptimizelyMessage(_ message: [String: Any]?) throws {
        guard let messageRaw = message else { return }
        
        var messageModel: OptimizelyMessage
        do {
            let optimizelyData = try JSONSerialization.data(withJSONObject: messageRaw, options: .prettyPrinted)
            messageModel = try JSONDecoder().decode(OptimizelyMessage.self, from: optimizelyData)
        } catch {
            NSLog("[PushExp] Received push message process failed: \(error)")
            return
        }
        
        switch messageModel.type {
        case .update:
            if case .update(let value) = messageModel.info {
                let sdkKey = value.sdkKey
                
                NSLog("[PushExp] OptimizelyMessage update is processed for sdkKey: \(sdkKey)")

            } else {
                NSLog("[PushExp] OptimizelyMessage fomrat is not valid")
            }
        }
    }
}
