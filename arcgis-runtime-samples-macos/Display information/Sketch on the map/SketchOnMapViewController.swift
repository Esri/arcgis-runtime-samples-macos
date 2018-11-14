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

class SketchOnMapViewController: NSViewController {

    @IBOutlet private weak var mapView: AGSMapView!
    @IBOutlet private weak var geometrySegmentedControl: NSSegmentedControl!
    @IBOutlet private weak var undoButton: NSButton!
    @IBOutlet private weak var redoButton: NSButton!
    @IBOutlet private weak var clearButton: NSButton!
    
    private var map: AGSMap!
    private var sketchEditor: AGSSketchEditor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.map = AGSMap(basemap: .lightGrayCanvas())
        
        self.sketchEditor = AGSSketchEditor()
        self.mapView.sketchEditor = self.sketchEditor
        
        //self.sketchEditor.start(with: .polyline)
        self.sketchEditor.start(with: nil, creationMode: .polyline)
        
        self.mapView.map = self.map
        self.mapView.interactionOptions.isMagnifierEnabled = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(respondToGeomChanged), name: .AGSSketchEditorGeometryDidChange, object: nil)
        
        //set initial viewpoint
        self.map.initialViewpoint = AGSViewpoint(targetExtent: AGSEnvelope(xMin: -10049589.670344, yMin: 3480099.843772, xMax: -10010071.251113, yMax: 3512023.489701, spatialReference: .webMercator()))
    }
    
    @objc
    func respondToGeomChanged() {
        //Enable/disable UI elements appropriately
        self.undoButton.isEnabled = self.sketchEditor.undoManager.canUndo
        self.redoButton.isEnabled = self.sketchEditor.undoManager.canRedo
        self.clearButton.isEnabled = self.sketchEditor.geometry != nil && !self.sketchEditor.geometry!.isEmpty
    }
    
    // MARK: - Actions
    
    @IBAction func geometryValueChanged(_ segmentedControl: NSSegmentedControl) {
        switch segmentedControl.selectedSegment {
        case 0://point
            self.sketchEditor.start(with: nil, creationMode: .point)
            
        case 1://polyline
            self.sketchEditor.start(with: nil, creationMode: .polyline)

        case 2://freehand polyline
            self.sketchEditor.start(with: nil, creationMode: .freehandPolyline)
        
        case 3://polygon
            self.sketchEditor.start(with: nil, creationMode: .polygon)
            
        case 4://freehand polygon
            self.sketchEditor.start(with: nil, creationMode: .freehandPolygon)
            
        default:
            break
        }
        self.mapView.sketchEditor = self.sketchEditor
    }
    
    @IBAction func undo(_ sender: NSButton) {
        if self.sketchEditor.undoManager.canUndo { //extra check, just to be sure
            self.sketchEditor.undoManager.undo()
        }
    }
    
    @IBAction func redo(_ sender: NSButton) {
        if self.sketchEditor.undoManager.canRedo { //extra check, just to be sure
            self.sketchEditor.undoManager.redo()
        }
    }
    
    @IBAction func clear(_ sender: NSButton) {
        self.sketchEditor.clearGeometry()
    }
}
