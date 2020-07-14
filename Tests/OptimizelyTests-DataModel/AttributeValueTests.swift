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

import XCTest

class AttributeValueTests: XCTestCase {
    
    let conditionString = ""
    let attributeKey = "key"
    let invalidValue = ["invalid"]
    
    // MARK: - Decode
    
    func testDecodeSuccessWithString() {
        let value = "geo"
        
        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == AttributeValue.string(value))
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == AttributeValue.string(value))
    }
    
    func testDocodeSuccessWithAllIntTypes() {
        let value = 10
        
        let tests = [
            [Int(value), Double(value), Int64(value)],
            [Int8(value), Double(value), Int64(value)],
            [Int16(value), Double(value), Int64(value)],
            [Int32(value), Double(value), Int64(value)],
            [Int64(value), Double(value), Int64(value)],
            [UInt(value), Double(value), Int64(value)],
            [UInt8(value), Double(value), Int64(value)],
            [UInt16(value), Double(value), Int64(value)],
            [UInt32(value), Double(value), Int64(value)],
            [UInt64(value), Double(value), Int64(value)]
        ]
        
        for (idx, test) in tests.enumerated() {
            let inputValue = test[0]
            let expModelValue = test[1] as! Double
            let expModel2Value = test[2] as! Int64
            
            // integer can be parsed as int or double (we catch as double first)
            let model = try! OTUtils.getAttributeValueFromNative(inputValue)
            XCTAssert(model == AttributeValue.double(expModelValue), "int type error with index = \(idx)")
            
            let model2 = AttributeValue(value: inputValue)
            XCTAssert(model2 == AttributeValue.int(expModel2Value), "int type error with index = \(idx)")
        }
    }
    
    func testDocodeSuccessWithAllNumberTypes() {
        let value = 13.5
        
        let tests = [
            [Double(value), Double(value), Double(value)],
            [Float(value), Double(value), Double(value)],
            [Float32(value), Double(value), Double(value)],
            [Float64(value), Double(value), Double(value)]
        ]
        
        for (idx, test) in tests.enumerated() {
            let inputValue = test[0]
            let expModelValue = test[1] as! Double
            let expModel2Value = test[2] as! Double
            
            let model = try! OTUtils.getAttributeValueFromNative(inputValue)
            XCTAssert(model == AttributeValue.double(expModelValue), "num type error with index = \(idx)")

            let model2 = AttributeValue(value: inputValue)
            XCTAssert(model2 == AttributeValue.double(expModel2Value), "num type error with index = \(idx)")
        }
        
        // Float80 (CLongDouble) is not supported JSON parser (it's not expected to see this from datafile, but it still
        // can be passed as attribute values from client app
        let testsAttributesOnly = [
            [CLongDouble(value), Double(value)]
        ]
        
        for (idx, test) in testsAttributesOnly.enumerated() {
            let inputValue = test[0]
            let expModel2Value = test[1] as! Double
            
            let model2 = AttributeValue(value: inputValue)
            XCTAssert(model2 == AttributeValue.double(expModel2Value), "num type error with index = \(idx)")
        }
    }
    
    func testDecodeSuccessWithAllBoolTypes() {
        let tests = [
            [true, true, true],
            [false, false, false]
        ]
        
        for (idx, test) in tests.enumerated() {
            let inputValue = test[0]
            let expModelValue = test[1]
            let expModel2Value = test[2]
            
            // integer can be parsed as int or double (we catch as double first)
            let model = try! OTUtils.getAttributeValueFromNative(inputValue)
            XCTAssert(model == AttributeValue.bool(expModelValue), "bool type error with index = \(idx)")
            
            let model2 = AttributeValue(value: inputValue)
            XCTAssert(model2 == AttributeValue.bool(expModel2Value), "bool type error with index = \(idx)")
        }
     }
    
    func testDecodeSuccessWithInt64_LargeValue() {
        // big numbers (larer than 2^53 max valid range) allowed to parse ok
        // only filtered as invalid when evaluated
        
        let value = Int64(pow(2, 53) as Double)
        
        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == AttributeValue.double(Double(value)))
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == AttributeValue.int(Int64(value)))
    }

    func testDecodeSuccessWithInvalidType() {
        let value = ["invalid type"]

        let model = try! OTUtils.getAttributeValueFromNative(value)
        
        XCTAssert(model == AttributeValue.others)
        
        let model2 = AttributeValue(value: value)
        XCTAssertNil(model2)
    }
    
    func testDecodeSuccessWithInvalidTypeNil() {
        let anyNil: Any? = nil
        let model = try! OTUtils.getAttributeValueFromNative(anyNil)
        XCTAssert(model == AttributeValue.others)
        
        let model2 = AttributeValue(value: anyNil)
        XCTAssertNil(model2)
    }
    
    // MARK: - NSNumber
    // ObjC client apps can pass NSNumber, NSNull etc
    
    func testDecodeSuccessWithNSNumberTrue() {
        let value = NSNumber(value: true)
        let expValue = AttributeValue.bool(true)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == expValue)
    }
    
    func testDecodeSuccessWithNSNumberFalse() {
        let value = NSNumber(value: false)
        let expValue = AttributeValue.bool(false)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == expValue)
    }

    func testDecodeSuccessWithNSNumber0() {
        let value = NSNumber(value: 0)
        // JSONParser() cannot tell {NSNumber(int), NSNumber(double) - catch as double first.
        let expValueJSON = AttributeValue.double(0.0)
        let expValueInstance = AttributeValue.int(0)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValueJSON)
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == expValueInstance)
    }
    
    func testDecodeSuccessWithNSNumber1() {
        let value = NSNumber(value: 1)
        // JSONParser() cannot tell {NSNumber(int), NSNumber(double) - catch as double first.
        let expValueJSON = AttributeValue.double(1.0)
        let expValueInstance = AttributeValue.int(1)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValueJSON)
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == expValueInstance)
    }

    func testDecodeSuccessWithNSNumber0_0() {
        let value = NSNumber(value: 0.0)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(0.0)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == expValue)
    }

    func testDecodeSuccessWithNSNumber1_0() {
        let value = NSNumber(value: 1.0)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(1.0)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == expValue)
    }
    
    func testDecodeSuccessWithNSNumber1_5() {
        let value = NSNumber(value: 1.5)
        let expValue = AttributeValue.double(1.5)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)

        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == expValue)
    }

    // MARK: - NSNull
    
    func testDecodeSuccessWithInvalidTypeNSNull() {
        let model = try! OTUtils.getAttributeValueFromNative(NSNull())

        // NSNull as Attribu
        XCTAssert(model == AttributeValue.others)
        
        // NSNull parsed same as nil
        let model2 = AttributeValue(value: NSNull())
        XCTAssertNil(model2)
    }
    
}

