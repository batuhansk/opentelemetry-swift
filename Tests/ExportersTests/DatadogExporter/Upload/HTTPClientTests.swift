/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

@testable import DatadogExporter
import XCTest

class HTTPClientTests: XCTestCase {
  func testWhenRequestIsDelivered_itReturnsHTTPResponse() {
    let server = ServerMock(delivery: .success(response: .mockResponseWith(statusCode: 200)))
    let expectation = expectation(description: "receive response")
    let client = HTTPClient(session: server.getInterceptedURLSession())

    client.send(request: .mockAny()) { result in
      switch result {
      case let .success(httpResponse):
        XCTAssertEqual(httpResponse.statusCode, 200)
        expectation.fulfill()
      case .failure:
        break
      }
    }

    waitForExpectations(timeout: 1, handler: nil)
    server.waitFor(requestsCompletion: 1)
  }

  func testWhenRequestIsNotDelivered_itReturnsHTTPRequestDeliveryError() throws {
    #if os(watchOS)
      throw XCTSkip("Implementation needs to be updated for watchOS to make this test pass")
    #endif

    let mockError = NSError(domain: "network", code: 999, userInfo: [NSLocalizedDescriptionKey: "no internet connection"])
    let server = ServerMock(delivery: .failure(error: mockError))
    let expectation = expectation(description: "receive response")
    let client = HTTPClient(session: server.getInterceptedURLSession())

    client.send(request: .mockAny()) { result in
      switch result {
      case .success:
        break
      case let .failure(error):
        XCTAssertEqual((error as NSError).localizedDescription, "no internet connection")
        expectation.fulfill()
      }
    }

    waitForExpectations(timeout: 1, handler: nil)
    server.waitFor(requestsCompletion: 1)
  }
}
