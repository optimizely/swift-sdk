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

#import "AppDelegate.h"
#import "VariationViewController.h"
#import "CustomLogger.h"
#import "SamplesForAPI.h"

@import Optimizely;


static NSString * const kOptimizelySdkKey = @"FCnSegiEkRry9rhVMroit4";
static NSString * const kOptimizelyDatafileName = @"demoTestDatafile";
static NSString * const kOptimizelyFeatureKey = @"decide_demo";
static NSString * const kOptimizelyExperimentKey = @"background_experiment_decide";
static NSString * const kOptimizelyEventKey = @"sample_conversion";

@interface AppDelegate ()
@property(nonnull, strong, nonatomic) NSString *userId;
@property(nonnull, strong, nonatomic) NSDictionary *attributes;
@property(nullable, strong, nonatomic) OptimizelyClient *optimizely;
@property(nullable, strong, nonatomic) OptimizelyUserContext *user;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.userId = [NSString stringWithFormat:@"%d", arc4random_uniform(300000)];
    self.attributes = @{ @"location": @"CA", @"semanticVersioning": @"1.2"};

    // initialize SDK in one of these two ways:
    // (1) asynchronous SDK initialization (RECOMMENDED)
    //     - fetch a JSON datafile from the server
    //     - network delay, but the local configuration is in sync with the server experiment settings
    // (2) synchronous SDK initialization
    //     - initialize immediately with the given JSON datafile or its cached copy
    //     - no network delay, but the local copy is not guaranteed to be in sync with the server experiment settings
    
    [self initializeOptimizelySDKWithCustomization];
    return YES;
}

// MARK: - Initialization Examples

-(void)initializeOptimizelySDKAsynchronous {
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey:kOptimizelySdkKey
                                                        logger:nil
                                               eventDispatcher:nil
                                            userProfileService:nil
                                      periodicDownloadInterval:@(5)
                                               defaultLogLevel:OptimizelyLogLevelDebug];
    
    [self.optimizely startWithCompletion:^(NSData *data, NSError *error) {
        if (error == nil) {
            NSLog(@"Optimizely SDK initialized successfully!");
        } else {
            NSLog(@"Optimizely SDK initiliazation failed: %@", error.localizedDescription);
        }
        
        [self startWithRootViewController];
    }];
}

-(void)initializeOptimizelySDKSynchronous {
    NSString *localDatafilePath = [[NSBundle mainBundle] pathForResource:kOptimizelyDatafileName ofType:@"json"];
    if (localDatafilePath == nil) {
        NSAssert(false, @"Local datafile cannot be found");
        return;
    }
    
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey:kOptimizelySdkKey];
    
    NSString *datafileJSON = [NSString stringWithContentsOfFile:localDatafilePath encoding:NSUTF8StringEncoding error:nil];
    
    if (datafileJSON == nil) {
        NSLog(@"Invalid JSON format");
    } else {
        NSError *error;
        BOOL status = [self.optimizely startWithDatafile:datafileJSON error:&error];
        if (status) {
            NSLog(@"Optimizely SDK initialized successfully!");
        } else {
            NSLog(@"Optimizely SDK initiliazation failed: %@", error.localizedDescription);
        }
    }
    
    [self startWithRootViewController];
}

-(void)initializeOptimizelySDKWithCustomization {
    // customization example (optional)
    
    // You can enable background datafile polling by setting periodicDownloadInterval (polling is disabled by default)
    // 60 sec interval may be too frequent. This is for demo purpose. (You can set this to nil to use the recommended value of 600 secs).
    NSNumber *downloadIntervalInSecs = @(60);
    
    // You can turn off event batching with 0 timerInterval (this means that events are sent out immediately to the server instead of saving in the local queue for batching)
    DefaultEventDispatcher *eventDispatcher = [[DefaultEventDispatcher alloc] initWithBatchSize:10
                                                                                  timerInterval:0
                                                                                   maxQueueSize:1000];
    
    // customize logger
    CustomLogger *customLogger = [[CustomLogger alloc] init];

    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey:kOptimizelySdkKey
                                                         logger:customLogger
                                                eventDispatcher:eventDispatcher
                                             userProfileService:nil
                                       periodicDownloadInterval:downloadIntervalInSecs
                                                defaultLogLevel:OptimizelyLogLevelDebug];
    
    [self addNotificationListeners];
    
    [self.optimizely startWithCompletion:^(NSData *data, NSError *error) {
        if (error == nil) {
            NSLog(@"Optimizely SDK initialized successfully!");
        } else {
            NSLog(@"Optimizely SDK initiliazation failed: %@", error.localizedDescription);
        }
        
        [self startWithRootViewController];
        
        // For sample codes for APIs, see "Samples/SamplesForAPI.swift"
        //[SamplesForAPI checkOptimizelyConfig:self.optimizely];
        //[SamplesForAPI checkOptimizelyUserContext:self.optimizely];
    }];
}

-(void)addNotificationListeners {
    NSNumber *notifId;
    notifId = [self.optimizely.notificationCenter addDecisionNotificationListenerWithDecisionListener:^(NSString *type,
                                                                                              NSString *userId,
                                                                                              NSDictionary<NSString *,id> *attributes,
                                                                                              NSDictionary<NSString *,id> *decisionInfo) {
        NSLog(@"Received decision notification: %@ %@ %@ %@", type, userId, attributes, decisionInfo);
    }];
    
    notifId = [self.optimizely.notificationCenter addTrackNotificationListenerWithTrackListener:^(NSString *eventKey,
                                                                                                  NSString *userId,
                                                                                                  NSDictionary<NSString *,id> *attributes, NSDictionary<NSString *,id> *eventTags, NSDictionary<NSString *,id> *event) {
        NSLog(@"Received track notification: %@ %@ %@ %@ %@", eventKey, userId, attributes, eventTags, event);
        
    }];
    
    notifId = [self.optimizely.notificationCenter addLogEventNotificationListenerWithLogEventListener:^(NSString *url,
                                                                                                        NSDictionary<NSString *,id> *event) {
        NSLog(@"Received logEvent notification: %@ %@", url, event);
    }];
}


// MARK: - ViewControl

-(void)startWithRootViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        // For sample codes for other APIs, see "Samples/SamplesForAPI.m"

        self.user = [self.optimizely createUserContextWithUserId:self.userId
                                                      attributes:self.attributes];
        
        OptimizelyDecision *decision = [self.user decideWithKey:kOptimizelyFeatureKey
                                                        options:@[@(OptimizelyDecideOptionIncludeReasons)]];

        if (decision.variationKey != nil) {
            [self openVariationViewWithVariationKey:decision.variationKey];
        } else {
            NSLog(@"Optimizely SDK activation failed: %@", decision.reasons);
            [self openFailureView];
        }
    });
}

-(void)openVariationViewWithVariationKey:(nullable NSString*)variationKey {
    VariationViewController *variationViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"VariationViewController"];
    
    variationViewController.optimizely = self.optimizely;
    variationViewController.userId = self.userId;
    variationViewController.variationKey = variationKey;
    variationViewController.eventKey = kOptimizelyEventKey;
    
    self.window.rootViewController = variationViewController;
}

-(void)openFailureView {
    self.window.rootViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FailureViewController"];
}

-(UIStoryboard*)storyboard {
#if TARGET_OS_IOS
    return [UIStoryboard storyboardWithName:@"iOSMain" bundle:nil];
#else
    return [UIStoryboard storyboardWithName:@"tvOSMain" bundle:nil];
#endif
}

// MARK: - AppDelegate

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
