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

@objc public class OTUtils: NSObject {
    
    @objc public static func clearRegistryService() {
        HandlerRegistryService.shared.removeAll()
    }
   
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
    
    // use EventProcessor + EventDispatcher
    static func createOptimizely(sdkKey: String? = nil,
                                 datafileName: String,
                                 clearUserProfileService: Bool,
                                 eventProcessor: OPTEventsProcessor? = nil,
                                 eventDispatcher: OPTEventsDispatcher? = nil) -> OptimizelyClient? {
        
        prepareDocumentFolderInSimulator()
        
        // use random sdkKey to avoid registration conflicts when multiple tests running in parallel
        let sdkKey = sdkKey ?? randomSdkKey
        
        //-------------------------------------------------------------------
        // reset previous services so that new EP (No SDKKey) can be registered OK
        //-------------------------------------------------------------------
        OTUtils.clearRegistryService()

        let userProfileService = clearUserProfileService ? createClearUserProfileService() : nil
        
        let optimizely = OptimizelyClient(sdkKey: sdkKey,
                                          eventProcessor: eventProcessor,
                                          eventDispatcher: eventDispatcher,
                                          userProfileService: userProfileService)

        do {
            guard let datafile = OTUtils.loadJSONDatafile(datafileName) else { return nil }
            try optimizely.start(datafile: datafile, doFetchDatafileBackground: false)

            return optimizely
        } catch {
            return nil
        }
    }
    
