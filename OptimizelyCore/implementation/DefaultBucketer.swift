//
//  DefaultBucketer.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 12/4/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class DefaultBucketer : Bucketer {
    let MAX_TRAFFIC_VALUE = 10000;
    let HASH_SEED = 1;
    let MAX_HASH_SEED:UInt64 = 1
    var MAX_HASH_VALUE:UInt64?
    
    private var config:ProjectConfig
    
    internal required init(config:ProjectConfig) {
        self.config = config
        
        MAX_HASH_VALUE = MAX_HASH_SEED << 32
    }
    
    static func createInstance(config: ProjectConfig) -> Bucketer? {
        return DefaultBucketer(config: config)
    }
    
    func bucketToExperiment(group: Group, bucketingId: String) -> Experiment? {
        let hashId = makeHashIdFromBucketingId(bucketingId: bucketingId, entityId: group.id)
        let bucketValue = self.generateBucketValue(bucketingId: hashId)
        
        if group.trafficAllocation.count == 0 {
            // log error if there are no traffic allocation values
            return nil;
        }
        
        for trafficAllocation in group.trafficAllocation {
            if bucketValue <= trafficAllocation.endOfRange {
                let experimentId = trafficAllocation.entityId;
                let experiment = config.experiments.filter({$0.id == experimentId}).first
                
                // propagate errors and logs for unknown experiment
                if let _ = experiment
                {
                }
                else {
                    // log problem with experiment id
                }
                return experiment;
            }
        }
        
        // log error if invalid bucketing id
        return nil
    }
    
    func bucketExperiment(experiment: Experiment, bucketingId: String) -> Variation? {
        var ok = true
        // check for mutex
        let group = config.groups.filter({ if let _ = $0.experiments.filter({$0.id == experiment.id }).first { return true } else { return false }}).first
        
        if let group = group {
            switch group.policy {
            case .overlapping:
                break;
            case .random:
                let mutexExperiment = bucketToExperiment(group: group, bucketingId: bucketingId)
                if let mutexExperiment = mutexExperiment, mutexExperiment.id == experiment.id {
                    ok = false
                }
            }
        }
        
        // bucket to variation only if experiment passes Mutex check
        if (ok) {
            return bucketToVariation(experiment:experiment, bucketingId:bucketingId)
        }
        else {
            // log message if the user is mutually excluded
            return nil;
        }
    }
    
    func bucketToVariation(experiment:Experiment, bucketingId:String) -> Variation? {
        let hashId = makeHashIdFromBucketingId(bucketingId: bucketingId, entityId: experiment.id)
        let bucketValue = generateBucketValue(bucketingId: hashId)
        
        if experiment.trafficAllocation.count == 0 {
            // log error if there are no traffic allocation values
            return nil
        }
        
        for trafficAllocation in experiment.trafficAllocation {
            if (bucketValue <= trafficAllocation.endOfRange) {
                
                let variationId = trafficAllocation.entityId;
                let variation = experiment.variations.filter({$0.id == variationId }).first
                // propagate errors and logs for unknown variation
                if let _ = variation {
                   // log we got a variation
                }
                else {
                    // log error
                    
                }
                return variation;
            }
        }
        
        // log error if invalid bucketing id
        
        return nil;

    }
    
    func generateBucketValue(bucketingId: String) -> Int {
        let ratio = Double(generateUnsignedHashCode32Bit(hashId: bucketingId)) /  Double(MAX_HASH_VALUE!)
        return Int(ratio * Double(MAX_TRAFFIC_VALUE))
    }
    
    func makeHashIdFromBucketingId(bucketingId: String, entityId: String) -> String {
        return bucketingId + entityId
    }
    
    func generateUnsignedHashCode32Bit(hashId:String) -> UInt32 {
        let result = MurmurHash3.doHash32(key: hashId, maxBytes: hashId.lengthOfBytes(using: String.Encoding.utf8), seed: 1)
        return result;
    }
    
    
}
