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

#import "AppDelegate.h"
#import "VariationViewController.h"
#import "CustomLogger.h"
#import "SamplesForAPI.h"

@import Optimizely;


static NSString * const kOptimizelySdkKey = @"FCnSegiEkRry9rhVMroit4";
static NSString * const kOptimizelyDatafileName = @"demoTestDatafile";
static NSString * const kOptimizelyExperimentKey = @"background_experiment";
static NSString * const kOptimizelyEventKey = @"sample_conversion";

@interface AppDelegate ()
@property(nonnull, strong, nonatomic) NSString *userId;
@property(nonnull, strong, nonatomic) NSDictionary *attributes;
@property(nullable, strong, nonatomic) OptimizelyClient *optimizely;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.userId = [NSString stringWithFormat:@"%d", arc4random_uniform(300000)];
    self.attributes = @{ @"browser_type": @"safari" };
    
    // initialize SDK in one of these two ways:
    // (1) asynchronous SDK initialization (RECOMMENDED)
    //     - fetch a JSON datafile from the server
    //     - network delay, but the local configuration is in sync with the server experiment settings
    // (2) synchronous SDK initialization
    //     - initialize immediately with the given JSON datafile or its cached copy
    //     - no network delay, but the local copy is not guaranteed to be in sync with the server experiment settings
    
    [self initializeOptimizelySDKAsynchronous];
    return YES;
}

// MARK: - Initialization Examples

-(void)initializeOptimizelySDKAsynchronous {
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey:kOptimizelySdkKey];
    
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
    NSString *datafileName = [NSString stringWithFormat:@"%@_%@", kOptimizelyDatafileName, kOptimizelySdkKey];
    NSString *localDatafilePath = [[NSBundle mainBundle] pathForResource:datafileName ofType:@"json"];
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
    
    CustomLogger *customLogger = [[CustomLogger alloc] init];
    // 30 sec interval may be too frequent. This is for demo purpose.
    // This should be should be much larger (default = 10 mins).
    NSNumber *customDownloadIntervalInSecs = @(30);
    
    HTTPEventDispatcher *customDispatcher = [[HTTPEventDispatcher alloc] init];
    BatchEventProcessor *customProcessor = [[BatchEventProcessor alloc] initWithEventDispatcher:customDispatcher
                                                                                      batchSize:10
                                                                                  timerInterval:30
                                                                                   maxQueueSize:1000];    
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey:kOptimizelySdkKey
                                                        logger:customLogger
                                                eventProcessor:customProcessor
                                               eventDispatcher:nil
                                            userProfileService:nil
                                      periodicDownloadInterval:customDownloadIntervalInSecs
                                               defaultLogLevel:OptimizelyLogLevelDebug];
    
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
    
    [self.optimizely startWithCompletion:^(NSData *data, NSError *error) {
        if (error == nil) {
            NSLog(@"Optimizely SDK initialized successfully!");
        } else {
            NSLog(@"Optimizely SDK initiliazation failed: %@", error.localizedDescription);
        }
        
        [self startWithRootViewController];
    }];
}

// MARK: - ViewControl

-(void)startWithRootViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        // For sample codes for other APIs, see "Samples/SamplesForAPI.m"
        
        NSError *error;
        NSString *variationKey = [self.optimizely activateWithExperimentKey:kOptimizelyExperimentKey
                                                                     userId:self.userId
                                                                 attributes:self.attributes
                                                                      error:&error];
        
        if (variationKey != nil) {
            [self openVariationViewWithVariationKey:variationKey];
        } else {
            NSLog(@"Optimizely SDK activation failed: %@", error.localizedDescription);
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