// MARK: - Encode

extension AttributeValueTests {
    
    func testEncodeJSON() {
        let modelGiven = [AttributeValue.string("us")]
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven))
    }
    
    func testEncodeJSON2() {
        let modelGiven = [AttributeValue.int(10)]
        let doubleResult = [AttributeValue.double(10.0)]
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven) ||    OTUtils.isEqualWithEncodeThenDecode(doubleResult))
    }
    
    func testEncodeJSON3() {
        let modelGiven = [AttributeValue.double(13.5)]
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven))
    }
    
    func testEncodeJSON4() {
        let modelGiven = [AttributeValue.bool(true)]
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven))
    }
    
    func testEncodeJSON5() {
        let modelGiven = [AttributeValue.others]
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven))
    }
    
}

// MARK: - Others

extension AttributeValueTests {
    
    func testDescription() {
        let valueString = "string"
        var model = try! OTUtils.getAttributeValueFromNative(valueString)
        XCTAssert(model == AttributeValue.string(valueString))
        XCTAssert(model.description == "string(\(valueString))")
        
        let valueDouble = 123.45
        model = try! OTUtils.getAttributeValueFromNative(valueDouble)
        XCTAssert(model == AttributeValue.double(valueDouble))
        XCTAssert(model.description == "double(\(valueDouble))")

        let valueBool = true
        model = try! OTUtils.getAttributeValueFromNative(valueBool)
        XCTAssert(model == AttributeValue.bool(valueBool))
        XCTAssert(model.description == "bool(\(valueBool))")

        let valueOther = [3]
        model = try! OTUtils.getAttributeValueFromNative(valueOther)
        XCTAssert(model == AttributeValue.others)
        XCTAssert(model.description == "others")
        
        
        let valueInteger = Int64(100)
        model = AttributeValue(value: valueInteger)!
        XCTAssert(model.description == "int(\(valueInteger))")
        
        let modelOptional = AttributeValue(value: valueOther)
        XCTAssertNil(modelOptional)
    }
    
