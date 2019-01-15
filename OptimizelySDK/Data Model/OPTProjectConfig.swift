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

public class OPTProjectConfig : Codable
{
    var version:String = ""
    var rollouts:[OPTRollout]? = []
    var typedAudiences:[OPTAudience]? = []
    var anonymizeIP:Bool? = true
    var projectId:String = ""
    var variables:[OPTVariable]? = []
    var featureFlags:[OPTFeatureFlag]? = []
    var experiments:[OPTExperiment] = []
    var audiences:[OPTAudience] = []
    var groups:[OPTGroup] = []
    var attributes:[OPTAttribute] = []
    var botFiltering:Bool? = false
    var accountId:String = ""
    var events:[OPTEvent]? = []
    var revision:String = ""
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

extension OPTProjectConfig {
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
