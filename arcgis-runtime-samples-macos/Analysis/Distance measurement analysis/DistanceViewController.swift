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

class DistanceViewController: NSViewController {
    var locationDistanceMeasurement: AGSLocationDistanceMeasurement? {
        didSet {
            updateMeasurementLabels()
            locationDistanceMeasurement?.measurementChangedHandler = { [weak self] _, _, _ in
                DispatchQueue.main.async {
                    self?.updateMeasurementLabels()
                }
            }
        }
    }
    
    @IBOutlet weak var directMeasurementLabel: NSTextField!
    @IBOutlet weak var horizontalMeasurementLabel: NSTextField!
    @IBOutlet weak var verticalMeasurementLabel: NSTextField!
    
    @IBAction func useImperialUnitSystem(_ sender: Any) {
        locationDistanceMeasurement?.unitSystem = .imperial
    }
    
    @IBAction func useMetricUnitSystem(_ sender: Any) {
        locationDistanceMeasurement?.unitSystem = .metric
    }
    
    let measurementFormatter: MeasurementFormatter = {
        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.numberFormatter.minimumFractionDigits = 2
        measurementFormatter.numberFormatter.maximumFractionDigits = 2
        return measurementFormatter
    }()
    
    func updateMeasurementLabels() {
        if let measurement = locationDistanceMeasurement,
            measurement.startLocation != measurement.endLocation,
            let directDistance = measurement.directDistance,
            let horizontalDistance = measurement.horizontalDistance,
            let verticalDistance = measurement.verticalDistance {
            directMeasurementLabel.stringValue = measurementFormatter.string(from: Measurement(distance: directDistance))
            horizontalMeasurementLabel.stringValue = measurementFormatter.string(from: Measurement(distance: horizontalDistance))
            verticalMeasurementLabel.stringValue = measurementFormatter.string(from: Measurement(distance: verticalDistance))
        } else {
            directMeasurementLabel.stringValue = "--"
            horizontalMeasurementLabel.stringValue = "--"
            verticalMeasurementLabel.stringValue = "--"
        }
        directMeasurementLabel.sizeToFit()
        horizontalMeasurementLabel.sizeToFit()
        verticalMeasurementLabel.sizeToFit()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateMeasurementLabels()
    }
}

extension Measurement where UnitType == Unit {
    /// Creates a measurement from an ArcGIS distance.
    ///
    /// - Parameter distance: An `AGSDistance` object.
    init(distance: AGSDistance) {
        let unit = Unit(symbol: distance.unit.abbreviation)
        let value = distance.value
        self.init(value: value, unit: unit)
    }
}
