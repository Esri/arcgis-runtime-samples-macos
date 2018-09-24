//
// Copyright 2018 Esri.
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
import ArcGIS

class ListKMLContentsViewController: NSViewController {

    @IBOutlet weak var sceneView: AGSSceneView!
    @IBOutlet weak var outlineView: NSOutlineView!
    
    var kmlDataset: AGSKMLDataset?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize scene with labeled imagery
        let scene = AGSScene(basemapType: .imageryWithLabels)
        // assign the scene to the view
        sceneView.scene = scene
        
        // create the dataset from the local kml/kmz file with the given name
        let kmlDataset = AGSKMLDataset(name: "esri_test_data")
        // create a layer to display the dataset
        let kmlLayer = AGSKMLLayer(kmlDataset: kmlDataset)
       
        // add the kml layer to the map
        scene.operationalLayers.add(kmlLayer)
        
        // load the dataset asynchronously so we can list its contents
        kmlDataset.load {[weak self] (error) in
            
            guard let self = self else{
                return
            }
            
            guard error == nil else{
                if let window = self.view.window {
                    // display the error as an alert
                    NSAlert(error: error!).beginSheetModal(for: window)
                }
                return
            }
            
            // some nodes are not visible by default so ensure that all of them are
            self.makeNodesVisible(kmlDataset.rootNodes)
            
            // make the dataset accesible now that the data is loaded
            self.kmlDataset = kmlDataset
            // populate the outline view now that the dataset is accessible
            self.outlineView.reloadData()
            
            // expand all items in the outline
            self.outlineView.expandItem(nil, expandChildren: true)
            // select the first node
            self.outlineView.selectRowIndexes([0], byExtendingSelection: false)
        }
    }
    
    /// Sets `isVisible` to `true` for these nodes and their desdendants
    func makeNodesVisible(_ nodes: [AGSKMLNode]){
        for node in nodes{
            node.isVisible = true
            makeNodesVisible(childNodes(of: node))
        }
    }
    
    /// Returns all the child nodes of this node
    func childNodes(of node: AGSKMLNode) -> [AGSKMLNode] {
        var children = [AGSKMLNode]()
        if let container = node as? AGSKMLContainer {
            children.append(contentsOf: container.childNodes)
        }
        if let networkLink = node as? AGSKMLNetworkLink {
            children.append(contentsOf: networkLink.childNodes)
        }
        return children
    }

    /// Sets the viewpoint of the scene to the extent of the node, if it has one
    func setSceneViewpoint(on node: AGSKMLNode){
        if let extent = node.extent,
            // some nodes do not include a geometry, so check that the extent isn't empty
            !extent.isEmpty {
           
            let viewpoint = AGSViewpoint(targetExtent: extent)
            sceneView.setViewpoint(viewpoint)
        }
    }
    
}

// Boilerplate datasource code to display the KML node hierarchy
extension ListKMLContentsViewController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let node = item as? AGSKMLNode {
            return childNodes(of: node).count
        }
        else if let kmlDataset = kmlDataset {
            return kmlDataset.rootNodes.count
        }
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? AGSKMLNode {
            return childNodes(of: node)[index]
        }
        else if let kmlDataset = kmlDataset {
            return kmlDataset.rootNodes[index]
        }
        return NSNull()
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let node = item as? AGSKMLNode{
            return !childNodes(of: node).isEmpty
        }
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("KMLNodeCellView"), owner: outlineView) as! NSTableCellView
        if let node = item as? AGSKMLNode{
            // Use the node's name and class for the label
            let label = "\(node.name) - \(type(of:node))"
            cellView.textField?.stringValue = label
        }
        return cellView
    }

}
extension ListKMLContentsViewController: NSOutlineViewDelegate {
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = outlineView.selectedRow
        if selectedRow >= 0,
            let selectedNode = outlineView.item(atRow: selectedRow) as? AGSKMLNode {
            // when the user selects a node in the outline view, set the viewpoint on it
            setSceneViewpoint(on: selectedNode)
        }
    }
    
}
