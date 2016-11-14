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

protocol SuggestionsVCDelegate: class {
    
    func suggestionsViewController(suggestionsViewController: SuggestionsViewController, didSelectSuggestion suggestion: String)
}

class SuggestionsViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet var tableView:NSTableView!
    
    weak var delegate: SuggestionsVCDelegate?
    
    var suggestions: [String]! {
        didSet {
            self.tableView?.deselectAll(nil)
            self.tableView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    
    }
    
    //MARK: - NSTableViewDataSource
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.suggestions?.count ?? 0
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return self.suggestions[row]
    }

    //MARK: - NSTableViewDelegate
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        let selectedRow = self.tableView.selectedRow
        if selectedRow >= 0 {
            let suggestion = self.suggestions[selectedRow]
            self.delegate?.suggestionsViewController(self, didSelectSuggestion: suggestion)
        }
    }
}
