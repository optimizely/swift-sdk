//
// Copyright 2020-2021, Optimizely, Inc. and contributors
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

@interface OptimizelyClientTests_OptimizelyJSON_Objc : XCTestCase
@property(nonatomic) OptimizelyJSON *optimizelyJSON;
@property(nonatomic) NSString *payload;
@property(nonatomic) NSDictionary *map;
@end

@implementation OptimizelyClientTests_OptimizelyJSON_Objc

- (void)setUp {
    _payload = @"{\"testfield\":1}";
    _map = @{@"testfield":@1};
}

- (void)testConstructorWithInvalidPayload {
    XCTAssertNil([[OptimizelyJSON alloc] initWithPayload:@""]);
    XCTAssertNil([[OptimizelyJSON alloc] initWithPayload:@"invalid_string"]);
    XCTAssertNil([[OptimizelyJSON alloc] initWithPayload:@"[{}]"]);
}

- (void)testConstructorWithValidPayload {
    OptimizelyJSON *optimizelyJSON = [[OptimizelyJSON alloc] initWithPayload:_payload];
    NSString *jsonString = [optimizelyJSON toString];
    XCTAssertTrue([jsonString isEqualToString:_payload]);
    
    NSDictionary<NSString *, id> *jsonDictionary = [optimizelyJSON toMap];
    NSInteger expectedValue = [[_map valueForKey:@"testfield"] integerValue];
    NSInteger actualValue = [[jsonDictionary valueForKey:@"testfield"] integerValue];
    XCTAssertEqual(expectedValue, actualValue);
}

- (void)testConstructorWithMap {
    OptimizelyJSON *optimizelyJSON = [[OptimizelyJSON alloc] initWithMap:_map];
    NSString *jsonString = [optimizelyJSON toString];
    XCTAssertTrue([jsonString isEqualToString:_payload]);
    
    NSDictionary<NSString *, id> *jsonDictionary = [optimizelyJSON toMap];
    NSInteger expectedValue = [[_map valueForKey:@"testfield"] integerValue];
    NSInteger actualValue = [[jsonDictionary valueForKey:@"testfield"] integerValue];
    XCTAssertEqual(expectedValue, actualValue);
}

@end
