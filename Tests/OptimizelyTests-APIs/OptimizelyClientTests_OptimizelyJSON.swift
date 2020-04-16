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

import XCTest

// MARK: - Sample Data and Setup

class OptimizelyClientTests_OptimizelyJSON: XCTestCase {
    
    private var payload = ""
    private var data = [String: Any]()
    private var innerField2List = [InnerField2]()
    private var optimizelyJSON: OptimizelyJSON!
    
    override func setUp() {
        self.innerField2List = [
            InnerField2.string("1"),
            InnerField2.string("2"),
            InnerField2.double(3.01),
            InnerField2.double(4.23),
            InnerField2.bool(true)
        ]
        self.payload = """
        {
        "field1": 1,
        "field2": 2.5,
        "field3": "three",
        "field4": {"inner_field1":3,"inner_field2":["1","2",3.01,4.23,true]},
        "field5": true,
        }
        """
        self.data = [
            "field1": 1,
            "field2": 2.5,
            "field3": "three",
            "field4": [
                "inner_field1": 3.0,
                "inner_field2": ["1","2",3.01,4.23,true]
            ],
            "field5": true,
        ]
        try! self.optimizelyJSON = OptimizelyJSON(payload: self.payload)
    }
    
    private struct ValidSchema: Decodable, Equatable {
        static func == (lhs: ValidSchema, rhs: ValidSchema) -> Bool {
            return lhs.field1 == rhs.field1 && lhs.field2 == rhs.field2 && lhs.field3 == rhs.field3 &&
                lhs.field4 == rhs.field4 && lhs.field5 == rhs.field5
        }
        
        var field1: Int = 0
        var field2: Double = 0.0
        var field3: String = ""
        var field4: Field4 = Field4()
        var field5: Bool = false
    }
    
    private struct Field4: Decodable, Equatable {
        
        static func == (lhs: Field4, rhs: Field4) -> Bool {
            if (lhs.innerField1 != rhs.innerField1 || lhs.innerField2.count != rhs.innerField2.count) {
                return false
            }
            for (index,value) in lhs.innerField2.enumerated() {
                if rhs.innerField2[index] != value {
                    return false
                }
            }
            return true
        }
        
        var innerField1: Int = 0
        var innerField2: [InnerField2] = []
        
        enum CodingKeys: String, CodingKey {
            case innerField1 = "inner_field1"
            case innerField2 = "inner_field2"
        }
    }
    
    private enum InnerField2: Decodable, Equatable  {
        case bool(Bool)
        case double(Double)
        case string(String)
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let x = try? container.decode(Bool.self) {
                self = .bool(x)
                return
            }
            if let x = try? container.decode(Double.self) {
                self = .double(x)
                return
            }
            if let x = try? container.decode(String.self) {
                self = .string(x)
                return
            }
            throw DecodingError.typeMismatch(InnerField2.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for InnerField2"))
        }
    }
    
    private struct EmptySchema: Decodable {
    }
    
    private struct IncorrectSchema: Decodable {
        var incorrectField: Int = 0
    }
    
    private struct NonDecodableSchema {
    }
    
}

// MARK: - Tests

extension OptimizelyClientTests_OptimizelyJSON {
    
    func testConstructorsHappyPathToString() {
        var err: Error?
        var optimizelyJSON1: OptimizelyJSON?
        do {
            try optimizelyJSON1 = OptimizelyJSON(payload: self.payload)
        } catch {
            err = error
        }
        XCTAssertNil(err)
        
        var optimizelyJSON2: OptimizelyJSON?
        do {
            try optimizelyJSON2 = OptimizelyJSON(data: self.data)
        } catch {
            err = error
        }
        XCTAssertNil(err)
        
        var optimizelyJSON1ToString: String?
        var optimizelyJSON2ToString: String?
        do {
            try optimizelyJSON1ToString = optimizelyJSON1?.toString()
            try optimizelyJSON2ToString = optimizelyJSON2?.toString()
        } catch {
            err = error
        }
        XCTAssertNil(err)
        XCTAssertNotNil(optimizelyJSON1ToString)
        XCTAssertEqual(optimizelyJSON1ToString, self.payload)
        // We cannot compare both string since when converting dict to string, the order is not certain
        XCTAssertNotNil(optimizelyJSON2ToString)
    }
    
