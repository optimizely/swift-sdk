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

import XCTest

// MARK: - Evaluate (Equal)

class AttributeValueTests_Evaluate: XCTestCase {
    
    func testIsExactMatchString() {
        let model = try! OTUtils.getAttributeValueFromNative("us")
        XCTAssertTrue(model.isExactMatch(with: "us")!)
    }
    
    func testIsExactMatchBool() {
        let model = try! OTUtils.getAttributeValueFromNative(true)
        XCTAssertTrue(model.isExactMatch(with: true)!)
    }

    func testIsExactMatchBool2() {
        let model = try! OTUtils.getAttributeValueFromNative(false)
        XCTAssertTrue(model.isExactMatch(with: false)!)
    }

    func testIsExactMatchStringFail() {
        let model = try! OTUtils.getAttributeValueFromNative("us")
        XCTAssertFalse(model.isExactMatch(with: "ca")!)
    }

    func testIsExactMatchBoolFail() {
        let model = try! OTUtils.getAttributeValueFromNative(true)
        XCTAssertFalse(model.isExactMatch(with: false)!)
    }
    
    // MARK: - All value types
    
    func testIsExactMatchWithAllNumTypes() {
        let valueInt = 30
        
        let modelInt = try! OTUtils.getAttributeValueFromNative(valueInt)
        for (idx, test) in allValueTypes(value: Double(valueInt)).enumerated() {
            XCTAssertTrue(modelInt.isExactMatch(with: test)!, "error with index = \(idx)")
        }
        for (idx, test) in allValueTypes(value: Double(99)).enumerated() {
            XCTAssertFalse(modelInt.isExactMatch(with: test)!, "error with index = \(idx)")
        }
        
        let valueDouble = 13.0
        
        let modelDouble = try! OTUtils.getAttributeValueFromNative(Double(valueDouble))
        for (idx, test) in allValueTypes(value: Double(valueDouble)).enumerated() {
            XCTAssertTrue(modelDouble.isExactMatch(with: test)!, "error with index = \(idx)")
        }
        for (idx, test) in allValueTypes(value: Double(99)).enumerated() {
            XCTAssertFalse(modelDouble.isExactMatch(with: test)!, "error with index = \(idx)")
        }
    }
    
    // MARK: - Bool compared with Numbers
    
    func testIsExactMatchFailWhenBoolComparedWithNumbers() {
        let modelTrue = try! OTUtils.getAttributeValueFromNative(true)
        XCTAssertNil(modelTrue.isExactMatch(with: Int(1)))
        XCTAssertNil(modelTrue.isExactMatch(with: Double(1)))

        let modelFalse = try! OTUtils.getAttributeValueFromNative(false)
        XCTAssertNil(modelFalse.isExactMatch(with: Int(0)))
        XCTAssertNil(modelFalse.isExactMatch(with: Double(0)))

        let modelInt1 = try! OTUtils.getAttributeValueFromNative(Int(1))
        XCTAssertNil(modelInt1.isExactMatch(with: true))
        let modelInt0 = try! OTUtils.getAttributeValueFromNative(Int(0))
        XCTAssertNil(modelInt0.isExactMatch(with: false))

        let modelDouble1 = try! OTUtils.getAttributeValueFromNative(Double(1))
        XCTAssertNil(modelDouble1.isExactMatch(with: true))
        let modelDouble0 = try! OTUtils.getAttributeValueFromNative(Double(0))
        XCTAssertNil(modelDouble0.isExactMatch(with: false))

    }
    
}

// MARK: - Evaluate (Substring)

extension AttributeValueTests_Evaluate {

    func testIsSubstringSuccessSame() {
        let model = try! OTUtils.getAttributeValueFromNative("us")
        XCTAssertTrue(model.isSubstring(of: "us")!)
    }

    func testIsSubstringSuccessContains() {
        let model = try! OTUtils.getAttributeValueFromNative("us")
        XCTAssertTrue(model.isSubstring(of: "us-ca")!)
    }

    func testIsSubstringFail() {
        let model = try! OTUtils.getAttributeValueFromNative("us-ca")
        XCTAssertFalse(model.isSubstring(of: "us")!)
    }
    
    func testIsSubstringFailWithInt() {
        let model = try! OTUtils.getAttributeValueFromNative("us")
        XCTAssertNil(model.isSubstring(of: 10))
    }

    func testIsSubstringFailWithBool() {
        let model = try! OTUtils.getAttributeValueFromNative("true")
        XCTAssertNil(model.isSubstring(of: true))
    }

    func testIsSubstringFailForWrongType() {
        let model = try! OTUtils.getAttributeValueFromNative(10)
        XCTAssertNil(model.isSubstring(of: "us"))
    }

}

