//
//  OptimizelyManagerTests.swift
//  OptimizelySDKTests
//
//  Created by Thomas Zurkan on 12/7/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import XCTest

class OptimizelyManagerTests: XCTestCase {
    let json = "{\"accountId\":\"2360254204\",\"anonymizeIP\":true,\"botFiltering\":true,\"projectId\":\"3918735994\",\"revision\":\"1480511547\",\"version\":\"4\",\"audiences\":[{\"id\":\"3468206642\",\"name\":\"Gryffindors\",\"conditions\":[\"and\",[\"or\",[\"or\",{\"name\":\"house\",\"type\":\"custom_attribute\",\"value\":\"Gryffindor\"}]]]},{\"id\":\"3988293898\",\"name\":\"Slytherins\",\"conditions\":[\"and\",[\"or\",[\"or\",{\"name\":\"house\",\"type\":\"custom_attribute\",\"value\":\"Slytherin\"}]]]},{\"id\":\"4194404272\",\"name\":\"english_citizens\",\"conditions\":[\"and\",[\"or\",[\"or\",{\"name\":\"nationality\",\"type\":\"custom_attribute\",\"value\":\"English\"}]]]},{\"id\":\"2196265320\",\"name\":\"audience_with_missing_value\",\"conditions\":[\"and\",[\"or\",[\"or\",{\"name\":\"nationality\",\"type\":\"custom_attribute\",\"value\":\"English\"},{\"name\":\"nationality\",\"type\":\"custom_attribute\"}]]]}],\"typedAudiences\":[{\"id\":\"3468206643\",\"name\":\"BOOL\",\"conditions\":[\"and\",[\"or\",[\"or\",{\"name\":\"booleanKey\",\"type\":\"custom_attribute\",\"match\":\"exact\",\"value\":true}]]]},{\"id\":\"3468206646\",\"name\":\"INTEXACT\",\"conditions\":[\"and\",[\"or\",[\"or\",{\"name\":\"integerKey\",\"type\":\"custom_attribute\",\"match\":\"exact\",\"value\":1}]]]},{\"id\":\"3468206644\",\"name\":\"INT\",\"conditions\":[\"and\",[\"or\",[\"or\",{\"name\":\"integerKey\",\"type\":\"custom_attribute\",\"match\":\"gt\",\"value\":1}]]]},{\"id\":\"3468206645\",\"name\":\"DOUBLE\",\"conditions\":[\"and\",[\"or\",[\"or\",{\"name\":\"doubleKey\",\"type\":\"custom_attribute\",\"match\":\"lt\",\"value\":100}]]]},{\"id\":\"3468206642\",\"name\":\"Gryffindors\",\"conditions\":[\"and\",[\"or\",[\"or\",{\"name\":\"house\",\"type\":\"custom_attribute\",\"match\":\"exact\",\"value\":\"Gryffindor\"}]]]},{\"id\":\"3988293898\",\"name\":\"Slytherins\",\"conditions\":[\"and\",[\"or\",[\"or\",{\"name\":\"house\",\"type\":\"custom_attribute\",\"match\":\"substring\",\"value\":\"Slytherin\"}]]]},{\"id\":\"4194404272\",\"name\":\"english_citizens\",\"conditions\":[\"and\",[\"or\",[\"or\",{\"name\":\"nationality\",\"type\":\"custom_attribute\",\"match\":\"exact\",\"value\":\"English\"}]]]},{\"id\":\"2196265320\",\"name\":\"audience_with_missing_value\",\"conditions\":[\"and\",[\"or\",[\"or\",{\"name\":\"nationality\",\"type\":\"custom_attribute\",\"value\":\"English\"},{\"name\":\"nationality\",\"type\":\"custom_attribute\"}]]]}],\"attributes\":[{\"id\":\"553339214\",\"key\":\"house\"},{\"id\":\"58339410\",\"key\":\"nationality\"},{\"id\":\"583394100\",\"key\":\"$opt_test\"},{\"id\":\"323434545\",\"key\":\"booleanKey\"},{\"id\":\"616727838\",\"key\":\"integerKey\"},{\"id\":\"808797686\",\"key\":\"doubleKey\"},{\"id\":\"808797686\",\"key\":\"\"}],\"events\":[{\"id\":\"3785620495\",\"key\":\"basic_event\",\"experimentIds\":[\"1323241596\",\"2738374745\",\"3042640549\",\"3262035800\",\"3072915611\"]},{\"id\":\"3195631717\",\"key\":\"event_with_paused_experiment\",\"experimentIds\":[\"2667098701\"]},{\"id\":\"1987018666\",\"key\":\"event_with_launched_experiments_only\",\"experimentIds\":[\"3072915611\"]}],\"experiments\":[{\"id\":\"1323241596\",\"key\":\"basic_experiment\",\"layerId\":\"1630555626\",\"status\":\"Running\",\"variations\":[{\"id\":\"1423767502\",\"key\":\"A\",\"variables\":[]},{\"id\":\"3433458314\",\"key\":\"B\",\"variables\":[]}],\"trafficAllocation\":[{\"entityId\":\"1423767502\",\"endOfRange\":5000},{\"entityId\":\"3433458314\",\"endOfRange\":10000}],\"audienceIds\":[],\"forcedVariations\":{\"Harry Potter\":\"A\",\"Tom Riddle\":\"B\"}},{\"id\":\"1323241597\",\"key\":\"typed_audience_experiment\",\"layerId\":\"1630555627\",\"status\":\"Running\",\"variations\":[{\"id\":\"1423767503\",\"key\":\"A\",\"variables\":[]},{\"id\":\"3433458315\",\"key\":\"B\",\"variables\":[]}],\"trafficAllocation\":[{\"entityId\":\"1423767503\",\"endOfRange\":5000},{\"entityId\":\"3433458315\",\"endOfRange\":10000}],\"audienceIds\":[\"3468206643\",\"3468206644\",\"3468206646\",\"3468206645\"],\"audienceConditions\":[\"or\",\"3468206643\",\"3468206644\",\"3468206646\",\"3468206645\"],\"forcedVariations\":{}},{\"id\":\"1323241598\",\"key\":\"typed_audience_experiment_with_and\",\"layerId\":\"1630555628\",\"status\":\"Running\",\"variations\":[{\"id\":\"1423767504\",\"key\":\"A\",\"variables\":[]},{\"id\":\"3433458316\",\"key\":\"B\",\"variables\":[]}],\"trafficAllocation\":[{\"entityId\":\"1423767504\",\"endOfRange\":5000},{\"entityId\":\"3433458316\",\"endOfRange\":10000}],\"audienceIds\":[\"3468206643\",\"3468206644\",\"3468206645\"],\"audienceConditions\":[\"and\",\"3468206643\",\"3468206644\",\"3468206645\"],\"forcedVariations\":{}},{\"id\":\"1323241599\",\"key\":\"typed_audience_experiment_leaf_condition\",\"layerId\":\"1630555629\",\"status\":\"Running\",\"variations\":[{\"id\":\"1423767505\",\"key\":\"A\",\"variables\":[]},{\"id\":\"3433458317\",\"key\":\"B\",\"variables\":[]}],\"trafficAllocation\":[{\"entityId\":\"1423767505\",\"endOfRange\":5000},{\"entityId\":\"3433458317\",\"endOfRange\":10000}],\"audienceIds\":[],\"audienceConditions\":\"3468206643\",\"forcedVariations\":{}},{\"id\":\"3262035800\",\"key\":\"multivariate_experiment\",\"layerId\":\"3262035800\",\"status\":\"Running\",\"variations\":[{\"id\":\"1880281238\",\"key\":\"Fred\",\"featureEnabled\":true,\"variables\":[{\"id\":\"675244127\",\"value\":\"F\"},{\"id\":\"4052219963\",\"value\":\"red\"}]},{\"id\":\"3631049532\",\"key\":\"Feorge\",\"featureEnabled\":true,\"variables\":[{\"id\":\"675244127\",\"value\":\"F\"},{\"id\":\"4052219963\",\"value\":\"eorge\"}]},{\"id\":\"4204375027\",\"key\":\"Gred\",\"featureEnabled\":false,\"variables\":[{\"id\":\"675244127\",\"value\":\"G\"},{\"id\":\"4052219963\",\"value\":\"red\"}]},{\"id\":\"2099211198\",\"key\":\"George\",\"featureEnabled\":true,\"variables\":[{\"id\":\"675244127\",\"value\":\"G\"},{\"id\":\"4052219963\",\"value\":\"eorge\"}]}],\"trafficAllocation\":[{\"entityId\":\"1880281238\",\"endOfRange\":2500},{\"entityId\":\"3631049532\",\"endOfRange\":5000},{\"entityId\":\"4204375027\",\"endOfRange\":7500},{\"entityId\":\"2099211198\",\"endOfRange\":10000}],\"audienceIds\":[\"3468206642\"],\"forcedVariations\":{\"Fred\":\"Fred\",\"Feorge\":\"Feorge\",\"Gred\":\"Gred\",\"George\":\"George\"}},{\"id\":\"2201520193\",\"key\":\"double_single_variable_feature_experiment\",\"layerId\":\"1278722008\",\"status\":\"Running\",\"variations\":[{\"id\":\"1505457580\",\"key\":\"pi_variation\",\"featureEnabled\":true,\"variables\":[{\"id\":\"4111654444\",\"value\":\"3.14\"}]},{\"id\":\"119616179\",\"key\":\"euler_variation\",\"variables\":[{\"id\":\"4111654444\",\"value\":\"2.718\"}]}],\"trafficAllocation\":[{\"entityId\":\"1505457580\",\"endOfRange\":4000},{\"entityId\":\"119616179\",\"endOfRange\":8000}],\"audienceIds\":[\"3988293898\"],\"forcedVariations\":{}},{\"id\":\"2667098701\",\"key\":\"paused_experiment\",\"layerId\":\"3949273892\",\"status\":\"Paused\",\"variations\":[{\"id\":\"391535909\",\"key\":\"Control\",\"variables\":[]}],\"trafficAllocation\":[{\"entityId\":\"391535909\",\"endOfRange\":10000}],\"audienceIds\":[],\"forcedVariations\":{\"Harry Potter\":\"Control\"}},{\"id\":\"3072915611\",\"key\":\"launched_experiment\",\"layerId\":\"3587821424\",\"status\":\"Launched\",\"variations\":[{\"id\":\"1647582435\",\"key\":\"launch_control\",\"variables\":[]}],\"trafficAllocation\":[{\"entityId\":\"1647582435\",\"endOfRange\":8000}],\"audienceIds\":[],\"forcedVariations\":{}},{\"id\":\"748215081\",\"key\":\"experiment_with_malformed_audience\",\"layerId\":\"1238149537\",\"status\":\"Running\",\"variations\":[{\"id\":\"535538389\",\"key\":\"var1\",\"variables\":[]}],\"trafficAllocation\":[{\"entityId\":\"535538389\",\"endOfRange\":10000}],\"audienceIds\":[\"2196265320\"],\"forcedVariations\":{}}],\"groups\":[{\"id\":\"1015968292\",\"policy\":\"random\",\"experiments\":[{\"id\":\"2738374745\",\"key\":\"first_grouped_experiment\",\"layerId\":\"3301900159\",\"status\":\"Running\",\"variations\":[{\"id\":\"2377378132\",\"key\":\"A\",\"variables\":[]},{\"id\":\"1179171250\",\"key\":\"B\",\"variables\":[]}],\"trafficAllocation\":[{\"entityId\":\"2377378132\",\"endOfRange\":5000},{\"entityId\":\"1179171250\",\"endOfRange\":10000}],\"audienceIds\":[\"3468206642\"],\"forcedVariations\":{\"Harry Potter\":\"A\",\"Tom Riddle\":\"B\"}},{\"id\":\"3042640549\",\"key\":\"second_grouped_experiment\",\"layerId\":\"2625300442\",\"status\":\"Running\",\"variations\":[{\"id\":\"1558539439\",\"key\":\"A\",\"variables\":[]},{\"id\":\"2142748370\",\"key\":\"B\",\"variables\":[]}],\"trafficAllocation\":[{\"entityId\":\"1558539439\",\"endOfRange\":5000},{\"entityId\":\"2142748370\",\"endOfRange\":10000}],\"audienceIds\":[\"3468206642\"],\"forcedVariations\":{\"Hermione Granger\":\"A\",\"Ronald Weasley\":\"B\"}}],\"trafficAllocation\":[{\"entityId\":\"2738374745\",\"endOfRange\":4000},{\"entityId\":\"3042640549\",\"endOfRange\":8000}]},{\"id\":\"2606208781\",\"policy\":\"random\",\"experiments\":[{\"id\":\"4138322202\",\"key\":\"mutex_group_2_experiment_1\",\"layerId\":\"3755588495\",\"status\":\"Running\",\"variations\":[{\"id\":\"1394671166\",\"key\":\"mutex_group_2_experiment_1_variation_1\",\"featureEnabled\":true,\"variables\":[{\"id\":\"2059187672\",\"value\":\"mutex_group_2_experiment_1_variation_1\"}]}],\"audienceIds\":[],\"forcedVariations\":{},\"trafficAllocation\":[{\"entityId\":\"1394671166\",\"endOfRange\":10000}]},{\"id\":\"1786133852\",\"key\":\"mutex_group_2_experiment_2\",\"layerId\":\"3818002538\",\"status\":\"Running\",\"variations\":[{\"id\":\"1619235542\",\"key\":\"mutex_group_2_experiment_2_variation_2\",\"featureEnabled\":true,\"variables\":[{\"id\":\"2059187672\",\"value\":\"mutex_group_2_experiment_2_variation_2\"}]}],\"trafficAllocation\":[{\"entityId\":\"1619235542\",\"endOfRange\":10000}],\"audienceIds\":[],\"forcedVariations\":{}}],\"trafficAllocation\":[{\"entityId\":\"4138322202\",\"endOfRange\":5000},{\"entityId\":\"1786133852\",\"endOfRange\":10000}]}],\"featureFlags\":[{\"id\":\"4195505407\",\"key\":\"boolean_feature\",\"rolloutId\":\"\",\"experimentIds\":[],\"variables\":[]},{\"id\":\"3926744821\",\"key\":\"double_single_variable_feature\",\"rolloutId\":\"\",\"experimentIds\":[\"2201520193\"],\"variables\":[{\"id\":\"4111654444\",\"key\":\"double_variable\",\"type\":\"double\",\"defaultValue\":\"14.99\"}]},{\"id\":\"3281420120\",\"key\":\"integer_single_variable_feature\",\"rolloutId\":\"2048875663\",\"experimentIds\":[],\"variables\":[{\"id\":\"593964691\",\"key\":\"integer_variable\",\"type\":\"integer\",\"defaultValue\":\"7\"}]},{\"id\":\"2591051011\",\"key\":\"boolean_single_variable_feature\",\"rolloutId\":\"\",\"experimentIds\":[],\"variables\":[{\"id\":\"3974680341\",\"key\":\"boolean_variable\",\"type\":\"boolean\",\"defaultValue\":\"true\"}]},{\"id\":\"2079378557\",\"key\":\"string_single_variable_feature\",\"rolloutId\":\"1058508303\",\"experimentIds\":[],\"variables\":[{\"id\":\"2077511132\",\"key\":\"string_variable\",\"type\":\"string\",\"defaultValue\":\"wingardium leviosa\"}]},{\"id\":\"3263342226\",\"key\":\"multi_variate_feature\",\"rolloutId\":\"813411034\",\"experimentIds\":[\"3262035800\"],\"variables\":[{\"id\":\"675244127\",\"key\":\"first_letter\",\"type\":\"string\",\"defaultValue\":\"H\"},{\"id\":\"4052219963\",\"key\":\"rest_of_name\",\"type\":\"string\",\"defaultValue\":\"arry\"}]},{\"id\":\"3263342226\",\"key\":\"mutex_group_feature\",\"rolloutId\":\"\",\"experimentIds\":[\"4138322202\",\"1786133852\"],\"variables\":[{\"id\":\"2059187672\",\"key\":\"correlating_variation_name\",\"type\":\"string\",\"defaultValue\":null}]}],\"rollouts\":[{\"id\":\"1058508303\",\"experiments\":[{\"id\":\"1785077004\",\"key\":\"1785077004\",\"status\":\"Running\",\"layerId\":\"1058508303\",\"audienceIds\":[],\"forcedVariations\":{},\"variations\":[{\"id\":\"1566407342\",\"key\":\"1566407342\",\"featureEnabled\":true,\"variables\":[{\"id\":\"2077511132\",\"value\":\"lumos\"}]}],\"trafficAllocation\":[{\"entityId\":\"1566407342\",\"endOfRange\":5000}]}]},{\"id\":\"813411034\",\"experiments\":[{\"id\":\"3421010877\",\"key\":\"3421010877\",\"status\":\"Running\",\"layerId\":\"813411034\",\"audienceIds\":[\"3468206642\"],\"forcedVariations\":{},\"variations\":[{\"id\":\"521740985\",\"key\":\"521740985\",\"variables\":[{\"id\":\"675244127\",\"value\":\"G\"},{\"id\":\"4052219963\",\"value\":\"odric\"}]}],\"trafficAllocation\":[{\"entityId\":\"521740985\",\"endOfRange\":5000}]},{\"id\":\"600050626\",\"key\":\"600050626\",\"status\":\"Running\",\"layerId\":\"813411034\",\"audienceIds\":[\"3988293898\"],\"forcedVariations\":{},\"variations\":[{\"id\":\"180042646\",\"key\":\"180042646\",\"featureEnabled\":true,\"variables\":[{\"id\":\"675244127\",\"value\":\"S\"},{\"id\":\"4052219963\",\"value\":\"alazar\"}]}],\"trafficAllocation\":[{\"entityId\":\"180042646\",\"endOfRange\":5000}]},{\"id\":\"2637642575\",\"key\":\"2637642575\",\"status\":\"Running\",\"layerId\":\"813411034\",\"audienceIds\":[\"4194404272\"],\"forcedVariations\":{},\"variations\":[{\"id\":\"2346257680\",\"key\":\"2346257680\",\"featureEnabled\":true,\"variables\":[{\"id\":\"675244127\",\"value\":\"D\"},{\"id\":\"4052219963\",\"value\":\"udley\"}]}],\"trafficAllocation\":[{\"entityId\":\"2346257680\",\"endOfRange\":5000}]},{\"id\":\"828245624\",\"key\":\"828245624\",\"status\":\"Running\",\"layerId\":\"813411034\",\"audienceIds\":[],\"forcedVariations\":{},\"variations\":[{\"id\":\"3137445031\",\"key\":\"3137445031\",\"featureEnabled\":true,\"variables\":[{\"id\":\"675244127\",\"value\":\"M\"},{\"id\":\"4052219963\",\"value\":\"uggle\"}]}],\"trafficAllocation\":[{\"entityId\":\"3137445031\",\"endOfRange\":5000}]}]},{\"id\":\"2048875663\",\"experiments\":[{\"id\":\"3794675122\",\"key\":\"3794675122\",\"status\":\"Running\",\"layerId\":\"2048875663\",\"audienceIds\":[],\"forcedVariations\":{},\"variations\":[{\"id\":\"589640735\",\"key\":\"589640735\",\"featureEnabled\":true,\"variables\":[]}],\"trafficAllocation\":[{\"entityId\":\"589640735\",\"endOfRange\":10000}]}]}],\"variables\":[]}"

