//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest

class OptimizelyClientTests_OptimizelyConfig: XCTestCase {

    var optimizely: OptimizelyClient!

    override func setUp() {
        super.setUp()
        
        let datafile = OTUtils.loadJSONDatafile("optimizely_config_datafile")!

        self.optimizely = OptimizelyClient(sdkKey: "12345",
                                           userProfileService: OTUtils.createClearUserProfileService())
        try! self.optimizely.start(datafile: datafile)
    }
    
    // this test can be also covered by FSC, but it'll be useful to confirm Swift and ObjC both generate correct outputs
    func testGetOptimizelyConfig_Equal() {
        if #available(iOS 11.0, tvOS 11.0, *) {
            let optimizelyConfig = try! optimizely.getOptimizelyConfig()
            
            // compare dictionaries as strings (after key-sorted and remove all spaces)
            guard let dict = optimizelyConfig.dict else {
                XCTAssert(false)
                return
            }
            
            let observedDict = dict
            let observedData = try! JSONSerialization.data(withJSONObject: observedDict, options: .sortedKeys)
            let observedJSON = String(bytes: observedData, encoding: .utf8)!
            let observed = observedJSON.filter{ !$0.isNewline && !$0.isWhitespace }
            
            // pre-geneerated expected JSON string (sorted by keys)
            let expectedData = OTUtils.loadJSONFile("optimizely_config_expected")!
            let expectedJSON = String(bytes: expectedData, encoding: .utf8)!
            let expected = expectedJSON.filter{ !$0.isNewline && !$0.isWhitespace }
            
            XCTAssertEqual(observed, expected, "\n\n[Observed]\n\(observed)\n\n[Expected]\n\(expected)\n\n")
        }
    }
    
    func testGetOptimizelyConfig_InvalidDatafile() {
        self.optimizely = OptimizelyClient(sdkKey: "12345")
        let invalidDatafile = "{\"version\": \"4\"}"
        try? self.optimizely.start(datafile: invalidDatafile)
        
        let result = try? self.optimizely.getOptimizelyConfig()
        XCTAssertNil(result)
    }
    
    func testGetOptimizelyConfig_AfterDatafileUpdate() {
        class FakeDatafileHandler: DefaultDatafileHandler {
            let datafile = OTUtils.loadJSONDatafile("optimizely_config_datafile")
            override func downloadDatafile(sdkKey: String,
                                           returnCacheIfNoChange: Bool,
                                           resourceTimeoutInterval: Double?,
                                           completionHandler: @escaping DatafileDownloadCompletionHandler) {
                completionHandler(.success(datafile))
            }
        }
        
        let badUniqueSdkKey = "badUniqueSdkKey"
        var optimizelyConfig: OptimizelyConfig?
        let optimizely = OptimizelyClient(sdkKey: badUniqueSdkKey,
                                          datafileHandler: FakeDatafileHandler(),
                                          periodicDownloadInterval: 1)
        
        var exp: XCTestExpectation? = expectation(description: "datafile update event")
        _ = optimizely.notificationCenter!.addDatafileChangeNotificationListener { _ in
            optimizelyConfig = try! optimizely.getOptimizelyConfig()
            exp?.fulfill()
        }
        
        let datafile = OTUtils.loadJSONDatafile("empty_datafile")!
        try! optimizely.start(datafile: datafile, doFetchDatafileBackground: false)
        
        // before datafile remote updated ("empty_datafile")
        
        optimizelyConfig = try! optimizely.getOptimizelyConfig()
        XCTAssert(optimizelyConfig!.revision == "100")
        XCTAssert(optimizelyConfig!.sdkKey == "")
        XCTAssert(optimizelyConfig!.environmentKey == "")
        
        wait(for: [exp!], timeout: 10)
        exp = nil // disregard following update notification

        // after datafile remote updated ("optimizely_config_datafile")
        XCTAssert(optimizelyConfig!.revision == "9")
        XCTAssert(optimizelyConfig!.sdkKey == "ValidProjectConfigV4")
        XCTAssert(optimizelyConfig!.environmentKey == "production")
    }

    func testGetOptimizelyConfig_ExperimentsMap() {
        print("------------------------------------------------------")
        let optimizelyConfig = try! optimizely.getOptimizelyConfig()
        
        print("   Experiments: \(optimizelyConfig.experimentsMap.keys)")

        XCTAssertEqual(optimizelyConfig.experimentsMap.count, 5)

        let experiment1 = optimizelyConfig.experimentsMap["exp_with_audience"]!
        let experiment2 = optimizelyConfig.experimentsMap["experiment_4000"]!
        
        XCTAssertEqual(experiment1.variationsMap.count, 2)
        XCTAssertEqual(experiment2.variationsMap.count, 2)
        
        print("   Experiment1 > Variations: \(experiment1.variationsMap.keys)")
        print("   Experiment2 > Variations: \(experiment2.variationsMap.keys)")
        
        let variation1 = experiment1.variationsMap["a"]!
        let variation2 = experiment1.variationsMap["b"]!

        XCTAssertEqual(variation1.variablesMap.count, 0)
        XCTAssertEqual(variation2.variablesMap.count, 0)
        print("------------------------------------------------------")
    }
    
    func testGetOptimizelyConfig_FeatureFlagsMap() {
        print("------------------------------------------------------")
        let optimizelyConfig = try! optimizely.getOptimizelyConfig()
        
        print("   Features: \(optimizelyConfig.featuresMap.keys)")
        
        XCTAssertEqual(optimizelyConfig.featuresMap.count, 2)
        
        let feature1 = optimizelyConfig.featuresMap["mutex_group_feature"]!
        let feature2 = optimizelyConfig.featuresMap["feature_exp_no_traffic"]!

        // FeatureFlag: experimentsMap
        
        XCTAssertEqual(feature1.experimentsMap.count, 2)
        XCTAssertEqual(feature2.experimentsMap.count, 1)

        print("   Feature1 > Experiments: \(feature1.experimentsMap.keys)")
        print("   Feature2 > Experiments: \(feature2.experimentsMap.keys)")

        let experiment1 = feature1.experimentsMap["experiment_4000"]!
        let experiment2 = feature1.experimentsMap["experiment_8000"]!
        
        XCTAssertEqual(experiment1.variationsMap.count, 2)
        XCTAssertEqual(experiment2.variationsMap.count, 1)

        print("   Feature1 > Experiment1 > Variations: \(experiment1.variationsMap.keys)")
        print("   Feature1 > Experiment2 > Variations: \(experiment2.variationsMap.keys)")
        
        let variation1 = experiment1.variationsMap["all_traffic_variation_exp_1"]!
        let variation2 = experiment1.variationsMap["no_traffic_variation_exp_1"]!

        XCTAssertEqual(variation1.variablesMap.count, 4)
        XCTAssertEqual(variation2.variablesMap.count, 4, "must include all default variables when empty");

        print("   Feature1 > Experiment1 > Variation1 > Variables: \(variation1.variablesMap.keys)")
        print("   Feature1 > Experiment1 > Variation2 > Variables: \(variation2.variablesMap.keys)")
        
        let variable1 = variation1.variablesMap["s_foo"]!
        XCTAssertEqual(variable1.id, "2687470097")
        XCTAssertEqual(variable1.key, "s_foo")
        XCTAssertEqual(variable1.type, "string")
        XCTAssertEqual(variable1.value, "s1")

        // FeatureFlag: variablesMap
        
        XCTAssertEqual(feature1.variablesMap.count, 4)
        XCTAssertEqual(feature2.variablesMap.count, 0)

        print("   Feature1 > FeatureVariables: \(feature1.variablesMap.keys)")
        
        let featureVariable = feature1.variablesMap["i_42"]!
        XCTAssertEqual(featureVariable.id, "2687470094")
        XCTAssertEqual(featureVariable.key, "i_42")
        XCTAssertEqual(featureVariable.type, "integer")
        XCTAssertEqual(featureVariable.value, "42")
        print("------------------------------------------------------")
    }

}

