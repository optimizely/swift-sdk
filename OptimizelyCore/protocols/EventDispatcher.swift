//
//  EventDispatcher.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 12/3/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

public typealias DispatchCompletionHandler = (Result<Event, EventDispatchError>?)->(Void)
public class EventDispatchError : Error {
}

public protocol EventDispatcher {
    static func createInstance() -> EventDispatcher?
    // Not sure the completion handler will actually be called on complete.
    func dispatchEvent(event:EventForDispatch, completionHandler: @escaping DispatchCompletionHandler)
}
