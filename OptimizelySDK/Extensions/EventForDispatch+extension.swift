//
//  EventForDispatch+extension.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/20/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

extension EventForDispatch {
    public static func == (lhs: EventForDispatch, rhs: EventForDispatch) -> Bool {
        return lhs.url == rhs.url && lhs.body == rhs.body
    }
}
