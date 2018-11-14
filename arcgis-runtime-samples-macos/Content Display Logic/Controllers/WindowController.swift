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

extension NSApplication {
    // MARK: - Progres indicator
    
    func showProgressIndicator() {
        let controller = windows.compactMap { $0.windowController as? WindowController }.first
        controller?.showProgressIndicator()
    }
    
    func hideProgressIndicator() {
        let controller = windows.compactMap { $0.windowController as? WindowController }.first
        controller?.hideProgressIndicator()
    }
}

class WindowController: NSWindowController {
    
    private var searchEngine: SampleSearchEngine?
    
    @IBOutlet private var progressIndicator: NSProgressIndicator!
    
    func loadSearchEngine(samples: [Sample]) {
        searchEngine = SampleSearchEngine(samples: samples)
    }
    
    // MARK: - Progress indicator
    
    func showProgressIndicator() {
        progressIndicator.startAnimation(nil)
    }

    func hideProgressIndicator() {
        progressIndicator.stopAnimation(nil)
    }
    
}

extension WindowController: NSSearchFieldDelegate {
    
    func controlTextDidBeginEditing(_ obj: Notification) {
        if let mainViewController = contentViewController as? MainViewController {
            // Remove the selection in the outline since it doesn't correspond to the search results
            mainViewController.sampleListViewController.deselectAllOutlineViewCells()
        }
    }
    
    func controlTextDidChange(_ notification: Notification) {
        guard let searchEngine = searchEngine,
            let searchField = notification.object as? NSSearchField,
            let mainViewController = contentViewController as? MainViewController else {
            return
        }
            
        let query = searchField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            let matchingSamples = searchEngine.sortedSamples(matching: query)
            let searchResultsCategory = Category(name: "Results for \"\(query)\"", samples: matchingSamples)
            mainViewController.showCategory(searchResultsCategory)
        } else {
            mainViewController.showCategoryForAllSamples()
        }
    }
    
}
