/****************************************************************************
* Copyright 2019-2020, Optimizely, Inc. and contributors                   *
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

class DefaultBucketer: OPTBucketer {
    let MAX_TRAFFIC_VALUE = 10000
    let HASH_SEED = 1
    let MAX_HASH_SEED: UInt64 = 1
    var MAX_HASH_VALUE: UInt64?
    
    private lazy var logger = OPTLoggerFactory.getLogger()
    
    init() {
        MAX_HASH_VALUE = MAX_HASH_SEED << 32
    }

    func bucketExperiment(config: ProjectConfig,
                          experiment: Experiment,
                          bucketingId: String,
                          options: [OptimizelyDecideOption]? = nil,
                          reasons: DecisionReasons? = nil) -> Variation? {
        var mutexAllowed = true
        
        // check for mutex
        
        let group = config.project.groups.filter { $0.getExperiment(id: experiment.id) != nil }.first
        
        if let group = group {
            switch group.policy {
            case .overlapping:
                break
            case .random:
                let mutexExperiment = bucketToExperiment(config: config,
                                                         group: group,
                                                         bucketingId: bucketingId,
                                                         options: options,
                                                         reasons: reasons)
                if let mutexExperiment = mutexExperiment {
                    if mutexExperiment.id == experiment.id {
                        mutexAllowed = true
                        
                        let info = LogMessage.userBucketedIntoExperimentInGroup(bucketingId, experiment.key, group.id)
                        logger.i(info)
                        reasons?.addInfo(info)
                    } else {
                        mutexAllowed = false
                        
                        let info = LogMessage.userNotBucketedIntoExperimentInGroup(bucketingId, experiment.key, group.id)
                        logger.i(info)
                        reasons?.addInfo(info)
                    }
                } else {
                    mutexAllowed = false
                    
                    let info = LogMessage.userNotBucketedIntoAnyExperimentInGroup(bucketingId, group.id)
                    logger.i(info)
                    reasons?.addInfo(info)
                }
            }
        }
        
        if !mutexAllowed { return nil }
        
        // bucket to variation only if experiment passes Mutex check

        if let variation = bucketToVariation(experiment: experiment,
                                             bucketingId: bucketingId,
                                             options: options,
                                             reasons: reasons) {
            return variation
        } else {
            return nil
        }
    }
    
    func bucketToExperiment(config: ProjectConfig,
                            group: Group,
                            bucketingId: String,
                            options: [OptimizelyDecideOption]? = nil,
                            reasons: DecisionReasons? = nil) -> Experiment? {
        let hashId = makeHashIdFromBucketingId(bucketingId: bucketingId, entityId: group.id)
        let bucketValue = self.generateBucketValue(bucketingId: hashId)
        
        let info = LogMessage.userAssignedToBucketValue(bucketValue, bucketingId)
        logger.d(info)
        reasons?.addInfo(info)
        
        if group.trafficAllocation.count == 0 {
            let info = OptimizelyError.groupHasNoTrafficAllocation(group.id)
            logger.e(info)
            reasons?.addInfo(info)
            return nil
        }
        
        if let experimentId = allocateTraffic(trafficAllocation: group.trafficAllocation, bucketValue: bucketValue) {
            if let experiment = config.getExperiment(id: experimentId) {
                return experiment
            } else {
                let info = LogMessage.userBucketedIntoInvalidExperiment(experimentId)
                logger.e(info)
                reasons?.addInfo(info)
                return nil
            }
        }
        
        return nil
    }
    
    func bucketToVariation(experiment: Experiment,
                           bucketingId: String,
                           options: [OptimizelyDecideOption]? = nil,
                           reasons: DecisionReasons? = nil) -> Variation? {
        let hashId = makeHashIdFromBucketingId(bucketingId: bucketingId, entityId: experiment.id)
        let bucketValue = generateBucketValue(bucketingId: hashId)
        logger.d(.userAssignedToBucketValue(bucketValue, bucketingId))

        if experiment.trafficAllocation.count == 0 {
            let info = OptimizelyError.experimentHasNoTrafficAllocation(experiment.key)
            logger.e(info)
            reasons?.addInfo(info)
            return nil
        }

        if let variationId = allocateTraffic(trafficAllocation: experiment.trafficAllocation, bucketValue: bucketValue) {
            if let variation = experiment.getVariation(id: variationId) {
                return variation
            } else {
                let info = LogMessage.userBucketedIntoInvalidVariation(variationId)
                logger.e(info)
                reasons?.addInfo(info)
                return nil
            }
        } else {
            return nil
        }
    }
    
    func allocateTraffic(trafficAllocation: [TrafficAllocation], bucketValue: Int) -> String? {
        for bucket in trafficAllocation {
            if bucketValue < bucket.endOfRange {
                return bucket.entityId
            }
        }
        
        return nil
    }
    
    func generateBucketValue(bucketingId: String) -> Int {
        let ratio = Double(generateUnsignedHashCode32Bit(hashId: bucketingId)) /  Double(MAX_HASH_VALUE!)
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
