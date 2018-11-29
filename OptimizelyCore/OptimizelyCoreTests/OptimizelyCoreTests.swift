//
//  OptimizelyCoreTests.swift
//  OptimizelyCoreTests
//
//  Created by Thomas Zurkan on 11/26/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import XCTest
@testable import OptimizelyCore

class OptimizelyCoreTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        let json = "{\"version\": \"4\", \"rollouts\": [{\"experiments\": [{\"status\": \"Running\", \"key\": \"11214290043\", \"layerId\": \"11216280045\", \"trafficAllocation\": [{\"entityId\": \"11196890101\", \"endOfRange\": 0}], \"audienceIds\": [], \"variations\": [{\"variables\": [{\"id\": \"11196660143\", \"value\": \"\"}], \"id\": \"11196890101\", \"key\": \"11196890101\", \"featureEnabled\": true}], \"forcedVariations\": {}, \"id\": \"11214290043\"}], \"id\": \"11216280045\"}], \"typedAudiences\": [], \"anonymizeIP\": true, \"projectId\": \"11102097459\", \"variables\": [], \"featureFlags\": [{\"experimentIds\": [\"11174010269\"], \"rolloutId\": \"11216280045\", \"variables\": [{\"defaultValue\": \"\", \"type\": \"string\", \"id\": \"11196660143\", \"key\": \"string_variable\"}], \"id\": \"11216320075\", \"key\": \"my_feature\"}], \"experiments\": [{\"status\": \"Running\", \"key\": \"my_experiment\", \"layerId\": \"11186120103\", \"trafficAllocation\": [{\"entityId\": \"11193600046\", \"endOfRange\": 5000}, {\"entityId\": \"11198460034\", \"endOfRange\": 10000}], \"audienceIds\": [], \"variations\": [{\"variables\": [{\"id\": \"11196660143\", \"value\": \"\"}], \"id\": \"11193600046\", \"key\": \"variation_1\", \"featureEnabled\": true}, {\"variables\": [], \"id\": \"11198460034\", \"key\": \"variation_2\", \"featureEnabled\": false}], \"forcedVariations\": {}, \"id\": \"11174010269\"}, {\"status\": \"Running\", \"key\": \"background_experiment\", \"layerId\": \"11150133482\", \"trafficAllocation\": [{\"entityId\": \"11146534908\", \"endOfRange\": 5000}, {\"entityId\": \"11192561814\", \"endOfRange\": 10000}], \"audienceIds\": [], \"variations\": [{\"variables\": [], \"id\": \"11146534908\", \"key\": \"variation_a\"}, {\"variables\": [], \"id\": \"11192561814\", \"key\": \"variation_b\"}], \"forcedVariations\": {}, \"id\": \"11178792174\"}], \"audiences\": [], \"groups\": [], \"attributes\": [], \"botFiltering\": false, \"accountId\": \"8362480420\", \"events\": [{\"experimentIds\": [\"11174010269\", \"11178792174\"], \"id\": \"11173400866\", \"key\": \"sample_conversion\"}, {\"experimentIds\": [\"11174010269\"], \"id\": \"11196870086\", \"key\": \"my_conversion\"}, {\"experimentIds\": [], \"id\": \"12115533234\", \"key\": \"newevent\"}], \"revision\": \"10\"}"
        let data: Data? = json.data(using: .utf8)
        let config = try! JSONDecoder().decode(ProjectConfig.self, from: data!)
        
        XCTAssertNotNil(config)
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testExample2() {
        let json = "{\"version\": \"4\", \"rollouts\": [{\"experiments\": [{\"status\": \"Running\", \"key\": \"11214290043\", \"layerId\": \"11216280045\", \"trafficAllocation\": [{\"entityId\": \"11196890101\", \"endOfRange\": 0}], \"audienceIds\": [], \"variations\": [{\"variables\": [{\"id\": \"11196660143\", \"value\": \"\"}], \"id\": \"11196890101\", \"key\": \"11196890101\", \"featureEnabled\": true}], \"forcedVariations\": {}, \"id\": \"11214290043\"}], \"id\": \"11216280045\"}], \"typedAudiences\": [], \"anonymizeIP\": true, \"projectId\": \"11102097459\", \"variables\": [], \"featureFlags\": [{\"experimentIds\": [\"11174010269\"], \"rolloutId\": \"11216280045\", \"variables\": [{\"defaultValue\": \"\", \"type\": \"string\", \"id\": \"11196660143\", \"key\": \"string_variable\"}], \"id\": \"11216320075\", \"key\": \"my_feature\"}], \"experiments\": [{\"status\": \"Running\", \"key\": \"my_experiment\", \"layerId\": \"11186120103\", \"trafficAllocation\": [{\"entityId\": \"11193600046\", \"endOfRange\": 5000}, {\"entityId\": \"11198460034\", \"endOfRange\": 10000}], \"audienceIds\": [], \"variations\": [{\"variables\": [{\"id\": \"11196660143\", \"value\": \"\"}], \"id\": \"11193600046\", \"key\": \"variation_1\", \"featureEnabled\": true}, {\"variables\": [], \"id\": \"11198460034\", \"key\": \"variation_2\", \"featureEnabled\": false}], \"forcedVariations\": {}, \"id\": \"11174010269\"}, {\"status\": \"Running\", \"key\": \"background_experiment\", \"layerId\": \"11150133482\", \"trafficAllocation\": [{\"entityId\": \"11146534908\", \"endOfRange\": 5000}, {\"entityId\": \"11192561814\", \"endOfRange\": 10000}], \"audienceIds\": [\"12097998496\"], \"variations\": [{\"variables\": [], \"id\": \"11146534908\", \"key\": \"variation_a\"}, {\"variables\": [], \"id\": \"11192561814\", \"key\": \"variation_b\"}], \"forcedVariations\": {}, \"id\": \"11178792174\"}], \"audiences\": [{\"id\": \"12097998496\", \"conditions\": \"[\\\"and\\\", [\\\"or\\\", [\\\"not\\\", [\\\"or\\\", {\\\"name\\\": \\\"testAttr\\\", \\\"type\\\": \\\"custom_attribute\\\", \\\"value\\\": \\\"some\\\"}]]]]\", \"name\": \"testAudience\"}], \"groups\": [], \"attributes\": [{\"id\": \"12248392446\", \"key\": \"testAttr\"}], \"botFiltering\": false, \"accountId\": \"8362480420\", \"events\": [{\"experimentIds\": [\"11174010269\", \"11178792174\"], \"id\": \"11173400866\", \"key\": \"sample_conversion\"}, {\"experimentIds\": [\"11174010269\"], \"id\": \"11196870086\", \"key\": \"my_conversion\"}, {\"experimentIds\": [], \"id\": \"12115533234\", \"key\": \"newevent\"}], \"revision\": \"12\"}"
        
        let data: Data? = json.data(using: .utf8)
        let config = try! JSONDecoder().decode(ProjectConfig.self, from: data!)
        
        XCTAssertNotNil(config)
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
