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

import Cocoa
import ArcGIS

class ListTransformationsViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet var tableView: NSTableView!
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var orderByMapExtent: NSButton!
    
    var datumTransformations = [AGSDatumTransformation]()
    var defaultTransformation: AGSDatumTransformation?
    let graphicsOverlay = AGSGraphicsOverlay()
    var originalGeometry = AGSPoint(x: 538985.355, y: 177329.516, spatialReference: AGSSpatialReference(wkid: 27700))
    
    var projectedGraphic: AGSGraphic? {
        if graphicsOverlay.graphics.count > 1 {
            return graphicsOverlay.graphics.lastObject as? AGSGraphic
        } else {
            return nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // set a map into the mapView
        mapView.map = AGSMap(basemap: .lightGrayCanvasVector())
        mapView.graphicsOverlays.add(graphicsOverlay)
        
        // add original graphic to overlay
        addGraphic(originalGeometry, color: .red, style: .square)
        
        mapView.map?.load { [weak self] (error) in
            if let error = error {
                print("map load error = \(error)")
            } else {
                self?.mapDidLoad()
            }
        }
    }
    
    func mapDidLoad() {
        mapView.setViewpoint(AGSViewpoint(center: originalGeometry, scale: 5000), duration: 2.0, completion: nil)
        
        // set the url for our projection engine data;
        setPEDataURL()
    }
    
    // add a graphic with the given geometry, color and style to the graphics overlay
    func addGraphic(_ geometry: AGSGeometry, color: NSColor, style: AGSSimpleMarkerSymbolStyle) {
        let sms = AGSSimpleMarkerSymbol(style: style, color: color, size: 15.0)
        graphicsOverlay.graphics.add(AGSGraphic(geometry: geometry, symbol: sms, attributes: nil))
    }
    
    // set up our datumTransformations array
    func setupTransformsList() {
        guard let map = mapView.map,
            let inputSR = originalGeometry.spatialReference,
            let outputSR = map.spatialReference else { return }
        
        // if orderByMapExtent is on, use the map extent when retrieving the transformations
        if orderByMapExtent.state == .on {
            datumTransformations = AGSTransformationCatalog.transformationsBySuitability(withInputSpatialReference: inputSR, outputSpatialReference: outputSR, areaOfInterest: mapView.visibleArea?.extent)
        } else {
            datumTransformations = AGSTransformationCatalog.transformationsBySuitability(withInputSpatialReference: inputSR, outputSpatialReference: outputSR)
        }
        
        defaultTransformation = AGSTransformationCatalog.transformation(forInputSpatialReference: inputSR, outputSpatialReference: outputSR)
        
        // remove projected graphic from overlay
        if let graphic = projectedGraphic {
            // we have the projected graphic, remove it (it's always the last one)
            graphicsOverlay.graphics.remove(graphic)
        }
        
        tableView.reloadData()
    }
    
    func setPEDataURL() {
        // Look in the user's Documents directory for our PE data folder
        if let projectionEngineDataURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("PEDataRuntime") {
            do {
                guard try projectionEngineDataURL.checkResourceIsReachable() else { return }
                
                // Normally, this method would be called immediately upon application startup before any other API method calls.
                // So usually it would be called from AppDelegate.application(_:didFinishLaunchingWithOptions:), but for the purposes
                // of this sample, we're calling it here.
                try AGSTransformationCatalog.setProjectionEngineDirectory(projectionEngineDataURL)
            } catch {
                print("Could not load projection engine data.  See the README file for instructions on adding PE data to your app.")
            }
        }
        
        setupTransformsList()
    }

    @IBAction func oderByMapExtentValueChanged(_ sender: Any) {
        setupTransformsList()
    }
    
    // MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return datumTransformations.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView: NSView?

        let transformation = datumTransformations[row]
        if transformation.isMissingProjectionEngineFiles,
            // if we're missing the grid files, detail which ones
            let geographicTransformation = transformation as? AGSGeographicTransformation {

            cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DatumTransformCell"), owner: self) as? NSTableCellView
            if let titleLabel = cellView?.viewWithTag(0) as? NSTextField {
                titleLabel.stringValue = transformation.name
            }

            // get the list of missing transformations
            let files = geographicTransformation.steps.flatMap { (step) -> [String] in
                step.isMissingProjectionEngineFiles ? step.projectionEngineFilenames : []
            }

            // set the detail label with the list of missing grid files
            if let detailLabel = cellView?.viewWithTag(1) as? NSTextField {
                detailLabel.stringValue = "Missing grid files: \(files.joined(separator: ", "))"
            }

        } else {
            // we have the grid files, so use the simple, title-only cell to display the transformation name
            let tableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TitleCell"), owner: self) as? NSTableCellView
            tableCellView?.textField?.stringValue = transformation.name
            cellView = tableCellView
        }

        return cellView
    }
    
    // MARK: - NSTableViewDelegate

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let mapViewSR = mapView.spatialReference else { return }
        
        let selectedTransform = datumTransformations[tableView.selectedRow]
        if let projectedGeometry = AGSGeometryEngine.projectGeometry(originalGeometry, to: mapViewSR, datumTransformation: selectedTransform) {
            // projectGeometry succeeded
            if let graphic = projectedGraphic {
                // we've already added the projected graphic
                graphic.geometry = projectedGeometry
            } else {
                // add projected graphic
                addGraphic(projectedGeometry, color: .blue, style: .cross)
            }
        } else {
            // If a transformation is missing grid files, then it cannot be
            // successfully used to project a geometry, and "projectGeometry" will return nil.
            // In that case, remove projected graphic
            if graphicsOverlay.graphics.count > 1 {
                graphicsOverlay.graphics.removeLastObject()
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        // don't allow selection on transformations with missing files
        let transformation = datumTransformations[row]
        return !transformation.isMissingProjectionEngineFiles
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        // we have two different row heights
        let transformation = datumTransformations[row]
        return (transformation.isMissingProjectionEngineFiles ? 46.0 : 20.0)
    }
}
