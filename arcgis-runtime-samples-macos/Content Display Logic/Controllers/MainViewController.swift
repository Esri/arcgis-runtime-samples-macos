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

extension NSView {
    
    @IBInspectable
    var backgroundColor: NSColor? {
        get {
            if let colorRef = self.layer?.backgroundColor {
                return NSColor(cgColor: colorRef)
            } else {
                return nil
            }
        }
        set {
            self.wantsLayer = true
            self.layer?.backgroundColor = newValue?.cgColor
        }
    }
}

class MainViewController: NSSplitViewController {
    let nodes: [Node]
    
    required init?(coder: NSCoder) {
        let path = Bundle.main.path(forResource: "ContentPList", ofType: "plist")
        let content = NSArray(contentsOfFile: path!)
        nodes = (content as! [[String: Any]]).map { Node(dictionary: $0) }
        
        super.init(coder: coder)
    }
    
    @IBOutlet weak var sampleListSplitViewItem: NSSplitViewItem!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let sampleListViewController = sampleListSplitViewItem.viewController as! SampleListViewController
        sampleListViewController.delegate = self
        sampleListViewController.nodes = nodes
    }
    
    func show(_ node: Node) {
        let oldSplitViewItem = splitViewItems.last!
        let newSplitViewItem: NSSplitViewItem
        if node.childNodes.isEmpty && !node.storyboardName.isEmpty {
            let sampleViewController = SampleViewController(sample: node)
            newSplitViewItem = NSSplitViewItem(viewController: sampleViewController)
        } else {
            let sampleCollectionViewController = SampleCollectionViewController(samples: node.childNodes)
            sampleCollectionViewController.delegate = self
            newSplitViewItem = NSSplitViewItem(viewController: sampleCollectionViewController)
        }
        removeSplitViewItem(oldSplitViewItem)
        addSplitViewItem(newSplitViewItem)
    }
    
    func searchSamples(for string: String) {
        let node = Node()
        node.childNodes = {
            if let searchResults = SearchEngine.sharedInstance().searchForString(string) {
                return nodesByDisplayNames(searchResults)
            } else {
                return []
            }
        }()
        show(node)
    }
    
    func nodesByDisplayNames(_ names: [String]) -> [Node] {
        var nodes = [Node]()
        // Drop the Featured node to avoid redundancy.
        for node in self.nodes.dropFirst() {
            let matchingNodes = node.childNodes.filter { return names.contains($0.displayName) }
            nodes.append(contentsOf: matchingNodes)
        }
        return nodes
    }
}

extension MainViewController: SampleListViewControllerDelegate {
    func sampleListViewController(_ controller: SampleListViewController, didSelect node: Node) {
        show(node)
    }
}

extension MainViewController: SampleCollectionViewControllerDelegate {
    func sampleCollectionViewController(_ controller: SampleCollectionViewController, didSelect sample: Node) {
        let sampleListViewController = sampleListSplitViewItem.viewController as! SampleListViewController
        sampleListViewController.select(sample)
    }
}

extension Node {
    convenience init(dictionary: [String: Any]) {
        self.init()
        if let displayName = dictionary["displayName"] as? String {
            self.displayName = displayName
        }
        if let descriptionText = dictionary["descriptionText"] as? String {
            self.descriptionText = descriptionText
        }
        if let storyboardName = dictionary["storyboardName"] as? String {
            self.storyboardName = storyboardName
        }
        if let children = dictionary["children"] as? [[String: Any]] {
            childNodes = children.map { Node(dictionary: $0) }
        }
        if let sourceFileNames = dictionary["sourceFileNames"] as? [String] {
            self.sourceFileNames = sourceFileNames
        }
    }
}
