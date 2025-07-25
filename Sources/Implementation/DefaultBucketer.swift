//
// Copyright 2019-2022, Optimizely, Inc. and contributors
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

class DefaultBucketer: OPTBucketer {
    let MAX_TRAFFIC_VALUE = 10000
    let HASH_SEED = 1
    let MAX_HASH_SEED: UInt64 = 1
    var MAX_HASH_VALUE: UInt64?
    
    // thread-safe lazy logger load (after HandlerRegisterService ready)
    private let threadSafeLogger = ThreadSafeLogger()
    var logger: OPTLogger {
        return threadSafeLogger.logger
    }

    init() {
        MAX_HASH_VALUE = MAX_HASH_SEED << 32
    }
    
    func bucketExperiment(config: ProjectConfig,
                          experiment: Experiment,
                          bucketingId: String) -> DecisionResponse<Variation> {
        let reasons = DecisionReasons()
        
        // Check mutex rules
        let mutexAllowed = checkMutexRules(
            config: config,
            experiment: experiment,
            bucketingId: bucketingId,
            reasons: reasons
        )
        
        if !mutexAllowed {
            return DecisionResponse(result: nil, reasons: reasons)
        }
        
        if !mutexAllowed { return DecisionResponse(result: nil, reasons: reasons) }
        
        // bucket to variation only if experiment passes Mutex check
        
        let decisionResponse = bucketToVariation(experiment: experiment,
                                                 bucketingId: bucketingId)
        reasons.merge(decisionResponse.reasons)
        let variation = decisionResponse.result
        return DecisionResponse(result: variation, reasons: reasons)
    }
    
    func bucketToExperiment(config: ProjectConfig,
                            group: Group,
                            bucketingId: String) -> DecisionResponse<Experiment> {
        let reasons = DecisionReasons()
        
        let hashId = makeHashIdFromBucketingId(bucketingId: bucketingId, entityId: group.id)
        let bucketValue = self.generateBucketValue(bucketingId: hashId)
        
        let info = LogMessage.userAssignedToBucketValue(bucketValue, bucketingId)
        logger.d(info)
        reasons.addInfo(info)
        
        if group.trafficAllocation.count == 0 {
            let info = OptimizelyError.groupHasNoTrafficAllocation(group.id)
            logger.e(info)
            reasons.addInfo(info)
            return DecisionResponse(result: nil, reasons: reasons)
        }
        
        if let experimentId = allocateTraffic(trafficAllocation: group.trafficAllocation, bucketValue: bucketValue) {
            if let experiment = config.getExperiment(id: experimentId) {
                return DecisionResponse(result: experiment, reasons: reasons)
            } else {
                let info = LogMessage.userBucketedIntoInvalidExperiment(experimentId)
                logger.e(info)
                reasons.addInfo(info)
                return DecisionResponse(result: nil, reasons: reasons)
            }
        }
        
        return DecisionResponse(result: nil, reasons: reasons)
    }
    
    /// Checks if an experiment is allowed to run based on mutex rules
    /// - Parameters:
    ///   - config: The project configuration
    ///   - experiment: The experiment to check
    ///   - bucketingId: The bucketing ID for the user
    ///   - reasons: Decision reasons to track the mutex check process
    /// - Returns: A boolean indicating if the experiment is allowed to run
    private func checkMutexRules(
        config: ProjectConfig,
        experiment: Experiment,
        bucketingId: String,
        reasons: DecisionReasons
    ) -> Bool {
        // Find the group containing this experiment
        let group = config.project.groups.filter { $0.getExperiment(id: experiment.id) != nil }.first
        
        guard let group = group else {
            return true // No group found, experiment is allowed
        }
        
        switch group.policy {
            case .overlapping:
                return true // Overlapping experiments are always allowed
                
            case .random:
                let decisionResponse = bucketToExperiment(
                    config: config,
                    group: group,
                    bucketingId: bucketingId
                )
                reasons.merge(decisionResponse.reasons)
                
                guard let mutexExperiment = decisionResponse.result else {
                    let info = LogMessage.userNotBucketedIntoAnyExperimentInGroup(bucketingId, group.id)
                    logger.i(info)
                    reasons.addInfo(info)
                    return false
                }
                
                let isAllowed = mutexExperiment.id == experiment.id
                let info = isAllowed
                ? LogMessage.userBucketedIntoExperimentInGroup(bucketingId, experiment.key, group.id)
                : LogMessage.userNotBucketedIntoExperimentInGroup(bucketingId, experiment.key, group.id)
                
                logger.i(info)
                reasons.addInfo(info)
                return isAllowed
        }
    }
    
    func bucketToEntityId(config: ProjectConfig,
                          experiment: Experiment,
                          bucketingId: String,
                          trafficAllocation: [TrafficAllocation]) -> DecisionResponse<String> {
        
        let reasons = DecisionReasons()
        
        // Check mutex rules
        let mutexAllowed = checkMutexRules(
            config: config,
            experiment: experiment,
            bucketingId: bucketingId,
            reasons: reasons
        )
        
        if !mutexAllowed {
            return DecisionResponse(result: nil, reasons: reasons)
        }
        
        let hashId = makeHashIdFromBucketingId(bucketingId: bucketingId, entityId: experiment.id)
        let bucketValue = self.generateBucketValue(bucketingId: hashId)
        
        let entityId = allocateTraffic(trafficAllocation: trafficAllocation, bucketValue: bucketValue)
        
        return DecisionResponse(result: entityId, reasons: reasons)
    }
    
    func bucketToVariation(experiment: ExperimentCore,
                           bucketingId: String) -> DecisionResponse<Variation> {
        let reasons = DecisionReasons()
        
        let hashId = makeHashIdFromBucketingId(bucketingId: bucketingId, entityId: experiment.id)
        let bucketValue = generateBucketValue(bucketingId: hashId)
        logger.d(.userAssignedToBucketValue(bucketValue, bucketingId))
        
        if experiment.trafficAllocation.count == 0 {
            let info = OptimizelyError.experimentHasNoTrafficAllocation(experiment.key)
            logger.e(info)
            reasons.addInfo(info)
            return DecisionResponse(result: nil, reasons: reasons)
        }
        
        if let variationId = allocateTraffic(trafficAllocation: experiment.trafficAllocation, bucketValue: bucketValue) {
            if let variation = experiment.getVariation(id: variationId) {
                return DecisionResponse(result: variation, reasons: reasons)
            } else {
                let info = LogMessage.userBucketedIntoInvalidVariation(variationId)
                logger.e(info)
                reasons.addInfo(info)
                return DecisionResponse(result: nil, reasons: reasons)
            }
        } else {
            return DecisionResponse(result: nil, reasons: reasons)
        }
    }
    
    func allocateTraffic(trafficAllocation: [TrafficAllocation], bucketValue: Int) -> String? {
        for bucket in trafficAllocation where bucketValue < bucket.endOfRange {
            return bucket.entityId
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
