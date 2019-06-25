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

class ProjectConfig {
    
    var project: Project!
    
    lazy var logger = OPTLoggerFactory.getLogger()
    
    // local runtime forcedVariations [UserId: [ExperimentId: VariationId]]
    // NOTE: experiment.forcedVariations use [ExperimentKey: VariationKey] instead of ids
    
    var whitelistUsers = [String: [String: String]]()
    
    lazy var experimentKeyMap: [String: Experiment] = {
        var map = [String: Experiment]()
        allExperiments.forEach({map[$0.key] = $0})
        return map
    }()

    lazy var experimentIdMap: [String: Experiment] = {
        var map = [String: Experiment]()
        allExperiments.forEach({map[$0.id] = $0})
        return map
    }()

    lazy var experimentFeatureMap: [String: [String]] = {
        var experimentFeatureMap = [String: [String]]()
        project.featureFlags.forEach({ (ff) in
            ff.experimentIds.forEach({
                if var arr = experimentFeatureMap[$0] {
                    arr.append(ff.id)
                    experimentFeatureMap[$0] = arr
                } else {
                    experimentFeatureMap[$0] = [ff.id]
                }
            })
        })
        return experimentFeatureMap
    }()
    
    lazy var eventKeyMap: [String: Event] = {
        var eventKeyMap = [String: Event]()
        project.events.forEach({eventKeyMap[$0.key] = $0 })
        return eventKeyMap
    }()
    
    lazy var attributeKeyMap: [String: Attribute] = {
        var map = [String: Attribute]()
        project.attributes.forEach({map[$0.key] = $0 })
        return map
    }()

    lazy var featureFlagKeyMap: [String: FeatureFlag] = {
        var map = [String: FeatureFlag]()
        project.featureFlags.forEach({map[$0.key] = $0 })
        return map
    }()

    lazy var rolloutIdMap: [String: Rollout] = {
        var map = [String: Rollout]()
        project.rollouts.forEach({map[$0.id] = $0 })
        return map
    }()

    lazy var allExperiments: [Experiment] = {
        return project.experiments + project.groups.map({$0.experiments}).flatMap({$0})
    }()
    
    init(datafile: Data) throws {
        do {
            self.project = try JSONDecoder().decode(Project.self, from: datafile)
        } catch {
            throw OptimizelyError.dataFileInvalid
        }
        
        if !isValidVersion(version: self.project.version) {
            throw OptimizelyError.dataFileVersionInvalid(self.project.version)
        }
    }
    
    convenience init(datafile: String) throws {
        try self.init(datafile: Data(datafile.utf8))
   }
    
    init() {
    }
    
}

extension ProjectConfig {
    private func whitelistUser(userId: String, experimentId: String, variationId: String) {
        var dic = whitelistUsers[userId] ?? [String: String]()
        dic[experimentId] = variationId
        whitelistUsers[userId] = dic
    }
    
    private func removeFromWhitelist(userId: String, experimentId: String) {
        self.whitelistUsers[userId]?.removeValue(forKey: experimentId)
    }
    
    private func getWhitelistedVariationId(userId: String, experimentId: String) -> String? {
        if var dic = whitelistUsers[userId] {
            return dic[experimentId]
        }
        
        logger.d(.userHasNoForcedVariation(userId))
        return nil
    }
    
    private func isValidVersion(version: String) -> Bool {
        // old versions (< 4) of datafiles not supported
        return ["4"].contains(version)
    }

}

// MARK: - Project Access

extension ProjectConfig {
    
    /**
     * Get an Experiment object for a key.
     */
    func getExperiment(key: String) -> Experiment? {
        return experimentKeyMap[key]
    }
    
    /**
     * Get an Experiment object for an Id.
     */
    func getExperiment(id: String) -> Experiment? {
        return experimentIdMap[id]
    }
    
    /**
     * Get an experiment Id for the human readable experiment key
     **/
    func getExperimentId(key: String) -> String? {
        return getExperiment(key: key)?.id
    }
    
    /**
     * Get a Group object for an Id.
     */
    func getGroup(id: String) -> Group? {
        return project.groups.filter { $0.id == id }.first
    }
    
    /**
     * Get a Feature Flag object for a key.
     */
    func getFeatureFlag(key: String) -> FeatureFlag? {
        return featureFlagKeyMap[key]
    }
    
    /**
     * Get all Feature Flag objects.
     */
    func getFeatureFlags() -> [FeatureFlag] {
        return project.featureFlags
    }
    
    /**
     * Get a Rollout object for an Id.
     */
    func getRollout(id: String) -> Rollout? {
        return rolloutIdMap[id]
    }
    
    /**
     * Gets an event for a corresponding event key
     */
    func getEvent(key: String) -> Event? {
        return eventKeyMap[key]
    }
    
    /**
     * Gets an event id for a corresponding event key
     */
    func getEventId(key: String) -> String? {
        return getEvent(key: key)?.id
    }
    
    /**
     * Get an attribute for a given key.
     */
    func getAttribute(key: String) -> Attribute? {
        return attributeKeyMap[key]
    }
    
    /**
     * Get an attribute Id for a given key.
     **/
    func getAttributeId(key: String) -> String? {
        return getAttribute(key: key)?.id
    }
    
    /**
     * Get an audience for a given audience id.
     */
    func getAudience(id: String) -> Audience? {
        return project.getAudience(id: id)
    }
    
    /**
     *  Returns true if experiment belongs to any feature, false otherwise.
     */
    func isFeatureExperiment(id: String) -> Bool {
        return !(experimentFeatureMap[id]?.isEmpty ?? true)
    }
    
    /**
     * Get forced variation for a given experiment key and user id.
     */
    func getForcedVariation(experimentKey: String, userId: String) -> Variation? {
        guard let experiment = getExperiment(key: experimentKey) else {
            return nil
        }
        
        if let id = getWhitelistedVariationId(userId: userId, experimentId: experiment.id) {
            if let variation = experiment.getVariation(id: id) {
                logger.d(.userHasForcedVariation(userId, experiment.key, variation.key))
                return variation
            }
            
            logger.d(.userHasForcedVariationButInvalid(userId, experiment.key))
            return nil
        }
        
        logger.d(.userHasNoForcedVariationForExperiment(userId, experiment.key))
        return nil
    }
    
    /**
     * Set forced variation for a given experiment key and user id according to a given variation key.
     */
    func setForcedVariation(experimentKey: String, userId: String, variationKey: String?) -> Bool {
        guard let experiment = getExperiment(key: experimentKey) else {
            return false
        }
        
        guard var variationKey = variationKey else {
            logger.d(.variationRemovedForUser(userId, experimentKey))
            self.removeFromWhitelist(userId: userId, experimentId: experiment.id)
            return true
        }
        
        // TODO: common function to trim all keys
        variationKey = variationKey.trimmingCharacters(in: NSCharacterSet.whitespaces)

        guard !variationKey.isEmpty else {
            logger.e(.variationKeyInvalid(experimentKey, variationKey))
            return false
        }

        guard let variation = experiment.getVariation(key: variationKey) else {
            logger.e(.variationKeyInvalid(experimentKey, variationKey))
            return false
        }
        
        self.whitelistUser(userId: userId, experimentId: experiment.id, variationId: variation.id)
        
        logger.d(.userMappedToForcedVariation(userId, experiment.id, variation.id))
        return true
    }
    
}
