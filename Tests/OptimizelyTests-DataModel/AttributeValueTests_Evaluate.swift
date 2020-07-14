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
        XCTAssertTrue(try! model.isExactMatch(with: "us"))
    }
    
    func testIsExactMatchBool() {
        let model = try! OTUtils.getAttributeValueFromNative(true)
        XCTAssertTrue(try! model.isExactMatch(with: true))
    }

    func testIsExactMatchBool2() {
        let model = try! OTUtils.getAttributeValueFromNative(false)
        XCTAssertTrue(try! model.isExactMatch(with: false))
    }

    func testIsExactMatchStringFail() {
        let model = try! OTUtils.getAttributeValueFromNative("us")
        XCTAssertFalse(try! model.isExactMatch(with: "ca"))
    }

    func testIsExactMatchBoolFail() {
        let model = try! OTUtils.getAttributeValueFromNative(true)
        XCTAssertFalse(try! model.isExactMatch(with: false))
    }
    
    // MARK: - All value types
    
    func testIsExactMatchWithAllNumTypes() {
        let valueInt = 30
        
        let modelInt = try! OTUtils.getAttributeValueFromNative(valueInt)
        for (idx, test) in allValueTypes(value: Double(valueInt)).enumerated() {
            XCTAssertTrue(try! modelInt.isExactMatch(with: test), "error with index = \(idx)")
        }
        for (idx, test) in allValueTypes(value: Double(99)).enumerated() {
            XCTAssertFalse(try! modelInt.isExactMatch(with: test), "error with index = \(idx)")
        }
        
        let valueDouble = 13.0
        
        let modelDouble = try! OTUtils.getAttributeValueFromNative(Double(valueDouble))
        for (idx, test) in allValueTypes(value: Double(valueDouble)).enumerated() {
            XCTAssertTrue(try! modelDouble.isExactMatch(with: test), "error with index = \(idx)")
        }
        for (idx, test) in allValueTypes(value: Double(99)).enumerated() {
            XCTAssertFalse(try! modelDouble.isExactMatch(with: test), "error with index = \(idx)")
        }
    }
    
    // MARK: - Bool compared with Numbers
    
    func testIsExactMatchFailWhenBoolComparedWithNumbers() {
        let modelTrue = try! OTUtils.getAttributeValueFromNative(true)
        XCTAssertNil(try? modelTrue.isExactMatch(with: Int(1)))
        XCTAssertNil(try? modelTrue.isExactMatch(with: Double(1)))

        let modelFalse = try! OTUtils.getAttributeValueFromNative(false)
        XCTAssertNil(try? modelFalse.isExactMatch(with: Int(0)))
        XCTAssertNil(try? modelFalse.isExactMatch(with: Double(0)))

        let modelInt1 = try! OTUtils.getAttributeValueFromNative(Int(1))
        XCTAssertNil(try? modelInt1.isExactMatch(with: true))
        let modelInt0 = try! OTUtils.getAttributeValueFromNative(Int(0))
        XCTAssertNil(try? modelInt0.isExactMatch(with: false))

        let modelDouble1 = try! OTUtils.getAttributeValueFromNative(Double(1))
        XCTAssertNil(try? modelDouble1.isExactMatch(with: true))
        let modelDouble0 = try! OTUtils.getAttributeValueFromNative(Double(0))
        XCTAssertNil(try? modelDouble0.isExactMatch(with: false))

    }
    
}

// MARK: - Evaluate (Substring)

extension AttributeValueTests_Evaluate {

    func testIsSubstringSuccessSame() {
        let model = try! OTUtils.getAttributeValueFromNative("us")
        XCTAssertTrue(try! model.isSubstring(of: "us"))
    }

    func testIsSubstringSuccessContains() {
        let model = try! OTUtils.getAttributeValueFromNative("us")
        XCTAssertTrue(try! model.isSubstring(of: "us-ca"))
    }

    func testIsSubstringFail() {
        let model = try! OTUtils.getAttributeValueFromNative("us-ca")
        XCTAssertFalse(try! model.isSubstring(of: "us"))
    }
    
    func testIsSubstringFailWithInt() {
        let model = try! OTUtils.getAttributeValueFromNative("us")
        XCTAssertNil(try? model.isSubstring(of: 10))
    }

    func testIsSubstringFailWithBool() {
        let model = try! OTUtils.getAttributeValueFromNative("true")
        XCTAssertNil(try? model.isSubstring(of: true))
    }

    func testIsSubstringFailForWrongType() {
        let model = try! OTUtils.getAttributeValueFromNative(10)
        XCTAssertNil(try? model.isSubstring(of: "us"))
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
            XCTAssertTrue(try! model.isGreater(than: test), "error with index = \(idx)")
        }

        for (idx, test) in allValueTypes(value: biggerValue).enumerated() {
            XCTAssertFalse(try! model.isGreater(than: test), "error with index = \(idx)")
        }

