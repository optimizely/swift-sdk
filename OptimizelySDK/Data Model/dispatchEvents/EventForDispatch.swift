//
//  SendEvent.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/3/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

public class EventForDispatch : Equatable {
    static let eventEndpoint = "https://logx.optimizely.com/v1/events"
    
    public let url:URL?
    public let body:Data?
    
    static func createInstance(url:URL, body:Data) -> EventForDispatch {
        return EventForDispatch(url:url, body:body)
    }
    
    convenience init(body:Data) {
        self.init(url: URL(string:EventForDispatch.eventEndpoint)!, body: body)
    }
    
    init(url:URL, body:Data) {
        self.url = url
        self.body = body
    }
}
