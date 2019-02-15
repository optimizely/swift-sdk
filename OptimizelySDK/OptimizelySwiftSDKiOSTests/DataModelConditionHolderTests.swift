//
//  DataModelConditionHolderTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/15/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest


/* Test combinations
 
 // single UserAttribute
 
 U = userAttribute
 
 // [and/or/not, UserAttribute]
 
 AU = ["and", U]
 OU = ["or", U]
 NU = ["not", U]
 
 // [and/or/not, [and/or/not, UserAttribute]]
 
 A.AU = ["and", AU]
 A.OU = ["and", OU]
 A.NU = ["and", NU]
 
 O.AU = ["or", AU]
 O.OU = ["or", OU]
 O.NU = ["or", NU]
 
 N.AU = ["not", AU]
 N.OU = ["not", OU]
 N.NU = ["not", NU]
 
 // [and/or/not, [and/or/not, UserAttribute], [and/or/not, UserAttribute]]
 
 A.AU.AU = ["and", AU, AU]
 A.AU.OU = ["and", AU, OU]
 A.AU.NU = ["and", AU, NU]
 O.AU.AU = ["or", AU, AU]
 O.AU.OU = ["or", AU, OU]
 O.AU.NU = ["or", AU, NU]
 
 A.OU.AU = ["and", OU, AU]
 A.OU.OU = ["and", OU, OU]
 A.OU.NU = ["and", OU, NU]
 O.OU.AU = ["or", OU, AU]
 O.OU.OU = ["or", OU, OU]
 O.OU.NU = ["or", OU, NU]
 
 A.NU.AU = ["and", NU, AU]
 A.NU.OU = ["and", NU, OU]
 A.NU.NU = ["and", NU, NU]
 O.NU.AU = ["or", NU, AU]
 O.NU.OU = ["or", NU, OU]
 O.NU.NU = ["or", NU, NU]
 
 // [and/or/not, UserAttribute, [and/or/not, UserAttribute]]
 
 A.UA.AU = ["and", UA, AU]
 A.UA.OU = ["and", UA, OU]
 A.UA.NU = ["and", UA, NU]
 O.UA.AU = ["or", UA, AU]
 O.UA.OU = ["or", UA, OU]
 O.UA.NU = ["or", UA, NU]
 
 A.AU.UA = ["and", AU, UA]
 A.OU.UA = ["and", OU, UA]
 A.NU.UA = ["and", NU, UA]
 O.AU.UA = ["or", AU, UA]
 O.OU.UA = ["or", OU, UA]
 O.NU.UA = ["or", NU, UA]
 
 // [and/or/not, [and/or/not, UserAttribute, [and/or/not, UserAttribute], [and/or/not, UserAttribute]]
 
 Complex1 = ["and", A.UA.AU, AU]
 Complex2 = ["or", A.UA.AU, O.UA.AU]
 
 */


class DataModelConditionHolderTests: XCTestCase {

    let modelType = ConditionHolder.self
    
    let userAttribute: [String: Any] = ["name":"age", "type":"custom_attribute", "match":"exact", "value":30]
    
    // MARK: - Decode
    
    
    
    func testDecodeSuccessWithJSONValid() {
        let json: [Any] = ["and",
                           ["name":"geo", "type":"custom_attribute", "match":"exact", "value":30]]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode([ConditionHolder].self, from: jsonData)
        
        XCTAssert(model[0] == ConditionHolder.string("and"))
        let ua: UserAttribute = jsonDecodeFromDict(userAttribute)
        XCTAssert(model[1] == ConditionHolder.userAttribute(ua))
    }

    func testDecodeSuccessWithJSONValid2() {
        let jsonInside: [Any] = ["or",
                           ["name":"geo", "type":"custom_attribute", "match":"gt", "value":10]]
        let jsonDataInside = try! JSONSerialization.data(withJSONObject: jsonInside, options: [])
        let modelInside = try! JSONDecoder().decode([ConditionHolder].self, from: jsonDataInside)

        
        
        let json: [Any] =  ["and",
                            ["name":"geo", "type":"custom_attribute", "match":"exact", "value":30],
                            jsonInside]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode([ConditionHolder].self, from: jsonData)
        
        XCTAssert(model[0] == ConditionHolder.string("and"))
        let ua: UserAttribute = jsonDecodeFromDict(userAttribute)
        XCTAssert(model[1] == ConditionHolder.userAttribute(ua))
        XCTAssert(model[2] == ConditionHolder.array(modelInside))
    }
    
    func testEvaluateTrue() {
        let json: [Any] = ["and",
                           ["name":"geo", "type":"custom_attribute", "match":"exact", "value":30]]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode([ConditionHolder].self, from: jsonData)

        model[1].evaluate(projectConfig: <#T##ProjectConfig#>, attributes: <#T##Dictionary<String, Any>#>)
    }

}
