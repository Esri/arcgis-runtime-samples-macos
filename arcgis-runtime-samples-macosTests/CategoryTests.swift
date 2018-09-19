//
// Copyright © 2018 Esri.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest
@testable import arcgis_runtime_samples_macos

class CategoryTests: XCTestCase {
    func testInitFromDecoder() {
        let sampleData = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>displayName</key>
                <string>Maps</string>
                <key>children</key>
                <array>
                    <dict>
                        <key>displayName</key>
                        <string>Display a map</string>
                        <key>storyboardName</key>
                        <string>DisplayMap</string>
                        <key>descriptionText</key>
                        <string>This sample shows you how to display a map with imagery basemap</string>
                    </dict>
                    <dict>
                        <key>displayName</key>
                        <string>Change map view background</string>
                        <key>storyboardName</key>
                        <string>ChangeMapViewBackground</string>
                        <key>descriptionText</key>
                        <string>This sample shows you how to customize map view's background grid</string>
                    </dict>
                </array>
            </dict>
            </plist>
        """.data(using: .utf8)!
        let expectedCategory = arcgis_runtime_samples_macos.Category(
            name: "Maps",
            samples: [
                Sample(
                    name: "Display a map",
                    description: "This sample shows you how to display a map with imagery basemap",
                    storyboardName: "DisplayMap",
                    sourceFilenames: []
                ),
                Sample(
                    name: "Change map view background",
                    description: "This sample shows you how to customize map view's background grid",
                    storyboardName: "ChangeMapViewBackground",
                    sourceFilenames: []
                )
            ]
        )
        XCTAssertEqual(try PropertyListDecoder().decode(arcgis_runtime_samples_macos.Category.self, from: sampleData), expectedCategory)
    }
}
