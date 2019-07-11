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

extension OptimizelyClient {
    func registerServices(sdkKey: String,
                          logger: OPTLogger,
                          eventDispatcher: OPTEventDispatcher,
                          datafileHandler: OPTDatafileHandler,
                          decisionService: OPTDecisionService,
                          notificationCenter: OPTNotificationCenter) {
        // bind it as a non-singleton.  so, we will create an instance anytime injected.
        // we don't associate the logger with a sdkKey at this time because not all components are sdkKey specific.
        let binder: Binder = Binder<OPTLogger>(service: OPTLogger.self).to(factory: type(of: logger).init)
        //Register my logger service.
        HandlerRegistryService.shared.registerBinding(binder: binder)
        
        // this is bound a reusable singleton. so, if we re-initalize, we will keep this.
        HandlerRegistryService.shared.registerBinding(binder: Binder<OPTNotificationCenter>(service: OPTNotificationCenter.self).singetlon().reInitializeStrategy(strategy: .reUse).using(instance: notificationCenter).sdkKey(key: sdkKey))
        
        // the decision service is also a singleton that will reCreate on re-initalize
        HandlerRegistryService.shared.registerBinding(binder: Binder<OPTDecisionService>(service: OPTDecisionService.self).singetlon().using(instance: decisionService).reInitializeStrategy(strategy: .reUse).sdkKey(key: sdkKey))
        
        // An event dispatcher.  We use a singleton and use the same Event dispatcher for all
        // projects.  If you change the event dispatcher, you can potentially lose data if you
        // don't use the same backingstore.
        HandlerRegistryService.shared.registerBinding(binder: Binder<OPTEventDispatcher>(service: OPTEventDispatcher.self).singetlon().reInitializeStrategy(strategy: .reUse).using(instance: eventDispatcher).sdkKey(key: sdkKey))
        
        // This is a singleton and might be a good candidate for reuse.  The handler supports mulitple
        // sdk keys without having to be created for every key.
        HandlerRegistryService.shared.registerBinding(binder: Binder<OPTDatafileHandler>(service: OPTDatafileHandler.self).singetlon().reInitializeStrategy(strategy: .reUse).to(factory: type(of: datafileHandler).init).using(instance: datafileHandler).sdkKey(key: sdkKey))
    }
    
    /// Optimizely Manager
    ///
    /// - Parameters:
    ///   - sdkKey: sdk key
    ///   - logger: custom Logger
    ///   - eventDispatcher: custom EventDispatcher (optional)
    ///   - userProfileService: custom UserProfileService (optional)
    ///   - periodicDownloadInterval: custom interval for periodic background datafile download (optional. default = 10 * 60 secs)
    ///   - defaultLogLevel: default log level (optional. default = .info)
    public convenience init(sdkKey: String,
                            logger: OPTLogger? = nil,
                            eventDispatcher: OPTEventDispatcher? = nil,
                            userProfileService: OPTUserProfileService? = nil,
                            periodicDownloadInterval: Int? = nil,
                            defaultLogLevel: OptimizelyLogLevel? = nil) {
        let interval = periodicDownloadInterval ?? 10 * 60
        
        self.init(sdkKey: sdkKey, logger: logger, eventDispatcher: eventDispatcher, userProfileService: userProfileService, defaultLogLevel: defaultLogLevel)
        
        if let handler = datafileHandler as? DefaultDatafileHandler, interval > 0 {
            handler.setTimer(sdkKey: sdkKey, interval: interval)
        }
        
    }

}
