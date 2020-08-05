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
        scheduleBackgroundDatafileFetch()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        NSLog("[BGPoll] fetching datafile")
        doFetchDatafilesInBackground { result in
            task.setTaskCompleted(success: result)
        }
    }
    
    static func registerOptimizelyClient(_ client: OptimizelyClient?) {
        guard let client = client else { return }
        guard optimizelyClients.filter({ $0?.sdkKey == client.sdkKey }).first == nil else { return }
        
        weak var weakClient = client
        optimizelyClients.append(weakClient)
    }
    
    static func doFetchDatafilesInBackground(completionHandler: @escaping (Bool) -> Void) {
        guard let first = optimizelyClients.first, let client = first else { return }
        
        DefaultDatafileHandler().downloadDatafileSilent(sdkKey: client.sdkKey,
                                                        resourceTimeoutInterval: 30.0,
                                                        completionHandler: completionHandler)
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
                self.logger.e("[BGPoll] OptimizelyMessage update is failed with getRequest error")
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
                        if let data = self.getResponseData(sdkKey: sdkKey, response: response, url: url) {
                            result = true
                            let datafile = String(bytes: data, encoding: .utf8)
                            self.logger.d("[BGPoll] datafile revision downloaded silently for sdkKey: \(sdkKey): [\(datafile)]")
                        }
                    case 304:
                        self.logger.d("[BGPoll] The datafile was not modified and won't be downloaded again")
                        result = true
                    default:
                        self.logger.i("[BGPoll] got response code \(response.statusCode)")
                    }
                }
                
                completionHandler(result)
            }
            
            task.resume()
        }
    }
    
}
