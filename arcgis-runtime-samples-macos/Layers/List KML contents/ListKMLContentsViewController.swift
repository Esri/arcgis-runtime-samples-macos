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
    
    /// The KML dataset which provides the data for the KML layer and the outline view.
    private var kmlDataset: AGSKMLDataset?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize scene with labeled imagery
        let scene = AGSScene(basemapType: .imageryWithLabels)
        
        // create an elevation source and add it to the scene's surface
        let elevationSourceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        let elevationSource = AGSArcGISTiledElevationSource(url: elevationSourceURL)
        scene.baseSurface?.elevationSources.append(elevationSource)
        
        // assign the scene to the view
        sceneView.scene = scene
        
        // create the dataset from the local kml/kmz file with the given name
        let kmlDataset = AGSKMLDataset(name: "esri_test_data")
        self.kmlDataset = kmlDataset
        
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

            // populate the outline view now that the dataset is loaded
            self.outlineView.dataSource = self
            
            // expand all items in the outline
            self.outlineView.expandItem(nil, expandChildren: true)
            // select the first node
            self.outlineView.selectRowIndexes([0], byExtendingSelection: false)
        }
    }
    
    /// Sets `isVisible` to `true` for these nodes and their descendants
    private func makeNodesVisible(_ nodes: [AGSKMLNode]){
        for node in nodes{
            node.isVisible = true
            makeNodesVisible(childNodes(of: node))
        }
    }
    
    /// Returns all the child nodes of this node
    private func childNodes(of node: AGSKMLNode) -> [AGSKMLNode] {
        if let container = node as? AGSKMLContainer {
            return container.childNodes
        }
        else if let networkLink = node as? AGSKMLNetworkLink {
            return networkLink.childNodes
        }
        return []
    }
    
    //MARK: - Viewpoint
    
    /// Sets the viewpoint of the scene to that of the node, if available.
    private func setSceneViewpoint(for node: AGSKMLNode){
        if let nodeViewpoint = viewpoint(for: node),
            !nodeViewpoint.targetGeometry.isEmpty {
            sceneView.setViewpoint(nodeViewpoint)
        }
    }
    
    /// Returns the elevation of the scene's surface corresponding to the point's x/y.
    private func sceneSurfaceElevation(for point: AGSPoint) -> Double? {
        guard let surface = sceneView.scene?.baseSurface else {
            return nil
        }
        
        var surfaceElevation: Double? = nil
        let group = DispatchGroup()
        group.enter()
        // we want to return the elevation synchronously, so run the task in the background and wait
        DispatchQueue.global(qos: .userInteractive).async {
            surface.elevation(for: point, completion: { (elevation, error) in
                if error == nil{
                    surfaceElevation = elevation
                }
                group.leave()
            })
        }
        // wait, but not longer than three seconds
        _ = group.wait(timeout: .now() + 3)
        return surfaceElevation
    }
    
    /// Returns the viewpoint showing the node, converting it from the node's AGSKMLViewPoint if possible.
    private func viewpoint(for node: AGSKMLNode) -> AGSViewpoint? {
        
        if let kmlViewpoint = node.viewpoint {
            // Convert the KML viewpoint to a viewpoint for the scene.
            // The KML viewpoint may not correspond to the node's geometry.
            
            switch kmlViewpoint.type{
            case .lookAt:
                var lookAtPoint = kmlViewpoint.location
                if kmlViewpoint.altitudeMode != .absolute{
                    // if the elevation is relative, account for the surface's elevation
                    let elevation = sceneSurfaceElevation(for: lookAtPoint) ?? 0
                    lookAtPoint = AGSPoint(x: lookAtPoint.x, y: lookAtPoint.y, z: lookAtPoint.z + elevation, spatialReference: lookAtPoint.spatialReference)
                }
                let camera = AGSCamera(lookAt: lookAtPoint,
                                       distance: kmlViewpoint.range,
                                       heading: kmlViewpoint.heading,
                                       pitch: kmlViewpoint.pitch,
                                       roll: kmlViewpoint.roll)
                // only the camera parameter is used by the scene
                return AGSViewpoint(center: kmlViewpoint.location, scale: 1, camera: camera)
            case .camera:
                // convert the KML viewpoint to a camera
                let camera = AGSCamera(location: kmlViewpoint.location,
                                       heading: kmlViewpoint.heading,
                                       pitch: kmlViewpoint.pitch,
                                       roll: kmlViewpoint.roll)
                // only the camera parameter is used by the scene
                return AGSViewpoint(center: kmlViewpoint.location, scale: 1, camera: camera)
            case .unknown:
                print("Unexpected AGSKMLViewpointType \(kmlViewpoint.type)")
                return nil
            }
        }
        // the node does not have a predefined viewpoint, so create a viewpoint based on its extent
        else if let extent = node.extent,
            // some nodes do not include a geometry, so check that the extent isn't empty
            !extent.isEmpty {
            
            var center = extent.center
            // take the scene's elevation into account
            let elevation = sceneSurfaceElevation(for: center) ?? 0
            
            // It's possible for `isEmpty` to be false but for width/height to still be zero.
            if extent.width == 0,
                extent.height == 0 {

                center = AGSPoint(x: center.x, y: center.y, z: center.z + elevation, spatialReference: extent.spatialReference)
                // Defaults based on Google Earth.
                let camera = AGSCamera(lookAt: center, distance: 1000, heading: 0, pitch: 45, roll: 0)
                // only the camera parameter is used by the scene
                return AGSViewpoint(targetExtent: extent, camera: camera)

            }
            else {
                // expand the extent to give some margins when framing the node
                let bufferRadius = [extent.width, extent.height].max()! / 20
                let bufferedExtent = AGSEnvelope(xMin: extent.xMin - bufferRadius,
                                                 yMin: extent.yMin - bufferRadius,
                                                 zMin: extent.zMin - bufferRadius + elevation,
                                                 xMax: extent.xMax + bufferRadius,
                                                 yMax: extent.yMax + bufferRadius,
                                                 zMax: extent.zMax + bufferRadius + elevation,
                                                 spatialReference: .wgs84())
                return AGSViewpoint(targetExtent: bufferedExtent)
            }
        }
        // the node doesn't have a predefined viewpoint or geometry
        return nil
    }
    
}

// Boilerplate datasource code to display the KML node hierarchy
extension ListKMLContentsViewController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let node = item as? AGSKMLNode {
            return childNodes(of: node).count
        }
        // kmlDataset will never be nil since the data source is set after the data is successfully loaded
        return kmlDataset!.rootNodes.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? AGSKMLNode {
            return childNodes(of: node)[index]
        }
        return kmlDataset!.rootNodes[index]
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
            // when the user selects a node in the outline view, set the viewpoint for it
            setSceneViewpoint(for: selectedNode)
        }
    }
    
}