    func testStringValue() {
        let valueString = "string"
        var model = AttributeValue.string(valueString)
        XCTAssert(model.stringValue == valueString)
        
        let valueInt = Int64(100)
        model = AttributeValue.int(valueInt)
        XCTAssert(model.stringValue == "\(valueInt)")

        let valueDouble = 123.45
        model = AttributeValue.double(valueDouble)
        XCTAssert(model.stringValue == "\(valueDouble)")

        let valueBool = true
        model = AttributeValue.bool(valueBool)
        XCTAssert(model.stringValue == "\(valueBool)")

        model = AttributeValue.others
        XCTAssert(model.stringValue == "UNKNOWN")
    }
    
    func testIsExactMatchWithInvalidValue() {
        let attr = AttributeValue.others
        var tmpError: Error?
        do {
            _ = try attr.isExactMatch(with: invalidValue, condition: nil, name: attributeKey)
        } catch {
            tmpError = error
        }
        XCTAssertEqual("[Optimizely][Error] " + tmpError!.localizedDescription, OptimizelyError.evaluateAttributeInvalidCondition(conditionString).localizedDescription)
    }
    
    func testIsExactMatchWithInfiniteValue() {
        let attr = AttributeValue.double(Double.infinity)
        var tmpError: Error?
        do {
            _ = try attr.isExactMatch(with: invalidValue, condition: nil, name: attributeKey)
        } catch {
            tmpError = error
        }
        XCTAssertEqual("[Optimizely][Error] " + tmpError!.localizedDescription, OptimizelyError.evaluateAttributeInvalidCondition(conditionString).localizedDescription)
    }
    
    func testIsExactMatchWithInvalidAttributeValue() {
        let attr = AttributeValue.string("string")
        var tmpError: Error?
        do {
            _ = try attr.isExactMatch(with: invalidValue, condition: nil, name: attributeKey)
        } catch {
            tmpError = error
        }
        XCTAssertEqual("[Optimizely][Error] " + tmpError!.localizedDescription, OptimizelyError.evaluateAttributeInvalidType(conditionString, invalidValue, attributeKey).localizedDescription)
    }
    
    func testIsExactMatchWithInfiniteAttributeValue() {
        let attr = AttributeValue.double(1)
        let value = Double.infinity
        var tmpError: Error?
        do {
            _ = try attr.isExactMatch(with: value, condition: nil, name: attributeKey)
        } catch {
            tmpError = error
        }
        XCTAssertEqual("[Optimizely][Error] " + tmpError!.localizedDescription, OptimizelyError.evaluateAttributeValueOutOfRange(conditionString, attributeKey).localizedDescription)
    }
    
    func testIsGreaterWithInvalidValue() {
        let attr = AttributeValue.string("")
        var tmpError: Error?
        do {
            _ = try attr.isGreater(than: Double(1), condition: nil, name: attributeKey)
        } catch {
            tmpError = error
        }
        XCTAssertEqual("[Optimizely][Error] " + tmpError!.localizedDescription, OptimizelyError.evaluateAttributeInvalidCondition(conditionString).localizedDescription)
    }
    
