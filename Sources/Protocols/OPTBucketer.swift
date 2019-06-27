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

protocol OPTBucketer {
    /**
     Bucket experiment based on bucket value and traffic allocations.
     - Parameter group: representing Group from which experiment belongs to.
     - Parameter bucketingId: Id to be used for bucketing the user.
     - Returns: experiment which represent Experiment.
     */
    func bucketToExperiment(config: ProjectConfig, group: Group, bucketingId: String) -> Experiment?
    
    /**
     Bucket a bucketingId into an experiment.
     - Parameter experiment: The experiment in which to bucket the bucketingId.
     - Parameter bucketingId: The ID to bucket. This must be a non-null, non-empty string.
     - Returns: The variation the bucketingId was bucketed into.
     */
    func bucketExperiment(config: ProjectConfig, experiment: Experiment, bucketingId: String) -> Variation?

    /**
     Hash the bucketing ID and map it to the range [0, 10000).
     - Parameter bucketingId: The ID for which to generate the hash and bucket values.
     - Returns: A value in the range [0, 10000).
     */
    func generateBucketValue(bucketingId: String) -> Int
    
    /**
     Generate an ID to be used in Murmur3 hash based on the provided User ID and the ID of the entity the user is bucketed into.
     - Parameter bucketingId: The bucket ID provided to the bucketing API.
     - Parameter entityId: The ID of the entity the user is being bucketed into. ex: OPTLYExperiment.experimentId.
     - Returns: The string to be used in the Murmur3 hash for bucketing.
     */
    func makeHashIdFromBucketingId(bucketingId: String, entityId: String) -> String

}
