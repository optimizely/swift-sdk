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

public class DefaultEventDispatcher : OPTEventDispatcher {
    let logger = DefaultLogger(level: .debug)
    let dispatcher = DispatchQueue(label: "DefaultEventDispatcherQueue")
    let dataStore = DataStoreQueuStackImpl<EventForDispatch>(queueStackName: "OPTEventQueue", dataStore: DataStoreFile<Array<Data>>(storeName: "OPTEventQueue"))
    let notify = DispatchGroup()
    
    public static func createInstance() -> OPTEventDispatcher? {
        return DefaultEventDispatcher()
    }
    
    public func dispatchEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
        
        dataStore.save(item: event)
        
        dispatcher.async {
            while let eventToSend:EventForDispatch = self.dataStore.getFirstItem() {
                self.notify.enter()
                self.sendEvent(event: eventToSend) { (result) -> (Void) in
                    
                    switch result {
                    case .failure(let error):
                        self.logger.log(level: .error, message: error.localizedDescription)
                    case .success(_):
                        if let removedItem:EventForDispatch = self.dataStore.removeFirstItem() {
                            if removedItem != event {
                                self.logger.log(level: .error, message: "Removed event different from sent event")
                            }
                            else {
                                self.logger.log(level: .debug, message: "Successfully sent event " + event.body.debugDescription)
                            }
                        }
                        else {
                            self.logger.log(level: .error, message: "Removed event nil for sent item")
                        }
                    }
                    self.notify.leave()
                }
                self.notify.wait()
            }
        }
        
    }
    
    func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        var request = URLRequest(url: event.url)
        request.httpMethod = "POST"
        request.httpBody = event.body
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = session.uploadTask(with: request, from: event.body) { (data, response, error) in
            self.logger.log(level: .debug, message: response.debugDescription)
            
            if let error = error {
                completionHandler(Result.failure(OPTEventDispatchError(description: error.localizedDescription)))
            }
            else {
                self.logger.log(level: .debug, message: "Event Sent")
                completionHandler(Result.success(event.body))
            }
        }
        
        task.resume()
        
    }
    
}