        // false for equal values
        let valueInt = 30
        let modelInt = try! OTUtils.getAttributeValueFromNative(valueInt)
        for (idx, test) in allValueTypes(value: Double(valueInt)).enumerated() {
            XCTAssertFalse(try! modelInt.isGreater(than: test), "error with index = \(idx)")
        }
    }

    // MARK: - Large numbers
    
    func testIsGreaterSuccessWithDouble_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertFalse(try! model.isGreater(than: OTUtils.positiveMaxValueAllowed))
        XCTAssertNil(try? model.isGreater(than: OTUtils.positiveTooBigValue))
    }
    
    func testIsGreaterSuccessWithDouble_NegativeLargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isGreater(than: OTUtils.negativeMaxValueAllowed))
        XCTAssertNil(try? model.isGreater(than: OTUtils.negativeTooBigValue))
    }
    
    func testIsGreaterSuccessWithFloat_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertFalse(try! model.isGreater(than: Float(OTUtils.positiveMaxValueAllowed)))
        XCTAssertNil(try? model.isGreater(than: Float(OTUtils.positiveTooBigValue)))
    }
    
    func testIsGreaterSuccessWithInt64_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertFalse(try! model.isGreater(than: Int64(OTUtils.positiveMaxValueAllowed)))
        XCTAssertNil(try? model.isGreater(than: Int64(OTUtils.positiveTooBigValue)))
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
            XCTAssertFalse(try! model.isLess(than: test), "error with index = \(idx)")
        }
        
        for (idx, test) in allValueTypes(value: biggerValue).enumerated() {
            XCTAssertTrue(try! model.isLess(than: test), "error with index = \(idx)")
        }
        
        // false for equal values
        let valueInt = 30
        let modelInt = try! OTUtils.getAttributeValueFromNative(valueInt)
        for (idx, test) in allValueTypes(value: Double(valueInt)).enumerated() {
            XCTAssertFalse(try! modelInt.isLess(than: test), "error with index = \(idx)")
        }
    }

    // MARK: - Large numbers
    
    func testIsLessSuccessWithDouble_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isLess(than: OTUtils.positiveMaxValueAllowed))
        XCTAssertNil(try? model.isLess(than: OTUtils.positiveTooBigValue))
    }
    
    func testIsLessSuccessWithDouble_NegativeLargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertFalse(try! model.isLess(than: OTUtils.negativeMaxValueAllowed))
        XCTAssertNil(try? model.isLess(than: OTUtils.negativeTooBigValue))
    }
    
    func testIsLessSuccessWithFloat_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isLess(than: Float(OTUtils.positiveMaxValueAllowed)))
        XCTAssertNil(try? model.isLess(than: Float(OTUtils.positiveMaxValueAllowed * 2.0)))
    }
    
    func testIsLessSuccessWithInt64_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isLess(than: Int64(OTUtils.positiveMaxValueAllowed)))
        XCTAssertNil(try? model.isLess(than: Int64(OTUtils.positiveTooBigValue)))
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

// MARK: - SemanticVersion
extension AttributeValueTests_Evaluate {
    // It is import in this implementation as to which is the target and which is the
    // attribute. The target is always passed and evaluated on the attribute.
    
    // Test if same when all target is only major.minor
    func testIsSemanticSame() {
        let model = try! OTUtils.getAttributeValueFromNative("2.0.0")
        XCTAssertTrue(try! model.isSemanticVersionEqual(than: "2.0"))
    }
    // Test when target is full semantic version major.minor.patch
    func testIsSemanticSameFull() {
        let model = try! OTUtils.getAttributeValueFromNative("3.0.0")
        XCTAssertTrue(try! model.isSemanticVersionEqual(than: "3.0.0"))
    }

    // Test compare less when target is only major.minor
    func testIsSemanticLess() {
        let model = try! OTUtils.getAttributeValueFromNative("2.1.6")
        XCTAssertTrue(try! model.isSemanticVersionLess(than: "2.2"))
    }

    // Test compare less when target is full major.minor.patch
    func testIsSemanticFullLess() {
        let model = try! OTUtils.getAttributeValueFromNative("2.1.6")
        XCTAssertTrue(try! model.isSemanticVersionLess(than: "2.1.9"))
    }

    // Test compare greater when target is only major.minor
    func testIsSemanticMore() {
        let model = try! OTUtils.getAttributeValueFromNative("2.3.6")
        XCTAssertTrue(try! model.isSemanticVersionGreater(than: "2.2"))
    }

    // Test compare greater when target is major.minor.patch
    func testIsSemanticFullMore() {
        let model = try! OTUtils.getAttributeValueFromNative("2.1.9")
        XCTAssertTrue(try! model.isSemanticVersionGreater(than: "2.1.6"))
    }
    
    // Test compare equal when target is major.minor.patch-beta
    func testIsSemanticFullEqual() {
        let model = try! OTUtils.getAttributeValueFromNative("2.1.9-beta")
        XCTAssertTrue(try! model.isSemanticVersionEqual(than: "2.1.9-beta"))
    }


}
