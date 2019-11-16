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
    

#import <XCTest/XCTest.h>
@import Optimizely;

@interface OptimizelyClientTests_OptimizelyConfig_Objc : XCTestCase
@property(nonatomic) OptimizelyClient *optimizely;
@end

@implementation OptimizelyClientTests_OptimizelyConfig_Objc

- (void)setUp {
    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"optimizely_config_datafile" ofType:@"json"];
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey: @"12345"];
    
    [self.optimizely startWithDatafile:fileContents error:nil];
}

// this test can be also covered by FSC, but it'll be useful to confirm Swift and ObjC both generate correct outputs
- (void)testGetOptimizelyConfig_Equal {
    if (@available(iOS 11.0, *)) {
        
        id<OptimizelyConfig> optimizelyConfig = [self.optimizely getOptimizelyConfigWithError:nil];
        
        // compare dictionaries as strings (after key-sorted and remove all spaces)
        NSDictionary *observedDict = [self dictForOptimizelyConfig:optimizelyConfig];
        NSError *error;
        NSData *observedData = [NSJSONSerialization dataWithJSONObject:observedDict
                                                           options:NSJSONWritingSortedKeys
                                                             error:&error];
        NSString *observedJSON = [[NSString alloc] initWithData:observedData encoding:NSUTF8StringEncoding];
        NSString *observed = [self removeSpacesFromString:observedJSON];
        
        // pre-geneerated expected JSON string (sorted by keys)
        NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"optimizely_config_expected" ofType:@"json"];
        NSString *expectedJSON = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        NSString *expected = [self removeSpacesFromString:expectedJSON];
       
        XCTAssert([observed isEqualToString:expected]);
    }
}

- (void)testGetOptimizelyConfig_ExperimentsMap {
    NSLog(@"------------------------------------------------------");
    id<OptimizelyConfig> optimizelyConfig = [self.optimizely getOptimizelyConfigWithError:nil];
    
    NSLog(@"   Experiments: %@", optimizelyConfig.experimentsMap.allKeys);
    
    XCTAssertEqual(optimizelyConfig.experimentsMap.count, 5);
    
    id<OptimizelyExperiment> experiment1 = optimizelyConfig.experimentsMap[@"exp_with_audience"];
    id<OptimizelyExperiment> experiment2 = optimizelyConfig.experimentsMap[@"experiment_4000"];
    
    XCTAssertEqual(experiment1.variationsMap.count, 2);
    XCTAssertEqual(experiment2.variationsMap.count, 2);
    
    NSLog(@"   Experiment1 > Variations: %@", experiment1.variationsMap.allKeys);
    NSLog(@"   Experiment2 > Variations: %@", experiment2.variationsMap.allKeys);
    
    id<OptimizelyVariation> variation1 = experiment1.variationsMap[@"a"];
    id<OptimizelyVariation> variation2 = experiment1.variationsMap[@"b"];
    
    XCTAssertEqual(variation1.variablesMap.count, 0);
    XCTAssertEqual(variation2.variablesMap.count, 0);
    NSLog(@"------------------------------------------------------");
}

