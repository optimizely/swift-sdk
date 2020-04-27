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
    private var map = [String: Any]()
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
        self.map = [
            "field1": 1,
            "field2": 2.5,
            "field3": "three",
            "field4": [
                "inner_field1": 3.0,
                "inner_field2": ["1","2",3.01,4.23,true]
            ],
            "field5": true,
        ]
        self.optimizelyJSON = OptimizelyJSON(payload: self.payload)!
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
        let optimizelyJSON1 = OptimizelyJSON(payload: self.payload)
        let optimizelyJSON2 = OptimizelyJSON(map: self.map)
        
        let optimizelyJSON1ToString = optimizelyJSON1?.toString()
        let optimizelyJSON2ToString = optimizelyJSON2?.toString()
        
        XCTAssertNotNil(optimizelyJSON1ToString)
        XCTAssertEqual(optimizelyJSON1ToString, self.payload)
        // We cannot compare both string since when converting dict to string, the order is not certain
        XCTAssertNotNil(optimizelyJSON2ToString)
    }
    
    func testConstructorsHappyPathToMap() {
        let optimizelyJSON1 = OptimizelyJSON(payload: self.payload)!
        let optimizelyJSON2 = OptimizelyJSON(map: self.map)!
        
        let optimizelyJSON1ToMap = optimizelyJSON1.toMap()
        let optimizelyJSON2ToMap = optimizelyJSON2.toMap()
        
        XCTAssertNotNil(optimizelyJSON1ToMap)
        XCTAssertNotNil(optimizelyJSON2ToMap)
        XCTAssertTrue(NSDictionary(dictionary: optimizelyJSON1ToMap).isEqual(to: optimizelyJSON2ToMap))
        
        // Verifying json2 toString was valid by converting it to dict and comparing with json1 dict
        let json2StringToMap = OTUtils.convertToDictionary(text: optimizelyJSON2.toString()!)
        XCTAssertNotNil(json2StringToMap)
        XCTAssertTrue(NSDictionary(dictionary: optimizelyJSON1ToMap).isEqual(to: json2StringToMap!))
    }
    
    func testConstructorWithInvalidPayloadString() {
        XCTAssertNil(OptimizelyJSON(payload: "incorrect_string"))
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
        XCTAssertNil(OptimizelyJSON(payload: jsonArrayPayload))
    }
    
    func testConstructorWithNonSerializableMap() {
        let map: [String: Any] = ["test": UIImage()]
        XCTAssertNil(OptimizelyJSON(map: map))
    }
    
    func testToMap() {
        XCTAssertTrue(NSDictionary(dictionary: self.optimizelyJSON.toMap()).isEqual(to: self.map))
    }
    
    func testToString() {
        let optimizelyJSONToString = self.optimizelyJSON.toString()
        XCTAssertEqual(optimizelyJSONToString, self.payload)
    }
    
    func testGetValueForInvalidJSONKeyAndEmptySchema() {
        let schema: EmptySchema? = self.optimizelyJSON.getValue(jsonPath: "field4.")
        XCTAssertNil(schema)
    }
    
    func testGetValueForMissingJSONKeyAndEmptySchema() {
        let schema: EmptySchema? = self.optimizelyJSON.getValue(jsonPath: "some_key")
        XCTAssertNil(schema)
    }
    
    func testGetValueForInvalidJSONMultipleKeyAndEmptySchema() {
        let schema: EmptySchema? = self.optimizelyJSON.getValue(jsonPath: "field3.some_key")
        XCTAssertNil(schema)
    }
    
    func testGetValueForValidJSONKeyAndEmptySchema() {
        let schema: EmptySchema? = self.optimizelyJSON.getValue(jsonPath: "field4")
        XCTAssertNotNil(schema)
    }
    
    func testGetValueForValidJSONKeyAndNonDecodableEmptySchema() {
        let schema: NonDecodableSchema? = self.optimizelyJSON.getValue(jsonPath: "field4")
        XCTAssertNil(schema)
    }
    
    func testGetValueForValidJSONKeyAndIncorrectDecodableStructSchema() {
        let schema: IncorrectSchema? = self.optimizelyJSON.getValue(jsonPath: "field4")
        XCTAssertNil(schema)
    }
    
    func testGetValueForValidJSONMultipleKeyAndEmptySchema() {
        let schema: EmptySchema? = self.optimizelyJSON.getValue(jsonPath: "field4.inner_field1")
        XCTAssertNil(schema)
    }
    
    func testGetValueForValidJSONMultipleKeyAndNonDecodableSchema() {
        let schema: NonDecodableSchema? = self.optimizelyJSON.getValue(jsonPath: "field4.inner_field1")
        XCTAssertNil(schema)
    }
    
    func testGetValueForValidJSONMultipleKeyAndValidSchema() {
        let schema: Int? = self.optimizelyJSON.getValue(jsonPath: "field4.inner_field1")
        XCTAssertNotNil(schema)
        XCTAssertEqual(schema, 3)
    }
    
    func testGetValueForValidJSONMultipleKeyAndValidGenericSchema() {
        let schema: Any? = self.optimizelyJSON.getValue(jsonPath: "field4.inner_field2")
        XCTAssertNotNil(schema)
        XCTAssertTrue(schema is [Any])
        
        let v = schema as! [Any]
        XCTAssertEqual(v[0] as! String, "1")
        XCTAssertEqual(v[1] as! String, "2")
        XCTAssertEqual(v[2] as! Double, 3.01)
        XCTAssertEqual(v[3] as! Double, 4.23)
        XCTAssertEqual(v[4] as! Bool, true)
    }
    
    func testGetValueForValidJSONKeyAndIntValue() {
        let schema: Int? = self.optimizelyJSON.getValue(jsonPath: "field1")
        XCTAssertNotNil(schema)
        XCTAssertEqual(schema, 1)
    }
    
    func testGetValueForValidJSONKeyAndDoubleValue() {
        let schema: Double? = self.optimizelyJSON.getValue(jsonPath: "field2")
        XCTAssertNotNil(schema)
        XCTAssertEqual(schema, 2.5)
    }
    
    func testGetValueForValidJSONKeyAndStringValue() {
        let schema: String? = self.optimizelyJSON.getValue(jsonPath: "field3")
        XCTAssertNotNil(schema)
        XCTAssertEqual(schema, "three")
    }
    
    func testGetValueForValidJSONKeyAndBoolValue() {
        let schema: Bool? = self.optimizelyJSON.getValue(jsonPath: "field5")
        XCTAssertNotNil(schema)
        XCTAssertEqual(schema, true)
    }
    
    func testGetValueForEmptyJSONKeyAndInvalidSchema() {
        let schema: Int? = self.optimizelyJSON.getValue(jsonPath: "")
        XCTAssertNil(schema)
    }
    
    func testGetValueForNilJSONKeyAndInvalidSchema() {
        let schema: Int? = self.optimizelyJSON.getValue(jsonPath: nil)
        XCTAssertNil(schema)
    }
    
    func testGetValueForEmptyJSONKeyAndEmptySchema() {
        let schema: EmptySchema? = self.optimizelyJSON.getValue(jsonPath: "")
        XCTAssertNotNil(schema)
    }
    
    func testGetValueForNilJSONKeyAndEmptySchema() {
        let schema: EmptySchema? = self.optimizelyJSON.getValue(jsonPath: nil)
        XCTAssertNotNil(schema)
    }
    
    func testGetValueForEmptyJSONMultipleKeyAndEmptySchema() {
        let schema: EmptySchema? = self.optimizelyJSON.getValue(jsonPath: "field4..some_field")
        XCTAssertNil(schema)
    }
    
    func testGetValueForEmptyJsonKeyAndWholeSchema() {
        let schema: ValidSchema? = self.optimizelyJSON.getValue(jsonPath: "")
        XCTAssertNotNil(schema)
        
        let expectedStruct = ValidSchema(
            field1: 1,
            field2: 2.5,
            field3: "three",
            field4: Field4(innerField1: 3, innerField2: self.innerField2List),
            field5: true
        )
        XCTAssertEqual(schema, expectedStruct)
    }
    
    func testGetValueForNilJsonKeyAndWholeSchema() {
        let schema: ValidSchema? = self.optimizelyJSON.getValue(jsonPath: nil)
        XCTAssertNotNil(schema)
        
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
        var schema: Field4? = self.optimizelyJSON.getValue(jsonPath: "field4")
        XCTAssertNotNil(schema)
        
        let expectedStruct = Field4(
            innerField1: 3,
            innerField2: self.innerField2List
        )
        XCTAssertEqual(schema, expectedStruct)
        
        // check if it does not destroy original object
        schema = self.optimizelyJSON.getValue(jsonPath: "field4")
        XCTAssertNotNil(schema)
        XCTAssertEqual(schema, expectedStruct)
    }
    
    func testGetValueForValidJsonKeyAndArraySchema() {
        let schema: [Any]? = self.optimizelyJSON.getValue(jsonPath: "field4.inner_field2")
        XCTAssertNotNil(schema)
        
        XCTAssertEqual(schema?[0] as! String, "1")
        XCTAssertEqual(schema?[1] as! String, "2")
        XCTAssertEqual(schema?[2] as! Double, 3.01)
        XCTAssertEqual(schema?[3] as! Double, 4.23)
        XCTAssertEqual(schema?[4] as! Bool, true)
    }
}
