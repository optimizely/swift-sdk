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


static NSString * const kExperimentKey = @"exp_with_audience";

static NSString * const kVariationKey = @"a";
static NSString * const kVariationOtherKey = @"b";

static NSString * const kFeatureKey = @"feature_1";
static NSString * const kFeatureOtherKey = @"feature_2";

static NSString * const kVariableKeyString = @"s_foo";
static NSString * const kVariableKeyInt = @"i_42";
static NSString * const kVariableKeyDouble = @"d_4_2";
static NSString * const kVariableKeyBool = @"b_true";

static NSString * const kVariableValueString = @"foo";
static const int kVariableValueInt = 42;
static const double kVariableValueDouble = 4.2;
static const BOOL kVariableValueBool = true;

static NSString * const kEventKey = @"event1";

static NSString * const kUserId = @"11111";
static NSString * const kSdkKey = @"12345";


@interface OptimizelyManagerTests_ObjcAPIs : XCTestCase
@property(nonatomic) OptimizelyManager *optimizely;
@property(nonatomic) NSDictionary * attributes;
@end

@implementation OptimizelyManagerTests_ObjcAPIs

- (void)setUp {
    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"api_datafile" ofType:@"json"];
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    self.optimizely = [[OptimizelyManager alloc] initWithSdkKey: kSdkKey];
    
    [self.optimizely initializeSDKWithDatafile:fileContents error:nil];
    
    self.attributes = @{ @"name": @"tom", @"age": @21 };
}

- (void)tearDown {
}

- (void)testActivate {
    NSString *variationKey = [self.optimizely activateWithExperimentKey:kExperimentKey
                                                                 userId:kUserId
                                                             attributes:self.attributes
                                                                  error:nil];
    XCTAssertEqualObjects(variationKey, kVariationKey);
}

- (void)testGetVariationKey {
    NSString *variationKey = [self.optimizely getVariationKeyWithExperimentKey:kExperimentKey
                                                                        userId:kUserId
                                                                    attributes:self.attributes
                                                                         error:nil];
    XCTAssertEqualObjects(variationKey, kVariationKey);
}

- (void)testGetForcedVariation {
    NSString *variationKey = [self.optimizely getForcedVariationWithExperimentKey:kExperimentKey
                                                                           userId:kUserId];
    XCTAssertNil(variationKey);
}

- (void)testSetForcedVariation {
    BOOL result = [self.optimizely setForcedVariationWithExperimentKey:kExperimentKey
                                                                userId:kUserId
                                                          variationKey:kVariationOtherKey];
    XCTAssert(result);
    
    NSString *variationKey = [self.optimizely getForcedVariationWithExperimentKey:kExperimentKey
                                                                           userId:kUserId];
    XCTAssertEqualObjects(variationKey, kVariationOtherKey);
}

- (void)testIsFeatureEnabled {
    BOOL result = [self.optimizely isFeatureEnabledWithFeatureKey:kFeatureKey
                                                           userId:kUserId
                                                       attributes:self.attributes
                                                            error:nil];
    XCTAssertTrue(result);
}
    
- (void)testGetFeatureVariableBoolean {
    BOOL result = [self.optimizely getFeatureVariableBooleanWithFeatureKey:kFeatureKey
                                                               variableKey:kVariableKeyBool
                                                                    userId:kUserId
                                                                attributes:self.attributes
                                                                     error:nil];
    XCTAssert(result == kVariableValueBool);
}
    
- (void)testGetFeatureVariableDouble {
    NSNumber *result = [self.optimizely getFeatureVariableDoubleWithFeatureKey:kFeatureKey
                                                               variableKey:kVariableKeyDouble
                                                                    userId:kUserId
                                                                attributes:self.attributes
                                                                     error:nil];
    XCTAssert(result.doubleValue == kVariableValueDouble);
}

- (void)testGetFeatureVariableInteger {
    NSNumber *result = [self.optimizely getFeatureVariableIntegerWithFeatureKey:kFeatureKey
                                                                    variableKey:kVariableKeyInt
                                                                         userId:kUserId
                                                                     attributes:self.attributes
                                                                          error:nil];
    XCTAssert(result.integerValue == kVariableValueInt);
}

- (void)testGetFeatureVariableString {
    NSString *result = [self.optimizely getFeatureVariableStringWithFeatureKey:kFeatureKey
                                                                   variableKey:kVariableKeyString
                                                                        userId:kUserId
                                                                    attributes:self.attributes
                                                                         error:nil];
    XCTAssertEqualObjects(result, kVariableValueString);
}
    
- (void)testGetEnabledFeatures {
    NSArray *result = [self.optimizely getEnabledFeaturesWithUserId:kUserId
                                                         attributes:self.attributes
                                                              error:nil];
    XCTAssertEqualObjects(result, @[kFeatureKey]);
}
    
- (void)testTrack {
    BOOL result = [self.optimizely trackWithEventKey:kEventKey
                                              userId:kUserId
                                          attributes:self.attributes
                                           eventTags:nil
                                               error:nil];
    XCTAssert(result);
}

@end
