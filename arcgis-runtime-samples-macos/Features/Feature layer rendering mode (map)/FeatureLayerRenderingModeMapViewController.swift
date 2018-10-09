//
// Copyright © 2018 Esri.
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

/// A view controller that manages the interface of the Feature Layer Rendering
/// Mode (Map) sample.
class FeatureLayerRenderingModeMapViewController: NSViewController {
    
    /// The map displayed in the static map view.
    let staticMap = AGSMap()
    /// The map displayed in the dynamic map view.
    let dynamicMap = AGSMap()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        let geologyFeatureService = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Energy/Geology/FeatureServer")!
        /// The url of the Fault layer of the Geology Feature Service.
        let geologyFeatureServiceFaultLayerURL = geologyFeatureService.appendingPathComponent("0")
        /// The url of the Contacts layer of the Geology Feature Service.
        let geologyFeatureServiceContactsLayerURL = geologyFeatureService.appendingPathComponent("8")
        /// The url of the Outcrop layer of the Geology Feature Service.
        let geologyFeatureServiceOutcropLayerURL = geologyFeatureService.appendingPathComponent("9")
        
        /// The URLs of the the feature service layers for this sample.
        let featureServiceLayerURLs: [URL] = [
            geologyFeatureServiceFaultLayerURL,
            geologyFeatureServiceContactsLayerURL,
            geologyFeatureServiceOutcropLayerURL
        ]
        
        // Create the static feature layers and add them to the static map.
        let staticFeatureLayers = featureServiceLayerURLs.map { makeFeatureService(url: $0, renderingMode: .static) }
        staticMap.operationalLayers.addObjects(from: staticFeatureLayers)
        
        // Create the dynamic feature layers and add them to the dynamic map.
        let dynamicFeatureLayers = featureServiceLayerURLs.map { makeFeatureService(url: $0, renderingMode: .dynamic) }
        dynamicMap.operationalLayers.addObjects(from: dynamicFeatureLayers)
    }
    
    /// The map view that displays the static feature layers.
    @IBOutlet weak var staticMapView: AGSMapView!
    /// The map view that displays the dynamic feature layers.
    @IBOutlet weak var dynamicMapView: AGSMapView!
    /// The button used for zooming in and out.
    @IBOutlet weak var zoomButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the map views.
        staticMapView.map = staticMap
        staticMapView.interactionOptions.isEnabled = false
        dynamicMapView.map = dynamicMap
        dynamicMapView.interactionOptions.isEnabled = false
        
        // Start from the zoomed in viewpoint.
        zoomIn(animated: false)
    }
    
    /// Creates a feature layer that renders the features of a layer at the
    /// given URL with the given rendering mode.
    ///
    /// - Parameters:
    ///   - url: A URL of a layer in a feature service.
    ///   - renderingMode: A rendering mode.
    /// - Returns: A new `AGSFeatureLayer` object.
    func makeFeatureService(url: URL, renderingMode: AGSFeatureRenderingMode) -> AGSFeatureLayer {
        let serviceFeatureTable = AGSServiceFeatureTable(url: url)
        let featureLayer = AGSFeatureLayer(featureTable: serviceFeatureTable)
        featureLayer.renderingMode = renderingMode
        return featureLayer
    }
    
    // MARK: - Zooming
    
    /// The range of map scale values for the zoom animation.
    let scaleRange = 50_000.0...650_000.0
    
    /// The states of the zoom animation.
    enum ZoomState {
        case zoomedIn
        case zoomingOut
        case zoomedOut
        case zoomingIn
    }
    
    /// The current state of the zoom animation.
    private var zoomState = ZoomState.zoomedIn
    
    /// Triggers a zoom animation. Called in response to the Zoom button being
    /// clicked.
    @IBAction func zoom(_ sender: Any) {
        let animated = true
        switch zoomState {
        case .zoomedIn, .zoomingIn:
            zoomOut(animated: animated)
        case .zoomedOut, .zoomingOut:
            zoomIn(animated: animated)
        }
    }
    
    /// Animates the map to the zoomed in viewpoint.
    func zoomIn(animated: Bool) {
        // Set the viewpoint of the map views.
        let point = AGSPoint(x: -118.45, y: 34.395, spatialReference: .wgs84())
        let viewpoint = AGSViewpoint(center: point, scale: scaleRange.lowerBound, rotation: 90)
        setViewpoints(to: viewpoint, animated: animated) { [weak self] (finished) in
            guard finished else { return }
            self?.zoomState = .zoomedIn
        }
        // Update the zoom button.
        zoomButton.title = "Zoom Out"
        // Update the zoom state.
        zoomState = .zoomingIn
    }
    
    /// Animates the map to the zoomed out viewpoint.
    func zoomOut(animated: Bool) {
        // Set the viewpoint of the map views.
        let point = AGSPoint(x: -118.37, y: 34.46, spatialReference: .wgs84())
        let viewpoint = AGSViewpoint(center: point, scale: scaleRange.upperBound, rotation: 0)
        setViewpoints(to: viewpoint, animated: animated) { [weak self] (finished) in
            guard finished else { return }
            self?.zoomState = .zoomedOut
        }
        // Update the zoom button.
        zoomButton.title = "Zoom In"
        // Update the zoom state.
        zoomState = .zoomingOut
    }
    
    /// Sets the viewpoint of both map views to the given viewpoint.
    ///
    /// - Parameters:
    ///   - viewpoint: The viewpoint to be set.
    ///   - animated: Specify `true` if the viewpoint change should be animated.
    ///   - completion: A closure to execute after the animation has finished on
    ///   both map views.
    func setViewpoints(to viewpoint: AGSViewpoint, animated: Bool, completion: @escaping (Bool) -> Void) {
        var staticAnimationFinished = false
        var dynamicAnimationFinished = false
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dispatchGroup.enter()
        setViewpoint(viewpoint, of: staticMapView, animated: animated) { (finished) in
            staticAnimationFinished = finished
            dispatchGroup.leave()
        }
        setViewpoint(viewpoint, of: dynamicMapView, animated: animated) { (finished) in
            dynamicAnimationFinished = finished
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) {
            completion(staticAnimationFinished && dynamicAnimationFinished)
        }
    }
    
    /// Changes the viewpoint of the given map view.
    ///
    /// - Parameters:
    ///   - viewpoint: The viewpoint to be set.
    ///   - mapView: The mapview whose viewpoint should be set.
    ///   - animated: Specify `true` if the viewpoint change should be animated.
    ///   - completion: A closure to execute after the animation has finished.
    func setViewpoint(_ viewpoint: AGSViewpoint, of mapView: AGSMapView, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        let duration: TimeInterval
        if animated {
            // Determine the duration based on how close the map view's current
            // scale is to the target scale.
            let deltaScale = abs(viewpoint.targetScale - mapView.mapScale)
            duration = 5 * deltaScale / (scaleRange.upperBound - scaleRange.lowerBound)
        } else {
            duration = 0
        }
        mapView.setViewpoint(viewpoint, duration: duration, completion: completion)
    }
}
