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

typealias CmabCache = LruCache<String, CmabCacheValue>

class DefaultCmabService: CmabService {
    typealias UserAttributes = [String: Any?]
    
    let cmabClient: CmabClient
    let cmabCache: CmabCache
    private let logger = OPTLoggerFactory.getLogger()
    
    private static let NUM_LOCKS = 1000
    private let locks: [NSLock]
    
    init(cmabClient: CmabClient, cmabCache: CmabCache) {
        self.cmabClient = cmabClient
        self.cmabCache = cmabCache
        self.locks = (0..<Self.NUM_LOCKS).map { _ in NSLock() }
    }
    
    private func getLockIndex(userId: String, ruleId: String) -> Int {
        let combinedKey = userId + ruleId
        let hashValue = MurmurHash3.hash32(key: combinedKey)
        let lockIndex = Int(hashValue) % Self.NUM_LOCKS
        return lockIndex
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
            self.logger.i("Ignoring CMAB cache for user \(userId) and rule \(ruleId)")
            fetchDecision(ruleId: ruleId, userId: userId, attributes: filteredAttributes, completion: completion)
            return
        }
        
        if options.contains(.resetCmabCache) {
            self.logger.i("Resetting CMAB cache for user \(userId) and rule \(ruleId)")
            cmabCache.reset()
        }
        
        let cacheKey = getCacheKey(userId: userId, ruleId: ruleId)
        
        if options.contains(.invalidateUserCmabCache) {
            self.logger.i("Invalidating CMAB cache for user \(userId) and rule \(ruleId)")
            self.cmabCache.remove(key: cacheKey)
        }
        
        let attributesHash = hashAttributes(filteredAttributes)
        
        if let cachedValue = cmabCache.lookup(key: cacheKey) {
            if cachedValue.attributesHash == attributesHash {
                let decision = CmabDecision(variationId: cachedValue.variationId, cmabUUID: cachedValue.cmabUUID)
                self.logger.i("CMAB cache hit for user \(userId) and rule \(ruleId)")
                completion(.success(decision))
                return
            } else {
                self.logger.i("CMAB cache attributes mismatch for user \(userId) and rule \(ruleId), fetching new decision")
                cmabCache.remove(key: cacheKey)
            }
            
        } else {
            self.logger.i("CMAB cache miss for user \(userId) and rule \(ruleId)")
        }
        
        fetchDecision(ruleId: ruleId, userId: userId, attributes: filteredAttributes) { result in
            if case .success(let decision) = result {
                let cacheValue = CmabCacheValue(
                    attributesHash: attributesHash,
                    variationId: decision.variationId,
                    cmabUUID: decision.cmabUUID
                )
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
                    let decision = CmabDecision(variationId: variaitonId, cmabUUID: cmabUUID)
                    self.logger.i("Featched CMAB decision, (variationId: \(decision.variationId), cmabUUID: \(decision.cmabUUID))")
                    completion(.success(decision))
                case .failure(let error):
                    self.logger.e("Failed to fetch CMAB decision, error: \(error)")
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
        let cache = CmabCache(size: DEFAULT_CMAB_CACHE_SIZE, timeoutInSecs: DEFAULT_CMAB_CACHE_TIMEOUT)
        return DefaultCmabService(cmabClient: DefaultCmabClient(), cmabCache: cache)
    }

    static func createDefault(config: CmabConfig) -> DefaultCmabService {
        // if cache timeout is set to 0 or negative, use default timeout
        let timeout = config.cacheTimeoutInSecs <= 0 ? DEFAULT_CMAB_CACHE_TIMEOUT : config.cacheTimeoutInSecs
        let cache = CmabCache(size: config.cacheSize, timeoutInSecs: timeout)
        return DefaultCmabService(cmabClient: DefaultCmabClient(predictionEndpoint: config.predictionEndpoint), cmabCache: cache)
    }
}
