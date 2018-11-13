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

class OfflineMapParameterOverridesViewController: NSViewController {
    
    var parameterOverrides: AGSGenerateOfflineMapParameterOverrides?
    var map: AGSMap?
    
    // MARK: - outlets

    @IBOutlet weak var systemValvesCheckbox: NSButton!
    @IBOutlet weak var serviceConnectionsCheckbox: NSButton!
    
    @IBOutlet weak var waterPipesCheckbox: NSButton!
    
    @IBOutlet weak var minScaleSlider: NSSlider!
    @IBOutlet weak var maxScaleSlider: NSSlider!
    
    // MARK: - bound values
    
    /// The min scale level for the output. Note that lower values are zoomed further out,
    /// i.e. 0 has the least detail, but one tile covers the entire Earth.
    /// Bound to the UI in the storyboard.
    @objc dynamic var basemapMinScaleLevel: NSNumber = 0 {
        didSet {
            // ensure that the min is not set greater than that max
            if basemapMinScaleLevel.doubleValue > basemapMaxScaleLevel.doubleValue {
                basemapMinScaleLevel = basemapMaxScaleLevel
                // manually set slider value to prevent incorrect display
                minScaleSlider.doubleValue = basemapMinScaleLevel.doubleValue
            }
        }
    }
    
    /// The max scale level for the output. Note that higher values are zoomed further in,
    /// i.e. 23 has the most detail, but each tile covers a tiny area.
    /// Bound to the UI in the storyboard.
    @objc dynamic var basemapMaxScaleLevel: NSNumber = 23 {
        didSet {
            // ensure that the max is not set less than that min
            if basemapMaxScaleLevel.doubleValue < basemapMinScaleLevel.doubleValue {
                basemapMaxScaleLevel = basemapMinScaleLevel
                // manually set slider value to prevent incorrect display
                maxScaleSlider.doubleValue = basemapMaxScaleLevel.doubleValue
            }
        }
    }
    
    /// The extra padding added to the extent rect to fetch a larger area, in meters.
    /// Bound to the UI in the storyboard.
    @objc dynamic var basemapExtentBuffer: NSNumber = 0
    
    /// The minimum flow rate by which to filter features in the Hydrants layer, in gallons per minute.
    /// Bound to the UI in the storyboard.
    @objc dynamic var minHydrantFlowRate: NSNumber = 0
    
    // MARK: - cancelling
    
    /// The completion handler to run if the user clicks cancel
    var cancelHandler: ((OfflineMapParameterOverridesViewController) -> Void)?
    
    @IBAction func cancelButtonAction(_ sender: NSButton) {
        cancelHandler?(self)
    }
    
    // MARK: - completion
    
    /// The completion handler to run once the user is done setting the parameters.
    var startJobHandler: ((OfflineMapParameterOverridesViewController) -> Void)?
    
    @IBAction func startJobButtonAction(_ sender: NSButton) {
        // Update the parameters based on the user's input
        setParameterOverridesFromUI()
        // Run the handler callback now that the parameters have been updated
        startJobHandler?(self)
    }
    
    /// Updates the `AGSGenerateOfflineMapParameterOverrides` object with the user-set values.
    private func setParameterOverridesFromUI() {
        
        restrictBasemapScaleLevelRange()
        bufferBasemapAreaOfInterest()
        evaluateLayerVisiblity()
        addHydrantFilter()
        evaluatePipeLayersExtentCropping()
    }
    
    // MARK: - Basemap adjustment
    
    private func restrictBasemapScaleLevelRange() {
        
        /// The user-set min scale value
        let minScale = self.basemapMinScaleLevel.intValue
        /// The user-set max scale value
        let maxScale = self.basemapMaxScaleLevel.intValue
        
        guard let tileCacheParameters = getExportTileCacheParametersForBasemapLayer(),
            // Ensure that the lower bound of the range is not greater than the upper bound
            minScale <= maxScale else {
            return
        }
            
        let scaleLevelRange = minScale...maxScale
        let scaleLevelIDs = Array(scaleLevelRange) as [NSNumber]
        // Override the default level IDs
        tileCacheParameters.levelIDs = scaleLevelIDs
    }
    
    private func bufferBasemapAreaOfInterest() {
        
        guard let tileCacheParameters = getExportTileCacheParametersForBasemapLayer(),
            /// The area initially specified for download when the default parameters object was created
            let areaOfInterest = tileCacheParameters.areaOfInterest else {
            return
        }
            
        /// The user-set distance value
        let basemapExtentBufferDistance = basemapExtentBuffer.doubleValue
        
        // Assuming the distance is positive, expand the downloaded area by the given amount
        let bufferedArea = AGSGeometryEngine.bufferGeometry(areaOfInterest, byDistance: basemapExtentBufferDistance)
        // Override the default area of interest
        tileCacheParameters.areaOfInterest = bufferedArea
    }
    