    func testConstructorsHappyPathToMap() {
        var err: Error?
        let optimizelyJSON1 = try! OptimizelyJSON(payload: self.payload)
        let optimizelyJSON2 = try! OptimizelyJSON(data: self.data)
        
        var optimizelyJSON1ToMap: [String:Any]!
        var optimizelyJSON2ToMap: [String:Any]!
        do {
            try optimizelyJSON1ToMap = optimizelyJSON1.toMap()
            try optimizelyJSON2ToMap = optimizelyJSON2.toMap()
        } catch {
            err = error
        }
        XCTAssertNil(err)
        XCTAssertNotNil(optimizelyJSON1ToMap)
        XCTAssertNotNil(optimizelyJSON2ToMap)
        XCTAssertTrue(NSDictionary(dictionary: optimizelyJSON1ToMap).isEqual(to: optimizelyJSON2ToMap))
        
        // Verifying json2 toString was valid by converting it to dict and comparing with json1 dict
        let json2StringToMap = OTUtils.convertToDictionary(text: try! optimizelyJSON2.toString())
        XCTAssertNotNil(json2StringToMap)
        XCTAssertTrue(NSDictionary(dictionary: optimizelyJSON1ToMap).isEqual(to: json2StringToMap!))
    }
    
    func testConstructorWithInvalidPayloadString() {
        var err: Error?
        var optimizelyJSON: OptimizelyJSON?
        do {
            try optimizelyJSON = OptimizelyJSON(payload: "incorrect_string")
        } catch {
            err = error
        }
        XCTAssertEqual(err?.localizedDescription, OptimizelyError.failedToConvertStringToDictionary.reason)
        XCTAssertNil(optimizelyJSON)
    }
    
    func testConstructorWithInvalidJSONArrayPayloadString() {
        let jsonArrayPayload = """
        [{
        "field1": 1,
        "field2": 2.5,
        "field3": "three",
        "field4": {"inner_field1":3,"inner_field2":["1","2",3.01,4.23,true]},
        "field5": true,
        }]
        """
        var err: Error?
        var optimizelyJSON: OptimizelyJSON?
        do {
            try optimizelyJSON = OptimizelyJSON(payload: jsonArrayPayload)
        } catch {
            err = error
        }
        XCTAssertEqual(err?.localizedDescription, OptimizelyError.failedToConvertStringToDictionary.reason)
        XCTAssertNil(optimizelyJSON)
    }
    
    func testConstructorWithNonSerializableData() {
        let data: [String: Any] = ["test": UIImage()]
        var err: Error?
        do {
            try _ = OptimizelyJSON(data: data)
        } catch {
            err = error
        }
        XCTAssertEqual(err?.localizedDescription, OptimizelyError.invalidDictionary.reason)
    }
    
    func testToMap() {
        var err: Error?
        var optimizelyJSONToMap: [String:Any]!
        do {
            try optimizelyJSONToMap = self.optimizelyJSON.toMap()
        } catch {
            err = error
        }
        XCTAssertNil(err)
        XCTAssertTrue(NSDictionary(dictionary: optimizelyJSONToMap).isEqual(to: self.data))
    }
    
    func testToString() {
        var err: Error?
        var optimizelyJSONToString: String!
        do {
            try optimizelyJSONToString = self.optimizelyJSON.toString()
        } catch {
            err = error
        }
        XCTAssertNil(err)
        XCTAssertEqual(optimizelyJSONToString, self.payload)
    }
    
