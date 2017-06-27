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
import ArcGIS

enum ToggleState: String {
    case On = "On"
    case Off = "Off"
}

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

class MainViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, CollectionViewControllerDelegate {

    @IBOutlet private var outlineView:NSOutlineView!
    @IBOutlet private var placeholderView:NSView!
    @IBOutlet private var liveSampleSegmentedControl: NSSegmentedControl!
    @IBOutlet private var heightConstraint: NSLayoutConstraint!
    @IBOutlet private var headerView: NSView!
    
    private var nodesArray:[Node]!
    private var expandedNodeIndex:Int!
    private var sampleViewController:NSViewController!
    private var sourceCodeViewController: SourceCodeViewController!
    private var readmeViewController:ReadmeViewController!
    private var collectionViewController: CollectionViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //hide header view initially
        self.heightConstraint.constant = 0
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.populateTree()
    }
    /*
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }*/
    
    func populateTree() {
        
        let path = Bundle.main.path(forResource: "ContentPList", ofType: "plist")
        let content = NSArray(contentsOfFile: path!)
        self.nodesArray = self.populateNodesArray(content! as [AnyObject])
        self.outlineView.reloadData()
        
        //select first (Featured) node
        self.outlineView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
    }
    
    func populateNodesArray(_ array:[AnyObject]) -> [Node] {
        var nodesArray = [Node]()
        for object in array {
            let node = self.populateNode(object as! [String:AnyObject])
            nodesArray.append(node)
        }
        return nodesArray
    }
    
    func populateNode(_ dict:[String:AnyObject]) -> Node {
        let node = Node()
        if let displayName = dict["displayName"] as? String {
            node.displayName = displayName
        }
        if let descriptionText = dict["descriptionText"] as? String {
            node.descriptionText = descriptionText
        }
        if let storyboardName = dict["storyboardName"] as? String {
            node.storyboardName = storyboardName
        }
        if let children = dict["children"] as? [AnyObject] {
            node.childNodes = self.populateNodesArray(children)
        }
        if let sourceFileNames = dict["sourceFileNames"] as? [String] {
            node.sourceFileNames = sourceFileNames
        }
        return node
    }
    
    func clearPlaceholderView() {
        if self.sampleViewController != nil {
            self.sampleViewController.view.removeFromSuperview()
            self.sampleViewController = nil
        }
        
        if self.sourceCodeViewController != nil {
            self.sourceCodeViewController.view.removeFromSuperview()
            self.sourceCodeViewController = nil
        }
        
        if self.readmeViewController != nil {
            self.readmeViewController.view.removeFromSuperview()
            self.readmeViewController = nil
        }
        
        if self.collectionViewController != nil {
            self.collectionViewController.view.removeFromSuperview()
        }
    }
    
    func displaySampleForNode(_ node: Node) {
        self.clearPlaceholderView()
        
        if node.storyboardName != nil {
            //reset segmented control
            self.liveSampleSegmentedControl.selectedSegment = 0
            
            //enable segmented view control
            self.toggleSegmentedControl(.On)
            
            //add the readme controller view
            self.readmeViewController = self.storyboard!.instantiateController(withIdentifier: "ReadmeViewController") as! ReadmeViewController
            self.readmeViewController.view.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
            self.readmeViewController.view.frame = self.placeholderView.bounds
            self.readmeViewController.view.isHidden = true
            self.readmeViewController.folderName = node.displayName
            self.placeholderView.addSubview(self.readmeViewController.view)
            
            //add source code view controller
            self.sourceCodeViewController = self.storyboard!.instantiateController(withIdentifier: "SourceCodeViewController") as! SourceCodeViewController
            self.sourceCodeViewController.view.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
            self.sourceCodeViewController.view.frame = self.placeholderView.bounds
            self.sourceCodeViewController.view.isHidden = true
            self.sourceCodeViewController.fileNames = node.sourceFileNames
            self.placeholderView.addSubview(self.sourceCodeViewController.view)
            
            //get the intial controller from the storyboard of the sample
            let sampleStoryboard = NSStoryboard(name: node.storyboardName, bundle: nil)
            self.sampleViewController = sampleStoryboard.instantiateInitialController() as! NSViewController
            
            //set the view's frame and autoresizing mask
            self.sampleViewController.view.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
            self.sampleViewController.view.frame = self.placeholderView.bounds
            
            //add the view to the placeholder view as subview
            self.placeholderView.addSubview(self.sampleViewController.view)
        }
        else {
            //disable segmented control
            self.toggleSegmentedControl(.Off)
            
            //show collection view
            self.showCollectionView(node.childNodes)
        }
    }

    //MARK: - NSOutlineViewDataSource
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return item != nil ? (item as! Node).childNodes.count : ( self.nodesArray?.count ?? 0 )
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let _ = (item as! Node).childNodes {
            return true
        }
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? Node {
            return item.childNodes[index]
        }
        else {
            return self.nodesArray[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return (item as! Node).displayName
    }

    //MARK: - NSOutlineViewDelegate
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        
        //hide progress indicator
        self.view.window?.hideProgressIndicator()
        
        let row = self.outlineView.selectedRow
        if let node = self.outlineView.item(atRow: row) as? Node {
            //display the sample on the right hand side placeholder view
            self.displaySampleForNode(node)
        }
    }
    
    func outlineViewItemDidExpand(_ notification: Notification) {
        //collapse if a node already expanded
        if self.expandedNodeIndex != nil {
            self.outlineView.collapseItem(self.nodesArray[self.expandedNodeIndex])
        }
        if let node = (notification as NSNotification).userInfo?["NSObject"] as? Node {
            
            self.expandedNodeIndex = self.nodesArray.index(of: node)
        }
    }
    
    func outlineViewItemDidCollapse(_ notification: Notification) {
        //clear expandedNodeIndex
        self.expandedNodeIndex = nil
    }
    
    //MARK: - SegmentedView
    
    @IBAction func segmentedControlDidChangeSelection(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            self.sampleViewController.view.isHidden = false
            self.sourceCodeViewController.view.isHidden = true
            self.readmeViewController.view.isHidden = true
        case 1:
            self.sampleViewController.view.isHidden = true
            self.sourceCodeViewController.view.isHidden = false
            self.readmeViewController.view.isHidden = true
        case 2:
            self.sampleViewController.view.isHidden = true
            self.sourceCodeViewController.view.isHidden = true
            self.readmeViewController.view.isHidden = false
        default:
            break
        }
    }
    
    //MARK: - Collection view show/hide
    
    func showCollectionView(_ sampleNodes: [Node]) {
        if self.collectionViewController == nil {
            self.collectionViewController = self.storyboard!.instantiateController(withIdentifier: "CollectionViewController") as! CollectionViewController
            self.collectionViewController.view.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
            self.collectionViewController.delegate = self
        }
        
        self.clearPlaceholderView()
        self.collectionViewController.view.frame = self.placeholderView.bounds
        self.collectionViewController.sampleNodes = sampleNodes
        self.placeholderView.addSubview(self.collectionViewController.view)
    }
    
    //MARK: - Search logic
    
    func searchSamplesForString(_ text: String) {
        if let searchResults = SearchEngine.sharedInstance().searchForString(text) {
            let nodes = self.nodesByDisplayNames(searchResults)
            self.showCollectionView(nodes)
        }
        else {
            self.showCollectionView([Node]())
        }
    }
    
    func nodesByDisplayNames(_ names:[String]) -> [Node] {
        var nodes = [Node]()
        for node in self.nodesArray {
            //ignore featured samples to avoid redundancy
            if node.displayName == "Featured" {
                continue
            }
            let children = node.childNodes
            if let matchingNodes = children?.filter({ return names.contains($0.displayName) }) {
                nodes.append(contentsOf: matchingNodes)
            }
        }
        return nodes
    }
    
    func findParentForNode(_ node: Node) -> (parentIndex: Int, childIndex: Int)? {
        for parentNode in self.nodesArray {
            if let index = parentNode.childNodes.index(of: node) {
                //parent found
                return (self.nodesArray.index(of: parentNode)!, index)
            }
        }
        return nil
    }
    
    //MARK: - CollectionViewControllerDelegate
    
    func collectionViewController(_ collectionViewController: CollectionViewController, didSelectSampleNode node: Node) {
        
        if let abc = self.findParentForNode(node) {
            
            if self.expandedNodeIndex != nil {
                self.outlineView.collapseItem(self.nodesArray[self.expandedNodeIndex])
            }
            
            let rowIndexSet = IndexSet(integer: abc.parentIndex + abc.childIndex + 1)
            self.outlineView.expandItem(self.nodesArray[abc.parentIndex])
            self.outlineView.selectRowIndexes(rowIndexSet, byExtendingSelection: false)
        }
    }
    
    //MARK: - Show/hide liveSampleSegmentedControl
    
    func toggleSegmentedControl(_ state: ToggleState) {
        self.heightConstraint.animator().constant = state == .On ? 40 : 0
    }
}

