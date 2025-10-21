//
// Copyright 2025, Optimizely, Inc. and contributors 
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

struct CmabDecision {
    let variationId: String
    let cmabUUID: String
}

struct CmabCacheValue {
    let attributesHash: String
    let variationId: String
    let cmabUUID: String
}

typealias CmabDecisionCompletionHandler = (Result<CmabDecision, Error>) -> Void

protocol CmabService {
    func getDecision(config: ProjectConfig,
                     userContext: OptimizelyUserContext,
                     ruleId: String,
                     options: [OptimizelyDecideOption]) -> Result<CmabDecision, Error>
    func getDecision(config: ProjectConfig,
                     userContext: OptimizelyUserContext,
                     ruleId: String,
                     options: [OptimizelyDecideOption],
                     completion: @escaping CmabDecisionCompletionHandler)
}

class DefaultCmabService: CmabService {
    typealias UserAttributes = [String : Any?]
    
    private let cmabClient: CmabClient
    private let cmabCache: LruCache<String, CmabCacheValue>
    private let logger = OPTLoggerFactory.getLogger()
    
    private static let NUM_LOCKS = 1000
    private let locks: [NSLock]
    
    init(cmabClient: CmabClient, cmabCache: LruCache<String, CmabCacheValue>) {
        self.cmabClient = cmabClient
        self.cmabCache = cmabCache
        self.locks = (0..<Self.NUM_LOCKS).map { _ in NSLock() }
    }
    
    private func getLockIndex(userId: String, ruleId: String) -> Int {
        let combinedKey = userId + ruleId
        let hashValue = combinedKey.hashValue
        // Take absolute value to ensure positive number
        let positiveHash = abs(hashValue)
        // Use modulo to map to lock array index [0, NUM_LOCKS-1]
        return positiveHash % Self.NUM_LOCKS
    }
    
    func getDecision(config: ProjectConfig,
                     userContext: OptimizelyUserContext,
                     ruleId: String,
                     options: [OptimizelyDecideOption]) -> Result<CmabDecision, Error> {
        let lockIdx = getLockIndex(userId: userContext.userId, ruleId: ruleId)
        let lock = locks[lockIdx]
        return lock.withLock {
            var result: Result<CmabDecision, Error>!
            let semaphore = DispatchSemaphore(value: 0)
            getDecision(config: config,
                        userContext: userContext,
                        ruleId: ruleId, options: options) { _result in
                result = _result
                semaphore.signal()
            }
            semaphore.wait()
            return result
        }
    }
    
    func getDecision(config: ProjectConfig,
                     userContext: OptimizelyUserContext,
                     ruleId: String,
                     options: [OptimizelyDecideOption],
                     completion: @escaping CmabDecisionCompletionHandler) {
        
        let filteredAttributes = filterAttributes(config: config, attributes: userContext.attributes, ruleId: ruleId)
        
        let userId = userContext.userId
        
        if options.contains(.ignoreCmabCache) {
            self.logger.i("Ignoring CMAB cache.")
            fetchDecision(ruleId: ruleId, userId: userId, attributes: filteredAttributes, completion: completion)
            return
        }
        
        if options.contains(.resetCmabCache) {
            self.logger.i("Resetting CMAB cache.")
            cmabCache.reset()
        }
        
        let cacheKey = getCacheKey(userId: userId, ruleId: ruleId)
        
        if options.contains(.invalidateUserCmabCache) {
            self.logger.i("Invalidating user CMAB cache.")
            self.cmabCache.remove(key: cacheKey)
        }
        
        let attributesHash = hashAttributes(filteredAttributes)
        
        if let cachedValue = cmabCache.lookup(key: cacheKey), cachedValue.attributesHash == attributesHash {
            let decision = CmabDecision(variationId: cachedValue.variationId, cmabUUID: cachedValue.cmabUUID)
            self.logger.i("Returning cached CMAB decision.")
            completion(.success(decision))
            return
        } else {
            self.logger.i("CMAB decision not found in cache.")
            cmabCache.remove(key: cacheKey)
        }
        
        fetchDecision(ruleId: ruleId, userId: userId, attributes: filteredAttributes) { result in
            if case .success(let decision) = result {
                let cacheValue = CmabCacheValue(
                    attributesHash: attributesHash,
                    variationId: decision.variationId,
                    cmabUUID: decision.cmabUUID
                )
                self.logger.i("Featched CMAB decision and cached it.")
                self.cmabCache.save(key: cacheKey, value: cacheValue)
            }
            completion(result)
        }
    }
    
    private func fetchDecision(ruleId: String,
                               userId: String,
                               attributes: UserAttributes,
                               completion: @escaping CmabDecisionCompletionHandler) {
        let cmabUUID = UUID().uuidString
        cmabClient.fetchDecision(ruleId: ruleId, userId: userId, attributes: attributes, cmabUUID: cmabUUID) { result in
            switch result {
                case .success(let variaitonId):
                    self.logger.i("Fetched CMAB decision: \(variaitonId)")
                    let decision = CmabDecision(variationId: variaitonId, cmabUUID: cmabUUID)
                    completion(.success(decision))
                case .failure(let error):
                    self.logger.e("Failed to fetch CMAB decision: \(error)")
                    completion(.failure(error))
            }
        }
    }
    
    func getCacheKey(userId: String, ruleId: String) -> String {
        return "\(userId.count)-\(userId)-\(ruleId)"
    }
    
    func hashAttributes(_ attributes: UserAttributes) -> String {
        // Sort and serialize as array of [key, value] pairs for deterministic output
        let sortedPairs = attributes.sorted { $0.key < $1.key }
            .map { [$0.key, $0.value] }
        guard let data = try? JSONSerialization.data(withJSONObject: sortedPairs, options: []) else {
            return ""
        }
        let hash = MurmurHash3.hash32Bytes(key: [UInt8](data), maxBytes: data.count)
        return String(format: "%08x", hash)
    }
    
    private func filterAttributes(config: ProjectConfig,
                                  attributes: UserAttributes,
                                  ruleId: String) -> UserAttributes {
        let userAttributes = attributes
        var filteredUserAttributes: UserAttributes = [:]
        
        guard let experiment = config.getExperiment(id: ruleId), let cmab = experiment.cmab else {
            return filteredUserAttributes
        }
        
        let cmabAttributeIds = cmab.attributeIds
        for attributeId in cmabAttributeIds {
            if let attribute = config.getAttribute(id: attributeId), let value = userAttributes[attribute.key] {
                filteredUserAttributes[attribute.key] = value
            }
        }
        return filteredUserAttributes
    }
}

extension DefaultCmabService {
    static func createDefault() -> DefaultCmabService {
        let DEFAULT_CMAB_CACHE_TIMEOUT = 30 * 60 * 1000  // 30 minutes in milliseconds
        let DEFAULT_CMAB_CACHE_SIZE = 1000
        let cache = LruCache<String, CmabCacheValue>(size: DEFAULT_CMAB_CACHE_SIZE, timeoutInSecs: DEFAULT_CMAB_CACHE_TIMEOUT)
        return DefaultCmabService(cmabClient: DefaultCmabClient(), cmabCache: cache)
    }
}
