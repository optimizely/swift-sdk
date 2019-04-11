//
//  AppDelegate.m
//  DemoObjcApp
//
//  Created by Jae Kim on 1/7/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

#import "AppDelegate.h"
#import "VariationViewController.h"
#import "FailureViewController.h"

@import Optimizely;
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
@property(nullable, strong, nonatomic) OptimizelyManager *optimizely;
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
    self.optimizely = [[OptimizelyManager alloc] initWithSdkKey:kOptimizelySdkKey];

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
    
    self.optimizely = [[OptimizelyManager alloc] initWithSdkKey:kOptimizelySdkKey];
    
    // customization example (optional)
    // TODO: add cutomization for ObjC
    
    NSString *datafileJSON = [NSString stringWithContentsOfFile:localDatafilePath encoding:NSUTF8StringEncoding error:nil];
        
    if (datafileJSON == nil) {
        NSLog(@"Invalid JSON format");
        self.optimizely = nil;
    } else {
        NSError *error;
        BOOL status = [self.optimizely initializeSDKWithDatafile:datafileJSON error:&error];
        if (status) {
            NSLog(@"Optimizely SDK initialized successfully!");
        } else {
            NSLog(@"Optimizely SDK initiliazation failed: %@", error.localizedDescription);
            self.optimizely = nil;
        }
    }
    
    [self startAppWithExperimentActivated];
}
     
-(void)startAppWithExperimentActivated {
    NSError *error;
    NSString *variationKey = [self.optimizely activateWithExperimentKey:kOptimizelyExperimentKey
                                                                 userId:self.userId
                                                             attributes:self.attributes
                                                                  error:&error];
    
    if (variationKey == nil) {
        NSLog(@"Optimizely SDK activation failed: %@", error.localizedDescription);
        self.optimizely = nil;
    }


    [self setRootViewControllerWithOtimizelyManager:self.optimizely bucketedVariation:variationKey];
}

-(void)setRootViewControllerWithOtimizelyManager:(OptimizelyManager*)manager bucketedVariation:(NSString*)variationKey {
    dispatch_async(dispatch_get_main_queue(), ^{
        
#if TARGET_OS_IOS
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iOSMain" bundle:nil];
#else
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"tvOSMain" bundle:nil];
#endif
        UIViewController *rootViewController;
        
        if ((manager != nil) && (variationKey != nil)) {
            VariationViewController *vc = [storyboard instantiateViewControllerWithIdentifier: @"VariationViewController"];
            
            vc.eventKey = kOptimizelyEventKey;
            vc.optimizely = manager;
            vc.userId = self.userId;
            vc.variationKey = variationKey;

            rootViewController = vc;
        } else {
            rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"FailureViewController"];
        }
            
        self.window.rootViewController = rootViewController;
    });
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
