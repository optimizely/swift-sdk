//
//  SendEvent.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/3/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

@objc public class EventForDispatch : NSObject, Codable {
    static let eventEndpoint = "https://logx.optimizely.com/v1/events"
    
    public let url:URL
    public let body:Data
    
    init(url: URL? = nil, body: Data) {
        self.url = url ?? URL(string: EventForDispatch.eventEndpoint)!
        self.body = body
    }
    
    // override NSObject Equatable ('==' overriding not working for NSObject)
    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? EventForDispatch else { return false }
        return url == object.url && body == object.body
    }
}
