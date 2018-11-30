//
//  ProjectConfig.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/27/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

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