    // MARK: - Layer adjustment
    
    private func addHydrantFilter() {
        
        /// The user-set min flow rate value
        let minFlowRate = minHydrantFlowRate.doubleValue
        
        for option in getGenerateGeodatabaseParametersLayerOptions(forLayerNamed: "Hydrant") {
            // Set the SQL where clause for this layer's options, filtering features based on the FLOW field values
            option.whereClause = "FLOW >= \(minFlowRate)"
        }
    }
    
    private func evaluateLayerVisiblity() {
        
        func excludeLayerFromDownload(named name: String) {
            if let layer = operationalMapLayer(named: name),
                let serviceLayerID = serviceLayerID(for: layer),
                let parameters = getGenerateGeodatabaseParameters(forLayer: layer) {
                // Remove the options for this layer from the parameters
                parameters.layerOptions.removeAll { $0.layerID == serviceLayerID }
            }
        }
        
        // If the box is unchecked
        if systemValvesCheckbox.state == .off {
            excludeLayerFromDownload(named: "System Valve")
        }
        if serviceConnectionsCheckbox.state == .off {
            excludeLayerFromDownload(named: "Service Connection")
        }
        
    }
    
    private func evaluatePipeLayersExtentCropping() {
        // If the box is unchecked
        if waterPipesCheckbox.state == .off {
            // Two layers contain pipes, so loop through both
            for pipeLayerName in ["Main", "Lateral"] {
                for option in getGenerateGeodatabaseParametersLayerOptions(forLayerNamed: pipeLayerName) {
                    // Turn off the geometry extent evaluation so that the entire layer is downloaded
                    option.useGeometry = false
                }
            }
        }
    }
    
    // MARK: - Basemap helpers
    
    /// Retrieves the basemap's parameters from the `exportTileCacheParameters` dictionary.
    private func getExportTileCacheParametersForBasemapLayer() -> AGSExportTileCacheParameters? {
        if let basemapLayer = map?.basemap.baseLayers.firstObject as? AGSLayer {
            let key = AGSOfflineMapParametersKey(layer: basemapLayer)
            return parameterOverrides?.exportTileCacheParameters[key]
        }
        return nil
    }
    
    // MARK: - Layer helpers
    
    /// Retrieves the operational layer in the map with the given name, if it exists.
    private func operationalMapLayer(named name: String) -> AGSLayer? {
        let layers = map?.operationalLayers as? [AGSLayer]
        return layers?.first(where: { $0.name == name })
    }
    
    /// The service ID retrived from the layer's `AGSArcGISFeatureLayerInfo`, if it is a feature layer.
    /// Needed for use in conjunction with the `layerID` of `AGSGenerateLayerOption`.
    /// This is not the same as the `layerID` property of `AGSLayer`.
    private func serviceLayerID(for layer: AGSLayer) -> Int? {
        if let featureLayer = layer as? AGSFeatureLayer,
            let featureTable = featureLayer.featureTable as? AGSArcGISFeatureTable,
            let featureLayerInfo = featureTable.layerInfo {
            return featureLayerInfo.serviceLayerID
        }
        return nil
    }
    
    // MARK: - AGSGenerateGeodatabaseParameters helpers
    
    /// Retrieves this layer's parameters from the `generateGeodatabaseParameters` dictionary.
    private func getGenerateGeodatabaseParameters(forLayer layer: AGSLayer) -> AGSGenerateGeodatabaseParameters? {
        /// The parameters key for this layer
        let key = AGSOfflineMapParametersKey(layer: layer)
        return parameterOverrides?.generateGeodatabaseParameters[key]
    }
    /// Retrieves the layer's options from the layer's parameter in the `generateGeodatabaseParameters` dictionary.
    private func getGenerateGeodatabaseParametersLayerOptions(forLayerNamed name: String) -> [AGSGenerateLayerOption] {
        if let layer = operationalMapLayer(named: name),
            let serviceLayerID = serviceLayerID(for: layer),
            let parameters = getGenerateGeodatabaseParameters(forLayer: layer) {
            // The layers options may correspond to multiple layers, so filter based on the ID of the target layer.
            return parameters.layerOptions.filter { (option) -> Bool in
                option.layerID == serviceLayerID
            }
        }
        return []
    }
  
}
