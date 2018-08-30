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

protocol VectorStylesVCDelegate: AnyObject {
    
    func vectorStylesViewController(_ vectorStylesViewController: VectorStylesViewController, didSelectItemWithID itemID:String)
    
    func vectorStylesViewControllerDidCancel(_ vectorStylesViewController: VectorStylesViewController)
}

class VectorStylesViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet var tableView:NSTableView!
    
    var itemIDs = ["1349bfa0ed08485d8a92c442a3850b06", "bd8ac41667014d98b933e97713ba8377", "02f85ec376084c508b9c8e5a311724fa", "1bf0cc4a4380468fbbff107e100f65a5"]
    
    weak var delegate: VectorStylesVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.preferredContentSize = CGSize(width: 300, height: 260)
    }
    
    //MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "VectorStyleCell\(row)"), owner: self)
        
        return cellView
    }
    
    //MARK: - NSTableViewDelegate
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = self.tableView.selectedRow
        
        let itemID = self.itemIDs[row]
        
        self.delegate?.vectorStylesViewController(self, didSelectItemWithID: itemID)
    }
    
    //MARK: - Actions
    
    @IBAction func cancelAction(_ sender: NSButton) {
        
        //Notify the delegate that user tried to dismiss the view controller
        self.delegate?.vectorStylesViewControllerDidCancel(self)
    }
}
