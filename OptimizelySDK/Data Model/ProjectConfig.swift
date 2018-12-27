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

public class ProjectConfig : Codable
{
    let reservedAttributePrefix = "$opt_"
    var version:String = ""
    var rollouts:[Rollout]? = []
    var typedAudiences:[Audience]? = []
    var anonymizeIP:Bool? = true
    var projectId:String = ""
    var variables:[Variable]? = []
    var featureFlags:[FeatureFlag]? = []
    var experiments:[Experiment] = []
    var audiences:[Audience] = []
    var groups:[Group] = []
    var attributes:[Attribute] = []
    var botFiltering:Bool? = false
    var accountId:String = ""
    var events:[Event]? = []
    var revision:String = ""
    var forcedVariationMap = [String:[String:String]]()
    private var _allExperiments:[Experiment]?
    var allExperiments:[Experiment] {
        if (_allExperiments == nil) {
            _allExperiments = []
            var all = [Experiment]()
            all.append(contentsOf: experiments)
            for group in self.groups {
                for experiment in group.experiments {
                    experiment.groupId = group.id
                    experiment.groupPolicy = group.policy
                    all.append(experiment)
                }
            }
            if let _rollouts = rollouts {
                for rollout in _rollouts {
                    all.append(contentsOf: rollout.experiments)
                }
            }
            _allExperiments = all
        }
        return _allExperiments!
    }
    //MARK:- Maps
    private var _audienceIdToAudienceMap:[String:Audience]?
    var audienceIdToAudienceMap:[String:Audience] {
        if (_audienceIdToAudienceMap == nil) {
            _audienceIdToAudienceMap = [String:Audience]()
            var tmpAudiences:[Audience] = audiences
            if typedAudiences != nil {
                tmpAudiences.append(contentsOf: typedAudiences!)
            }
            _audienceIdToAudienceMap = generateKeyMap(entityList: tmpAudiences, mapValueType: Audience.self, key: "id")
        }
        return _audienceIdToAudienceMap!
    }
    private var _attributesKeyToAttributesMap:[String:Attribute]?
    var attributesKeyToAttributesMap:[String:Attribute] {
        if (_attributesKeyToAttributesMap == nil) {
            _attributesKeyToAttributesMap = [String:Attribute]()
            _attributesKeyToAttributesMap = generateKeyMap(entityList: attributes, mapValueType: Attribute.self, key: "key")
        }
        return _attributesKeyToAttributesMap!
    }
    private var _experimentKeyToExperimentMap:[String:Experiment]?
    var experimentKeyToExperimentMap:[String:Experiment] {
        if (_experimentKeyToExperimentMap == nil) {
            _experimentKeyToExperimentMap = [String:Experiment]()
            _experimentKeyToExperimentMap = generateKeyMap(entityList: allExperiments, mapValueType: Experiment.self, key: "key")
        }
        return _experimentKeyToExperimentMap!
    }
    private var _experimentIdToExperimentMap:[String:Experiment]?
    var experimentIdToExperimentMap:[String:Experiment] {
        if (_experimentIdToExperimentMap == nil) {
            _experimentIdToExperimentMap = [String:Experiment]()
            _experimentIdToExperimentMap = generateKeyMap(entityList: allExperiments, mapValueType: Experiment.self, key: "id")
        }
        return _experimentIdToExperimentMap!
    }
    private var _experimentKeyToExperimentIdMap:[String:String]?
    var experimentKeyToExperimentIdMap:[String:String] {
        if (_experimentKeyToExperimentIdMap == nil) {
            _experimentKeyToExperimentIdMap = [String:String]()
            _experimentKeyToExperimentIdMap = generateKeyMap(entityList: allExperiments, mapValueType: String.self, key: "key", valueKey: "id")
        }
        return _experimentKeyToExperimentIdMap!
    }
    private var _eventKeyToEventMap:[String:Event]?
    var eventKeyToEventMap:[String:Event] {
        if (_eventKeyToEventMap == nil) {
            _eventKeyToEventMap = [String:Event]()
            if let _events = events {
                _eventKeyToEventMap = generateKeyMap(entityList: _events, mapValueType: Event.self, key: "key")
            }
        }
        return _eventKeyToEventMap!
    }
    private var _featureKeyToFeatureMap:[String:FeatureFlag]?
    var featureKeyToFeatureMap:[String:FeatureFlag] {
        if (_featureKeyToFeatureMap == nil) {
            _featureKeyToFeatureMap = [String:FeatureFlag]()
            if let _featureFlags = featureFlags {
                _featureKeyToFeatureMap = generateKeyMap(entityList: _featureFlags, mapValueType: FeatureFlag.self, key: "key")
                for (key,value) in _featureKeyToFeatureMap! {
                    // Check if any of the experiments are in a group and add the group id for faster bucketing later on
                    for experimentId in value.experimentIds {
                        if let groupId = self.experimentIdToExperimentMap[experimentId]?.groupId {
                            _featureKeyToFeatureMap![key]!.groupId = groupId
                            // Experiments in feature can only belong to one mutex group
                            break
                        }
                    }
                }
            }
        }
        return _featureKeyToFeatureMap!
    }
    private var _featureKeyToFeatureVariablesMap:[String:[String:FeatureVariable]]?
    var featureKeyToFeatureVariablesMap:[String:[String:FeatureVariable]] {
        if (_featureKeyToFeatureVariablesMap == nil) {
            _featureKeyToFeatureVariablesMap = [String:[String:FeatureVariable]]()
            if let _featureFlags = featureFlags {
                for flag in _featureFlags {
                    if let _featureVariables = flag.variables {
                        _featureKeyToFeatureVariablesMap![flag.key] = generateKeyMap(entityList: _featureVariables, mapValueType: FeatureVariable.self, key: "key")
                    }
                }
            }
        }
        return _featureKeyToFeatureVariablesMap!
    }
    private var _groupIdToGroupMap:[String:Group]?
    var groupIdToGroupMap:[String:Group] {
        if (_groupIdToGroupMap == nil) {
            _groupIdToGroupMap = [String:Group]()
            for index in 0..<self.groups.count {
                for index2 in 0..<self.groups[index].experiments.count {
                    self.groups[index].experiments[index2].groupId = self.groups[index].id
                    self.groups[index].experiments[index2].groupPolicy = self.groups[index].policy
                }
            }
            _groupIdToGroupMap = generateKeyMap(entityList: groups, mapValueType: Group.self, key: "id")
        }
        return _groupIdToGroupMap!
    }
    private var _rolloutIdToRolloutMap:[String:Rollout]?
    var rolloutIdToRolloutMap:[String:Rollout] {
        if (_rolloutIdToRolloutMap == nil) {
            _rolloutIdToRolloutMap = [String:Rollout]()
            if let _rollouts = rollouts {
                _rolloutIdToRolloutMap = generateKeyMap(entityList: _rollouts, mapValueType: Rollout.self, key: "id")
            }
        }
        return _rolloutIdToRolloutMap!
    }
    private var _typedAudienceIdToTypedAudienceMap:[String:Audience]?
    var typedAudienceIdToTypedAudienceMap:[String:Audience] {
        if (_typedAudienceIdToTypedAudienceMap == nil) {
            _typedAudienceIdToTypedAudienceMap = [String:Audience]()
            if let _typedAudiences = typedAudiences {
                _typedAudienceIdToTypedAudienceMap = generateKeyMap(entityList: _typedAudiences, mapValueType: Audience.self, key: "id")
            }
        }
        return _typedAudienceIdToTypedAudienceMap!
    }
    private var _variationIdToVariationMap:[String:[String:Variation]]?
    var variationIdToVariationMap:[String:[String:Variation]] {
        if (_variationIdToVariationMap == nil) {
            _variationIdToVariationMap = [String:[String:Variation]]()
            for experiment in self.allExperiments {
                _variationIdToVariationMap![experiment.key] = self.generateKeyMap(entityList: experiment.variations, mapValueType: Variation.self , key: "id")
            }
        }
        return _variationIdToVariationMap!
    }
    private var _variationKeyToVariationMap:[String:[String:Variation]]?
    var variationKeyToVariationMap:[String:[String:Variation]] {
        if (_variationKeyToVariationMap == nil) {
            _variationKeyToVariationMap = [String:[String:Variation]]()
            for experiment in self.allExperiments {
                _variationKeyToVariationMap![experiment.key] = self.generateKeyMap(entityList: experiment.variations, mapValueType: Variation.self , key: "key")
            }
        }
        return _variationKeyToVariationMap!
    }
    private var _variationIdToVariationVariablesMap:[String:[String:Variable]]?
    var variationIdToVariationVariablesMap:[String:[String:Variable]] {
        if (_variationIdToVariationVariablesMap == nil) {
            _variationIdToVariationVariablesMap = [String:[String:Variable]]()
            for experiment in self.allExperiments {
                if let _variations = variationKeyToVariationMap[experiment.key] {
                    for _variation in _variations.values {
                        if let _variables = _variation.variables {
                           _variationIdToVariationVariablesMap![_variation.id] = self.generateKeyMap(entityList: _variables, mapValueType: Variable.self , key: "id")
                        }
                    }
                }
            }
        }
        return _variationIdToVariationVariablesMap!
    }
    
