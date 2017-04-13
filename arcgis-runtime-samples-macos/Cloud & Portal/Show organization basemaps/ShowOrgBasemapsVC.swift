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

class ShowOrgBasemapsVC: NSViewController, BasemapsCollectionVCDelegate, PortalSettingsVCDelegate {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var changeBasemapButton:NSButton!
    @IBOutlet var containerView:NSView!
    
    private var portal:AGSPortal!
    private var portalURLString = "https://www.arcgis.com"
    private var anonymousUser = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //OAuth setup
        let config = AGSOAuthConfiguration(portalURL: URL(string: self.portalURLString), clientID: "vVHDSfKfdKBs8lkA", redirectURL: nil)
        AGSAuthenticationManager.shared().oAuthConfigurations.add(config)
        AGSAuthenticationManager.shared().credentialCache.removeAllCredentials()
        
        //initialize map with basemap
        let map = AGSMap(basemap: AGSBasemap.terrainWithLabels())
        
        //initial viewpoint
        map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -13176752, y: 4090404, spatialReference: AGSSpatialReference.webMercator()), scale: 100000)
        
        //assign map to the map view
        self.mapView.map = map
        
        //initialize service feature table using url
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Energy/Geology/FeatureServer/9")!)
        
        //create a feature layer
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        
        //add the feature layer to the operational layers
        map.operationalLayers.add(featureLayer)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        //stylize container view
        self.containerView.layer?.cornerRadius = 10
        self.containerView.layer?.masksToBounds = true
    }
    
    func showBasemapsCollection() {
        let basemapsCollectionViewController = self.storyboard!.instantiateController(withIdentifier: "BasemapsCollectionViewController") as! BasemapsCollectionViewController
        basemapsCollectionViewController.portal = self.portal
        basemapsCollectionViewController.delegate = self
        
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = CGSize(width: 500, height: 300)
        popover.contentViewController = basemapsCollectionViewController
        popover.show(relativeTo: self.changeBasemapButton.frame, of: self.containerView, preferredEdge: NSRectEdge.maxY)
    }
    
    
    //MARK: - Actions
    
    @IBAction func changeBasemapAction(sender:NSButton) {
        
        self.portal = AGSPortal(url: URL(string: self.portalURLString)!, loginRequired: !self.anonymousUser)
        self.portal.load { [weak self] (error: Error?) in
            if let error = error {
                print(error)
            }
            else {
                self?.showBasemapsCollection()
            }
        }
    }
    
    //MARK: - PortalSettingsVCDelegate
    
    func portalSettingsViewControllerDidFinish(_ portalSettingsViewController: PortalSettingsViewController) {
        
        //get updated settings
        self.anonymousUser = portalSettingsViewController.anonymousUser
        self.portalURLString = portalSettingsViewController.portalURLString
        
        //dismiss popover
        self.dismissViewController(portalSettingsViewController)
    }
    
    //MARK: - BasemapsCollectionVCDelegate
    
    func basemapsCollectionViewController(_ basemapsCollectionViewController: BasemapsCollectionViewController, didSelectBasemap basemap: AGSBasemap) {
        
        self.mapView.map?.basemap = basemap
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
       
        if segue.identifier == "PortalSettingsSegue" {
            
            let controller = segue.destinationController as! PortalSettingsViewController
            controller.delegate = self
            
            
            controller.anonymousUser = self.anonymousUser
            controller.portalURLString = self.portalURLString
        }
    }
}
