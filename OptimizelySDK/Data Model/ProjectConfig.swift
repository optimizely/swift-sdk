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
    lazy var logger = HandlerRegistryService.shared.injectLogger()
    
    // local runtime forcedVariations [UserId: [ExperimentId: VariationId]]
    // NOTE: experiment.forcedVariations use [ExperimentKey: VariationKey] instead of ids
    
    private var whitelistUsers = [String: [String: String]]()
    private var experimentFeatureMap = [String: [String]]()
    
    init(datafile: Data) throws {
        do {
            self.project = try JSONDecoder().decode(Project.self, from: datafile)
        } catch {
            throw OptimizelyError.dataFileInvalid
        }
        if !isValidVersion(version: self.project.version) {
            throw OptimizelyError.dataFileVersionInvalid(self.project.version)
        }
        generateExperimentFeatureMap()
    }
    
    convenience init(datafile: String) throws {
        guard let data = datafile.data(using: .utf8) else {
            throw OptimizelyError.dataFileInvalid
        }
        
        try self.init(datafile: data)
   }
    
    init() {
        // TODO: [Jae] fix to throw error
    }
    
    class func DateFromString(dateString:String) -> NSDate
    {
        let dateFormatter = DateFormatter()
        let enUSPosixLocale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale as Locale
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return dateFormatter.date(from: dateString)! as NSDate
    }
}

extension ProjectConfig {
    private func whitelistUser(userId: String, experimentId: String, variationId: String) {
        if var dic = whitelistUsers[userId] {
            dic[experimentId] = variationId
        }
        else {
            var dic = Dictionary<String,String>()
            dic[experimentId] = variationId
            whitelistUsers[userId] = dic
        }
    }
    
    private func removeFromWhitelist(userId: String, experimentId: String) {
        self.whitelistUsers[userId]?.removeValue(forKey: experimentId)
    }
    
    private func getWhitelistedVariationId(userId: String, experimentId: String) -> String? {
        if var dic = whitelistUsers[userId] {
            return dic[experimentId]
        } else {
            logger?.d(.userHasNoForcedVariation(userId))
            return nil
        }
    }
    
    private func isValidVersion(version: String) -> Bool {
        // old versions (< 4) of datafiles not supported
        return ["4"].contains(version)
    }
    
    private func generateExperimentFeatureMap() {
        for feature in project.featureFlags {
            for id in feature.experimentIds {
                if var featureIdArray = experimentFeatureMap[id] {
                    featureIdArray.append(feature.id)
                    experimentFeatureMap[id] = featureIdArray
                }
                else {
                    experimentFeatureMap[id] = [feature.id]
                }
            }
        }
    }
}

// MARK: - Project Access

extension ProjectConfig {
    
    /**
     * Get an Experiment object for a key.
     */
    func getExperiment(key: String) -> Experiment? {
        return allExperiments.filter { $0.key == key }.first
    }
    
    /**
     * Get an Experiment object for an Id.
     */
    func getExperiment(id: String) -> Experiment? {
        return allExperiments.filter { $0.id == id }.first
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
        return project.groups.filter{ $0.id == id }.first
    }
    
    /**
     * Get a Feature Flag object for a key.
     */
    func getFeatureFlag(key: String) -> FeatureFlag? {
        return project.featureFlags.filter{ $0.key == key }.first
    }
    
    /**
     * Get a Rollout object for an Id.
     */
    func getRollout(id: String) -> Rollout? {
        return project.rollouts.filter{ $0.id == id }.first
    }
    
    /**
     * Gets an event for a corresponding event key
     */
    func getEvent(key: String) -> Event? {
        return project.events.filter{ $0.key == key }.first
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
        return project.attributes.filter{ $0.key == key }.first
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
        return experimentFeatureMap.keys.contains(id)
    }
    
    /**
     * Get forced variation for a given experiment key and user id.
     */
    func getForcedVariation(experimentKey: String, userId: String) -> Variation? {
        guard let experiment = getExperiment(key: experimentKey) else {
            return nil
        }
        
        if let id = getWhitelistedVariationId(userId: userId, experimentId: experiment.id) {
            if let variation = experiment.getVariation(id:id) {
                logger?.d(.userHasForcedVariation(userId, experiment.key, variation.key))
                return variation
            } else {
                logger?.d(.userHasForcedVariationButInvalid(userId, experiment.key))
                return nil
            }
        } else {
            logger?.d(.userHasNoForcedVariationForExperiment(userId, experiment.key))
            return nil
        }
    }
    
    /**
     * Set forced variation for a given experiment key and user id according to a given variation key.
     */
    func setForcedVariation(experimentKey: String, userId: String, variationKey: String?) -> Bool {
        guard let experiment = getExperiment(key: experimentKey) else {
            return false
        }
        
        guard var variationKey = variationKey else {
            logger?.d(.variationRemovedForUser(userId, experimentKey))
            self.removeFromWhitelist(userId: userId, experimentId: experiment.id)
            return true
        }
        
        // TODO: common function to trim all keys
        variationKey = variationKey.trimmingCharacters(in: NSCharacterSet.whitespaces)

        guard !variationKey.isEmpty else {
            return false
        }

        guard let variation = experiment.variations.filter({$0.key == variationKey }).first else {
            return false
        }
        
        self.whitelistUser(userId: userId, experimentId: experiment.id, variationId: variation.id)
        
        logger?.d(.userMappedToForcedVariation(userId, experiment.id, variation.id))
        return true
    }
    
    var allExperiments:[Experiment] {
        return  project.experiments + project.groups.map({$0.experiments}).flatMap({$0})
    }

}
