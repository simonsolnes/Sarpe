import Foundation
@testable import Sarpe
import XCTest

final class DocumentationTests: XCTestCase {
    func testCatOrDog() throws {
        XCTAssertEqual(digit.parse("1"), .success("1", ""))
        enum Animal {
            case cat
            case dog
        }
        let parser = either(
            literal("cat").to(Animal.cat),
            literal("dog").to(Animal.dog)
        )

        XCTAssertEqual(parser.parse("cat"), .success(.cat, ""))
    }

    func testBindExample() throws {
        enum Number: Equatable {
            case signed(Int)
            case unsigned(UInt)
        }

        let number = char("-").optional().bind { minus in
            let unsignedNumber = satisfy { "0" ... "9" ~= $0 }
                .repeat(0...)
                .map { String($0) }

            if let minus {
                return unsignedNumber
                    .map { -Int($0)! }
                    .map { Number.signed($0) }
            } else {
                return unsignedNumber
                    .map { UInt($0)! }
                    .map { Number.unsigned($0) }
            }
        }

        XCTAssertEqual(number.parse("3"), .limit(.unsigned(3), ""))
        XCTAssertEqual(number.parse("-0345somethingElse"), .success(.signed(-345), "somethingElse"))
    }
}