    // use legacy EventDispatcher
    static func createOptimizelyLegacy(sdkKey: String? = nil,
                                       datafileName: String,
                                       clearUserProfileService: Bool,
                                       eventDispatcher: OPTEventDispatcher) -> OptimizelyClient? {
        
        prepareDocumentFolderInSimulator()

        // use random sdkKey to avoid registration conflicts when multiple tests running in parallel
        let sdkKey = sdkKey ?? randomSdkKey

        //-------------------------------------------------------------------
        // reset previous services so that new EP (No SDKKey) can be registered OK
        //-------------------------------------------------------------------
        OTUtils.clearRegistryService()

        let userProfileService = clearUserProfileService ? createClearUserProfileService() : nil
        
        let optimizely = OptimizelyClient(sdkKey: sdkKey,
                                          eventDispatcher: eventDispatcher,
                                          userProfileService: userProfileService)
        do {
            guard let datafile = OTUtils.loadJSONDatafile(datafileName) else { return nil }
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
    
    // iOS11+ simulators do not have Document folder by default when launched.
    // Should be created manually.
    static func prepareDocumentFolderInSimulator() {
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            if (!FileManager.default.fileExists(atPath: url.path)) {
                do {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    // MARK: - others
    
    static var randomSdkKey: String {
        return String(arc4random())
    }
    
    static let keyTestEventFileName = "EventProcessorTests-Batch---"
    static var uniqueEventFileName: String {
        return keyTestEventFileName + randomSdkKey
    }
    
    static func cleanupTestEventFiles() {
        // remove all event files used for testing
        
        let fm = FileManager.default
        let docFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let allFiles = try! fm.contentsOfDirectory(atPath: docFolder)
        
        let predicate = NSPredicate(format: "self CONTAINS '\(OTUtils.keyTestEventFileName)'")
        let filtered = allFiles.filter { predicate.evaluate(with: $0) }
        
        filtered.forEach {
            do {
                try fm.removeItem(atPath: (docFolder as NSString).appendingPathComponent($0))
                print("[EventBatchTest] Removed temporary event file: \($0)")
            } catch {
                print("[EventBatchTest] ERROR: cannot remove temporary event file: \($0)")
            }
        }
    }
}

// MARK: - Test EventProcessor + EventDispatcher

class TestableBatchEventProcessor: BatchEventProcessor {
    let eventFileName: String
    
    init(eventDispatcher: OPTEventsDispatcher,
         eventFileName: String? = nil,
         removeDatafileObserver: Bool = true,
         disableBatch: Bool = false)
    {
        self.eventFileName = eventFileName ?? OTUtils.uniqueEventFileName
        
        if disableBatch {
            super.init(eventDispatcher: eventDispatcher,
                       batchSize: 1,
                       dataStoreName: self.eventFileName)
        } else {
            super.init(eventDispatcher: eventDispatcher,
                       dataStoreName: self.eventFileName)
        }
        
        print("[TestableEventProcessor] init with [\(self.eventFileName)] ")

        // block interference from other tests notifications when testing batch timing
        if removeDatafileObserver {
            removeProjectChangeNotificationObservers()
        }
    }
    
    override func process(event: UserEvent, completionHandler: DispatchCompletionHandler?) {
        super.process(event: event, completionHandler: completionHandler)
    }
}

class TestableHTTPEventDispatcher: HTTPEventDispatcher {
    var sendRequestedEvents: [EventForDispatch] = []
    var forceError = false
    var numReceivedVisitors = 0

    // set this if need to wait sendEvent completed
    var exp: XCTestExpectation?
    
    override func dispatch(event: EventForDispatch, completionHandler: DispatchCompletionHandler?) {
        sendRequestedEvents.append(event)
        
        do {
            let decodedEvent = try JSONDecoder().decode(BatchEvent.self, from: event.body)
            numReceivedVisitors += decodedEvent.visitors.count
            print("[TestableEventProcessor][SendEvent] Received a batched event with visitors: \(decodedEvent.visitors.count) \(numReceivedVisitors)")
        } catch {
            // invalid event format detected
            // - invalid events are supposed to be filtered out when batching (converting to nil, so silently dropped)
            // - an exeption is that an invalid event is alone in the queue, when validation is skipped for performance on common path
            
            // pass through invalid events, so server can filter them out
        }

        // must call completionHandler to complete synchronization
        super.dispatch(event: event) { _ in
            if self.forceError {
                completionHandler?(.failure(.eventDispatchFailed("forced")))
            } else {
                // return success to clear store after sending events
                completionHandler?(.success(Data()))
            }

            self.exp?.fulfill()
        }
    }
    
    func clear() {
        super.clear()
        sendRequestedEvents = []
        numReceivedVisitors = 0
    }
}

// MARK: - Test DefaultEventDispatcher

class TestableDefaultEventDispatcher: DefaultEventDispatcher {
    var sendRequestedEvents: [EventForDispatch] = []
    var forceError = false
    var numReceivedVisitors = 0
    let eventFileName: String
    
    // set this if need to wait sendEvent completed
    var exp: XCTestExpectation?
    
    init(eventFileName: String? = nil,
         removeDatafileObserver: Bool = true,
         disableBatch: Bool = false) {
        
        self.eventFileName = eventFileName ?? OTUtils.uniqueEventFileName
        if disableBatch {
            super.init(batchSize: 1, dataStoreName: self.eventFileName)
        } else {
            super.init(dataStoreName: self.eventFileName)
        }
        
        // block interference from other tests notifications when testing batch timing
        if removeDatafileObserver {
            removeProjectChangeNotificationObservers()
        }
    }
    
    override func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
        sendRequestedEvents.append(event)
        
        do {
            let decodedEvent = try JSONDecoder().decode(BatchEvent.self, from: event.body)
            numReceivedVisitors += decodedEvent.visitors.count
            print("[TestableEventDispatcher][SendEvent][\(self.eventFileName)] Received a batched event with visitors: \(decodedEvent.visitors.count) \(numReceivedVisitors)")
        } catch {
            // invalid event format detected
            // - invalid events are supposed to be filtered out when batching (converting to nil, so silently dropped)
            // - an exeption is that an invalid event is alone in the queue, when validation is skipped for performance on common path
            
            // pass through invalid events, so server can filter them out
        }

        // must call completionHandler to complete synchronization
        super.sendEvent(event: event) { _ in
            if self.forceError {
                completionHandler(.failure(.eventDispatchFailed("forced")))
            } else {
                // return success to clear store after sending events
                completionHandler(.success(Data()))
            }

            self.exp?.fulfill()
        }
    }
}

// MARK: - Mock EventProcessor + EventDispatcher

class MockEventProcessor: OPTEventsProcessor {
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

class MockEventDispatcher: OPTEventsDispatcher {
    public var events = [EventForDispatch]()
    required init() {}

    func dispatch(event: EventForDispatch, completionHandler: DispatchCompletionHandler?) {
        events.append(event)
        completionHandler?(.success(Data()))
    }
    
    func clear() {
        events = []
    }
}

// MARK: - Mock Legacy EventDispatcher

class MockLagacyEventDispatcher: OPTEventDispatcher {
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
