//
//  ThrowableConditionListTest.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 2/16/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class ThrowableConditionListTest: XCTestCase {

    // MARK: - AND
    
    func testAndTrue() {
        let conditions = [true, true, true]
        let result = try! evalsListFromBools(conditions).and()
        XCTAssertTrue(result)
    }
    
    func testAndFalse() {
        var conditions = [false, true, true]
        var result = try! evalsListFromBools(conditions).and()
        XCTAssertFalse(result)

        conditions = [true, false, true]
        result = try! evalsListFromBools(conditions).and()
        XCTAssertFalse(result)

        conditions = [true, true, false]
        result = try! evalsListFromBools(conditions).and()
        XCTAssertFalse(result)
    }
    
    func testAndThrows() {
        var conditions = [nil, true, true]
        var result = try? evalsListFromBools(conditions).and()
        XCTAssertNil(result)
        
        conditions = [true, nil, true]
        result = try? evalsListFromBools(conditions).and()
        XCTAssertNil(result)

        conditions = [true, true, nil]
        result = try? evalsListFromBools(conditions).and()
        XCTAssertNil(result)
    }
    
    // MARK: - OR
    
    func testOrTrue() {
        var conditions = [true, true, true]
        var result = try! evalsListFromBools(conditions).or()
        XCTAssertTrue(result)
        
        conditions = [false, true, false]
        result = try! evalsListFromBools(conditions).or()
        XCTAssertTrue(result)
        
        conditions = [false, false, true]
        result = try! evalsListFromBools(conditions).or()
        XCTAssertTrue(result)
    }
    
    func testOrFalse() {
        let conditions = [false, false, false]
        let result = try! evalsListFromBools(conditions).or()
        XCTAssertFalse(result)
    }
    
    func testOrThrows() {
        var conditions: [Bool?] = [nil, true, true]
        var result = try! evalsListFromBools(conditions).or()
        XCTAssertTrue(result)

        conditions = [nil, nil, true]
        result = try! evalsListFromBools(conditions).or()
        XCTAssertTrue(result)

        let c2: [Bool?] = [nil, nil, nil]
        let r2: Bool? = try? evalsListFromBools(c2).or()
        XCTAssertNil(r2)
    }
    
    // MARK: - NOT
    
    func testNotTrue() {
        let conditions = [false, true, true]
        let result = try! evalsListFromBools(conditions).not()
        XCTAssertTrue(result)
    }
    
    func testNotFalse() {
        var conditions = [true]
        var result = try! evalsListFromBools(conditions).not()
        XCTAssertFalse(result)
        
        conditions = [true, false]
        result = try! evalsListFromBools(conditions).not()
        XCTAssertFalse(result)
    }
    
    func testNotThrows() {
        var conditions: [Bool?] = [nil]
        var result = try? evalsListFromBools(conditions).not()
        XCTAssertNil(result)
        
        conditions = [nil, true]
        result = try? evalsListFromBools(conditions).not()
        XCTAssertNil(result)
    }
    
    // MARK: - Utils
    
    func evalsListFromBools(_ conditions: [Bool?]) -> [ThrowableCondition] {
        return conditions.map { value -> ThrowableCondition in
            return { () throws -> Bool in
                if let value = value {
                    return value
                } else {
                    throw OptimizelyError.conditionInvalidFormat("nil")
                }
            }
        }
    }
    
}
