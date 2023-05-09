@testable import Sarpe
import XCTest

final class SarpeTests: XCTestCase {
    func testNull() throws {
        XCTAssertEqual(jsonNull.parse("null"), .success(JSON.null, ""))
        XCTAssertEqual(jsonNull.parse("nul"), .limit(nil, "nul"))
        XCTAssertEqual(jsonNull.parse("nullaa"), .success(JSON.null, "aa"))
        XCTAssertTrue(jsonNull.parse("fnullaa").isRetreat())
    }

    func testBool() throws {
        XCTAssertEqual(jsonBool.parse("true"), .success(JSON.bool(true), ""))
        XCTAssertEqual(jsonBool.parse("false"), .success(JSON.bool(false), ""))
        XCTAssertEqual(jsonBool.parse("fals"), .limit(nil, "fals"))
        XCTAssertEqual(jsonBool.parse("falseff"), .success(JSON.bool(false), "ff"))
    }

    func testWhitespace() throws {
        XCTAssertEqual(jsonWhitespace.parse("\n \nf"), .success("\n \n", "f"))
        XCTAssertEqual(jsonWhitespace.parse("f"), .success("", "f"))
    }

    func testString() throws {
        XCTAssertEqual(jsonString.parse("\"hello\""), .success(JSON.string("hello"), ""))
        XCTAssertEqual(jsonString.parse("\"he\\rllo\""), .success(JSON.string("he\rllo"), ""))
        XCTAssertEqual(jsonString.parse("\"he\\rllo there \\u00ff\""), .success(JSON.string("he\rllo there ÿ"), ""))
        XCTAssertEqual(jsonString.parse("\"he\\rllo there \\u00ff\""), .success(JSON.string("he\rllo there \u{00ff}"), ""))
        XCTAssertTrue(jsonString.parse("\"he\\rllo th\\ere \\u00ff\"").isRetreat())
    }

    func testNumber() throws {
        XCTAssertEqual(jsonNumber.parse("34 "), .success(.uint(34), " "))
        XCTAssertEqual(jsonNumber.parse("34"), .limit(.uint(34), ""))
        XCTAssertEqual(jsonNumber.parse("34f"), .success(.uint(34), "f"))
        XCTAssertEqual(jsonNumber.parse("0f"), .success(.uint(0), "f"))
        XCTAssertEqual(jsonNumber.parse("-0f"), .success(.int(-0), "f"))
        XCTAssertEqual(jsonNumber.parse("-400"), .limit(.int(-400), ""))
        XCTAssertEqual(jsonNumber.parse("-0400"), .success(.int(-0), "400"))
        XCTAssertEqual(jsonNumber.parse("-400.3"), .limit(JSON.double(-400.3), ""))
        XCTAssertEqual(jsonNumber.parse("-400.3 "), .success(JSON.double(-400.3), " "))
        XCTAssertEqual(jsonNumber.parse("400.3 "), .success(JSON.double(400.3), " "))
        XCTAssertEqual(jsonNumber.parse("400.3e3 "), .success(JSON.double(400300.0), " "))
    }

    func testArray() throws {
        XCTAssertEqual(jsonArray.parse("[3]"), .success(JSON.array([JSON.uint(3)]), ""))
        XCTAssertEqual(jsonArray.parse("[[[]]]"), .success(JSON.array([JSON.array([JSON.array([])])]), ""))
        XCTAssertEqual(jsonArray.parse("[[5, [\"hei\"]]]"),
                       .success(JSON.array([
                           JSON.array([JSON.uint(5), JSON.array([JSON.string("hei")])]),
                       ]), ""))
        XCTAssertEqual(jsonArray.parse("[3 ,   \"fish\"]"), .success(JSON.array([JSON.uint(3), JSON.string("fish")]), ""))
    }

    func testObject() throws {
        XCTAssertEqual(jsonObject.parse("{}"), .success(JSON.object([:]), ""))
        XCTAssertEqual(jsonObject.parse("{ \"fish\" :3}"), .success(JSON.object(["fish": JSON.uint(3)]), ""))
        XCTAssertEqual(JSON.parse("{\"hei\": 7}"), .success(JSON.object(["hei": JSON.uint(7)]), ""))
    }

    func testIntegrationSmall() throws {
        let test1format1 = """
        [
            [
                {
                    "using": "notice",
                    "solar": true,
                    "trace": -1619953567,
                    "another": "shorter",
                    "certain": false,
                    "attack": "cool"
                },
                false,
                true,
                -2036083992,
                1706257801.7564554,
                "friend"
            ],
            "may",
            "bad",
            true,
            true,
            false
        ]
        """
        let test1format2 = #"[[{"using":"notice","solar":true,"trace":-1619953567,"another":"shorter","certain":false,"attack":"cool"},false,true, -2036083992,1706257801.7564554,"friend"],"may","bad",true,true,false]"#

        let test1format3 = """
        [[{"using":"notice","solar":            true,"trace":

        -1619953567,"another"   :"shorter",             "certain"



        :false,"attack":
        "cool"},false,true,

        -2036083992
        ,1706257801.7564554,                            "friend"],"may","bad",true,true,false]
        """

        let test1Expected = Parse<Substring, JSON>.success(JSON.array([
            JSON.array([
                JSON.object([
                    "using": JSON.string("notice"),
                    "solar": JSON.bool(true),
                    "trace": JSON.int(-1619953567),
                    "another": JSON.string("shorter"),
                    "certain": JSON.bool(false),
                    "attack": JSON.string("cool"),
                ]),
                JSON.bool(false),
                JSON.bool(true),
                JSON.int(-2036083992),
                JSON.double(Double(1706257801.7564554)),
                JSON.string("friend"),
            ]),
            JSON.string("may"),
            JSON.string("bad"),
            JSON.bool(true),
            JSON.bool(true),
            JSON.bool(false),
        ]), "")

        XCTAssertEqual(JSON.parse(test1format1), test1Expected)
        XCTAssertEqual(JSON.parse(test1format2), test1Expected)
        XCTAssertEqual(JSON.parse(test1format3), test1Expected)
    }

