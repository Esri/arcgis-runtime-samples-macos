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

import AppKit

protocol SampleListViewControllerDelegate: class {
    func sampleListViewController(_ controller: SampleListViewController, didSelect node: Node)
}

class SampleListViewController: NSViewController {
    var nodes = [Node]() {
        didSet {
            guard isViewLoaded else { return }
            outlineView.reloadData()
            select(nodes.first!)
        }
    }
    weak var delegate: SampleListViewControllerDelegate?
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    func select(_ node: Node) {
        // Expand the parent (if there is one).
        if let parentNode = parent(for: node) {
            outlineView.expandItem(parentNode)
        }
        // Select the new item.
        let index = outlineView.row(forItem: node)
        outlineView.selectRowIndexes([index], byExtendingSelection: false)
    }
    
    /// Returns the parent of a given node.
    ///
    /// - Parameter node: The node whose parent should be found.
    /// - Returns: The node's parent or `nil` if the node does not have a parent.
    func parent(for node: Node) -> Node? {
        let selectedRow = outlineView.selectedRow
        if selectedRow != -1, let selectedNode = outlineView.item(atRow: selectedRow) as? Node, selectedNode.childNodes.contains(node) {
            return selectedNode
        } else {
            // This is a major hack. If the parent node is not the selected
            // node, assume that the node was a selected search result. In that
            // case, we want to skip the "Featured" category and return the
            // sample's actual category.
            return nodes.dropFirst().first(where: { $0.childNodes.contains(node) })
        }
    }
}

extension SampleListViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let node = item as? Node {
            return node.childNodes.count
        } else {
            return nodes.count
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        let node = item as! Node
        return !node.childNodes.isEmpty
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? Node {
            return node.childNodes[index]
        } else {
            return nodes[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return (item as! Node).displayName
    }
}

extension SampleListViewController: NSOutlineViewDelegate {
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let node = self.outlineView.item(atRow: outlineView.selectedRow) as? Node else { return }
        delegate?.sampleListViewController(self, didSelect: node)
    }
}
