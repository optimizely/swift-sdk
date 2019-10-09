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
    
    // MARK: - OptimizelyConfig
    
    {
        NSError *error = nil;
        OptimizelyConfig *optConfig = [optimizely getOptimizelyConfigWithError:&error];
        if (optConfig == nil) {
            NSLog(@"Error: %@", error);
            return;
        }
        
        // enumerate all experiments (variations, and associated variables)

        NSDictionary<NSString*, OptimizelyExperiment*> *experimentsMap = optConfig.experimentsMap;
        //NSArray* experiments = experimentsMap.allValues;
        NSArray* experimentKeys = experimentsMap.allKeys;
        NSLog(@"[OptimizelyConfig] all experiment keys = %@)", experimentKeys);

        for(NSString *expKey in experimentKeys) {
            NSLog(@"[OptimizelyConfig] experimentKey = %@", expKey);
            
            NSDictionary<NSString*, OptimizelyVariation*> *variationsMap = experimentsMap[expKey].variationsMap;
            NSArray *variationKeys = variationsMap.allKeys;
            
            for(NSString *varKey in variationKeys) {
                NSLog(@"[OptimizelyConfig]   - variationKey = %@", varKey);
                
                NSDictionary<NSString*, OptimizelyVariable*> *variablesMap = variationsMap[varKey].variablesMap;
                NSArray *variableKeys = variablesMap.allKeys;
                
                for(NSString *variableKey in variableKeys) {
                    OptimizelyVariable *variable = variablesMap[variableKey];
                    
                    NSLog(@"[OptimizelyConfig]       -- variable: \%@, %@", variableKey, variable);
                }
            }
        }
        
        // enumerate all features (experiments, variations, and assocated variables)

        NSDictionary<NSString*, OptimizelyFeatureFlag*> *featuresMap = optConfig.featureFlagsMap;
        //NSArray* features = featuresMap.allValues;
        NSArray* featureKeys = featuresMap.allKeys;
        NSLog(@"[OptimizelyConfig] all experiment keys = %@)", featureKeys);

        for(NSString *featKey in featureKeys) {
            NSLog(@"[OptimizelyConfig] featureKey = %@", featKey);

            // enumerate feature experiments
            
            NSDictionary<NSString*, OptimizelyExperiment*> *experimentsMap = featuresMap[featKey].experimentsMap;
            NSArray *experimentKeys = experimentsMap.allKeys;

            for(NSString *expKey in experimentKeys) {
                NSLog(@"[OptimizelyConfig]   - experimentKey = %@", expKey);

                NSDictionary<NSString*, OptimizelyVariation*> *variationsMap = experimentsMap[expKey].variationsMap;
                NSArray *variationKeys = variationsMap.allKeys;

                for(NSString *varKey in variationKeys) {
                    NSLog(@"[OptimizelyConfig]       -- variationKey = %@", varKey);

                    NSDictionary<NSString*, OptimizelyVariable*> *variablesMap = variationsMap[varKey].variablesMap;
                    NSArray *variableKeys = variablesMap.allKeys;

                    for(NSString *variableKey in variableKeys) {
                        OptimizelyVariable *variable = variablesMap[variableKey];

                        NSLog(@"[OptimizelyConfig]           --- variable: %@, %@", variableKey, variable);
                    }
                }
            }

            // enumerate all feature-variables
            
            NSDictionary<NSString*, OptimizelyVariable*> *variablesMap = featuresMap[featKey].variablesMap;
            NSArray *variableKeys = variablesMap.allKeys;
            
            for(NSString *variableKey in variableKeys) {
                OptimizelyVariable *variable = variablesMap[variableKey];
                    
                NSLog(@"[OptimizelyConfig]       -- variable: \%@, %@", variableKey, variable);
            }
        }

    }
    
}

@end
