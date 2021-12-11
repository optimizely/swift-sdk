//
// Copyright 2021, Optimizely, Inc. and contributors 
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

protocol DecisionSchema: Encodable {
    func makeLookupInput(user: OptimizelyUserContext) -> String
    var allLookupInputs: [String] { get }
}

extension DecisionSchema {
    func encode(using encoder: JSONEncoder) throws -> Data {
        try encoder.encode(self)
    }
}

// DecisionSchema array wrapper for JSON encoding (since Codable not supported in Protocol)

struct SchemaCollection: Encodable {
    let array: [DecisionSchema]
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for value in array {
            if let schema = value as? BucketDecisionSchema {
                try container.encode(schema)
            } else if let schema = value as? AudienceDecisionSchema {
                try container.encode(schema)
            }
        }
    }
}

// MARK: - BucketDecisionSchema

struct BucketDecisionSchema: DecisionSchema, CustomStringConvertible {
    let type = "bucket"
    let bucketKey: String
    var buckets = [Int]()
    
    let MAX_TRAFFIC_VALUE = 10000
    
    enum CodingKeys: String, CodingKey {
        case type
        case bucketKey
        case buckets
    }
        
    init(bucketKey: String, trafficAllocations: [TrafficAllocation]) {
        self.bucketKey = bucketKey
        
        let collapsed = BucketDecisionSchema.collapseTrafficAllocations(trafficAllocations)
        var ranges = collapsed.map { $0.endOfRange }

        if ranges.isEmpty || (ranges.last! < MAX_TRAFFIC_VALUE) {
            ranges.append(MAX_TRAFFIC_VALUE)
        }
        
        self.buckets = ranges
    }
    
    func makeLookupInput(user: OptimizelyUserContext) -> String {
        let bucketingId = getBucketingId(user: user)
        
        let hashId = makeHashIdFromBucketingId(bucketingId: bucketingId, entityId: bucketKey)
        let bucketValue = generateBucketValue(bucketingId: hashId)

        let index = buckets.enumerated().filter { bucketValue < $0.element }.first?.offset ?? 0
        
        return letterForIndex(index)
    }
    
    var allLookupInputs: [String] {
        return (0..<buckets.count).reversed().map { letterForIndex($0) }
    }
    
    var description: String {
        return "      BucketSchema: \(bucketKey) \(buckets)"
    }
    
    // Utils
    
    // collapse trafficAllocation - merge contiguous ranges for the same bucket
    // [A,A,B,C,C,C,D] -> [A,B,C,D]
    static func collapseTrafficAllocations(_ trafficAllocations: [TrafficAllocation]) -> [TrafficAllocation] {
        var collapsed = [TrafficAllocation]()
        
        var prevEntityId: String?
        var prevEndOfRange = 0
        trafficAllocations.forEach {
            // do not allocate a bucket for "0" range
            guard $0.endOfRange > 0 else { return }
            
            if let prevEntityId = prevEntityId, $0.entityId != prevEntityId {
                collapsed.append(TrafficAllocation(entityId: prevEntityId, endOfRange: prevEndOfRange))
            }
            prevEntityId = $0.entityId
            prevEndOfRange = $0.endOfRange
        }
        if let prevEntityId = prevEntityId {
            collapsed.append(TrafficAllocation(entityId: prevEntityId, endOfRange: prevEndOfRange))
        }

        return collapsed
    }
    
}

// MARK: - AudienceDecisionSchema

struct AudienceDecisionSchema: DecisionSchema, CustomStringConvertible, Encodable {
    let type = "audience"
    let audiences: ConditionHolder
    
    enum CodingKeys: String, CodingKey {
        case type
        case audiences
    }
        
    init(audiences: ConditionHolder) {
        self.audiences = audiences
    }
    
    func makeLookupInput(user: OptimizelyUserContext) -> String {
        var bool = false
        do {
            if let project = user.optimizely?.config?.project {
                bool = try audiences.evaluate(project: project, attributes: user.attributes)
            }
        } catch {
            // print("[DecisionSchema audience evaluation error: \(error)")
        }
        
        return bool ? "1" : "0"
    }
    
    var allLookupInputs: [String] {
        return ["1", "0"]
    }
    
    var description: String {
        return "      AudienceSchema: \(audiences.serialized)"
    }
    
    // Utils
    
    func randomAttributes(optimizely: OptimizelyClient) -> [(String, Any)] {
        let userAttributes = getUserAttributes(optimizely: optimizely,
                                               audiences: audiences)
        return userAttributes.compactMap { $0.randomAttribute }
    }
    
