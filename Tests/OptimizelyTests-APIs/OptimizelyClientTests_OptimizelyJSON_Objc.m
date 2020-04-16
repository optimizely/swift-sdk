/****************************************************************************
* Copyright 2020, Optimizely, Inc. and contributors                        *
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

@interface OptimizelyClientTests_OptimizelyJSON_Objc : XCTestCase
@property(nonatomic) OptimizelyJSON *optimizelyJSON;
@property(nonatomic) NSString *payload;
@property(nonatomic) NSDictionary *data;
@end

@implementation OptimizelyClientTests_OptimizelyJSON_Objc

- (void)setUp {
    _payload = @"{\"testfield\":1}";
    _data = @{@"testfield":@1};
}

- (void)testConstructorWithPayload {
    NSError *err;
    OptimizelyJSON *optimizelyJSON = [[OptimizelyJSON alloc] initWithPayload:_payload error:nil];
    NSString *jsonString = [optimizelyJSON toStringAndReturnError:&err];
    XCTAssertTrue([jsonString isEqualToString:_payload]);
    XCTAssertNil(err);
    
    NSDictionary<NSString *, id> *jsonDictionary = [optimizelyJSON toMapAndReturnError:&err];
    NSInteger expectedValue = [[_data valueForKey:@"testfield"] integerValue];
    NSInteger actualValue = [[jsonDictionary valueForKey:@"testfield"] integerValue];
    XCTAssertEqual(expectedValue, actualValue);
    XCTAssertNil(err);
}

- (void)testConstructorWithData {
    NSError *err;
    OptimizelyJSON *optimizelyJSON = [[OptimizelyJSON alloc] initWithData:_data error:nil];
    NSString *jsonString = [optimizelyJSON toStringAndReturnError:&err];
    XCTAssertTrue([jsonString isEqualToString:_payload]);
    XCTAssertNil(err);
    
    NSDictionary<NSString *, id> *jsonDictionary = [optimizelyJSON toMapAndReturnError:&err];
    NSInteger expectedValue = [[_data valueForKey:@"testfield"] integerValue];
    NSInteger actualValue = [[jsonDictionary valueForKey:@"testfield"] integerValue];
    XCTAssertEqual(expectedValue, actualValue);
    XCTAssertNil(err);
}

- (void)testGetValue {
    NSError *err;
    OptimizelyJSON *optimizelyJSON = [[OptimizelyJSON alloc] initWithData:_data error:nil];
    // Fetching integer type
    id expectedValue = @1;
    id actualIntValue = @0;
    [optimizelyJSON getValueWithJsonPath:@"testfield" schema: &actualIntValue error:&err];
    XCTAssertEqual(expectedValue, actualIntValue);
    
    // Fetching dictionary type
    optimizelyJSON = [[OptimizelyJSON alloc] initWithData:_data error:nil];
    id actualDictionaryValue = @{};
    [optimizelyJSON getValueWithJsonPath:@"" schema: &actualDictionaryValue error:&err];
    XCTAssertTrue([_data isEqualToDictionary:(NSDictionary *)actualDictionaryValue]);
}

@end
