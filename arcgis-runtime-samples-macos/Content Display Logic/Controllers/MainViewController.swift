//
// Copyright 2016 Esri.
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

class MainViewController: NSSplitViewController {
    
    var categories = [Category]() {
        didSet {
            sampleListViewController.categories = categories
        }
    }
    
    @IBOutlet weak var sampleListSplitViewItem: NSSplitViewItem!
    
    var sampleListViewController: SampleListViewController! {
        return sampleListSplitViewItem.viewController as? SampleListViewController
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        sampleListViewController.delegate = self
    }
    
    /// Shows the given category in the right split view item.
    ///
    /// - Parameter category: A category.
    func showCollection(for category: Category) {
        showCollection(for: category.samples)
    }
    
    /// Shows a collection view with the samples in the right split view item.
    ///
    /// - Parameter samples: The samples to display.
    func showCollection(for samples: [Sample]) {
        let sampleCollectionViewController = SampleCollectionViewController(samples: samples)
        sampleCollectionViewController.delegate = self
        showDetailViewController(sampleCollectionViewController)
    }
    
    
    /// Shows a collection view with all the samples in the app.
    func showCollectionForAllSamples() {
        let allSamples = categories.flatMap({ $0.samples })
        showCollection(for: allSamples)
    }
    
    /// Shows the given sample in the right split view item.
    ///
    /// - Parameter sample: A sample.
    func show(sample: Sample) {
        let sampleViewController = SampleViewController(sample: sample)
        showDetailViewController(sampleViewController)
    }
    
    /// Presents the given view controller in a secondary (or detail) context.
    ///
    /// - Parameter viewController: A view controller.
    func showDetailViewController(_ viewController: NSViewController) {
        let oldSplitViewItem = splitViewItems.last!
        removeSplitViewItem(oldSplitViewItem)
        let newSplitViewItem = NSSplitViewItem(viewController: viewController)
        addSplitViewItem(newSplitViewItem)
    }
}

extension MainViewController /* NSSplitViewDelegate */ {
    override func splitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return min(proposedPosition, splitView.bounds.width / 2)
    }
}

extension MainViewController: SampleListViewControllerDelegate {
    func sampleListViewControllerSelectionDidChange(_ controller: SampleListViewController) {
        if let category = controller.selectedCategory {
            showCollection(for: category)
        } else if let sample = controller.selectedSample {
            show(sample: sample)
        }
    }
}

extension MainViewController: SampleCollectionViewControllerDelegate {
    func sampleCollectionViewController(_ controller: SampleCollectionViewController, didSelect sample: Sample) {
        let sampleListViewController = sampleListSplitViewItem.viewController as! SampleListViewController
        sampleListViewController.select(sample)
    }
}