    func testIsGreaterWithInfiniteValue() {
        let attr = AttributeValue.double(Double.infinity)
        var tmpError: Error?
        do {
            _ = try attr.isGreater(than: Double(1), condition: nil, name: attributeKey)
        } catch {
            tmpError = error
        }
        XCTAssertEqual("[Optimizely][Error] " + tmpError!.localizedDescription, OptimizelyError.evaluateAttributeInvalidCondition(conditionString).localizedDescription)
    }
    
    func testIsGreaterWithInvalidAttributeValue() {
        let attr = AttributeValue.double(100.23)
        var tmpError: Error?
        do {
            _ = try attr.isGreater(than: invalidValue, condition: nil, name: attributeKey)
        } catch {
            tmpError = error
        }
        XCTAssertEqual("[Optimizely][Error] " + tmpError!.localizedDescription, OptimizelyError.evaluateAttributeInvalidType(conditionString, invalidValue, attributeKey).localizedDescription)
    }

    func testIsLessWithInvalidValue() {
        let attr = AttributeValue.string("")
        var tmpError: Error?
        do {
            _ = try attr.isLess(than: Double(1), condition: nil, name: attributeKey)
        } catch {
            tmpError = error
        }
        XCTAssertEqual("[Optimizely][Error] " + tmpError!.localizedDescription, OptimizelyError.evaluateAttributeInvalidCondition(conditionString).localizedDescription)
    }
    
    func testIsLessWithInfiniteValue() {
        let attr = AttributeValue.double(Double.infinity)
        var tmpError: Error?
        do {
            _ = try attr.isLess(than: Double(1), condition: nil, name: attributeKey)
        } catch {
            tmpError = error
        }
        XCTAssertEqual("[Optimizely][Error] " + tmpError!.localizedDescription, OptimizelyError.evaluateAttributeInvalidCondition(conditionString).localizedDescription)
    }
    
    func testIsLessWithInvalidAttributeValue() {
        let attr = AttributeValue.double(100.23)
        var tmpError: Error?
        do {
            _ = try attr.isLess(than: invalidValue, condition: nil, name: attributeKey)
        } catch {
            tmpError = error
        }
        XCTAssertEqual("[Optimizely][Error] " + tmpError!.localizedDescription, OptimizelyError.evaluateAttributeInvalidType(conditionString, invalidValue, attributeKey).localizedDescription)
    }
    
    func testIsSubstringWithInvalidValue() {
        let attr = AttributeValue.double(1)
        var tmpError: Error?
        do {
            _ = try attr.isSubstring(of: "valid", condition: nil, name: attributeKey)
        } catch {
            tmpError = error
        }
        XCTAssertEqual("[Optimizely][Error] " + tmpError!.localizedDescription, OptimizelyError.evaluateAttributeInvalidCondition(conditionString).localizedDescription)
    }
    
    func testIsSubstringWithInvalidAttributeValue() {
        let attr = AttributeValue.string("valid")
        var tmpError: Error?
        do {
            _ = try attr.isSubstring(of: invalidValue, condition: nil, name: attributeKey)
        } catch {
            tmpError = error
        }
        XCTAssertEqual("[Optimizely][Error] " + tmpError!.localizedDescription, OptimizelyError.evaluateAttributeInvalidType(conditionString, invalidValue, attributeKey).localizedDescription)
    }
    
    func testIsValidForExactMatcher() {
        var attr = AttributeValue.string("valid")
        XCTAssertTrue(attr.isValidForExactMatcher())
        attr = AttributeValue.int(1)
        XCTAssertTrue(attr.isValidForExactMatcher())
        attr = AttributeValue.double(1)
        XCTAssertTrue(attr.isValidForExactMatcher())
        attr = AttributeValue.bool(true)
        XCTAssertTrue(attr.isValidForExactMatcher())
        attr = AttributeValue.others
        XCTAssertFalse(attr.isValidForExactMatcher())
    }
    
}
