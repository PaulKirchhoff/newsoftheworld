//
//  newsoftheworldUITests.swift
//  newsoftheworldUITests
//
//  Created by Paul Kirchhoff on 17.04.26.
//

import XCTest

final class newsoftheworldUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testAppLaunches() throws {
        // News of the World ist eine LSUIElement-Menüleisten-App — sie läuft nach dem
        // Start erwartungsgemäß im Hintergrund (kein Dock-Icon, kein Hauptfenster).
        let app = XCUIApplication()
        app.launch()
        XCTAssertEqual(app.state, .runningBackground)
    }
}