- (void)testGetOptimizelyConfig_FeatureFlagsMap {
    NSLog(@"------------------------------------------------------");
    id<OptimizelyConfig> optimizelyConfig = [self.optimizely getOptimizelyConfigWithError:nil];

    NSLog(@"   Features: %@", optimizelyConfig.featuresMap.allKeys);
    
    XCTAssertEqual(optimizelyConfig.featuresMap.count, 2);
    
    id<OptimizelyFeature> feature1 = optimizelyConfig.featuresMap[@"mutex_group_feature"];
    id<OptimizelyFeature> feature2 = optimizelyConfig.featuresMap[@"feature_exp_no_traffic"];
    
    // FeatureFlag: experimentsMap
    
    XCTAssertEqual(feature1.experimentsMap.count, 2);
    XCTAssertEqual(feature2.experimentsMap.count, 1);
    
    NSLog(@"   Feature1 > Experiments: %@", feature1.experimentsMap.allKeys);
    NSLog(@"   Feature2 > Experiments: %@", feature2.experimentsMap.allKeys);
    
    id<OptimizelyExperiment> experiment1 = feature1.experimentsMap[@"experiment_4000"];
    id<OptimizelyExperiment> experiment2 = feature1.experimentsMap[@"experiment_8000"];
    
    XCTAssertEqual(experiment1.variationsMap.count, 2);
    XCTAssertEqual(experiment2.variationsMap.count, 1);
    
    NSLog(@"   Feature1 > Experiment1 > Variations: %@", experiment1.variationsMap.allKeys);
    NSLog(@"   Feature1 > Experiment2 > Variations: %@", experiment2.variationsMap.allKeys);
    
    id<OptimizelyVariation> variation1 = experiment1.variationsMap[@"all_traffic_variation_exp_1"];
    id<OptimizelyVariation> variation2 = experiment1.variationsMap[@"no_traffic_variation_exp_1"];
    
    XCTAssertEqual(variation1.variablesMap.count, 4);
    XCTAssertEqual(variation2.variablesMap.count, 4, "must include all default variables when empty");
    
    NSLog(@"   Feature1 > Experiment1 > Variation1 > Variables: %@", variation1.variablesMap.allKeys);
    NSLog(@"   Feature1 > Experiment1 > Variation2 > Variables: %@", variation2.variablesMap.allKeys);
    
    id<OptimizelyVariable> variable1 = variation1.variablesMap[@"s_foo"];
    XCTAssertEqualObjects(variable1.id, @"2687470097");
    XCTAssertEqualObjects(variable1.key, @"s_foo");
    XCTAssertEqualObjects(variable1.type, @"string");
    XCTAssertEqualObjects(variable1.value, @"s1");
    
    // FeatureFlag: variablesMap
    
    XCTAssertEqual(feature1.variablesMap.count, 4);
    XCTAssertEqual(feature2.variablesMap.count, 0);
    
    NSLog(@"   Feature1 > FeatureVariables: %@", feature1.variablesMap.allKeys);
    
    id<OptimizelyVariable> featureVariable = feature1.variablesMap[@"i_42"];
    XCTAssertEqualObjects(featureVariable.id, @"2687470094");
    XCTAssertEqualObjects(featureVariable.key, @"i_42");
    XCTAssertEqualObjects(featureVariable.type, @"integer");
    XCTAssertEqualObjects(featureVariable.value, @"42");
    NSLog(@"------------------------------------------------------");
}


// MARK: - Utils

-(NSDictionary*)dictForOptimizelyConfig: (id <OptimizelyConfig>)optConfig {
    NSMutableDictionary *expMap = [NSMutableDictionary new];
    for(NSString *key in optConfig.experimentsMap.allKeys){
        id<OptimizelyExperiment> value = optConfig.experimentsMap[key];
        expMap[key] = [self dictForOptimizelyExperiment:value];
    }
    
    NSMutableDictionary *featMap = [NSMutableDictionary new];
    for(NSString *key in optConfig.featuresMap.allKeys){
        id<OptimizelyFeature> value = optConfig.featuresMap[key];
        featMap[key] = [self dictForOptimizelyFeature:value];
    }

    return @{
        @"revision": optConfig.revision,
        @"experimentsMap": expMap,
        @"featuresMap": featMap
    };
}

-(NSDictionary*)dictForOptimizelyExperiment: (id <OptimizelyExperiment>)experiment {
    NSMutableDictionary *map = [NSMutableDictionary new];
    for(NSString *key in experiment.variationsMap.allKeys){
        id<OptimizelyVariation> value = experiment.variationsMap[key];
        map[key] = [self dictForOptimizelyVariation:value];
    }

    return @{
        @"key": experiment.key,
        @"id": experiment.id,
        @"variationsMap": map
    };
}

-(NSDictionary*)dictForOptimizelyFeature: (id <OptimizelyFeature>)feature {
    NSMutableDictionary *expMap = [NSMutableDictionary new];
    for(NSString *key in feature.experimentsMap.allKeys){
        id<OptimizelyExperiment> value = feature.experimentsMap[key];
        expMap[key] = [self dictForOptimizelyExperiment:value];
    }
    
    NSMutableDictionary *varMap = [NSMutableDictionary new];
    for(NSString *key in feature.variablesMap.allKeys){
        id<OptimizelyVariable> value = feature.variablesMap[key];
        varMap[key] = [self dictForOptimizelyVariable:value];
    }
    
    return @{
        @"key": feature.key,
        @"id": feature.id,
        @"experimentsMap": expMap,
        @"variablesMap": varMap
    };
}

-(NSDictionary*)dictForOptimizelyVariation: (id <OptimizelyVariation>)variation {
    NSMutableDictionary *map = [NSMutableDictionary new];
    for(NSString *key in variation.variablesMap.allKeys){
        id<OptimizelyVariable> value = variation.variablesMap[key];
        map[key] = [self dictForOptimizelyVariable:value];
    }

    return @{
        @"key": variation.key,
        @"id": variation.id,
        @"featureEnabled": [NSNumber numberWithBool:variation.featureEnabled],
        @"variablesMap": map
    };
}

-(NSDictionary*)dictForOptimizelyVariable: (id <OptimizelyVariable>)variable {
    return @{
        @"key": variable.key,
        @"id": variable.id,
        @"type": variable.type,
        @"value": variable.value
    };
}

-(NSString*)removeSpacesFromString:(NSString*)str {
    return [[str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@""];
}

@end

