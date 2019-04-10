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

/// A generic view controller to display a progress bar, percentage, and cancel button.
class ProgressViewController: NSViewController {
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var progressLabelField: NSTextField!
    
    private var progressObservation: NSKeyValueObservation?
    
    /// The progress object used to update the UI
    private let progress: Progress
    /// The text to display alongside the completion percentage.
    private let operationLabel: String
    
    init(progress: Progress, operationLabel: String = "") {
        self.progress = progress
        
        let suffix = !operationLabel.isEmpty ? ": " : ""
        self.operationLabel = "\(operationLabel)\(suffix)"
        
        super.init(nibName: "ProgressView", bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        // observe progress
        progressObservation = progress.observe(\.fractionCompleted, options: .initial, changeHandler: { [weak self] (_, _) in
            // run UI updates on the main thread
            DispatchQueue.main.async {
                self?.updateProgressUI()
            }
        })
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        // remove progress observation
        progressObservation = nil
    }
    
    private func updateProgressUI() {
        // update progress label
        progressLabelField?.stringValue = "\(operationLabel)\(progress.localizedDescription!)"
        // update progress indicator
        progressIndicator?.doubleValue = progress.fractionCompleted
    }
    
    @IBAction func cancelAction(_ button: NSButton) {
        // cancel the progress
        progress.cancel()
    }
}