// MARK: - Convert to JSON

extension OptimizelyConfig {
    var dict: [String: Any]? {
        let expected: [String: Any] = [
            "revision": self.revision,
            "sdkKey": self.sdkKey,
            "environmentKey": self.environmentKey,
            "experimentsMap": self.experimentsMap.mapValues{ $0.dict },
            "featuresMap": self.featuresMap.mapValues{ $0.dict },
            "attributes": self.attributes,
            "audiences": self.audiences,
            "events": self.events
        ]
                
        if expected.count != Mirror(reflecting: self).children.count {
            print("ERROR: invalid properites included in OptimizelyConfig: \(Mirror(reflecting: self).children.compactMap { $0.label })")
            return nil
        }
        
        return expected
    }
}

extension OptimizelyExperiment {
    var dict: [String: Any] {
        return [
            "key": self.key,
            "id": self.id,
            "variationsMap": self.variationsMap.mapValues{ $0.dict }
        ]
    }
}

extension OptimizelyFeature {
    var dict: [String: Any] {
        return [
            "key": self.key,
            "id": self.id,
            "experimentsMap": self.experimentsMap.mapValues{ $0.dict },
            "variablesMap": self.variablesMap.mapValues{ $0.dict }
        ]
    }
}

extension OptimizelyVariation {
    var dict: [String: Any] {
        var expected: [String: Any] = [
            "key": self.key,
            "id": self.id,
            "variablesMap": self.variablesMap.mapValues{ $0.dict }
        ]
        
        // An expected JSON file ("optimizely_config_expected.json") shared for Swift and Objective-C tests
        // - it has "false" value for "featureEnabled" of AB test variations since Objective-C app has no optional value
        // - nil value is convereted to false before converting to JSON
        expected["featureEnabled"] = self.featureEnabled ?? false
        
        return expected
    }
}

extension OptimizelyVariable {
    var dict: [String: Any] {
        return [
            "key": self.key,
            "id": self.id,
            "type": self.type,
            "value": self.value
        ]
    }
}
//
//extension OptimizelyAttribute {
//    var dict: [String: Any] {
//        return [
//            "key": self.key,
//            "id": self.id
//        ]
//    }
//}
//
//extension OptimizelyAudience {
//    var dict: [String: Any] {
//        return [
//            "name": self.name,
//            "id": self.id,
//            "conditions": self.conditions
//        ]
//    }
//}
//
//extension OptimizelyEvent {
//    var dict: [String: Any] {
//        return [
//            "key": self.key,
//            "id": self.id,
//            "experimentIds": self.experimentIds
//        ]
//    }
//}


