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

import Foundation
import XCTest

class OTUtils {
    
    static let testSdkKeyBasename = "testSdkKey"

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
    
    static var sampleEvent = """
            {
                "revision":"1001",
                "account_id":"11111",
                "client_version":"3.1.2",
                "visitors":[
                    {"attributes":[],"snapshots":[],"visitor_id":"123"}
                ],
                "enrich_decisions":true,
                "project_id":"33331",
                "client_name":"swift-sdk",
                "anonymize_ip":true
            }
        """
    
    static func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
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
    
    static func loadJSONDatafileString(_ filename: String) -> String? {
        guard let data = loadJSONDatafile(filename) else { return nil }
        return String(bytes: data, encoding: .utf8)
    }
    
    static func loadJSONFile(_ filename: String) -> Data? {
        return loadJSONDatafile(filename)
    }

    static func createClearUserProfileService() -> DefaultUserProfileService {
        let ups = DefaultUserProfileService()
        ups.reset()
        return ups
    }
    
    static func createOptimizely(datafileName: String,
                                 clearUserProfileService: Bool,
                                 eventDispatcher: OPTEventDispatcher?=nil,
                                 logger: OPTLogger?=nil) -> OptimizelyClient? {
        
        guard let datafile = OTUtils.loadJSONDatafile(datafileName) else { return nil }
        let userProfileService = clearUserProfileService ? createClearUserProfileService() : nil
        
        // use random sdkKey to avoid registration conflicts when multiple tests running in parallel
        
        let optimizely = OptimizelyClient(sdkKey: randomSdkKey,
                                          logger: logger,
                                          eventDispatcher: eventDispatcher,
                                          userProfileService: userProfileService)
        do {
            try optimizely.start(datafile: datafile, doFetchDatafileBackground: false)
            return optimizely
        } catch {
            return nil
        }
    }
    
    // MARK: - HandlerRegistryService
    
    static func bindLoggerForTest(_ level: OptimizelyLogLevel? = nil) {
        if let level = level {
            DefaultLogger.logLevel = level
        }
        let logger = DefaultLogger()

        let binder: Binder = Binder<OPTLogger>(service: OPTLogger.self, factory: type(of: logger).init)
        HandlerRegistryService.shared.registerBinding(binder: binder)
    }
    
    static func clearAllBinders() {
        HandlerRegistryService.shared.binders.property?.removeAll()
    }

    // MARK: - storage
    
    static func clearAllTestStorage(including: String? = nil) {
        clearAllDataFiles(including: including)
        clearAllEventQueues()
        clearAllLastModifiedData()
        clearAllUPS()
    }

    // MARK: - UPS
    
    static func getVariationFromUPS(ups: OPTUserProfileService, userId: String, experimentId: String) -> String? {
        if let profile = ups.lookup(userId: userId),
            let bucketMap = profile[UserProfileKeys.kBucketMap] as? OPTUserProfileService.UPBucketMap,
            let experimentMap = bucketMap[experimentId],
            let variationId = experimentMap[UserProfileKeys.kVariationId] {
            return variationId
        } else {
            return nil
        }
    }
    
    static func setVariationToUPS(ups: OPTUserProfileService, userId: String, experimentId: String, variationId: String){
        var profile = ups.lookup(userId: userId) ?? OPTUserProfileService.UPProfile()
        
        var bucketMap = profile[UserProfileKeys.kBucketMap] as? OPTUserProfileService.UPBucketMap ?? OPTUserProfileService.UPBucketMap()
        bucketMap[experimentId] = [UserProfileKeys.kVariationId: variationId]
        
        profile[UserProfileKeys.kBucketMap] = bucketMap
        profile[UserProfileKeys.kUserId] = userId
        
        ups.save(userProfile: profile)
    }
    
    static func clearAllUPS() {
        UserDefaults.standard.removeObject(forKey: "user-profile-service")
    }
    
    // MARK: - events
    
    static func makeEventForDispatch(url: String? = nil, event: BatchEvent? = nil) -> EventForDispatch {
        let targetUrl = URL(string: url ?? "https://a.b.c")
        let data = try! JSONEncoder().encode(event ?? makeTestBatchEvent())
        return EventForDispatch(url: targetUrl, body: data)
    }
    
