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
}
