//
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

class StatisticalQueryViewController: NSViewController {
    
    @IBOutlet private weak var mapView: AGSMapView!
    @IBOutlet weak var settingsView: NSVisualEffectView!
    @IBOutlet private var getStatisticsButton: NSButton!
    @IBOutlet private var onlyInCurrentExtentCheckBox: NSButton!
    @IBOutlet private var onlyBigCitiesCheckBox: NSButton!
    private var map: AGSMap?
    private var serviceFeatureTable: AGSServiceFeatureTable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Corner radius for view
        settingsView.wantsLayer = true
        settingsView.layer?.cornerRadius = 10
        
        // Initialize map and set it on map view
        map = AGSMap(basemap: .streetsVector())
        mapView.map = map

        // Initialize feature table, layer and add it to map
        serviceFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/SampleWorldCities/MapServer/0")!)
        let featureLayer = AGSFeatureLayer(featureTable: serviceFeatureTable!)
        map?.operationalLayers.add(featureLayer)
    }
    
    // MARK: - Actions
    
    @IBAction private func getStatisticsAction(_ sender: Any) {
        //
        // Add the statistic definitions
        var statisticDefinitions = [AGSStatisticDefinition]()
        statisticDefinitions.append(AGSStatisticDefinition(onFieldName: "POP", statisticType: .average, outputAlias: nil))
        statisticDefinitions.append(AGSStatisticDefinition(onFieldName: "POP", statisticType: .minimum, outputAlias: nil))
        statisticDefinitions.append(AGSStatisticDefinition(onFieldName: "POP", statisticType: .maximum, outputAlias: nil))
        statisticDefinitions.append(AGSStatisticDefinition(onFieldName: "POP", statisticType: .sum, outputAlias: nil))
        statisticDefinitions.append(AGSStatisticDefinition(onFieldName: "POP", statisticType: .standardDeviation, outputAlias: nil))
        statisticDefinitions.append(AGSStatisticDefinition(onFieldName: "POP", statisticType: .variance, outputAlias: nil))
        statisticDefinitions.append(AGSStatisticDefinition(onFieldName: "POP", statisticType: .count, outputAlias: nil))
        
        // Create the parameters with statistic definitions
        let statisticsQueryParameters = AGSStatisticsQueryParameters(statisticDefinitions: statisticDefinitions)
        
        // If only using features in the current extent, set up the spatial filter for the statistics query parameters
        if onlyInCurrentExtentCheckBox.state.rawValue == 1 {
            //
            // Set the statistics query parameters geometry with the envelope
            statisticsQueryParameters.geometry = mapView.visibleArea?.extent
            
            // Set the spatial relationship to Intersects (which is the default)
            statisticsQueryParameters.spatialRelationship = .intersects
        }
        
        // If only evaluating the largest cities (over 5 million in population), set up an attribute filter
        if onlyBigCitiesCheckBox.state.rawValue == 1 {
            statisticsQueryParameters.whereClause = "POP_RANK = 1"
        }
        
        // Execute the statistical query with parameters
        serviceFeatureTable?.queryStatistics(with: statisticsQueryParameters, completion: { [weak self] (statisticsQueryResult, error) in
            //
            // If there an error, display it
            guard error == nil else {
                self?.showAlert(messageText: "Error", informativeText: "Error while executing statistics query :: \(String(describing: error?.localizedDescription))")
                return
            }
            
            // Get the result
            if let statisticRecordEnumerator = statisticsQueryResult?.statisticRecordEnumerator() {
                //
                // Let's build result message
                var resultMessage = " \n"
                while statisticRecordEnumerator.hasNextObject() {
                    let statisticRecord = statisticRecordEnumerator.nextObject()
                    for (key, value) in (statisticRecord?.statistics)! {
                        resultMessage += "\(key): \(value) \n"
                    }
                }
                
                // Show result
                self?.showAlert(messageText: "Statistical Query Results", informativeText: resultMessage)
            }
        })
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(messageText: String, informativeText: String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!)
    }
}
