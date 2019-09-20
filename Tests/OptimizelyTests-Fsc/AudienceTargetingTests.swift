import XCTest
import Foundation
import Cucumberish

class AudienceTargetingTests: NSObject {
    
    static func setup() {
        self.setupBackgroundScenarios()
        beforeStart { () -> Void in
            print("start")
            //Setup sdk here
        }
        
        before { (scenario) in
        }
        
        setupAndListeners()
        setupWhenListeners()
        setupThenListeners()
    }
    
    private static func setupBackgroundScenarios() {
        
        Given("^the datafile is \"([^\\\"]*)\"$") { (args, userInfo) -> Void in
            let datafileName = (args?[0])!
            print(datafileName)
        }
        
        And("^([1-9]{1}) \"([^\\\"]*)\" listener is added$") { (args, userInfo) -> Void in
            let numberOfListeners = (args?[0])!
            let listenerType = (args?[1])!
            
            print(numberOfListeners)
            print(listenerType)
        }
    }
    
    private static func setupAndListeners() {
        
        And("^in the response, \"listener_called\" should be \"([^\\\"]*)\"$") { (args, userInfo) -> Void in
            let listenerCalled = (args?[0])!
        }
        And("^there are no dispatched events$") { (args, userInfo) -> Void in
        }
    }
    
    private static func setupWhenListeners() {
        
        When("^([^\\\"]*) is called with arguments") { (args, userInfo) -> Void in
            let apiType: String = (args?[0])!
            var parameterDictionary: [String:Any?]?
            if let parameters = userInfo?["DocString"] as? String {
                parameterDictionary = YAMLParser.getMapFromYAML(value: parameters)
            }
            print(apiType)
            print(parameterDictionary)
        }
    }
    
    private static func setupThenListeners() {
        
        Then("^the result should be ([^\\\"]*)$") { (args, userInfo) -> Void in
            let result: String = (args?[0])!
            print(result)
        }
        
        Then("^the result should be (?:boolean )?\"([^\\\"]*)\"$") { (args, userInfo) -> Void in
            let result: String = (args?[0])!
            print(result)
        }
    }
}