    // transient
    var whitelistUsers:Dictionary<String,Dictionary<String,String>> = Dictionary<String,Dictionary<String,String>>()
    
    private enum CodingKeys: String, CodingKey {
        case version
        case rollouts
        case typedAudiences
        case anonymizeIP
        case projectId
        case variables
        case featureFlags
        case experiments
        case audiences
        case groups
        case attributes
        case botFiltering
        case accountId
        case events
        case revision
        // transient
        // case whitelistUsers
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

//MARK:- Setter Methods
extension ProjectConfig {
    func setForcedVariation(experimentKey: String, userId: String, variationKey: String?) -> Bool {
        // Return true if there were no errors, else return false
        // Check if experiment exists and experimentId is non-empty
        guard let experiment = self.getExperimentForKey(experimentKey: experimentKey), experiment.id != "" else {
            return false
        }
        // Check if variationKey is null
        guard let _variationKey = variationKey else {
            // Clear the forced variation if the variation key is null
            self.forcedVariationMap[userId]?.removeValue(forKey: experiment.id)
            return true
        }
        // Check if variationKey is empty string
        if _variationKey.trimmingCharacters(in: NSCharacterSet.whitespaces) == "" {
            // TODO: Log Message here
            return false
        }
        // Get experiment from experimentKey and Check if variation with non-empty variationId exists
        guard let variation = self.getVariationFor(experimentKey: experimentKey, variationKey: _variationKey), variation.id != "" else {
            // TODO: Log Message here
            return false
        }
        // Add/Replace Experiment to Variation ID map.
        if self.forcedVariationMap[userId] == nil {
            self.forcedVariationMap[userId] = [String:String]()
        }
        self.forcedVariationMap[userId] = [experiment.id:variation.id]
        return true
    }
}

//MARK:- Getter Methods
extension ProjectConfig {
    func getAttributeIdForKey(attributeKey:String) -> String? {
        let hasReservedPrefix:Bool = attributeKey.starts(with: reservedAttributePrefix)
        guard let attribute = self.attributesKeyToAttributesMap[attributeKey] else {
            if (hasReservedPrefix) {
                return attributeKey
            }
            // TODO: Log Message here
            return nil
        }
        if (hasReservedPrefix) {
            // TODO: Log Message here
        }
        return attribute.id
    }
    
