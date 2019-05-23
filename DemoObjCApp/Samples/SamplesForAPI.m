//
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
@import Optimizely;

@implementation SamplesForAPI

+(void)run:(OptimizelyClient*)optimizely {    
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
        NSString *variationKey = [optimizely activateWithExperimentKey:@"my_experiment_key"
                                                                userId:@"user_123"
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
        NSString *variationKey = [optimizely getVariationKeyWithExperimentKey:@"my_experiment_key"
                                                                       userId:@"user_123"
                                                                   attributes:attributes
                                                                        error:&error];
        if (variationKey == nil) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"[getVariationKey] %@", variationKey);
        }
    }
    
    // MARK: - getForcedVariation

    {
        NSString *variationKey = [optimizely getForcedVariationWithExperimentKey:@"my_experiment_key"
                                                                          userId:@"user_123"];
        NSLog(@"[getForcedVariation] %@", variationKey);
    }
    
    // MARK: - setForcedVariation

    {
        BOOL result = [optimizely setForcedVariationWithExperimentKey:@"my_experiment_key"
                                                               userId:@"user_123"
                                                         variationKey:@"some_variation_key"];
        NSLog(@"[setForcedVariation] %d", result);
    }
    
    // MARK: - isFeatureEnabled
    
    {
        BOOL enabled = [optimizely isFeatureEnabledWithFeatureKey:@"my_feature_key"
                                                                userId:@"user_123"
                                                            attributes:attributes];
        
        NSLog(@"[isFeatureEnabled] %@", enabled ? @"YES": @"NO");
    }
    
    // MARK: - getFeatureVariable

    {
        NSError *error = nil;
        NSNumber *featureVariableValue = [optimizely getFeatureVariableDoubleWithFeatureKey:@"my_feature_key"
                                                                                variableKey:@"double_variable_key"
                                                                                     userId:@"user_123"
                                                                                 attributes:attributes
                                                                                      error:&error];
        if (featureVariableValue == nil) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"[getFeatureVariableDouble] %@", featureVariableValue);
        }
    }
    
    // MARK: - getEnabledFeatures

    {
        NSArray *enabledFeatures = [optimizely getEnabledFeaturesWithUserId:@"user_123"
                                                                 attributes:attributes];
        NSLog(@"[getEnabledFeatures] %@", enabledFeatures);
    }
    
    // MARK: - track

    {
        NSError *error = nil;
        BOOL success = [optimizely trackWithEventKey:@"my_purchase_event_key"
                                              userId:@"user_123"
                                          attributes:attributes
                                           eventTags:tags
                                               error:&error];
        if (success == false) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"[track]");
        }
    }
    
}

@end
