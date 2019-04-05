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
    
    private lazy var logger = HandlerRegistryService.shared.injectLogger()
    
    // [Jae]: let be configured after initialized (with custom DecisionHandler set up on OPTManger initialization)
    init() {
        MAX_HASH_VALUE = MAX_HASH_SEED << 32
    }

    func bucketToExperiment(config:ProjectConfig, group: Group, bucketingId: String) -> Experiment? {
        let hashId = makeHashIdFromBucketingId(bucketingId: bucketingId, entityId: group.id)
        let bucketValue = self.generateBucketValue(bucketingId: hashId)
        
        if group.trafficAllocation.count == 0 {
            // log error if there are no traffic allocation values
            logger?.log(level: .error, message: "Group \(group.id) has no traffic allocation")
            return nil;
        }
        
        for trafficAllocation in group.trafficAllocation {
            if bucketValue <= trafficAllocation.endOfRange {
                let experimentId = trafficAllocation.entityId;
                let experiment = config.getExperiment(id: experimentId)
                
                // propagate errors and logs for unknown experiment
                if let _ = experiment
                {
                }
                else {
                    // log problem with experiment id
                    logger?.log(level: .error, message: "Experiment Id \(experimentId) for experiment not in datafile")
                }
                return experiment;
            }
        }
        
        // log error if invalid bucketing id
        logger?.log(level: .error, message: "Bucketing value \(bucketValue) not in traffic allocation")

        return nil
    }
    
    func bucketExperiment(config:ProjectConfig, experiment: Experiment, bucketingId: String) -> Variation? {
        var ok = true
        // check for mutex
        let group = config.project.groups.filter{ $0.getExperiemnt(id: experiment.id) != nil }.first
        
        if let group = group {
            switch group.policy {
            case .overlapping:
                break;
            case .random:
                let mutexExperiment = bucketToExperiment(config: config, group: group, bucketingId: bucketingId)
                if let mutexExperiment = mutexExperiment, mutexExperiment.id == experiment.id {
                    ok = true
                }
                else {
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
            logger?.log(level: .error, message: "User not bucketed into variation. Mutually excluded via group \(group?.id ?? "unknown")")

            return nil;
        }
    }
    
    func bucketToVariation(experiment:Experiment, bucketingId:String) -> Variation? {
        let hashId = makeHashIdFromBucketingId(bucketingId: bucketingId, entityId: experiment.id)
        let bucketValue = generateBucketValue(bucketingId: hashId)
        
        if experiment.trafficAllocation.count == 0 {
            // log error if there are no traffic allocation values
            logger?.log(level: .error, message: "Experiment \(experiment.key) has no traffic allocation")

            return nil
        }
        
        for trafficAllocation in experiment.trafficAllocation {
            if (bucketValue <= trafficAllocation.endOfRange) {
                
                let variationId = trafficAllocation.entityId;
                let variation = experiment.getVariation(id: variationId)
                // propagate errors and logs for unknown variation
                if let variation = variation {
                   // log we got a variation
                    logger?.log(level: .info, message: "Got variation \(variation.key) for experiment \(experiment.key)")

                }
                else {
                    // log error
                    logger?.log(level: .error, message: "Not bucketed into variation experiment \(experiment.key)")

                }
                return variation;
            }
        }
        
        // log error if invalid bucketing id
        logger?.log(level: .error, message: "Invalid bucketing value for experiment \(experiment.key)")

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
