//
//  OptimizelyTestUtils.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 2/11/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation
import XCTest

func isEqualWithEncodeThenDecode<T: Codable & Equatable>(_ model: T) -> Bool {
    let jsonData = try! JSONEncoder().encode(model)
    let modelExp = try! JSONDecoder().decode(T.self, from: jsonData)
    return modelExp == model
}
