//
//  DefaultEventDispatcher.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/13/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class DefaultEventDispatcher : EventDispatcher {
    let logger = DefaultLogger.createInstance(logLevel: .OptimizelyLogLevelDebug)
    static func createInstance() -> EventDispatcher? {
        return DefaultEventDispatcher()
    }
    
    func dispatchEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
        
        self.sendEvent(event: event, completionHandler: completionHandler)
    }
    
    func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
        guard let url = event.url else { return }
        
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = event.body
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = session.uploadTask(with: request, from: event.body) { (data, response, error) in
            if let body = event.body {
                self.logger?.log(level: OptimizelyLogLevel.OptimizelyLogLevelDebug, message: String(data: body, encoding: .utf8) ?? "trouble parsing event body")
            }
            self.logger?.log(level: OptimizelyLogLevel.OptimizelyLogLevelDebug, message: response.debugDescription)
        }
        
        task.resume()
        
    }
    
}