    func getAudienceForId(audienceId:String) -> Audience? {
        guard let audience = self.audienceIdToAudienceMap[audienceId] else {
            // TODO: Log Message here
            return nil
        }
        return audience
    }
    
    func getEventForKey(eventKey:String) -> Event? {
        guard let event = self.eventKeyToEventMap[eventKey] else {
            // TODO: Log Message here
            return nil
        }
        return event
    }
    
    func getExperimentForId(experimentId:String) -> Experiment? {
        guard let experiment = self.experimentIdToExperimentMap[experimentId] else {
            // TODO: Log Message here
            return nil
        }
        return experiment
    }
    
    func getExperimentForKey(experimentKey:String) -> Experiment? {
        guard let experiment = self.experimentKeyToExperimentMap[experimentKey] else {
            // TODO: Log Message here
            return nil
        }
        return experiment
    }
    
    func getExperimentIdForKey(experimentKey:String) -> String? {
        guard let experimentId = self.experimentKeyToExperimentIdMap[experimentKey] else {
            // TODO: Log Message here
            return nil
        }
        return experimentId
    }
    
    func getFeatureForKey(featureKey:String) -> FeatureFlag? {
        guard let feature = self.featureKeyToFeatureMap[featureKey] else {
            // TODO: Log Message here
            return nil
        }
        return feature
    }
    
