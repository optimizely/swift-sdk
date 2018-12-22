//
//  DefaultEventDispatcher.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/13/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

public class DefaultEventDispatcher : EventDispatcher {
    let logger = DefaultLogger(level: .OptimizelyLogLevelDebug)
    let dispatcher = DispatchQueue(label: "DefaultEventDispatcherQueue")
    let dataStore = DataStoreEvents()
    let notify = DispatchGroup()
    
    public static func createInstance() -> EventDispatcher? {
        return DefaultEventDispatcher()
    }
    
    public func dispatchEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
        
        dataStore.save(item: event)
        
        dispatcher.async {
            while let event:EventForDispatch = self.dataStore.getFirstItem() {
                self.notify.enter()
                self.sendEvent(event: event) { (result) -> (Void) in
                    
                    switch result {
                    case .failure(let error):
                        self.logger.log(level: OptimizelyLogLevel.OptimizelyLogLevelError, message: error.localizedDescription)
                    case .success(_):
                        if let removedItem:EventForDispatch = self.dataStore.removeFirstItem() {
                            if removedItem != event {
                                self.logger.log(level: OptimizelyLogLevel.OptimizelyLogLevelError, message: "Removed event different from sent event")
                            }
                            else {
                                self.logger.log(level: OptimizelyLogLevel.OptimizelyLogLevelDebug, message: "Successfully sent event " + event.body.debugDescription)
                            }
                        }
                        else {
                            self.logger.log(level: OptimizelyLogLevel.OptimizelyLogLevelError, message: "Removed event nil for sent item")
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
            self.logger.log(level: OptimizelyLogLevel.OptimizelyLogLevelDebug, message: "Event Sent")
                completionHandler(Result.success(event.body))
            self.logger.log(level: OptimizelyLogLevel.OptimizelyLogLevelDebug, message: response.debugDescription)
            
            if let error = error {
                completionHandler(Result.failure(EventDispatchError(description: error.localizedDescription)))
            }
            else {
                
            }
        }
        
        task.resume()
        
    }
    
}
