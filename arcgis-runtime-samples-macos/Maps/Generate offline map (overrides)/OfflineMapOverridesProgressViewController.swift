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

protocol OfflineMapOverridesProgressViewControllerDelegate: AnyObject {
    
    func progressViewControllerDidCancel(_ progressViewController:OfflineMapOverridesProgressViewController)
}

class OfflineMapOverridesProgressViewController: NSViewController {
    
    @IBOutlet var progressView: NSProgressIndicator!
    @IBOutlet var progressLabel: NSTextField!
    @IBOutlet var cancelButton: NSButton!
    
    weak var delegate:OfflineMapOverridesProgressViewControllerDelegate?
    
    //the progress object that will be used to update the UI
    var progress: Progress?{
        didSet{
            //remove observer if an old value exists
            oldValue?.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
            
            //add observer to track progress
            progress?.addObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), options: .new, context: nil)
        }
    }
    
    @IBAction func cancelAction(_ button:NSButton) {
        // notify the delegate that cancel was pressed
        delegate?.progressViewControllerDidCancel(self)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == #keyPath(Progress.fractionCompleted) {
            
            //run UI updates on the main thread
            DispatchQueue.main.async { [weak self] in
                
                guard let strongSelf = self,
                    let progress = strongSelf.progress else {
                        return
                }
                
                //update progress label
                strongSelf.progressLabel.stringValue = "Generating Offline Map: "+progress.localizedDescription
                
                //update progress view
                strongSelf.progressView.doubleValue = progress.fractionCompleted
            }
        }
    }
    
    deinit {
        //set progress to nil to trigger removal of observer
        progress = nil
    }
}
