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
import XCTest

class OTUtils {
    
    static func isEqualWithEncodeThenDecode<T: Codable & Equatable>(_ model: T) -> Bool {
        let jsonData = try! JSONEncoder().encode(model)
        let modelExp = try! JSONDecoder().decode(T.self, from: jsonData)
        return modelExp == model
    }
    
    static func getAttributeValueFromNative(_ value: Any?) throws -> AttributeValue {
        // JSONEncoder does not support fragmented JSON format (string alone), so wrap in an array
        let json: [Any?] = [value]
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        let modelArray = try JSONDecoder().decode([AttributeValue].self, from: jsonData)
        return modelArray[0]
    }
    
    static func jsonDataFromNative(_ raw: Any) -> Data {
        return try! JSONSerialization.data(withJSONObject: raw, options: [])
    }
    
    static func jsonStringFromNative(_ raw: Any) -> String {
        return String(data: jsonDataFromNative(raw), encoding: .utf8)!
    }
    
    static var emptyDatafile = """
            {
                "version": "4",
                "rollouts": [],
                "anonymizeIP": true,
                "projectId": "10431130345",
                "variables": [],
                "featureFlags": [],
                "experiments": [],
                "audiences": [],
                "groups": [],
                "attributes": [],
                "accountId": "10367498574",
                "events": [],
                "revision": "241"
            }
        """
    
    static func model<T: Codable>(from raw: Any) throws -> T {
        return try JSONDecoder().decode(T.self, from: jsonDataFromNative(raw))
    }
    
    static func model<T: Codable>(fromData data: Data) throws -> T {
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    static func loadJSONDatafile(_ filename: String) -> Data? {
        guard let filePath = Bundle(for: self).path(forResource: filename, ofType: "json") else {
            return nil
        }
        
        do {
            let fileContents = try String(contentsOfFile: filePath)
            return fileContents.data(using: .utf8)
        } catch {
            return nil
        }
    }
    
    static func createClearUserProfileService() -> DefaultUserProfileService {
        let ups = DefaultUserProfileService()
        ups.reset()
        return ups
    }
    
    static func createOptimizely(datafileName: String,
                                 clearUserProfileService: Bool,
                                 eventProcessor: OPTEventsProcessor?,
                                 eventDispatcher: OPTEventsDispatcher?) -> OptimizelyClient? {
        
        guard let datafile = OTUtils.loadJSONDatafile(datafileName) else { return nil }
        let userProfileService = clearUserProfileService ? createClearUserProfileService() : nil
        
        // use random sdkKey to avoid registration conflicts when multiple tests running in parallel
        
        OptimizelyClient.clearRegistryService()
        let optimizely = OptimizelyClient(sdkKey: randomSdkKey,
                                          eventProcessor: eventProcessor,
                                          eventDispatcher: eventDispatcher,
                                          userProfileService: userProfileService)
        do {
            try optimizely.start(datafile: datafile, doFetchDatafileBackground: false)
            return optimizely
        } catch {
            return nil
        }
    }
    
    static func createOptimizely(datafileName: String,
                                 clearUserProfileService: Bool,
                                 eventDispatcher: OPTEventDispatcher) -> OptimizelyClient? {
        
        guard let datafile = OTUtils.loadJSONDatafile(datafileName) else { return nil }
        let userProfileService = clearUserProfileService ? createClearUserProfileService() : nil
        
        // use random sdkKey to avoid registration conflicts when multiple tests running in parallel
        
        OptimizelyClient.clearRegistryService()
        let optimizely = OptimizelyClient(sdkKey: randomSdkKey,
                                          eventDispatcher: eventDispatcher,
                                          userProfileService: userProfileService)
        do {
            try optimizely.start(datafile: datafile, doFetchDatafileBackground: false)
            return optimizely
        } catch {
            return nil
        }
    }
    
    // MARK: - big numbers
    
    static var positiveMaxValueAllowed: Double {
        return pow(2, 53)
    }
    
    static var negativeMaxValueAllowed: Double {
        return -pow(2, 53)
    }
    
    static var positiveTooBigValue: Double {
        return positiveMaxValueAllowed * 2.0
    }
    
    static var negativeTooBigValue: Double {
        return negativeMaxValueAllowed * 2.0
    }
    
    static func saveAFile(name:String, data:Data) -> URL? {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(name, isDirectory: false)
            
            try? data.write(to: fileURL, options: .atomic)
            return fileURL
        }
        
        return nil
    }
    
    // MARK: - others
    
    static var randomSdkKey: String {
        return String(arc4random())
    }
    
}

class FakeEventProcessor: OPTEventsProcessor {
    public var events = [UserEvent]()
    required init() {}
    
    func process(event: UserEvent, completionHandler: DispatchCompletionHandler?) {
        events.append(event)
        completionHandler?(.success(Data()))
    }
    
    func flush() {
        events.removeAll()
    }
}

class FakeEventDispatcher: OPTEventsDispatcher {
    public var events = [EventForDispatch]()
    required init() {}

    func dispatch(event: EventForDispatch, completionHandler: DispatchCompletionHandler?) {
        events.append(event)
        completionHandler?(.success(Data()))
    }
}

class FakeLagacyEventDispatcher: OPTEventDispatcher {
    public var events = [EventForDispatch]()
    required init() {}
    
    func dispatchEvent(event: EventForDispatch, completionHandler: DispatchCompletionHandler?) {
        events.append(event)
        completionHandler?(.success(Data()))
    }
    
    /// Attempts to flush the event queue if there are any events to process.
    func flushEvents() {
        events.removeAll()
    }
}
