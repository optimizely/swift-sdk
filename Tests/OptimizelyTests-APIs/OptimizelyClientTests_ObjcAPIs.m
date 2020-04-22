/****************************************************************************
* Copyright 2019-2020, Optimizely, Inc. and contributors                   *
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
static NSString * const kVariableKeyJSON = @"j_1";

static NSString * const kVariableValueString = @"foo";
static const int kVariableValueInt = 42;
static const double kVariableValueDouble = 4.2;
static const BOOL kVariableValueBool = true;
static NSString * const kVariableValueJSON = @"{\"value\":1}";

static NSString * const kEventKey = @"event1";

static NSString * const kUserId = @"11111";
static NSString * const kSdkKey = @"12345";


@interface OptimizelyClientTests_ObjcAPIs : XCTestCase
@property(nonatomic) OptimizelyClient *optimizely;
@property(nonatomic) NSDictionary * attributes;
@end

// MARK: - Custom Logger

@interface TestOPTLogger: NSObject <OPTLogger>
@end

@implementation TestOPTLogger
- (void)logWithLevel:(enum OptimizelyLogLevel)level message:(NSString * _Nonnull)message {
    NSLog(@"[LOG] %@", message);
}

static enum OptimizelyLogLevel logLevel = OptimizelyLogLevelInfo;
+ (enum OptimizelyLogLevel)logLevel {
    return logLevel;
}
+ (void)setLogLevel:(enum OptimizelyLogLevel)newValue {
    logLevel = newValue;
}
@end

// MARK: - Custom EventDispatcher

@interface TestOPTEventDispatcher: NSObject <OPTEventDispatcher>
@end

@implementation TestOPTEventDispatcher
- (void)dispatchEventWithEvent:(EventForDispatch * _Nonnull)event completionHandler:(void (^ _Nullable)(NSData * _Nullable, NSError * _Nullable))completionHandler {
    return;
}

- (void)flushEvents {
    return;
}
@end

// MARK: - Custom UserProfileService

@interface TestOPTUserProfileService: NSObject<OPTUserProfileService>
@end

@implementation TestOPTUserProfileService
- (NSDictionary<NSString *,id> * _Nullable)lookupWithUserId:(NSString * _Nonnull)userId {
    return nil;
}

- (void)saveWithUserProfile:(NSDictionary<NSString *,id> * _Nonnull)userProfile {
    return;
}
@end


// MARK: - tests

@implementation OptimizelyClientTests_ObjcAPIs

- (void)setUp {
    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"api_datafile" ofType:@"json"];
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey: kSdkKey];
    
    [self.optimizely startWithDatafile:fileContents error:nil];
    
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
                                                       attributes:self.attributes];
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

- (void)testGetFeatureVariableJSON {
    OptimizelyJSON *result = [self.optimizely getFeatureVariableJSONWithFeatureKey:kFeatureKey
                                                                       variableKey:kVariableKeyJSON
                                                                            userId:kUserId
                                                                        attributes:self.attributes
                                                                             error:nil];
    XCTAssertEqualObjects([result toString], kVariableValueJSON);
}
    
- (void)testGetEnabledFeatures {
    NSArray *result = [self.optimizely getEnabledFeaturesWithUserId:kUserId
                                                         attributes:self.attributes];
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

// MARK: - Customization API testing

- (void)testCustomizationAPIs {
    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"api_datafile" ofType:@"json"];
    NSString *datafile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSData *datafileData = [datafile dataUsingEncoding:NSUTF8StringEncoding];

    TestOPTLogger *logger = [[TestOPTLogger alloc] init];
    XCTAssertEqual(TestOPTLogger.logLevel, OptimizelyLogLevelInfo);
    
    TestOPTEventDispatcher *eventDispatcher = [[TestOPTEventDispatcher alloc] init];
    EventForDispatch *event = [[EventForDispatch alloc] initWithUrl:nil body:[[NSData alloc] init]];
    [eventDispatcher dispatchEventWithEvent:event completionHandler:nil];
    [eventDispatcher flushEvents];
    
    TestOPTUserProfileService *userProfileService = [[TestOPTUserProfileService alloc] init];
    (void)[userProfileService lookupWithUserId:@"dummy"];
    [userProfileService saveWithUserProfile:@{}];
    
    // check all SDK initialization APIs for ObjC
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey:kSdkKey];
    
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey:kSdkKey
                                                         logger:logger
                                                eventDispatcher:eventDispatcher
                                             userProfileService:userProfileService
                                       periodicDownloadInterval:@(50)
                                                 defaultLogLevel:OptimizelyLogLevelInfo];
    
    [self.optimizely startWithCompletion:nil];
    
    [self.optimizely startWithDatafile:datafile error:nil];
    
    [self.optimizely startWithDatafile:datafileData doFetchDatafileBackground:false error:nil];
    [self.optimizely startWithDatafile:datafileData doUpdateConfigOnNewDatafile:true doFetchDatafileBackground:true error:nil];
    [self.optimizely startWithDatafile:datafileData doUpdateConfigOnNewDatafile:false doFetchDatafileBackground:true error:nil];
}

@end

