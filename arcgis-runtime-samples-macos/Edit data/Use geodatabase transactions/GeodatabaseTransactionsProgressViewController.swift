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

class GeodatabaseTransactionsProgressViewController: NSViewController {
    
    @IBOutlet weak var progressView: NSProgressIndicator?
    @IBOutlet weak var progressLabel: NSTextField?
    
    private var progressObservation: NSKeyValueObservation?
    
    ///The progress object used to update the UI
    var progress: Progress?{
        didSet{
            //observe here in case the view appears before progress is set
            observeProgress()
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        //observe here in case progress is set before the view is loaded
        observeProgress()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        //remove observation
        progressObservation = nil
    }
    
    func observeProgress(){
        //observe progress
        progressObservation = progress?.observe(\.fractionCompleted,  options: .initial, changeHandler: {[weak self] (_, _) in
            DispatchQueue.main.async {
                self?.updateProgressUI()
            }
        })
    }
    
    func updateProgressUI(){
        
        guard let progress = progress else {
            return
        }
        
        //update progress label
        progressLabel?.stringValue = "Downloading Geodatabase: \(progress.localizedDescription!)"
        
        //update progress view
        progressView?.doubleValue = progress.fractionCompleted
    }
    
    var cancelHandler: ((GeodatabaseTransactionsProgressViewController) -> Void)?
    
    @IBAction func cancelAction(_ button:NSButton) {
        // run the cancel handler
        cancelHandler?(self)
    }
}
