import Foundation
import Testing
@testable import Core

struct ConfigManagerTests {
    @Test
    func apiBaseURLRejectsMissingOrInvalidValues() {
        #expect(ConfigManager.apiBaseURL(from: nil) == nil)
        #expect(ConfigManager.apiBaseURL(from: "") == nil)
        #expect(ConfigManager.apiBaseURL(from: "   ") == nil)
        #expect(ConfigManager.apiBaseURL(from: "not a url") == nil)
        #expect(ConfigManager.apiBaseURL(from: 123) == nil)
    }

    @Test
    func apiBaseURLAcceptsHTTPURLsWithHost() throws {
        let url = try #require(ConfigManager.apiBaseURL(from: "https://api.example.com"))

        #expect(url.scheme == "https")
        #expect(url.host == "api.example.com")
    }
}
