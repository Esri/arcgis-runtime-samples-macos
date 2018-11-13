// Copyright 2017 Esri.
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

import Cocoa
import ArcGIS

class ChangeSublayerRendererVC: NSViewController {

    @IBOutlet private var mapView: AGSMapView!
    @IBOutlet private var applyRendererButton: NSButton!
    @IBOutlet private var resetButton: NSButton!
    
    //map image layer
    private var mapImageLayer: AGSArcGISMapImageLayer = {
        /// The url of a map service containing sample census data of the United States.
        let censusMapServiceURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer")!
        return AGSArcGISMapImageLayer(url: censusMapServiceURL)
    }()
    
    private var originalRenderer: AGSRenderer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize map with basemap
        let map = AGSMap(basemap: .streets())
        
        //add map image layer to the map
        map.operationalLayers.add(self.mapImageLayer)
        
        //initial viewpoint
        let envelope = AGSEnvelope(xMin: -14387199.261871, yMin: 2189974.377594, xMax: -6944275.345711, yMax: 6893094.239799, spatialReference: AGSSpatialReference.webMercator())
        
        //set initial viewpoint on map
        map.initialViewpoint = AGSViewpoint(targetExtent: envelope)
        
        //set map on the map view
        self.mapView.map = map
        
        //load map image layer to access sublayers
        self.mapImageLayer.load { [weak self] (error: Error?) in
            
            guard let weakSelf = self else {
                return
            }
            
            //get the counties sublayer
            if let sublayer = weakSelf.mapImageLayer.mapImageSublayers[2] as? AGSArcGISMapImageSublayer {
                
                //load the sublayer to get the original renderer
                sublayer.load(completion: { (error) in
                    if error == nil {
                        weakSelf.originalRenderer = sublayer.renderer
                        
                        //enable bar button items
                        self?.applyRendererButton.isEnabled = true
                        self?.resetButton.isEnabled = true
                    }
                })
            }
        }
    }
    
    //returns a class break renderer
    private func classBreakRenderer() -> AGSClassBreaksRenderer {
        
        //create a class breaks renderer for counties in US based on their population in 2007
        
        //outline symbol
        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: NSColor(white: 0.6, alpha: 1), width: 0.5)
        
        //symbols for each class break
        let symbol1 = AGSSimpleFillSymbol(style: .solid, color: NSColor(red: 0.89, green: 0.92, blue: 0.81, alpha: 1), outline: lineSymbol)
        let symbol2 = AGSSimpleFillSymbol(style: .solid, color: NSColor(red: 0.59, green: 0.76, blue: 0.75, alpha: 1), outline: lineSymbol)
        let symbol3 = AGSSimpleFillSymbol(style: .solid, color: NSColor(red: 0.38, green: 0.65, blue: 0.71, alpha: 1), outline: lineSymbol)
        let symbol4 = AGSSimpleFillSymbol(style: .solid, color: NSColor(red: 0.27, green: 0.49, blue: 0.59, alpha: 1), outline: lineSymbol)
        let symbol5 = AGSSimpleFillSymbol(style: .solid, color: NSColor(red: 0.16, green: 0.33, blue: 0.47, alpha: 1), outline: lineSymbol)
        
        //class breaks
        let classBreak1 = AGSClassBreak(description: "-99 to 8560", label: "-99 to 8560", minValue: -99, maxValue: 8560, symbol: symbol1)
        let classBreak2 = AGSClassBreak(description: "> 8,560 to 18,109", label: "> 8,560 to 18,109", minValue: 8561, maxValue: 18109, symbol: symbol2)
        let classBreak3 = AGSClassBreak(description: "> 18,109 to 35,501", label: "> 18,109 to 35,501", minValue: 18110, maxValue: 35501, symbol: symbol3)
        let classBreak4 = AGSClassBreak(description: "> 35,501 to 86,100", label: "> 35,501 to 86,100", minValue: 35502, maxValue: 86100, symbol: symbol4)
        let classBreak5 = AGSClassBreak(description: "> 86,100 to 10,110,975", label: "> 86,100 to 10,110,975", minValue: 86101, maxValue: 10110975, symbol: symbol5)
        
        //create a class break renderer using the class breaks above
        let classBreakRenderer = AGSClassBreaksRenderer(fieldName: "POP2007", classBreaks: [ classBreak1, classBreak2, classBreak3, classBreak4, classBreak5])
        
        return classBreakRenderer
    }
    
    //MARK: - Actions
    
    @IBAction private func applyRenderer(_ sender: NSButton) {
        
        //get the counties sublayer
        if let sublayer = self.mapImageLayer.mapImageSublayers[2] as? AGSArcGISMapImageSublayer {
            
            //set the class breaks renderer on the counties sublayer
            sublayer.renderer = self.classBreakRenderer()
        }
    }
    
    @IBAction private func reset(_ sender: NSButton) {
        
        if let renderer = self.originalRenderer, let sublayer = self.mapImageLayer.mapImageSublayers[2] as? AGSArcGISMapImageSublayer {
            
            //set the class breaks renderer on the counties sublayer
            sublayer.renderer = renderer
        }
    }
}
