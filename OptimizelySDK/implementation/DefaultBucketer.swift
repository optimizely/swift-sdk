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

class DefaultBucketer : OPTBucketer {
    let MAX_TRAFFIC_VALUE = 10000;
    let HASH_SEED = 1;
    let MAX_HASH_SEED:UInt64 = 1
    var MAX_HASH_VALUE:UInt64?
    
    private var config:OPTProjectConfig!
    private lazy var logger = HandlerRegistryService.shared.injectLogger()
    
    internal required init(config:OPTProjectConfig) {
        self.config = config

        MAX_HASH_VALUE = MAX_HASH_SEED << 32
    }
    
    // [Jae]: let be configured after initialized (with custom DecisionHandler set up on OPTManger initialization)
    init() {
        MAX_HASH_VALUE = MAX_HASH_SEED << 32
    }

    func initialize(config:OPTProjectConfig) {
        self.config = config
    }

    
    
    static func createInstance(config: OPTProjectConfig) -> OPTBucketer? {
        return DefaultBucketer(config: config)
    }
    
    func bucketToExperiment(group: OPTGroup, bucketingId: String) -> OPTExperiment? {
        let hashId = makeHashIdFromBucketingId(bucketingId: bucketingId, entityId: group.id)
        let bucketValue = self.generateBucketValue(bucketingId: hashId)
        
        if group.trafficAllocation.count == 0 {
            // log error if there are no traffic allocation values
            logger?.log(level: .error, message: String(format:"Group %@ has no traffic allocation", group.id))
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
                    logger?.log(level: .error, message: String(format:"Experiment Id %@ for experiment not in datafile", experimentId))
                }
                return experiment;
            }
        }
        
        // log error if invalid bucketing id
        logger?.log(level: .error, message: String(format:"Bucketing value %@ not in traffic allocation", bucketValue))

        return nil
    }
    
    func bucketExperiment(experiment: OPTExperiment, bucketingId: String) -> OPTVariation? {
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
            logger?.log(level: .error, message: String(format:"User not bucketed into variation. Mutually excluded via group %@", group?.id ?? "unknown"))

            return nil;
        }
    }
    
    func bucketToVariation(experiment:OPTExperiment, bucketingId:String) -> OPTVariation? {
        let hashId = makeHashIdFromBucketingId(bucketingId: bucketingId, entityId: experiment.id)
        let bucketValue = generateBucketValue(bucketingId: hashId)
        
        if experiment.trafficAllocation.count == 0 {
            // log error if there are no traffic allocation values
            logger?.log(level: .error, message: String(format:"Experiment %@ has no traffic allocation", experiment.key))

            return nil
        }
        
        for trafficAllocation in experiment.trafficAllocation {
            if (bucketValue <= trafficAllocation.endOfRange) {
                
                let variationId = trafficAllocation.entityId;
                let variation = experiment.variations.filter({$0.id == variationId }).first
                // propagate errors and logs for unknown variation
                if let variation = variation {
                   // log we got a variation
                    logger?.log(level: .info, message: String(format:"Got variation %@ for experiment %@", variation.key, experiment.key))

                }
                else {
                    // log error
                    logger?.log(level: .error, message: String(format:"Not bucketed into variation experiment %@", experiment.key))

                }
                return variation;
            }
        }
        
        // log error if invalid bucketing id
        logger?.log(level: .error, message: String(format:"Invalid bucketing value for experiment %@", experiment.key))

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
