/****************************************************************************
 * Copyright 2018, Optimizely, Inc. and contributors                        *
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

public protocol Bucketer {
    /**
     * Initialize the default bucketer with the project config.
     * @param config The project config that the bucketer will use for reference.
     * @return The bucketer that has been created.
     */
    static func createInstance(config:ProjectConfig) -> Bucketer?

    /**
     * Bucket experiment based on bucket value and traffic allocations.
     * @param group representing Group from which experiment belongs to.
     * @param bucketingId Id to be used for bucketing the user.
     * @return experiment which represent Experiment.
     */
    func bucketToExperiment(group:Group, bucketingId:String) -> Experiment?
    
    /**
     * Bucket a bucketingId into an experiment.
     * @param experiment The experiment in which to bucket the bucketingId.
     * @param bucketingId The ID to bucket. This must be a non-null, non-empty string.
     * @return The variation the bucketingId was bucketed into.
     */
    func bucketExperiment(experiment:Experiment, bucketingId:String) -> Variation?

    /**
     * Hash the bucketing ID and map it to the range [0, 10000).
     * @param bucketingId The ID for which to generate the hash and bucket values.
     * @return A value in the range [0, 10000).
     */
    func generateBucketValue(bucketingId:String) -> Int
    
    /**
     * Generate an ID to be used in Murmur3 hash based on the provided User ID and the ID of the entity the user is bucketed into.
     * @param bucketingId The bucket ID provided to the bucketing API.
     * @param entityId The ID of the entity the user is being bucketed into. ex: OPTLYExperiment.experimentId.
     * @return The string to be used in the Murmur3 hash for bucketing.
     */
    func makeHashIdFromBucketingId(bucketingId:String, entityId:String) -> String

}
