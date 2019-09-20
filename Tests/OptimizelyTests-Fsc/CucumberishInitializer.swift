import XCTest
import Foundation
import Cucumberish

class CucumberishInitializer: NSObject {
    
    @objc class func setupCucumberish(){
        
        AudienceTargetingTests.setup()
        let bundle = Bundle(for: CucumberishInitializer.self)
        Cucumberish.instance()?.fixMissingLastScenario = true
        Cucumberish.instance()?.prettyNamesAllowed = true
        Cucumberish.executeFeatures(inDirectory: "Features", from: bundle, includeTags: self.getIncludedTags() , excludeTags: self.getExcludedTags())
    }
    
    fileprivate class func getExcludedTags() -> [String]? {
        return ["EVENT_BATCHING","DATAFILE_MANAGER","NO_EASY_EVENT_TRACKING","DYNAMIC_LANGUAGES","OASIS-3654","GET_FEATURE_VAR","OASIS-3582","EVENT_FLUSH"]
    }
    
    fileprivate class func getIncludedTags() -> [String]? {
        return ["FEATURE_ROLLOUT","ALL"]
    }
}