// MARK: - Evaluate (GreaterThan)

extension AttributeValueTests_Evaluate {
    
    // MARK: - All value types
    
    func testIsGreaterWithAllNumTypes() {
        let value = 13.5
        let smallerValue = 10.0
        let biggerValue = 20.0
        
        let model = try! OTUtils.getAttributeValueFromNative(value)

        for (idx, test) in allValueTypes(value: smallerValue).enumerated() {
            XCTAssertTrue(model.isGreater(than: test)!, "error with index = \(idx)")
        }

        for (idx, test) in allValueTypes(value: biggerValue).enumerated() {
            XCTAssertFalse(model.isGreater(than: test)!, "error with index = \(idx)")
        }

        // false for equal values
        let valueInt = 30
        let modelInt = try! OTUtils.getAttributeValueFromNative(valueInt)
        for (idx, test) in allValueTypes(value: Double(valueInt)).enumerated() {
            XCTAssertFalse(modelInt.isGreater(than: test)!, "error with index = \(idx)")
        }
    }

    // MARK: - Large numbers
    
    func testIsGreaterSuccessWithDouble_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertFalse(model.isGreater(than: OTUtils.positiveMaxValueAllowed)!)
        XCTAssertNil(model.isGreater(than: OTUtils.positiveTooBigValue))
    }
    
    func testIsGreaterSuccessWithDouble_NegativeLargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(model.isGreater(than: OTUtils.negativeMaxValueAllowed)!)
        XCTAssertNil(model.isGreater(than: OTUtils.negativeTooBigValue))
    }
    
    func testIsGreaterSuccessWithFloat_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertFalse(model.isGreater(than: Float(OTUtils.positiveMaxValueAllowed))!)
        XCTAssertNil(model.isGreater(than: Float(OTUtils.positiveTooBigValue)))
    }
    
    func testIsGreaterSuccessWithInt64_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertFalse(model.isGreater(than: Int64(OTUtils.positiveMaxValueAllowed))!)
        XCTAssertNil(model.isGreater(than: Int64(OTUtils.positiveTooBigValue)))
    }

}

// MARK: - Evaluate (LessThan)

extension AttributeValueTests_Evaluate {
    
    // MARK: - All value types
    
    func testIsLessWithAllNumTypes() {
        let value = 13.5
        let smallerValue = 10.0
        let biggerValue = 20.0
        
        let model = try! OTUtils.getAttributeValueFromNative(value)
        
        for (idx, test) in allValueTypes(value: smallerValue).enumerated() {
            XCTAssertFalse(model.isLess(than: test)!, "error with index = \(idx)")
        }
        
        for (idx, test) in allValueTypes(value: biggerValue).enumerated() {
            XCTAssertTrue(model.isLess(than: test)!, "error with index = \(idx)")
        }
        
        // false for equal values
        let valueInt = 30
        let modelInt = try! OTUtils.getAttributeValueFromNative(valueInt)
        for (idx, test) in allValueTypes(value: Double(valueInt)).enumerated() {
            XCTAssertFalse(modelInt.isLess(than: test)!, "error with index = \(idx)")
        }
    }

    // MARK: - Large numbers
    
    func testIsLessSuccessWithDouble_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(model.isLess(than: OTUtils.positiveMaxValueAllowed)!)
        XCTAssertNil(model.isLess(than: OTUtils.positiveTooBigValue))
    }
    
    func testIsLessSuccessWithDouble_NegativeLargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertFalse(model.isLess(than: OTUtils.negativeMaxValueAllowed)!)
        XCTAssertNil(model.isLess(than: OTUtils.negativeTooBigValue))
    }
    
    func testIsLessSuccessWithFloat_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(model.isLess(than: Float(OTUtils.positiveMaxValueAllowed))!)
        XCTAssertNil(model.isLess(than: Float(OTUtils.positiveMaxValueAllowed * 2.0)))
    }
    
    func testIsLessSuccessWithInt64_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(model.isLess(than: Int64(OTUtils.positiveMaxValueAllowed))!)
        XCTAssertNil(model.isLess(than: Int64(OTUtils.positiveTooBigValue)))
    }
    
    // MARK: - Utils
    
    func allIntTypes(value: Double) -> [Any] {
        return [Int(value), Int8(value), Int16(value), Int32(value), Int64(value),
                UInt(value), UInt8(value), UInt16(value), UInt32(value), UInt64(value)]
    }

    func allNumTypes(value: Double) -> [Any] {
        return [Double(value), Float(value), Float32(value), Float64(value), CLongDouble(value)]
    }
    
    func allValueTypes(value: Double) -> [Any] {
        return allIntTypes(value: value) + allNumTypes(value: value)
    }

}