    public func getForcedVariation(experimentKey: String, userId: String) -> Variation? {
        guard let _forcedVariationsDict = forcedVariationMap[userId] else {
            // TODO: Log Message here
            return nil
        }
        guard let _experiment = self.getExperimentForKey(experimentKey: experimentKey) else {
            return nil
        }
        guard let _variationId = _forcedVariationsDict[_experiment.id] else{
            // TODO: Log Message here
            return nil
        }
        // TODO: Log Message here
        return self.getVariationForVariationId(experimentKey:_experiment.key ,variationId:_variationId)
    }
    
    func getGroupForId(groupId:String) -> Group? {
        guard let group = self.groupIdToGroupMap[groupId] else {
            // TODO: Log Message here
            return nil
        }
        return group
    }
    
    func getRolloutForId(rolloutId:String) -> Rollout? {
        guard let rollout = self.rolloutIdToRolloutMap[rolloutId] else {
            // TODO: Log Message here
            return nil
        }
        return rollout
    }
    
    func getVariableValueForVariation(variable:FeatureVariable, variation:Variation) -> String? {
        guard let variablesDict = variationIdToVariationVariablesMap[variation.id] else {
            return nil
        }
        guard let _variable = variablesDict[variable.id] else {
            // TODO: Log Message here
            return variable.defaultValue
        }
        // TODO: Log Message here
        return _variable.value
    }
    
    func getVariableForFeature(featureKey:String, variableKey:String) -> FeatureVariable? {
        if self.featureKeyToFeatureMap[featureKey] == nil {
            // TODO: Log Message here
            return nil
        }
        guard let _variable = featureKeyToFeatureVariablesMap[featureKey]?[variableKey] else{
            // TODO: Log Message here
            return nil
        }
        return _variable
    }
    
    func getVariationForVariationId(experimentKey:String, variationId:String) -> Variation? {
        guard let variation = self.variationIdToVariationMap[experimentKey]?[variationId] else {
            // TODO: Log Message here
            return nil
        }
        return variation
    }
    
    func getVariationFor(experimentKey:String, variationKey:String) -> Variation? {
        guard let variation = self.variationKeyToVariationMap[experimentKey]?[variationKey] else {
            // TODO: Log Message here
            return nil
        }
        return variation
    }
    
    func whitelistUser(userId:String, experimentId:String, variationId:String) {
        if var dic = whitelistUsers[userId] {
            dic[experimentId] = variationId
        }
        else {
            var dic = Dictionary<String,String>()
            dic[experimentId] = variationId
            whitelistUsers[userId] = dic
        }
    }
    
    func getWhitelistedVariationId(userId:String, experimentId:String) -> String? {
        if var dic = whitelistUsers[userId] {
            return dic[experimentId]
        }
        return nil
    }
}

//MARK:- Helper Methods
extension ProjectConfig {
    func generateKeyMap<T:NSObject, U>(entityList:[T], mapValueType:U.Type, key:String, valueKey:String? = nil) -> [String:U] {
        var dict = [String:U]()
        guard let _valueKey = valueKey else {
            for obj in entityList {
                dict[obj.value(forKey: key) as! String] = obj as? U
            }
            return dict
        }
        for obj in entityList {
            dict[obj.value(forKey: key) as! String] = obj.value(forKey: _valueKey) as? U
        }
        return dict
    }
}
