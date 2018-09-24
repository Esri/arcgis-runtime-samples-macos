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

protocol OfflineMapProgressViewControllerDelegate: AnyObject {
    
    func progressViewControllerDidCancel(_ progressViewController:OfflineMapProgressViewController)
}

class OfflineMapProgressViewController: NSViewController {
    
    @IBOutlet weak var progressView: NSProgressIndicator?
    @IBOutlet weak var progressLabel: NSTextField?
    
    weak var delegate:OfflineMapProgressViewControllerDelegate?
     
    private var progressObservation: NSKeyValueObservation?
    
    //the progress object that will be used to update the UI
    var progress: Progress?{
        didSet{
            //add observer to track progress
            progressObservation = progress?.observe(\.fractionCompleted, changeHandler: {[weak self] (progress, change) in
                DispatchQueue.main.async {
                    self?.updateProgressUI()
                }
            })
            updateProgressUI()
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        updateProgressUI()
    }
    
    func updateProgressUI(){
        
        guard let progress = progress else {
            return
        }
        
        //update progress label
        progressLabel?.stringValue = "Generating Offline Map: "+progress.localizedDescription
        
        //update progress view
        progressView?.doubleValue = progress.fractionCompleted
    }
    
    @IBAction func cancelAction(_ button:NSButton) {
        // notify the delegate that cancel was pressed
        delegate?.progressViewControllerDidCancel(self)
    }
    
    deinit {
        //remove observation
        progressObservation = nil
    }
}
