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

func getAttributeValueFromNative(_ value: Any) throws -> AttributeValue {
    // JSONEncoder does not support fragmented JSON format (string alone), so wrap in an array
    let json = [value]
    let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
    let modelArray = try JSONDecoder().decode([AttributeValue].self, from: jsonData)
    return modelArray[0]
}