    func getUserAttributes(optimizely: OptimizelyClient, audiences: ConditionHolder) -> [UserAttribute] {
        var userAttributes = [UserAttribute]()
        getUserAttributes(optimizely: optimizely,
                          conditionHolder: audiences,
                          result: &userAttributes)
        
        // print(">>>> \(userAttributes)   \(audiences)")
        return userAttributes
    }
    
    func getUserAttributes(optimizely: OptimizelyClient, conditionHolder: ConditionHolder, result: inout [UserAttribute]) {
        switch conditionHolder {
        case .leaf(let leaf):
            switch leaf {
            case .attribute(let userAttribute):
                result.append(userAttribute)
            case .audienceId(let audienceId):
                if let audience = optimizely.config?.getAudience(id: audienceId) {
                    getUserAttributes(optimizely: optimizely,
                                      conditionHolder: audience.conditionHolder,
                                      result: &result)
                }
            }
        case .array(let array):
            array.forEach {
                getUserAttributes(optimizely: optimizely,
                                  conditionHolder: $0,
                                  result: &result)
            }
        default:
            // print("ignored conditionHolder: \(conditionHolder)")
            break
        }
    }
    
}

// MARK: - ErrorDecisionSchema

struct ErrorDecisionSchema: DecisionSchema, CustomStringConvertible, Encodable {
    let name: String
    
    init(name: String) {
        self.name = name
    }

    func makeLookupInput(user: OptimizelyUserContext) -> String {
        return ""
    }
    
    var allLookupInputs: [String] {
        return []
    }
    
    var description: String {
        return "      ErrorSchema: failure ****** \(name) *******"
    }
}

// MARK: - random attributes

extension UserAttribute {
    
    var randomAttribute: (String, Any)? {
        guard let nameFinal = name else { return nil }
        guard let matchFinal = matchSupported else { return nil }
                
        var randoms: [Any?]
        switch matchFinal {
        case .exists:
            randoms = [1, nil]
        case .exact:
            let v = value!.stringValue
            randoms = [v, "non-" + v]
        case .substring:
            let v = value!.stringValue
            randoms = [v, "random-string"]
        case .lt, .le, .gt, .ge:
            let v = value!.doubleValue
            randoms = [v, 0, 999999]
        case .semver_eq, .semver_lt, .semver_le, .semver_gt, .semver_ge:
            let v = value!.stringValue
            randoms = [v, "0.0.0", "10.0.0"]
        }

        if let element = randoms.randomElement(), let value = element {
            return (nameFinal, value)
        } else {
            return nil
        }
    }
    
}

// MARK: - Utils

extension BucketDecisionSchema {
    
    var startAsciiValue: Int {
        return 65   // "A"
    }
    
    func indexForLetter(_ letter: String) -> Int {
        // return Int(Character(letter).asciiValue!) - startAsciiValue
        return Int(letter)!
    }
    
    func letterForIndex(_ index: Int?) -> String {
//        guard let index = index else { return "Z" }
//        return String(format: "%c", startAsciiValue + index)
        
        guard let index = index else { return "0" }
        return String(index)
    }
    
    func getBucketingId(user: OptimizelyUserContext) -> String {
        // By default, the bucketing ID should be the user ID .
        var bucketingId = user.userId
        // If the bucketing ID key is defined in attributes, then use that
        // in place of the userID for the murmur hash key
        if let newBucketingId = user.attributes[Constants.Attributes.OptimizelyBucketIdAttribute] as? String {
            bucketingId = newBucketingId
        }
        
        return bucketingId
    }
    
    // Bucketer
    
    var MAX_HASH_VALUE: UInt64 {
        return 1 << 32
    }

    func generateBucketValue(bucketingId: String) -> Int {
        let ratio = Double(generateUnsignedHashCode32Bit(hashId: bucketingId)) /  Double(MAX_HASH_VALUE)
        return Int(ratio * Double(MAX_TRAFFIC_VALUE))
    }
    
    func makeHashIdFromBucketingId(bucketingId: String, entityId: String) -> String {
        return bucketingId + entityId
    }
    
    func generateUnsignedHashCode32Bit(hashId: String) -> UInt32 {
        let result = MurmurHash3.doHash32(key: hashId, maxBytes: hashId.lengthOfBytes(using: String.Encoding.utf8), seed: 1)
        return result
    }
    
}
