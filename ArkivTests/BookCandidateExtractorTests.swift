@testable import Arkiv
import XCTest

final class BookCandidateExtractorTests: XCTestCase {
    private let extractor = BookCandidateExtractor()

    func testExtractsTitleByAuthorRelationship() {
        let result = OCRResult(
            fullText: "Project Hail Mary by Andy Weir",
            blocks: []
        )

        let candidates = extractor.extract(from: result)

        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(candidates.first?.title, "Project Hail Mary")
        XCTAssertEqual(candidates.first?.author, "Andy Weir")
        XCTAssertEqual(candidates.first?.evidence, .byRelationship)
    }

    func testExtractsTitleOnlyLinesAndExcludesBoilerplate() {
        let result = OCRResult(
            fullText: "Books you need to read:\nThe Silent Patient\nFollow for more",
            blocks: []
        )

        let candidates = extractor.extract(from: result)

        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(candidates.first?.title, "The Silent Patient")
        XCTAssertNil(candidates.first?.author)
        XCTAssertEqual(candidates.first?.evidence, .standaloneLine)
    }

    func testExtractsAdjacentTitleAndAuthorLines() {
        let result = OCRResult(
            fullText: "The Midnight Library\nMatt Haig",
            blocks: []
        )

        let candidates = extractor.extract(from: result)

        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(candidates.first?.title, "The Midnight Library")
        XCTAssertEqual(candidates.first?.author, "Matt Haig")
        XCTAssertEqual(candidates.first?.evidence, .adjacentLines)
    }
}
