//
// Copyright 2016 Esri.
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

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject {
    var mainWindowController: WindowController {
        return NSApplication.shared.windows.first!.windowController as! WindowController
    }
    var mainViewController: MainViewController {
        return mainWindowController.contentViewController as! MainViewController
    }
    
    /// The URL of the content plist file inside the bundle.
    private var contentPlistURL: URL {
        return Bundle.main.url(forResource: "ContentPList", withExtension: "plist")!
    }
    
    /// Decodes an array of categories from the plist at the given URL.
    ///
    /// - Parameter url: The url of a plist that defines categories.
    /// - Returns: An array of categories.
    private func decodeCategories(at url: URL) -> [Category] {
        do {
            let data = try Data(contentsOf: url)
            return try PropertyListDecoder().decode([Category].self, from: data)
        } catch {
            fatalError("Error decoding categories at \(url): \(error)")
        }
    }
}

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Decode and populate Categories.
        let categories = decodeCategories(at: contentPlistURL)
        mainViewController.categories = categories
        let allSamples = categories.flatMap({ $0.samples })
        mainWindowController.loadSearchEngine(samples: allSamples)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

extension NSColor {
    class var primaryBlue: NSColor { return #colorLiteral(red: 0, green: 0.475, blue: 0.757, alpha: 1) }
    class var secondaryBlue: NSColor { return #colorLiteral(red: 0, green: 0.368, blue: 0.584, alpha: 1) }
    class var backgroundGray: NSColor { return #colorLiteral(red: 0.973, green: 0.973, blue: 0.973, alpha: 1) }
}
