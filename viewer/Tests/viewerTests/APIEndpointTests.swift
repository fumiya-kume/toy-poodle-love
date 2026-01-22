import XCTest
@testable import VideoOverlayViewer

final class APIEndpointTests: XCTestCase {

    private let expectedBaseURL = "https://toy-poodle-lover.vercel.app"

    // MARK: - AI生成エンドポイント

    func testQwen_path_returnsCorrectPath() {
        XCTAssertEqual(APIEndpoint.qwen.path, "/api/qwen")
    }

    func testQwen_url_returnsFullURL() {
        XCTAssertEqual(APIEndpoint.qwen.url?.absoluteString, "\(expectedBaseURL)/api/qwen")
    }

    func testQwen_method_returnsPOST() {
        XCTAssertEqual(APIEndpoint.qwen.method, "POST")
    }

    func testGemini_path_returnsCorrectPath() {
        XCTAssertEqual(APIEndpoint.gemini.path, "/api/gemini")
    }

    func testGemini_url_returnsFullURL() {
        XCTAssertEqual(APIEndpoint.gemini.url?.absoluteString, "\(expectedBaseURL)/api/gemini")
    }

    func testGemini_method_returnsPOST() {
        XCTAssertEqual(APIEndpoint.gemini.method, "POST")
    }

    // MARK: - Places エンドポイント

    func testGeocode_path_returnsCorrectPath() {
        XCTAssertEqual(APIEndpoint.geocode.path, "/api/places/geocode")
    }

    func testGeocode_url_returnsFullURL() {
        XCTAssertEqual(APIEndpoint.geocode.url?.absoluteString, "\(expectedBaseURL)/api/places/geocode")
    }

    func testGeocode_method_returnsPOST() {
        XCTAssertEqual(APIEndpoint.geocode.method, "POST")
    }

    // MARK: - Routes エンドポイント

    func testRouteOptimize_path_returnsCorrectPath() {
        XCTAssertEqual(APIEndpoint.routeOptimize.path, "/api/routes/optimize")
    }

    func testRouteOptimize_url_returnsFullURL() {
        XCTAssertEqual(APIEndpoint.routeOptimize.url?.absoluteString, "\(expectedBaseURL)/api/routes/optimize")
    }

    func testRouteOptimize_method_returnsPOST() {
        XCTAssertEqual(APIEndpoint.routeOptimize.method, "POST")
    }

    // MARK: - Pipeline エンドポイント

    func testPipelineRouteOptimize_path_returnsCorrectPath() {
        XCTAssertEqual(APIEndpoint.pipelineRouteOptimize.path, "/api/pipeline/route-optimize")
    }

    func testPipelineRouteOptimize_url_returnsFullURL() {
        XCTAssertEqual(APIEndpoint.pipelineRouteOptimize.url?.absoluteString, "\(expectedBaseURL)/api/pipeline/route-optimize")
    }

    func testPipelineRouteOptimize_method_returnsPOST() {
        XCTAssertEqual(APIEndpoint.pipelineRouteOptimize.method, "POST")
    }

    // MARK: - Scenario エンドポイント

    func testRouteGenerate_path_returnsCorrectPath() {
        XCTAssertEqual(APIEndpoint.routeGenerate.path, "/api/route/generate")
    }

    func testRouteGenerate_url_returnsFullURL() {
        XCTAssertEqual(APIEndpoint.routeGenerate.url?.absoluteString, "\(expectedBaseURL)/api/route/generate")
    }

    func testRouteGenerate_method_returnsPOST() {
        XCTAssertEqual(APIEndpoint.routeGenerate.method, "POST")
    }

    func testScenario_path_returnsCorrectPath() {
        XCTAssertEqual(APIEndpoint.scenario.path, "/api/scenario")
    }

    func testScenario_url_returnsFullURL() {
        XCTAssertEqual(APIEndpoint.scenario.url?.absoluteString, "\(expectedBaseURL)/api/scenario")
    }

    func testScenario_method_returnsPOST() {
        XCTAssertEqual(APIEndpoint.scenario.method, "POST")
    }

    func testScenarioSpot_path_returnsCorrectPath() {
        XCTAssertEqual(APIEndpoint.scenarioSpot.path, "/api/scenario/spot")
    }

    func testScenarioSpot_url_returnsFullURL() {
        XCTAssertEqual(APIEndpoint.scenarioSpot.url?.absoluteString, "\(expectedBaseURL)/api/scenario/spot")
    }

    func testScenarioSpot_method_returnsPOST() {
        XCTAssertEqual(APIEndpoint.scenarioSpot.method, "POST")
    }

    func testScenarioIntegrate_path_returnsCorrectPath() {
        XCTAssertEqual(APIEndpoint.scenarioIntegrate.path, "/api/scenario/integrate")
    }

    func testScenarioIntegrate_url_returnsFullURL() {
        XCTAssertEqual(APIEndpoint.scenarioIntegrate.url?.absoluteString, "\(expectedBaseURL)/api/scenario/integrate")
    }

    func testScenarioIntegrate_method_returnsPOST() {
        XCTAssertEqual(APIEndpoint.scenarioIntegrate.method, "POST")
    }

    // MARK: - URL Validity

    func testAllEndpoints_url_isNotNil() {
        let allEndpoints: [APIEndpoint] = [
            .qwen,
            .gemini,
            .geocode,
            .routeOptimize,
            .pipelineRouteOptimize,
            .routeGenerate,
            .scenario,
            .scenarioSpot,
            .scenarioIntegrate,
        ]

        for endpoint in allEndpoints {
            XCTAssertNotNil(endpoint.url, "Endpoint \(endpoint) should have a valid URL")
        }
    }

    func testAllEndpoints_url_usesHTTPS() {
        let allEndpoints: [APIEndpoint] = [
            .qwen,
            .gemini,
            .geocode,
            .routeOptimize,
            .pipelineRouteOptimize,
            .routeGenerate,
            .scenario,
            .scenarioSpot,
            .scenarioIntegrate,
        ]

        for endpoint in allEndpoints {
            XCTAssertTrue(endpoint.url?.scheme == "https", "Endpoint \(endpoint) should use HTTPS")
        }
    }

    func testAllEndpoints_method_isPOST() {
        let allEndpoints: [APIEndpoint] = [
            .qwen,
            .gemini,
            .geocode,
            .routeOptimize,
            .pipelineRouteOptimize,
            .routeGenerate,
            .scenario,
            .scenarioSpot,
            .scenarioIntegrate,
        ]

        for endpoint in allEndpoints {
            XCTAssertEqual(endpoint.method, "POST", "Endpoint \(endpoint) should use POST method")
        }
    }
}
