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
//

import Cocoa
import ArcGIS

class HotspotsViewController: NSViewController {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var datePicker:NSDatePicker!
    @IBOutlet var applyButton:NSButton!
    
    private var geoprocessingTask: AGSGeoprocessingTask!
    private var geoprocessingJob: AGSGeoprocessingJob!
    private var graphicsOverlay = AGSGraphicsOverlay()
    
    private var dateFormatter: DateFormatter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize map with basemap
        let map = AGSMap(basemap: AGSBasemap.topographic())
        
        //center for initial viewpoint
        let center = AGSPoint(x: -13671170.647485, y: 5693633.356735, spatialReference: AGSSpatialReference(wkid: 3857))
        
        //set initial viewpoint
        map.initialViewpoint = AGSViewpoint(center: center, scale: 57779)
        
        //assign map to map view
        self.mapView.map = map
        
        //initilaize geoprocessing task with the url of the service
        self.geoprocessingTask = AGSGeoprocessingTask(url: URL(string: "http://sampleserver6.arcgisonline.com/arcgis/rest/services/911CallsHotspot/GPServer/911%20Calls%20Hotspot")!)
        
        //create date formatter to format dates for input
        self.dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
    }
    
    private func analyzeHotspots(fromDate: Date, toDate: Date) {
        
        //disable apply button until processing
        self.applyButton.isEnabled = false
        
        //cancel previous job request
        self.geoprocessingJob?.cancel()
        
        //geoprocessing parameters
        let params = AGSGeoprocessingParameters(executionType: .asynchronousSubmit)
        params.processSpatialReference = self.mapView.map?.spatialReference
        params.outputSpatialReference = self.mapView.map?.spatialReference
        
        //format dates to format required for input string
        let fromDateString = self.dateFormatter.string(from: fromDate)
        let toDateString = self.dateFormatter.string(from: toDate)
        
        //prepare query string
        let queryString = "(\"DATE\" > date '\(fromDateString) 00:00:00' AND \"DATE\" < date '\(toDateString) 00:00:00')"
        params.inputs["Query"] = AGSGeoprocessingString(value: queryString)
        
        //job
        self.geoprocessingJob = self.geoprocessingTask.geoprocessingJob(with: params)
        
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        //start job
        self.geoprocessingJob.start(statusHandler: { (status: AGSJobStatus) in
            print(status.rawValue)
        }) { [weak self] (result: AGSGeoprocessingResult?, error: Error?) in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            //enable apply button
            self?.applyButton.isEnabled = true
            
            if let error = error {
                self?.showAlert(messageText: "Error", informativeText: error.localizedDescription)
            }
            else {
                //a map image layer is generated as a result
                //remove any layer previously added to the map
                self?.mapView.map?.operationalLayers.removeAllObjects()
                
                //add the new layer to the map
                self?.mapView.map?.operationalLayers.add(result!.mapImageLayer!)
                
                //set map view's viewpoint to the new layer's full extent
                (self?.mapView.map?.operationalLayers.firstObject as! AGSLayer).load { (error: Error?) in
                    if error == nil {
                        
                        //set viewpoint as the extent of the mapImageLayer
                        if let extent = result?.mapImageLayer?.fullExtent {
                            self?.mapView.setViewpointGeometry(extent, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - Actions
    
    @IBAction func applyAction(_ sender:NSButton) {
        
        //validate input
        let timeInterval = self.datePicker.timeInterval
        
        //if no interval specified
        if timeInterval <= 0 {
            self.showAlert(messageText: "Error", informativeText: "Please select a date range")
        }
        else {
            //get the dates from the date picker
            let fromDate = self.datePicker.dateValue
            let toDate = self.datePicker.dateValue.addingTimeInterval(timeInterval)
            
            //analyze hotspots
            self.analyzeHotspots(fromDate: fromDate, toDate: toDate)
        }
    }
    
    //MARK: - Helper methods
    
    private func showAlert(messageText:String, informativeText:String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
}
