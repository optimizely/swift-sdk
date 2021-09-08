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

protocol DecisionSchema {
    func makeLookupInput(user: OptimizelyUserContext) -> String
    var allLookupInputs: [String] { get }
}

struct BucketDecisionSchema: DecisionSchema, CustomStringConvertible {
    let bucketKey: String
    let buckets: [Int]
    
    init(bucketKey: String, trafficAllocations: [TrafficAllocation]) {
        self.bucketKey = bucketKey
        
        var buckets = [Int]()
        trafficAllocations.forEach {
            buckets.append($0.endOfRange)
        }
        if buckets.isEmpty {
            // no bucket - same as 100%
            buckets.append(MAX_TRAFFIC_VALUE)
        } else if let last = buckets.last, last < MAX_TRAFFIC_VALUE {
            buckets.append(MAX_TRAFFIC_VALUE)
        }
        
        self.buckets = buckets
    }
    
    func makeLookupInput(user: OptimizelyUserContext) -> String {
        let bucketingId = getBucketingId(user: user)
        
        let hashId = makeHashIdFromBucketingId(bucketingId: bucketingId, entityId: bucketKey)
        let bucketValue = generateBucketValue(bucketingId: hashId)

        let index = buckets.filter { bucketValue < $0 }.first
        return letterForIndex(index)
    }
    
    var allLookupInputs: [String] {
        return buckets.enumerated().map { letterForIndex($0.offset) }
    }
    
    let startAsciiValue = 65   // "A"
    
    func indexForLetter(_ letter: String) -> Int {
        return Int(Character(letter).asciiValue!) - startAsciiValue
    }
    
    func letterForIndex(_ index: Int?) -> String {
        guard let index = index else { return "Z" }
        
        return String(format: "%c", startAsciiValue + index)
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
    
    let MAX_TRAFFIC_VALUE = 10000
    var MAX_HASH_VALUE: UInt64 = 1 << 32

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
    
    var description: String {
        return "      BucketSchema: \(bucketKey) \(buckets)"
    }

}

struct AudienceDecisionSchema: DecisionSchema, CustomStringConvertible {
    let audience: UserAttribute
    
    init(audience: UserAttribute) {
        self.audience = audience
    }
    
    func makeLookupInput(user: OptimizelyUserContext) -> String {
        var bool = false
        do {
            bool = try audience.evaluate(attributes: user.attributes)
        } catch {
            print("[DecisionSchema audience evaluation error: \(error)")
        }
        
        return bool ? "1" : "0"
    }
    
    var allLookupInputs: [String] {
        return ["0", "1"]
    }
    
    var description: String {
        let name = audience.name ?? "nil"
        let match = audience.match ?? "nil"
        let value = audience.value == nil ? "nil" : "\(audience.value!)"
        return "      AudienceSchema: \(name) (\(match), \(value))"
    }

}
