import Foundation
import Testing
@testable import VideoOverlayViewer

struct APIEndpointTests {
    // MARK: - Path Tests

    @Test func qwen_hasCorrectPath() {
        #expect(APIEndpoint.qwen.path == "/api/qwen")
    }

    @Test func gemini_hasCorrectPath() {
        #expect(APIEndpoint.gemini.path == "/api/gemini")
    }

    @Test func geocode_hasCorrectPath() {
        #expect(APIEndpoint.geocode.path == "/api/places/geocode")
    }

    @Test func routeOptimize_hasCorrectPath() {
        #expect(APIEndpoint.routeOptimize.path == "/api/routes/optimize")
    }

    @Test func pipelineRouteOptimize_hasCorrectPath() {
        #expect(APIEndpoint.pipelineRouteOptimize.path == "/api/pipeline/route-optimize")
    }

    @Test func routeGenerate_hasCorrectPath() {
        #expect(APIEndpoint.routeGenerate.path == "/api/route/generate")
    }

    @Test func scenario_hasCorrectPath() {
        #expect(APIEndpoint.scenario.path == "/api/scenario")
    }

    @Test func scenarioSpot_hasCorrectPath() {
        #expect(APIEndpoint.scenarioSpot.path == "/api/scenario/spot")
    }

    @Test func scenarioIntegrate_hasCorrectPath() {
        #expect(APIEndpoint.scenarioIntegrate.path == "/api/scenario/integrate")
    }

    // MARK: - URL Tests

    @Test func qwen_hasValidURL() {
        #expect(APIEndpoint.qwen.url != nil)
        #expect(APIEndpoint.qwen.url?.absoluteString.contains("/api/qwen") == true)
    }

    @Test func gemini_hasValidURL() {
        #expect(APIEndpoint.gemini.url != nil)
        #expect(APIEndpoint.gemini.url?.absoluteString.contains("/api/gemini") == true)
    }

    @Test func geocode_hasValidURL() {
        #expect(APIEndpoint.geocode.url != nil)
        #expect(APIEndpoint.geocode.url?.absoluteString.contains("/api/places/geocode") == true)
    }

    @Test func routeOptimize_hasValidURL() {
        #expect(APIEndpoint.routeOptimize.url != nil)
    }

    @Test func pipelineRouteOptimize_hasValidURL() {
        #expect(APIEndpoint.pipelineRouteOptimize.url != nil)
    }

    @Test func routeGenerate_hasValidURL() {
        #expect(APIEndpoint.routeGenerate.url != nil)
    }

    @Test func scenario_hasValidURL() {
        #expect(APIEndpoint.scenario.url != nil)
    }

    @Test func scenarioSpot_hasValidURL() {
        #expect(APIEndpoint.scenarioSpot.url != nil)
    }

    @Test func scenarioIntegrate_hasValidURL() {
        #expect(APIEndpoint.scenarioIntegrate.url != nil)
    }

    // MARK: - Method Tests

    @Test func qwen_usesPOST() {
        #expect(APIEndpoint.qwen.method == "POST")
    }

    @Test func gemini_usesPOST() {
        #expect(APIEndpoint.gemini.method == "POST")
    }

    @Test func geocode_usesPOST() {
        #expect(APIEndpoint.geocode.method == "POST")
    }

    @Test func routeOptimize_usesPOST() {
        #expect(APIEndpoint.routeOptimize.method == "POST")
    }

    @Test func pipelineRouteOptimize_usesPOST() {
        #expect(APIEndpoint.pipelineRouteOptimize.method == "POST")
    }

    @Test func routeGenerate_usesPOST() {
        #expect(APIEndpoint.routeGenerate.method == "POST")
    }

    @Test func scenario_usesPOST() {
        #expect(APIEndpoint.scenario.method == "POST")
    }

    @Test func scenarioSpot_usesPOST() {
        #expect(APIEndpoint.scenarioSpot.method == "POST")
    }

    @Test func scenarioIntegrate_usesPOST() {
        #expect(APIEndpoint.scenarioIntegrate.method == "POST")
    }

    // MARK: - URL Base Tests

    @Test func allEndpoints_useHTTPS() {
        let endpoints: [APIEndpoint] = [
            .qwen, .gemini, .geocode, .routeOptimize,
            .pipelineRouteOptimize, .routeGenerate,
            .scenario, .scenarioSpot, .scenarioIntegrate
        ]

        for endpoint in endpoints {
            #expect(endpoint.url?.scheme == "https")
        }
    }
}
