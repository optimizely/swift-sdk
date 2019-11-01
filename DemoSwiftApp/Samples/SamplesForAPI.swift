/****************************************************************************
 * Copyright 2019, Optimizely, Inc. and contributors                        *
 *                                                                          *
 * Licensed under the Apache License, Version 2.0 (the "License");          *
 * you may not use this file except in compliance with the License.         *
 * You may obtain a copy of the License at                                  *
 *                                                                          *
 *    http://www.apache.org/licenses/LICENSE-2.0                            *
 *                                                                          *
 * Unless required by applicable law or agreed to in writing, software      *
 * distributed under the License is distributed on an "AS IS" BASIS,        *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
 * See the License for the specific language governing permissions and      *
 * limitations under the License.                                           *
 ***************************************************************************/

import Foundation
import Optimizely

class SamplesForAPI {

    static func run() {

        let sdkKey = "AqLkkcss3wRGUbftnKNgh2" // SDK Key for your project
        let datafileName = "demoTestDatafile_" + sdkKey

        // MARK: - initialization
        
        var optimizely: OptimizelyClient
        
        // (1) create SDK client with default SDK settings
        optimizely = OptimizelyClient(sdkKey: sdkKey)
        
        // (2) or create SDK client with a custom logger
        optimizely = OptimizelyClient(sdkKey: sdkKey,
                                      logger: CustomLogger(),
                                      defaultLogLevel: .debug)

        // (3) or create SDK client with a custom UserProfileService
        optimizely = OptimizelyClient(sdkKey: sdkKey,
                                      userProfileService: CustomUserProfileService(),
                                      defaultLogLevel: .debug)

        // (4) or create SDK client with a custom EventProcessor + EventDispatcher or
        let customEventDispatcher = HTTPEventDispatcher()  // or other custom OPTEventsDispatcher class
        let customEventProcessor = BatchEventProcessor(eventDispatcher: customEventDispatcher,  // or other custom OPTEventsProcessor class
                                                       batchSize: 10,
                                                       timerInterval: 60,
                                                       maxQueueSize: 1000)
        optimizely = OptimizelyClient(sdkKey: sdkKey,
                                      logger: nil,
                                      eventProcessor: customEventProcessor,
                                      eventDispatcher: nil,
                                      userProfileService: nil,
                                      periodicDownloadInterval: nil,
                                      defaultLogLevel: .debug)
     
        // (5) or create SDK client with a custom EventDispatcher
        optimizely = OptimizelyClient(sdkKey: sdkKey,
                                      logger: nil,
                                      eventProcessor: nil,
                                      eventDispatcher: customEventDispatcher,
                                      userProfileService: nil,
                                      periodicDownloadInterval: nil,
                                      defaultLogLevel: .debug)

        // MARK: - start
        
        // (1) start SDK synchronously
        do {
            let localDatafilePath = Bundle.main.path(forResource: datafileName, ofType: "json")!
            let datafileJSON = try String(contentsOfFile: localDatafilePath, encoding: .utf8)
            try optimizely.start(datafile: datafileJSON)

            print("[SamplesForAPI] Optimizely SDK initiliazation synchronously------")
            runAPISamples(optimizely)
        } catch {
            print("[SamplesForAPI] Optimizely SDK initiliazation failed: \(error)")
        }
                
        // (2) or start SDK asynchronously
        optimizely.start { result in
                        switch result {
            case .failure(let error):
                print("[SamplesForAPI] Optimizely SDK initiliazation failed: \(error)")
            case .success:
                print("[SamplesForAPI] Optimizely SDK initiliazation asynchronously------")
                runAPISamples(optimizely)
            }
        }
        
    }
    
    static func runAPISamples(_ optimizely: OptimizelyClient) {
        
        let featureKey = "demo_feature"
        let experimentKey = "demo_experiment"
        let variationKey = "variation_a"
        let variableKey = "discount"
        let eventKey = "sample_conversion"
        let userId = "user_123"

        let attributes: [String: Any] = [
            "browser": "iPhone",
            "lifetime": 24738388,
            "is_logged_in": true
            ]
        let tags: [String: Any] = [
            "category": "shoes",
            "count": 2
            ]
        
        // MARK: - activate

        do {
            let variationKey = try optimizely.activate(experimentKey: experimentKey,
                                                       userId: userId,
                                                       attributes: attributes)
            print("[SamplesForAPI][activate] \(variationKey)")
        } catch {
            print("[SamplesForAPI][activate] \(error)")
        }

        // MARK: - getVariationKey

        do {
            let variationKey = try optimizely.getVariationKey(experimentKey: experimentKey,
                                                              userId: userId,
                                                              attributes: attributes)
            print("[SamplesForAPI][getVariationKey] \(variationKey)")
        } catch {
            print("[SamplesForAPI][getVariationKey] \(error)")
        }

        // MARK: - getForcedVariation

        if let variationKey = optimizely.getForcedVariation(experimentKey: experimentKey, userId: userId) {
            print("[SamplesForAPI][getForcedVariation] \(variationKey)")
        }

        // MARK: - setForcedVariation

        if optimizely.setForcedVariation(experimentKey: experimentKey,
                                         userId: userId,
                                         variationKey: variationKey) {
            print("[SamplesForAPI][setForcedVariation]")
        }

        // MARK: - isFeatureEnabled

        let enabled = optimizely.isFeatureEnabled(featureKey: featureKey,
                                                          userId: userId,
                                                          attributes: attributes)
        print("[SamplesForAPI][isFeatureEnabled] \(enabled)")

        // MARK: - getFeatureVariable

        do {
            let featureVariableValue = try optimizely.getFeatureVariableInteger(featureKey: featureKey,
                                                                                variableKey: variableKey,
                                                                                userId: userId,
                                                                                attributes: attributes)
            print("[SamplesForAPI][getFeatureVariableDouble] \(featureVariableValue)")
        } catch {
            print("[SamplesForAPI][getFeatureVariableDouble] \(error)")
        }

        // MARK: - getEnabledFeatures

        let enabledFeatures = optimizely.getEnabledFeatures(userId: userId, attributes: attributes)
        print("[SamplesForAPI][getEnabledFeatures] \(enabledFeatures)")

        // MARK: - track

        do {
            try optimizely.track(eventKey: eventKey, userId: userId, attributes: attributes, eventTags: tags)
            print("[SamplesForAPI][track]")
        } catch {
            print("[SamplesForAPI][track] \(error)")
        }
    }

}