    var optimizely:OptimizelyManager?
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        optimizely = OptimizelyManager(sdkKey: "SDKKEY")
        
       try! optimizely?.initializeSDK(datafile:json)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        optimizely = nil
        
    }

    func testTypedAudience() {
//        let variation = try? optimizely?.activate(experimentKey: "typed_audience_experiment", userId: "userId", attributes: ["doubleKey":5])
        let variation = try? optimizely?.activate(experimentKey: "typed_audience_experiment_with_and", userId: "userId")

        XCTAssertNil(variation as Any?, "no variation found")

    }
    
    func testTypedAudienceThroughProject() {
        //        let variation = try? optimizely?.activate(experimentKey: "typed_audience_experiment", userId: "userId", attributes: ["doubleKey":5])
        let answer = try? optimizely?.config?.project.evaluateAudience(audienceId: "3468206643", attributes: ["booleanKey":true])
        XCTAssertTrue(answer!!)
        
    }

//
//    func testBasicExperiment() {
//        let basicVariation = try? optimizely?.activate(experimentKey: "basic_experiment", userId: "userId")
//
//        XCTAssertNotNil(basicVariation!, "no variation found")
//    }
    
    func testLoadingTestJson() {
        let filesSupported = ["ab_experiments",
            "audience_targeting",
            "bot_filtering_enabled",
            "bucketing_id",
            "empty_datafile",
            "feature_exp",
            "feature_experiments",
            "feature_flag",
            "feature_management_experiment_bucketing",
            "feature_rollouts",
            "feature_variables",
            "forced_variation",
            "grouped_experiments",
            "rollout_bucketing",
            "simple_datafile"
        ]
        
        let filesNotSupported = [
            "unsupported_datafile"
        ]

        for file in filesSupported {
            let optimizely = OTUtils.createOptimizely(datafileName: file, clearUserProfileService: true)
            XCTAssertNotNil(optimizely)
        }
        
        for file in filesNotSupported {
            let optimizely = OTUtils.createOptimizely(datafileName: file, clearUserProfileService: true)
            XCTAssertNil(optimizely)
        }
    }
    
    func testActivateWithInvalidAttribute() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting", clearUserProfileService: true)
        
        /*
         experiment_key: ab_running_exp_typed_audiences_gt_41_and_lt_43
         user_id: test_user_1
         attributes:
         i_42: false
         */
        let variation = try? optimizely?.activate(experimentKey:
            "ab_running_exp_typed_audiences_gt_41_and_lt_43",
                                                  userId: "test_user_1",
                                                  attributes:
            ["i_42": false])
        
        XCTAssertNil(variation as Any?)
    }

    func testActivateWithEmptyConditions() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting", clearUserProfileService: true)
        
        /*
         "experiment_key": "ab_running_exp_audience_combo_empty_conditions",
         "user_id": "test_user_1",
         "attributes": {
         "s_foo": "foo",
         "b_true": "N/A",
         "i_42": 44,
         "d_4_2": "N/A"

         */
        let variation = try? optimizely?.activate(experimentKey:
            "ab_running_exp_audience_combo_empty_conditions",
                                                  userId: "test_user_1",
                                                  attributes:
            ["s_foo": "foo",
             "b_true": "N/A",
             "i_42": 44,
             "d_4_2": "N/A"])
        
        XCTAssertEqual(variation, "all_traffic_variation")
    }

    func testGetExperimentGetVariation() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting", clearUserProfileService: true)
        
        let experiment:Experiment? = optimizely?.config?.getExperiment(key: "ab_running_exp_audience_combo_empty_conditions")
        
        XCTAssertNotNil(experiment)

        let ex2 = optimizely?.config?.getExperiment(id: experiment!.id)
        
        XCTAssert(experiment == ex2)
        
        XCTAssert(ex2!.id == optimizely?.config?.getExperimentId(key: experiment!.key))
        
        
        let event = optimizely?.config?.project.events.first
        
        let evId = optimizely?.config?.getEventId(key: event!.key)
        
        XCTAssert(event!.id == evId)
        
        let variation = experiment?.getVariation(key: "all_traffic_variation")
        
        XCTAssertNotNil(variation)

        let var2 = ex2?.getVariation(id: variation!.id)
        
        XCTAssert(variation == var2)
        
        let audience = optimizely?.config?.project.audiences.first
        
        let aud2 = optimizely?.config?.getAudience(id: audience!.id)
        
        XCTAssert(audience == aud2)
    }

//    func testPerformanceInitialize() {
//        // This is an example of a performance test case.
//        measure {
//            let optimizely = OptimizelyManager(sdkKey: "SDKKEY")
//            
//            try? optimizely.initializeSDK(datafile:json)
//        }
//    }
//
////    func testPerformanceBasicExperiment() {
////        // This is an example of a performance test case.
////        self.measure {
////            // Put the code you want to measure the time of here.
////            testBasicExperiment()
////        }
////    }
//    func testPerformanceTypedAudience() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//            for _ in 0...100 {
//              testTypedAudience()
//            }
//        }
//    }

}