    func testGetValueForInvalidJSONKeyAndEmptySchema() {
        var err: Error?
        var schema = EmptySchema()
        do {
            try self.optimizelyJSON.getValue(jsonPath: "field4.", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertEqual(err?.localizedDescription, OptimizelyError.valueForKeyNotFound("").reason)
    }
    
    func testGetValueForMissingJSONKeyAndEmptySchema() {
        var err: Error?
        var schema = EmptySchema()
        do {
            try self.optimizelyJSON.getValue(jsonPath: "some_key", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertEqual(err?.localizedDescription, OptimizelyError.valueForKeyNotFound("some_key").reason)
    }
    
    func testGetValueForInvalidJSONMultipleKeyAndEmptySchema() {
        var err: Error?
        var schema = EmptySchema()
        do {
            try self.optimizelyJSON.getValue(jsonPath: "field3.some_key", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertEqual(err?.localizedDescription, OptimizelyError.valueForKeyNotFound("some_key").reason)
    }
    
    func testGetValueForValidJSONKeyAndEmptySchema() {
        var err: Error?
        var schema = EmptySchema()
        do {
            try self.optimizelyJSON.getValue(jsonPath: "field4", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertNil(err)
    }
    
    func testGetValueForValidJSONKeyAndNonDecodableEmptySchema() {
        var err: Error?
        var schema = NonDecodableSchema()
        do {
            try self.optimizelyJSON.getValue(jsonPath: "field4", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertEqual(err?.localizedDescription, OptimizelyError.failedToAssignValueToSchema.reason)
    }
    
    func testGetValueForValidJSONKeyAndIncorrectDecodableStructSchema() {
        var err: Error?
        var schema = IncorrectSchema()
        do {
            try self.optimizelyJSON.getValue(jsonPath: "field4", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertEqual(err?.localizedDescription, OptimizelyError.failedToAssignValueToSchema.reason)
        
    }
    
    func testGetValueForValidJSONMultipleKeyAndEmptySchema() {
        var err: Error?
        var schema = EmptySchema()
        do {
            try self.optimizelyJSON.getValue(jsonPath: "field4.inner_field1", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertEqual(err?.localizedDescription, OptimizelyError.failedToAssignValueToSchema.reason)
    }
    
    func testGetValueForValidJSONMultipleKeyAndNonDecodableSchema() {
        var err: Error?
        var schema = NonDecodableSchema()
        do {
            try self.optimizelyJSON.getValue(jsonPath: "field4.inner_field1", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertEqual(err?.localizedDescription, OptimizelyError.failedToAssignValueToSchema.reason)
    }
    
    func testGetValueForValidJSONMultipleKeyAndValidSchema() {
        var err: Error?
        var schema: Int = 0
        do {
            try self.optimizelyJSON.getValue(jsonPath: "field4.inner_field1", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertNil(err)
        XCTAssertEqual(schema, 3)
    }
    
    func testGetValueForValidJSONMultipleKeyAndValidGenericSchema() {
        var err: Error?
        var schema: Any!
        do {
            try self.optimizelyJSON.getValue(jsonPath: "field4.inner_field2", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertNil(err)
        XCTAssertTrue(schema is [Any])
        
        let v = schema as! [Any]
        XCTAssertEqual(v[0] as! String, "1")
        XCTAssertEqual(v[1] as! String, "2")
        XCTAssertEqual(v[2] as! Double, 3.01)
        XCTAssertEqual(v[3] as! Double, 4.23)
        XCTAssertEqual(v[4] as! Bool, true)
    }
    
    func testGetValueForValidJSONKeyAndIntValue() {
        var err: Error?
        var schema: Int = 0
        do {
            try self.optimizelyJSON.getValue(jsonPath: "field1", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertNil(err)
        XCTAssertEqual(schema, 1)
    }
    
    func testGetValueForValidJSONKeyAndDoubleValue() {
        var err: Error?
        var schema: Double = 0
        do {
            try self.optimizelyJSON.getValue(jsonPath: "field2", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertNil(err)
        XCTAssertEqual(schema, 2.5)
    }
    
    func testGetValueForValidJSONKeyAndStringValue() {
        var err: Error?
        var schema: String = ""
        do {
            try self.optimizelyJSON.getValue(jsonPath: "field3", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertNil(err)
        XCTAssertEqual(schema, "three")
    }
    
    func testGetValueForValidJSONKeyAndBoolValue() {
        var err: Error?
        var schema: Bool = false
        do {
            try self.optimizelyJSON.getValue(jsonPath: "field5", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertNil(err)
        XCTAssertEqual(schema, true)
    }
    
    func testGetValueForEmptyJSONKeyAndInvalidSchema() {
        var err: Error?
        var schema: Int = 0
        do {
            try self.optimizelyJSON.getValue(jsonPath: "", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertEqual(err?.localizedDescription, OptimizelyError.failedToAssignValueToSchema.reason)
    }
    
    func testGetValueForEmptyJSONKeyAndEmptySchema() {
        var err: Error?
        var schema = EmptySchema()
        do {
            try self.optimizelyJSON.getValue(jsonPath: "", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertNil(err)
    }
    
    func testGetValueForEmptyJsonKeyAndWholeSchema() {
        var err: Error?
        var schema = ValidSchema()
        do {
            try self.optimizelyJSON.getValue(jsonPath: "", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertNil(err)
        
        let expectedStruct = ValidSchema(
            field1: 1,
            field2: 2.5,
            field3: "three",
            field4: Field4(innerField1: 3, innerField2: self.innerField2List),
            field5: true
        )
        XCTAssertEqual(schema, expectedStruct)
    }
    
    func testGetValueForValidJsonKeyAndPartialSchema() {
        var err: Error?
        var schema = Field4()
        do {
            try self.optimizelyJSON.getValue(jsonPath: "field4", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertNil(err)
        
        let expectedStruct = Field4(
            innerField1: 3,
            innerField2: self.innerField2List
        )
        XCTAssertEqual(schema, expectedStruct)
        
        // check if it does not destroy original object
        do {
            try self.optimizelyJSON.getValue(jsonPath: "field4", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertNil(err)
        XCTAssertEqual(schema, expectedStruct)
    }
    
    func testGetValueForValidJsonKeyAndArraySchema() {
        var err: Error?
        var schema: [Any]!
        do {
            try self.optimizelyJSON.getValue(jsonPath: "field4.inner_field2", schema: &schema)
        } catch {
            err = error
        }
        XCTAssertNil(err)
        
        XCTAssertEqual(schema[0] as! String, "1")
        XCTAssertEqual(schema[1] as! String, "2")
        XCTAssertEqual(schema[2] as! Double, 3.01)
        XCTAssertEqual(schema[3] as! Double, 4.23)
        XCTAssertEqual(schema[4] as! Bool, true)
    }
}
