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

class ProjectConfig : Codable
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

    class func DateFromString(dateString:String) -> NSDate
    {
        let dateFormatter = DateFormatter()
        let enUSPosixLocale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale as Locale
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return dateFormatter.date(from: dateString)! as NSDate
    }
}
