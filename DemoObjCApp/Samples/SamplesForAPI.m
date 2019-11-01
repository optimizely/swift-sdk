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

#import "SamplesForAPI.h"
#import "CustomLogger.h"
#import "CustomUserProfileService.h"
@import Optimizely;

@implementation SamplesForAPI

+(void)run {
    NSString *sdkKey = @"AqLkkcss3wRGUbftnKNgh2";    // SDK Key for your project
    NSString *datafileName = [NSString stringWithFormat:@"demoTestDatafile_%@", sdkKey];

    // MARK: - initialization
       
    OptimizelyClient *optimizely;
       
    // (1) create SDK client with default SDK settings
    optimizely = [[OptimizelyClient alloc] initWithSdkKey:sdkKey];
       
    // (2) or create SDK client with custom service handlers
    CustomLogger *customLogger = [[CustomLogger alloc] init];
    
    CustomUserProfileService *customUserProfileService = [[CustomUserProfileService alloc] init];
    
    HTTPEventDispatcher *customDispatcher = [[HTTPEventDispatcher alloc] init];
    BatchEventProcessor *customProcessor = [[BatchEventProcessor alloc] initWithEventDispatcher:customDispatcher
                                                                                      batchSize:10
                                                                                  timerInterval:60
                                                                                   maxQueueSize:1000];

    optimizely = [[OptimizelyClient alloc] initWithSdkKey:sdkKey
                                                   logger:customLogger
                                           eventProcessor:customProcessor
                                          eventDispatcher:nil
                                       userProfileService:customUserProfileService
                                 periodicDownloadInterval:nil
                                          defaultLogLevel:OptimizelyLogLevelDebug];
    
    // MARK: - start
       
    // (1) start SDK synchronously
    NSString *localDatafilePath = [[NSBundle mainBundle] pathForResource:datafileName ofType:@"json"];
    NSString *datafileJSON = [NSString stringWithContentsOfFile:localDatafilePath encoding:NSUTF8StringEncoding error:nil];
    
    NSError *error = nil;
    BOOL status = [optimizely startWithDatafile:datafileJSON error:&error];
    if (status) {
        NSLog(@"[SamplesForAPI] Optimizely SDK initiliazation synchronously------");
        [self runAPISamples:optimizely];
    } else {
        NSLog(@"[SamplesForAPI] Optimizely SDK initiliazation failed: %@", error.localizedDescription);
    }
                         
    // (2) or start SDK asynchronously
    [optimizely startWithCompletion:^(NSData *data, NSError *error) {
        if (error == nil) {
            NSLog(@"[SamplesForAPI] Optimizely SDK initiliazation asynchronously------");
            [self runAPISamples:optimizely];
        } else {
            NSLog(@"[SamplesForAPI] Optimizely SDK initiliazation failed: %@", error.localizedDescription);
        }
    }];
}
     
+(void)runAPISamples:(OptimizelyClient*)optimizely {
    
    NSString *featureKey = @"demo_feature";
    NSString *experimentKey = @"demo_experiment";
    NSString *variationKey = @"variation_a";
    NSString *variableKey = @"discount";
    NSString *eventKey = @"sample_conversion";
    NSString *userId = @"user_123";

    NSDictionary *attributes = @{
                                 @"device": @"iPhone",
                                 @"lifetime": @24738388,
                                 @"is_logged_in": @true
                                 };
    
    NSDictionary *tags = @{
                           @"category" : @"shoes",
                           @"count": @5
                           };
    
    // MARK: - activate

    {
        NSError *error = nil;
        NSString *variationKey = [optimizely activateWithExperimentKey:experimentKey
                                                                userId:userId
                                                            attributes:attributes
                                                                 error:&error];
        if (variationKey == nil) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"[activate] %@", variationKey);
        }
    }
    
    // MARK: - getVariationKey

    {
        NSError *error = nil;
        NSString *variationKey = [optimizely getVariationKeyWithExperimentKey:experimentKey
                                                                       userId:userId
                                                                   attributes:attributes
                                                                        error:&error];
        if (variationKey == nil) {
            NSLog(@"[SamplesForAPI] Error: %@", error);
        } else {
            NSLog(@"[SamplesForAPI][getVariationKey] %@", variationKey);
        }
    }
    
    // MARK: - getForcedVariation

    {
        NSString *variationKey = [optimizely getForcedVariationWithExperimentKey:experimentKey
                                                                          userId:userId];
        NSLog(@"[SamplesForAPI][getForcedVariation] %@", variationKey);
    }
    
    // MARK: - setForcedVariation

    {
        BOOL result = [optimizely setForcedVariationWithExperimentKey:experimentKey
                                                               userId:userId
                                                         variationKey:variationKey];
        NSLog(@"[SamplesForAPI][setForcedVariation] %d", result);
    }
    
    // MARK: - isFeatureEnabled
    
    {
        BOOL enabled = [optimizely isFeatureEnabledWithFeatureKey:featureKey
                                                                userId:userId
                                                            attributes:attributes];
        
        NSLog(@"[SamplesForAPI][isFeatureEnabled] %@", enabled ? @"YES": @"NO");
    }
    
    // MARK: - getFeatureVariable

    {
        NSError *error = nil;
        NSNumber *featureVariableValue = [optimizely getFeatureVariableIntegerWithFeatureKey:featureKey
                                                                                 variableKey:variableKey
                                                                                      userId:userId
                                                                                  attributes:attributes
                                                                                       error:&error];
        if (featureVariableValue == nil) {
            NSLog(@"[SamplesForAPI] Error: %@", error);
        } else {
            NSLog(@"[SamplesForAPI][getFeatureVariableDouble] %@", featureVariableValue);
        }
    }
    
    // MARK: - getEnabledFeatures

    {
        NSArray *enabledFeatures = [optimizely getEnabledFeaturesWithUserId:userId
                                                                 attributes:attributes];
        NSLog(@"[SamplesForAPI][getEnabledFeatures] %@", [enabledFeatures componentsJoinedByString:@", "]);
    }
    
    // MARK: - track

    {
        NSError *error = nil;
        BOOL success = [optimizely trackWithEventKey:eventKey
                                              userId:userId
                                          attributes:attributes
                                           eventTags:tags
                                               error:&error];
        if (success == false) {
            NSLog(@"[SamplesForAPI] Error: %@", error);
        } else {
            NSLog(@"[SamplesForAPI][track]");
        }
    }
    
}

@end
