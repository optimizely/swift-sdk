//
//  AppDelegate.m
//  DemoObjcApp
//
//  Created by Jae Kim on 1/7/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

#import "AppDelegate.h"
@import OptimizelySwiftSDK;
#if TARGET_OS_IOS
    @import Amplitude_iOS;
#endif

static NSString * const kOptimizelyDatafileName = @"demoTestDatafile";
static NSString * const kOptimizelyExperimentKey = @"background_experiment";
static NSString * const kOptimizelyEventKey = @"sample_conversion";
static NSString * const kOptimizelySdkKey = @"AqLkkcss3wRGUbftnKNgh2";


@interface AppDelegate ()
@property(nonnull, strong, nonatomic) NSString *userId;
@property(nonnull, strong, nonatomic) NSDictionary *attributes;
@property(nullable, strong, nonatomic) OPTManager *optimizely;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.userId = [NSString stringWithFormat:@"%d", arc4random()];
    self.attributes = @{ @"browser_type": @"safari" };
    
    // initialize SDK in one of these two ways:
    // (1) asynchronous SDK initialization (RECOMMENDED)
    //     - fetch a JSON datafile from the server
    //     - network delay, but the local configuration is in sync with the server experiment settings
    // (2) synchronous SDK initialization
    //     - initialize immediately with the given JSON datafile or its cached copy
    //     - no network delay, but the local copy is not guaranteed to be in sync with the server experiment settings

    [self initializeOptimizelySDKAsynchronous];
    //[self initializeOptimizelySDKSynchronous];

    return YES;
}

-(void)initializeOptimizelySDKAsynchronous {
    self.optimizely = [[OPTManager alloc] initWithSdkKey:kOptimizelySdkKey];
    
    [self.optimizely initializeSDKWithCompletion:^(NSError * _Nullable error, NSData * _Nullable data) {
        if (error == nil) {
            NSLog(@"Optimizely SDK initialized successfully!");
        } else {
            NSLog(@"Optimizely SDK initiliazation failed: %@", error.localizedDescription);
            self.optimizely = nil;
        }
        
        [self startAppWithExperimentActivated];
    }];
}

-(void)initializeOptimizelySDKSynchronous {
    NSString *localDatafilePath = [[NSBundle bundleForClass:self.classForCoder] pathForResource:kOptimizelyDatafileName ofType:@"json"];
    if (localDatafilePath == nil) {
        NSAssert(false, @"Local datafile cannot be found");
        self.optimizely = nil;
        return;
    }
    
    self.optimizely = [[OPTManager alloc] initWithSdkKey:kOptimizelySdkKey];
    
    NSError *error = nil;
    NSString *datafileJSON = [NSString stringWithContentsOfFile:localDatafilePath encoding:NSUTF8StringEncoding error:&error];
        
    if (error == nil) {
        [self.optimizely initializeSDKWithDatafile:datafileJSON error:&error];
        if (error == nil) {
            NSLog(@"Optimizely SDK initialized successfully!");
        } else {
            NSLog(@"Optimizely SDK initiliazation failed: %@", error.localizedDescription);
            self.optimizely = nil;
        }
    } else {
        NSLog(@"Invalid JSON format");
        self.optimizely = nil;
    }
    
    [self startAppWithExperimentActivated];
}
     
-(void)startAppWithExperimentActivated {
    
}


-(id<OPTNotificationCenter>)makeCustomNotificationCenter {
//#if os(tvOS)
//    return CustomNotificationCenter()
//#else
//
//
//    // most of the third-party integrations only support iOS, so the sample code is only targeted for iOS builds
//    Amplitude.instance().initializeApiKey("YOUR_API_KEY_HERE")
//
//    let notificationCenter = CustomNotificationCenter()
//
//    notificationCenter.addActivateNotificationListener { (experiment, userId, attributes, variation, event) in
//        Amplitude.instance().logEvent("[Optimizely] \(experiment.key) - \(variation.key)")
//    }
//
//    notificationCenter.addTrackNotificationListener { (eventKey, userId, attributes, eventTags, event) in
//        Amplitude.instance().logEvent("[Optimizely] " + eventKey)
//    }
//
//    return notificationCenter
//
//#endif
    
    return nil;
}

-(void)setRootViewControllerWithOtimizelyManager: OPTManager bucketedVariation:NSString {
}



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