    func testIntegrationBig() throws {
        let test2 = """
        [
            [
                {
                    "foot": [
                        {
                            "tone": {
                                "ever": -2090952406,
                                "top": 16053742.921692848,
                                "middle": {
                                    "move": [
                                        {
                                            "subject": "engineer",
                                            "bottle": -1586440403,
                                            "hang": [
                                                136820061,
                                                -837346463.2924082,
                                                {
                                                    "wait": {
                                                        "level": -293146016,
                                                        "depend": -1825927357,
                                                        "fifteen": "article",
                                                        "social": -348169927.8115847
                                                    },
                                                    "instant": "close",
                                                    "greatest": false,
                                                    "bridge": "whistle"
                                                },
                                                1438015304.3254042
                                            ],
                                            "sail": 2099043766.135565
                                        },
                                        469912132,
                                        -294042962.783715,
                                        1529443645
                                    ],
                                    "gravity": -334952669,
                                    "mountain": "largest",
                                    "flow": "element"
                                },
                                "lack": 1776536515
                            },
                            "discuss": 774342363.2296839,
                            "pen": "select",
                            "arrow": {
                                "paid": "particularly",
                                "tight": [
                                    {
                                        "public": "slipped",
                                        "love": {
                                            "my": {
                                                "very": [
                                                    1401909510,
                                                    {
                                                        "line": true,
                                                        "coach": "butter"
                                                    }
                                                ],
                                                "appearance": 2142521985
                                            },
                                            "two": [
                                                [
                                                    {
                                                        "gentle": "beside",
                                                        "rise": "place"
                                                    },
                                                    {
                                                        "fast": true,
                                                        "putting": [
                                                            "to",
                                                            "purpose"
                                                        ]
                                                    }
                                                ],
                                                641590699
                                            ]
                                        }
                                    },
                                    [
                                        "package",
                                        1492476026.7092535
                                    ]
                                ]
                            }
                        },
                        false,
                        false,
                        true
                    ],
                    "ten": -367932371,
                    "twice": "cool",
                    "engineer": true
                },
                -1280235865,
                "or",
                1353663779
            ],
            "nodded",
            798743318,
            true
        ]
        """

        let test2Expected = JSON.array([
            .array([
                .object([
                    "foot": .array([
                        .object([
                            "tone": .object([
                                "ever": .int(-2090952406),
                                "top": .double(16053742.921692848),
                                "middle": .object([
                                    "move": .array([
                                        .object([
                                            "subject": .string("engineer"),
                                            "bottle": .int(-1586440403),
                                            "hang": .array([
                                                .uint(136820061),
                                                .double(-837346463.2924082),
                                                .object([
                                                    "wait": .object([
                                                        "level": .int(-293146016),
                                                        "depend": .int(-1825927357),
                                                        "fifteen": .string("article"),
                                                        "social": .double(-348169927.8115847),
                                                    ]),
                                                    "instant": .string("close"),
                                                    "greatest": .bool(false),
                                                    "bridge": .string("whistle"),
                                                ]),
                                                .double(1438015304.3254042),
                                            ]),
                                            "sail": .double(2099043766.135565),
                                        ]),
                                        .uint(469912132),
                                        .double(-294042962.783715),
                                        .uint(1529443645),
                                    ]),
                                    "gravity": .int(-334952669),
                                    "mountain": .string("largest"),
                                    "flow": .string("element"),
                                ]),
                                "lack": .uint(1776536515),
                            ]),
                            "discuss": .double(774342363.2296839),
                            "pen": .string("select"),
                            "arrow": .object([
                                "paid": .string("particularly"),
                                "tight": .array([
                                    .object([
                                        "public": .string("slipped"),
                                        "love": .object([
                                            "my": .object([
                                                "very": .array([
                                                    .uint(1401909510),
                                                    .object([
                                                        "line": .bool(true),
                                                        "coach": .string("butter"),
                                                    ]),
                                                ]),
                                                "appearance": .uint(2142521985),
                                            ]),
                                            "two": .array([
                                                .array([
                                                    .object([
                                                        "gentle": .string("beside"),
                                                        "rise": .string("place"),
                                                    ]),
                                                    .object([
                                                        "fast": .bool(true),
                                                        "putting": .array([
                                                            .string("to"),
                                                            .string("purpose"),
                                                        ]),
                                                    ]),
                                                ]),
                                                .uint(641590699),
                                            ]),
                                        ]),
                                    ]),
                                    .array([
                                        .string("package"),
                                        .double(1492476026.7092535),
                                    ]),
                                ]),
                            ]),
                        ]),
                        .bool(false),
                        .bool(false),
                        .bool(true),
                    ]),
                    "ten": .int(-367932371),
                    "twice": .string("cool"),
                    "engineer": .bool(true),
                ]),
                .int(-1280235865),
                .string("or"),
                .uint(1353663779),
            ]),
            .string("nodded"),
            .uint(798743318),
            .bool(true),

        ])

        XCTAssertEqual(JSON.parse(test2), .success(test2Expected, ""))
    }
}
