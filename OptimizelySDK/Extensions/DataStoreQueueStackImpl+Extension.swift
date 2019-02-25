//
//  DataStoreQueueStackImpl+extension.swift
//  OptimizelySwiftSDK-iOS
//
//  Created by Thomas Zurkan on 1/31/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

extension DataStoreQueueStack {
    func getFirstItem()->T? {
        return getFirstItems(count: 1)?.first
    }
    func getLastItem()->T? {
        return getLastItems(count: 1)?.first
    }
    func removeFirstItem()->T? {
        return removeFirstItems(count: 1)?.first
    }
    func removeLastItem()->T? {
        return removeLastItems(count: 1)?.first
    }
 }
