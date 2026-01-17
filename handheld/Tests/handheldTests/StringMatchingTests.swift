import XCTest
@testable import handheld

final class StringMatchingTests: XCTestCase {

    // MARK: - Levenshtein Distance Tests

    func testLevenshteinDistance_sameStrings() {
        XCTAssertEqual(StringMatching.levenshteinDistance("hello", "hello"), 0)
        XCTAssertEqual(StringMatching.levenshteinDistance("渋谷", "渋谷"), 0)
    }

    func testLevenshteinDistance_emptyStrings() {
        XCTAssertEqual(StringMatching.levenshteinDistance("", ""), 0)
        XCTAssertEqual(StringMatching.levenshteinDistance("hello", ""), 5)
        XCTAssertEqual(StringMatching.levenshteinDistance("", "hello"), 5)
    }

    func testLevenshteinDistance_singleCharacterDifference() {
        XCTAssertEqual(StringMatching.levenshteinDistance("cat", "bat"), 1)
        XCTAssertEqual(StringMatching.levenshteinDistance("渋谷", "渋谷駅"), 1)
    }

    func testLevenshteinDistance_knownValues() {
        XCTAssertEqual(StringMatching.levenshteinDistance("kitten", "sitting"), 3)
        XCTAssertEqual(StringMatching.levenshteinDistance("saturday", "sunday"), 3)
    }

    func testLevenshteinDistance_caseInsensitive() {
        XCTAssertEqual(StringMatching.levenshteinDistance("Hello", "hello"), 0)
        XCTAssertEqual(StringMatching.levenshteinDistance("TOKYO", "tokyo"), 0)
    }

    // MARK: - Similarity Score Tests

    func testSimilarityScore_identicalStrings() {
        XCTAssertEqual(StringMatching.similarityScore("hello", "hello"), 1.0)
        XCTAssertEqual(StringMatching.similarityScore("渋谷駅", "渋谷駅"), 1.0)
    }

    func testSimilarityScore_emptyStrings() {
        XCTAssertEqual(StringMatching.similarityScore("", ""), 1.0)
    }

    func testSimilarityScore_completelyDifferent() {
        let score = StringMatching.similarityScore("abc", "xyz")
        XCTAssertEqual(score, 0.0)
    }

    func testSimilarityScore_partialMatch() {
        let score = StringMatching.similarityScore("渋谷駅", "渋谷")
        XCTAssertGreaterThan(score, 0.6)
        XCTAssertLessThan(score, 1.0)
    }

    func testSimilarityScore_similarStrings() {
        let score = StringMatching.similarityScore("Tokyo Tower", "Tokyo Towers")
        XCTAssertGreaterThan(score, 0.8)
    }

    // MARK: - Normalize Tests

    func testNormalize_removesSpaces() {
        XCTAssertEqual(StringMatching.normalize("hello world"), "helloworld")
        XCTAssertEqual(StringMatching.normalize("渋谷 駅"), "渋谷駅")
    }

    func testNormalize_removesSymbols() {
        XCTAssertEqual(StringMatching.normalize("hello-world"), "helloworld")
        XCTAssertEqual(StringMatching.normalize("hello_world"), "helloworld")
        XCTAssertEqual(StringMatching.normalize("hello.world"), "helloworld")
    }

    func testNormalize_removesJapaneseParentheses() {
        XCTAssertEqual(StringMatching.normalize("渋谷（駅）"), "渋谷駅")
        XCTAssertEqual(StringMatching.normalize("渋谷「駅」"), "渋谷駅")
        XCTAssertEqual(StringMatching.normalize("渋谷『駅』"), "渋谷駅")
        XCTAssertEqual(StringMatching.normalize("渋谷【駅】"), "渋谷駅")
    }

    func testNormalize_removesEnglishParentheses() {
        XCTAssertEqual(StringMatching.normalize("Shibuya (Station)"), "shibuyastation")
        XCTAssertEqual(StringMatching.normalize("Shibuya [Station]"), "shibuyastation")
    }

    func testNormalize_lowercases() {
        XCTAssertEqual(StringMatching.normalize("HELLO"), "hello")
        XCTAssertEqual(StringMatching.normalize("Tokyo Tower"), "tokyotower")
    }

    // MARK: - Fuzzy Match Tests

    func testFuzzyMatch_identicalStrings() {
        XCTAssertTrue(StringMatching.fuzzyMatch("渋谷駅", "渋谷駅"))
    }

    func testFuzzyMatch_similarStrings() {
        XCTAssertTrue(StringMatching.fuzzyMatch("渋谷駅", "渋谷 駅"))
        XCTAssertTrue(StringMatching.fuzzyMatch("Tokyo Tower", "tokyo-tower"))
    }

    func testFuzzyMatch_completelyDifferent() {
        XCTAssertFalse(StringMatching.fuzzyMatch("abc", "xyz"))
    }

    func testFuzzyMatch_customThreshold() {
        // With a high threshold, similar but not identical strings should not match
        XCTAssertFalse(StringMatching.fuzzyMatch("hello", "hallo", threshold: 0.9))
        // With a lower threshold, they should match
        XCTAssertTrue(StringMatching.fuzzyMatch("hello", "hallo", threshold: 0.6))
    }

    // MARK: - Real World Test Cases

    func testRealWorld_japaneseStationNames() {
        // 駅名のバリエーション
        let score = StringMatching.similarityScore(
            StringMatching.normalize("渋谷駅"),
            StringMatching.normalize("渋谷")
        )
        XCTAssertGreaterThan(score, 0.6)
    }

    func testRealWorld_touristSpots() {
        // 観光地名のバリエーション
        XCTAssertTrue(StringMatching.fuzzyMatch("東京スカイツリー", "東京 スカイツリー"))
        XCTAssertTrue(StringMatching.fuzzyMatch("浅草寺", "浅草寺（雷門）", threshold: 0.5))
    }
}
