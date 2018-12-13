//
//  DefaultEventDispatcher.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 12/13/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class DefaultEventDispatcher : EventDispatcher {
    let dispatchQueue = DispatchQueue(label: "OPTLYEventDispatcherQueue")
    static func createInstance() -> EventDispatcher? {
        return DefaultEventDispatcher()
    }
    
    func dispatchEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
        dispatchQueue.async {
            self.sendEvent(event: event, completionHandler: completionHandler)
        }
    }
    
    func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
        guard let url = event.url else { return }
        
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = event.body
        
        session.dataTask(with: request) { (data, response, error) in
            
        }
    }
    
}
