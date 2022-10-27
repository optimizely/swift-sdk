//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
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

// this test for full-content validation will be covered by FSC,
// but it'll be useful here especially for ObjC APIs which is not covered by FSC.

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
       
        //NSLog(@"\n\n[Observed]\n\%@\n\n[Expected]\n\%@\n\n", observed, expected);
        XCTAssert([observed isEqualToString:expected]);
    }
}

- (void)testGetOptimizelyConfig_InvalidDatafile {
    NSString *invalidDatafile = @"{\"version\": \"4\"}";
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey: @"12345"];
    [self.optimizely startWithDatafile:invalidDatafile error:nil];

    id<OptimizelyConfig> result = [self.optimizely getOptimizelyConfigWithError:nil];
    XCTAssertNil(result);
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
    
    NSMutableArray *attributes = [NSMutableArray new];
    for(id<OptimizelyAttribute> item in optConfig.attributes) {
        [attributes addObject:[self dictForOptimizelyAttribute:item]];
    }

    NSMutableArray *audiences = [NSMutableArray new];
    for(id<OptimizelyAudience> item in optConfig.audiences) {
        [audiences addObject:[self dictForOptimizelyAudience:item]];
    }

    NSMutableArray *events = [NSMutableArray new];
    for(id<OptimizelyEvent> item in optConfig.events) {
        [events addObject:[self dictForOptimizelyEvent:item]];
    }

    return @{
        @"revision": optConfig.revision,
        @"sdkKey": optConfig.sdkKey,
        @"environmentKey": optConfig.environmentKey,
        @"experimentsMap": expMap,
        @"featuresMap": featMap,
        @"attributes": attributes,
        @"audiences": audiences,
        @"events": events
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
        @"variationsMap": map,
        @"audiences": experiment.audiences
    };
}

-(NSDictionary*)dictForOptimizelyFeature: (id <OptimizelyFeature>)feature {
    NSMutableDictionary *expMap = [NSMutableDictionary new];
    for(id<OptimizelyExperiment> exp in feature.experimentRules){
        NSString *key = exp.key;
        expMap[key] = [self dictForOptimizelyExperiment:exp];
    }
    
    NSMutableDictionary *varMap = [NSMutableDictionary new];
    for(NSString *key in feature.variablesMap.allKeys){
        id<OptimizelyVariable> value = feature.variablesMap[key];
        varMap[key] = [self dictForOptimizelyVariable:value];
    }
    
    NSMutableArray *experimentRules = [NSMutableArray new];
    for(id<OptimizelyExperiment> exp in feature.experimentRules) {
        [experimentRules addObject:[self dictForOptimizelyExperiment:exp]];
    }
    
    NSMutableArray *deliveryRules = [NSMutableArray new];
    for(id<OptimizelyExperiment> exp in feature.deliveryRules) {
        [deliveryRules addObject:[self dictForOptimizelyExperiment:exp]];
    }
    
    return @{
        @"key": feature.key,
        @"id": feature.id,
        @"experimentRules": experimentRules,
        @"deliveryRules": deliveryRules,
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

-(NSDictionary*)dictForOptimizelyAttribute: (id <OptimizelyAttribute>)attribute {
    return @{
        @"key": attribute.key,
        @"id": attribute.id
    };
}

-(NSDictionary*)dictForOptimizelyAudience: (id <OptimizelyAudience>)audience {
    return @{
        @"name": audience.name,
        @"id": audience.id,
        @"conditions": audience.conditions
    };
}

-(NSDictionary*)dictForOptimizelyEvent: (id <OptimizelyEvent>)event {
    return @{
        @"key": event.key,
        @"id": event.id,
        @"experimentIds": event.experimentIds
    };
}


-(NSString*)removeSpacesFromString:(NSString*)str {
    return [[str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@""];
}

@end