    static func makeTestBatchEvent(projectId: String? = nil, revision: String? = nil, visitor: Visitor? = nil) -> BatchEvent {
        let testProjectId = projectId ?? "12345"
        let testVisitor = visitor ?? Visitor(attributes: [], snapshots: [], visitorID: "tester")
        let testRevision = revision ?? "101"
        
        return BatchEvent(revision: testRevision,
                          accountID: "1234",
                          clientVersion: "1.0.0",
                          visitors: [testVisitor],
                          projectID: testProjectId,
                          clientName: "test",
                          anonymizeIP: true,
                          enrichDecisions: true)
    }
    
    static func clearAllEventQueues() {
        removeAllFiles(including: "OPTEventQueue", in: .documentDirectory)
        removeAllFiles(including: "OPTEventQueue", in: .cachesDirectory)
    }

    // MARK: - datafiles
    
    static func createDatafileCache(sdkKey: String, contents: String? = nil) {
        let data = (contents ?? "datafile-for-\(sdkKey)").data(using: .utf8)!
        _ = saveAFile(name: sdkKey, data: data)
    }
    
    static func clearAllDataFiles(including: String? = nil) {
        removeAllFiles(including: including, in: .documentDirectory)
        removeAllFiles(including: including, in: .cachesDirectory)
    }
    
    static func removeAllFiles(including: String? = nil, in directory: FileManager.SearchPathDirectory) {
        if let docUrl = FileManager.default.urls(for: directory, in: .userDomainMask).first {
            if let names = try? FileManager.default.contentsOfDirectory(atPath: docUrl.path) {
                names.forEach{ name in
                    if name.contains(including ?? testSdkKeyBasename) {
                        let fileUrl = docUrl.appendingPathComponent(name)
                        do {
                            try FileManager.default.removeItem(at: fileUrl)
                            //print("[OTUtils] removed file: '\(name)' from '\(directory)' directory")
                        } catch {
                            //print("[OTUtils] removing file failed for '\(name)' from '\(directory)' directory: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    static func clearAllLastModifiedData() {
        removeAllUserDefaults(including: "LastModified")
    }

    // MARK: - files
    
    static func saveAFile(name: String, data: Data) -> URL? {
        let ds = DataStoreFile<Data>(storeName: name, async: false)
        ds.saveItem(forKey: name, value: data)
        
        return ds.url
    }

    static func removeAFile(name: String) -> URL? {
        let ds = DataStoreFile<Data>(storeName: name, async: false)
        ds.removeItem(forKey: name)
        
        return ds.url
    }
    
    static func createDocumentDirectoryIfNotAvailable() {
        // documentDirectory may not exist for simulator unit test (iOS11+). create it if not found.
        
        #if os(tvOS)
        let directory = FileManager.SearchPathDirectory.cachesDirectory
        #else
        let directory = FileManager.SearchPathDirectory.documentDirectory
        #endif
        
        if let url = FileManager.default.urls(for: directory, in: .userDomainMask).first {
            if (!FileManager.default.fileExists(atPath: url.path)) {
                do {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    // MARK: - UserDefaults
    
    static func removeAllUserDefaults(including: String) {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        allKeys.filter{ $0.contains(including) }.forEach{ itemKey in
            UserDefaults.standard.removeObject(forKey: itemKey)
            //print("[OTUtils] removed UserDefaults: '\(itemKey)'")
        }
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - concurrency
    
    static func runConcurrent(for items: [String],
                              timeoutInSecs: Int = 10,
                              task: @escaping (Int, String) -> Void) -> Bool {
        let group = DispatchGroup()
        
        for (idx, item) in items.enumerated() {
            group.enter()
            
            // NOTE: do not use DispatchQueue.global(), which looks like a deadlock because of too many threads
            DispatchQueue(label: item).async {
                task(idx, item)
                group.leave()
            }
        }
        
        let timeout = DispatchTime.now() + .seconds(timeoutInSecs)
        let result = group.wait(timeout: timeout)
        return result == .success
    }
    
    static func runConcurrent(count: Int,
                              timeoutInSecs: Int = 10,
                              task: @escaping (Int) -> Void) -> Bool {
        let items = (0..<count).map{ String($0) }

        return runConcurrent(for: items, timeoutInSecs: timeoutInSecs) { (idx, item) in
            task(idx)
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
    
    // MARK: - others
    
    static var randomSdkKey: String {
        return "\(testSdkKeyBasename)-\(arc4random())"
    }
    
    static func makeRandomSdkKeys(_ num: Int) -> [String] {
        return (0..<num).map {
            return "\(testSdkKeyBasename)-\($0)-\(arc4random())"
        }
    }

}

