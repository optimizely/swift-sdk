//
// Copyright 2019-2021, Optimizely, Inc. and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

extension OptimizelyClient {
    func registerServices(sdkKey: String,
                          logger: OPTLogger,
                          eventDispatcher: OPTEventDispatcher,
                          datafileHandler: OPTDatafileHandler,
                          decisionService: OPTDecisionService,
                          notificationCenter: OPTNotificationCenter) {
        // Register my logger service. Bind it as a non-singleton. So, we will create an instance anytime injected.
        //   we don't associate the logger with a sdkKey at this time because not all components are sdkKey specific.
        HandlerRegistryService.shared.registerBinding(binder: Binder<OPTLogger>(service: OPTLogger.self, factory: type(of: logger).init))
        
        // This is bound a reusable singleton. so, if we re-initalize, we will keep this.
        HandlerRegistryService.shared.registerBinding(binder: Binder<OPTNotificationCenter>(sdkKey: sdkKey, service: OPTNotificationCenter.self, strategy: .reUse, isSingleton: true, inst: notificationCenter))
        
        // The decision service is also a singleton that will reCreate on re-initalize
        HandlerRegistryService.shared.registerBinding(binder: Binder<OPTDecisionService>(sdkKey: sdkKey, service: OPTDecisionService.self, strategy: .reUse, isSingleton: true, inst: decisionService))
        
        // An event dispatcher. We use a singleton and use the same Event dispatcher for all
        // projects.  If you change the event dispatcher, you can potentially lose data if you
        // don't use the same backingstore.
        HandlerRegistryService.shared.registerBinding(binder: Binder<OPTEventDispatcher>(sdkKey: sdkKey, service: OPTEventDispatcher.self, strategy: .reUse, isSingleton: true, inst: eventDispatcher))
        
        // This is a singleton and might be a good candidate for reuse.  The handler supports mulitple
        // sdk keys without having to be created for every key.
        HandlerRegistryService.shared.registerBinding(binder: Binder<OPTDatafileHandler>(sdkKey: sdkKey, service: OPTDatafileHandler.self, strategy: .reUse, isSingleton: true, inst: datafileHandler))
    }
    
    /// OptimizelyClient init
    ///
    /// - Parameters:
    ///   - sdkKey: sdk key
    ///   - logger: custom Logger
    ///   - eventDispatcher: custom EventDispatcher (optional)
    ///   - datafileHandler: custom datafile handler (optional)
    ///   - userProfileService: custom UserProfileService (optional)
    ///   - periodicDownloadInterval: interval in secs for periodic background datafile download.
    ///         The recommended value is 10 * 60 secs (you can also set this to nil to use the recommended value).
    ///         Set this to 0 to disable periodic downloading.
    ///   - defaultLogLevel: default log level (optional. default = .info)
    ///   - defaultDecisionOptions: default decision optiopns (optional)
    public convenience init(sdkKey: String,
                            logger: OPTLogger? = nil,
                            eventDispatcher: OPTEventDispatcher? = nil,
                            datafileHandler: OPTDatafileHandler? = nil,
                            userProfileService: OPTUserProfileService? = nil,
                            periodicDownloadInterval: Int?,
                            defaultLogLevel: OptimizelyLogLevel? = nil,
                            defaultDecideOptions: [OptimizelyDecideOption]? = nil) {
        
        self.init(sdkKey: sdkKey,
                  logger: logger,
                  eventDispatcher: eventDispatcher,
                  datafileHandler: datafileHandler,
                  userProfileService: userProfileService,
                  defaultLogLevel: defaultLogLevel,
                  defaultDecideOptions: defaultDecideOptions)
        
        let interval = periodicDownloadInterval ?? 10 * 60
        if interval > 0 {
            self.currentDatafileHandler?.setPeriodicInterval(sdkKey: sdkKey, interval: interval)
        }
    }

}
