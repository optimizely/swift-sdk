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
    
    func Populate(dictionary:NSDictionary) {
        
        version = dictionary["version"] as! String
        rollouts = Rollout.PopulateArray(array: dictionary["rollouts"] as? NSArray ?? [])
        typedAudiences = Audience.PopulateArray(array: dictionary["typedAudiences"] as? NSArray ?? [])
        anonymizeIP = dictionary["anonymizeIP"] as? Bool
        projectId = dictionary["projectId"] as! String
        variables = Variable.PopulateArray(array: dictionary["variables"] as? NSArray ?? [])
        featureFlags = FeatureFlag.PopulateArray(array: dictionary["featureFlags"] as? NSArray ?? [])
        experiments = Experiment.PopulateArray(array: dictionary["experiments"] as! [NSArray] as NSArray)
        audiences = Audience.PopulateArray(array: dictionary["audiences"] as! NSArray)
        groups = Group.PopulateArray(array: dictionary["groups"] as? NSArray ?? [])
        attributes = Attribute.PopulateArray(array: dictionary["attributes"] as? NSArray ?? [])
        botFiltering = dictionary["botFiltering"] as? Bool
        accountId = dictionary["accountId"] as! String
        events = Event.PopulateArray(array: dictionary["events"] as? NSArray ?? [])
        revision = dictionary["revision"] as! String
    }
    
    class func DateFromString(dateString:String) -> NSDate
    {
        let dateFormatter = DateFormatter()
        let enUSPosixLocale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale as Locale
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return dateFormatter.date(from: dateString)! as NSDate
    }
    class func Populate(data:NSData) -> ProjectConfig
    {
        let json = try? JSONSerialization.jsonObject(with: data as Data, options: [])
        return Populate(dictionary:json as! NSDictionary)
    }
    
    class func Populate(dictionary:NSDictionary) -> ProjectConfig
    {
        let result = ProjectConfig()
        result.Populate(dictionary: dictionary)
        return result
    }
    
}
