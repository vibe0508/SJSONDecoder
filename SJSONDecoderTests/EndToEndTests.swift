//
//  SJSONDecoderTests.swift
//  SJSONDecoderTests
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import XCTest
import SJSONDecoder

class EndToEndTests: XCTestCase {

    var decoder: SJSONDecoder!

    override func setUp() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-dd-MM HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        decoder = SJSONDecoder()
        decoder.dateDecodingStrategy = .withFormatter(formatter)
    }

    override func tearDown() {
    }

    func testInvalidData() {
        do {
            _ = try decoder.decode(TestEntity.self, from: Data())
            XCTAssert(false, "Error wasn't thrown on invalid data")
        } catch {
            XCTAssert(true)
        }
    }

    func testInvalidString() {
        do {
            _ = try decoder.decode(TestEntity.self, from: "Not valid string".data(using: .utf8)!)
            XCTAssert(false, "Error wasn't thrown on invalid string")
        } catch {
            XCTAssert(true)
        }
    }

    func testValidDictionaryString() {
        let testData = """
            {
                "string": "A",
                "double": 2.88,
                "integer": 8,
                "decimal": 80.6,
                "null": null,
                "date": "2019-09-06 18:15:10",
                "bool": true
            }
        """.data(using: .utf8)!
        do {
            let entry = try decoder.decode(TestEntity.self, from: testData)

            XCTAssertEqual(entry.string, "A")
            XCTAssertEqual(entry.double, 2.88)
            XCTAssertEqual(entry.integer, 8)
            XCTAssertEqual(entry.decimal, 80.6)
            XCTAssertEqual(entry.date.timeIntervalSince1970.rounded(), 1560104110)
        } catch {
            XCTAssert(false, "Error during decoding: \(error)")
        }
    }

    func testValidArrayString() {
        let testData = """
            [
                {
                    "string": "A",
                    "double": 2.88,
                    "integer": 8,
                    "decimal": 80.6,
                    "null": null,
                    "bool": true,
                    "date": "2019-09-06 18:15:10"
                },
                {
                    "string": "B",
                    "double": 2.88,
                    "integer": 8,
                    "decimal": 80.6,
                    "null": null,
                    "bool": true,
                    "date": "2019-09-06 18:15:10"
                }
            ]
        """.data(using: .utf8)!
        do {
            let array = try decoder.decode([TestEntity].self, from: testData)

            XCTAssertEqual(array.count, 2)
            XCTAssertEqual(array.first?.string, "A")
            XCTAssertEqual(array.last?.string, "B")
        } catch {
            XCTAssert(false, "Error during decoding: \(error)")
        }
    }

    func testMissingKey() {
        let testData = """
            {
                "string": "A",
                "integer": 8,
                "decimal": 80.6,
                "null": null,
                "bool": true,
                "date": "2019-09-06 18:15:10"
            }
        """.data(using: .utf8)!
        do {
            _ = try decoder.decode(TestEntity.self, from: testData)
            XCTAssert(false, "Error wasn't thrown on missing key")
        } catch DecodingError.keyNotFound(let codingKey, _) {
            XCTAssertEqual(codingKey.stringValue, "double")
        } catch {
            XCTAssert(false, "Wrong during decoding. Expected 'key not found', received \(error)")
        }
    }

    func testMissingValue() {
        let testData = """
            {
                "string": "A",
                "double": null,
                "integer": 8,
                "decimal": 80.6,
                "null": null,
                "bool": true,
                "date": "2019-09-06 18:15:10"
            }
        """.data(using: .utf8)!
        do {
            _ = try decoder.decode(TestEntity.self, from: testData)
            XCTAssert(false, "Error wasn't thrown on missing value")
        } catch DecodingError.valueNotFound(let type, let context) {
            XCTAssertEqual(context.codingPath.last?.stringValue, "double")
            XCTAssert(type == Double.self)
        } catch {
            XCTAssert(false, "Wrong during decoding. Expected 'value not found', received \(error)")
        }
    }

    func testTypeMismatch() {
        let testData = """
            {
                "string": "A",
                "double": 8.88,
                "integer": "8",
                "decimal": 80.6,
                "null": null,
                "date": "2019-09-06 18:15:10",
                "bool": true
            }
        """.data(using: .utf8)!
        do {
            _ = try decoder.decode(TestEntity.self, from: testData)
            XCTAssert(false, "Error wasn't thrown on type mismatch")
        } catch DecodingError.typeMismatch(let type, let context) {
            XCTAssertEqual(context.codingPath.last?.stringValue, "integer")
            XCTAssert(type == Int.self)
        } catch {
            XCTAssert(false, "Wrong during decoding. Expected 'type mismatch', received \(error)")
        }
    }

    func testPerformance() {
        let testData = """
            [
                {
                    "string": "A",
                    "double": 2.88,
                    "integer": 8,
                    "decimal": 80.6,
                    "null": null,
                    "date": "2019-09-06 18:15:10",
                    "bool": true
                },
                {
                    "string": "B",
                    "double": 2.88,
                    "integer": 8,
                    "decimal": 80.6,
                    "null": null,
                    "date": "2019-09-06 18:15:10",
                    "bool": true
                }
            ]
        """.data(using: .utf8)!

        let customDecoder = decoder!
        measureMetrics([
            XCTPerformanceMetric.wallClockTime,
            XCTPerformanceMetric("com.apple.XCTPerformanceMetric_HighWaterMarkForHeapAllocations"), XCTPerformanceMetric("com.apple.XCTPerformanceMetric_HighWaterMarkForVMAllocations")
        ], automaticallyStartMeasuring: true) {
            _ = try? customDecoder.decode([TestEntity].self, from: testData)
        }
    }

    func testPerformaceWithDefaultDecoder() {
        let testData = """
            [
                {
                    "string": "A",
                    "double": 2.88,
                    "integer": 8,
                    "decimal": 80.6,
                    "null": null,
                    "date": "2019-09-06 18:15:10",
                    "bool": true
                },
                {
                    "string": "B",
                    "double": 2.88,
                    "integer": 8,
                    "decimal": 80.6,
                    "null": null,
                    "date": "2019-09-06 18:15:10",
                    "bool": true
                }
            ]
        """.data(using: .utf8)!

        let defaultDecoder = JSONDecoder()
        measureMetrics([
            XCTPerformanceMetric.wallClockTime,
            XCTPerformanceMetric("com.apple.XCTPerformanceMetric_HighWaterMarkForHeapAllocations"), XCTPerformanceMetric("com.apple.XCTPerformanceMetric_HighWaterMarkForVMAllocations")
        ], automaticallyStartMeasuring: true) {
            _ = try? defaultDecoder.decode([TestEntity].self, from: testData)
        }
    }
}
