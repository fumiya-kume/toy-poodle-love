import Foundation
import Testing
@testable import VideoOverlayViewer

struct AIModelTests {
    // MARK: - Raw Value Tests

    @Test func gemini_hasCorrectRawValue() {
        #expect(AIModel.gemini.rawValue == "gemini")
    }

    @Test func qwen_hasCorrectRawValue() {
        #expect(AIModel.qwen.rawValue == "qwen")
    }

    // MARK: - Display Name Tests

    @Test func gemini_hasCorrectDisplayName() {
        #expect(AIModel.gemini.displayName == "Gemini")
    }

    @Test func qwen_hasCorrectDisplayName() {
        #expect(AIModel.qwen.displayName == "Qwen")
    }

    // MARK: - Identifiable Tests

    @Test func gemini_idMatchesRawValue() {
        #expect(AIModel.gemini.id == "gemini")
    }

    @Test func qwen_idMatchesRawValue() {
        #expect(AIModel.qwen.id == "qwen")
    }

    // MARK: - CaseIterable Tests

    @Test func allCases_containsAllModels() {
        #expect(AIModel.allCases.count == 2)
        #expect(AIModel.allCases.contains(.gemini))
        #expect(AIModel.allCases.contains(.qwen))
    }

    // MARK: - Codable Tests

    @Test func encode_gemini_producesCorrectJSON() throws {
        let data = try JSONEncoder().encode(AIModel.gemini)
        let string = String(data: data, encoding: .utf8)
        #expect(string == "\"gemini\"")
    }

    @Test func encode_qwen_producesCorrectJSON() throws {
        let data = try JSONEncoder().encode(AIModel.qwen)
        let string = String(data: data, encoding: .utf8)
        #expect(string == "\"qwen\"")
    }

    @Test func decode_gemini_fromJSON() throws {
        let json = "\"gemini\""
        let data = json.data(using: .utf8)!
        let model = try JSONDecoder().decode(AIModel.self, from: data)
        #expect(model == .gemini)
    }

    @Test func decode_qwen_fromJSON() throws {
        let json = "\"qwen\""
        let data = json.data(using: .utf8)!
        let model = try JSONDecoder().decode(AIModel.self, from: data)
        #expect(model == .qwen)
    }
}
