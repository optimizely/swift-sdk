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

func jsonDataFromNative(_ raw: Any) -> Data {
    return try! JSONSerialization.data(withJSONObject: raw, options: [])
}

func jsonStringFromNative(_ raw: Any) -> String {
    return String(data: jsonDataFromNative(raw), encoding: .utf8)!
}

func modelFromNative<T: Codable>(_ raw: Any) throws -> T {
    return try JSONDecoder().decode(T.self, from: jsonDataFromNative(raw))
}

func loadJSONDatafileIntoDataObject(datafile:String) -> Data? {
    let filePath = Bundle(for: BatchEventBuilder.self).path(forResource: datafile, ofType: "json")
    
    return try? Data(contentsOf: URL(fileURLWithPath: filePath!, isDirectory: false))
}

