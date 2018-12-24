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
    private var _allExperiments:[Experiment]?
    var allExperiments:[Experiment] {
        if (_allExperiments == nil) {
            _allExperiments = []
            var all = [Experiment]()
            all.append(contentsOf: experiments)
            for group in self.groups {
                for experiment in group.experiments {
                    all.append(experiment)
                }
            }
            _allExperiments = all
        }
        return _allExperiments!
    }
    // Experiment Maps
    private var _experimentIdToExperimentMap:[String:Experiment]?
    var experimentIdToExperimentMap: [String:Experiment] {
        if (_experimentIdToExperimentMap == nil) {
            _experimentIdToExperimentMap = [String:Experiment]()
            _experimentIdToExperimentMap = self.generateExperimentIdToExperimentMap()
        }
        return _experimentIdToExperimentMap!
    }
    private var _experimentKeyToExperimentMap:[String:Experiment]?
    var experimentKeyToExperimentMap:[String:Experiment] {
        if (_experimentKeyToExperimentMap == nil) {
            _experimentKeyToExperimentMap = [String:Experiment]()
            _experimentKeyToExperimentMap = self.generateExperimentKeyToExperimentMap()
        }
        return _experimentKeyToExperimentMap!
    }
    private var _experimentKeyToExperimentIdMap:[String:String]?
    var experimentKeyToExperimentIdMap:[String:String] {
        if (_experimentKeyToExperimentIdMap == nil) {
            _experimentKeyToExperimentIdMap = [String:String]()
            _experimentKeyToExperimentIdMap = self.generateExperimentKeyToIdMap()
        }
        return _experimentKeyToExperimentIdMap!
    }
    var forcedVariationMap = [String:[String:String]]()
    
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

extension ProjectConfig {
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
}

//MARK:- Map generation methods
extension ProjectConfig {
    func generateExperimentIdToExperimentMap() -> [String:Experiment] {
        var dict:[String:Experiment] = [String:Experiment]()
        for experiment in self.allExperiments{
            dict[experiment.id] = experiment
        }
        return dict
    }
    func generateExperimentKeyToExperimentMap() -> [String:Experiment] {
        var dict:[String:Experiment] = [String:Experiment]()
        for experiment in self.allExperiments{
            dict[experiment.key] = experiment
        }
        return dict
    }
    func generateExperimentKeyToIdMap() -> [String:String] {
        var dict:[String:String] = [String:String]()
        for experiment in self.allExperiments{
            dict[experiment.key] = experiment.id
        }
        return dict
    }
}
