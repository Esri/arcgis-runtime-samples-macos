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

/// The protocol you implement to respond as the user interacts with the
/// document browser.
protocol SampleListViewControllerDelegate: AnyObject {
    /// Called in response to the sample list selection changing.
    ///
    /// - Parameter controller: The current sample list.
    func sampleListViewControllerSelectionDidChange(_ controller: SampleListViewController)
}

/// A view controller that manages an interface for displaying a list of samples
/// by category.
class SampleListViewController: NSViewController {
    /// The delegate of the view controller.
    weak var delegate: SampleListViewControllerDelegate?
    /// The categories displayed by the view controller.
    var categories = [Category]() {
        didSet {
            categoriesDidChange()
        }
    }
    
    /// Selects the given category in the list.
    ///
    /// - Parameter category: The category to select.
    func select(_ category: Category) {
        guard isViewLoaded else { return }
        guard let boxedCategory = boxedCategories[category] else { return }
        let index = outlineView.row(forItem: boxedCategory)
        outlineView.selectRowIndexes([index], byExtendingSelection: false)
    }
    
    /// The category currently selected in the list or `nil` if no category
    /// is selected.
    var selectedCategory: Category? {
        guard isViewLoaded else { return nil }
        let selectedRow = outlineView.selectedRow
        if selectedRow != -1, let selectedBox = outlineView.item(atRow: selectedRow) as? Box<Category> {
            return selectedBox.value
        } else {
            return nil
        }
    }
    
    /// Selects the given sample in the list. This will expand the sample's
    /// category if it isn't already.
    ///
    /// - Parameter sample: The sample to select.
    func select(_ sample: Sample) {
        guard isViewLoaded else { return }
        guard let boxedSample = boxedSamples[sample] else { return }

        let row = outlineView.row(forItem: boxedSample)
        // Is the sample's category expanded?
        if row != -1 {
            // Yes. We just need to select it if it isn't already.
            if !outlineView.isRowSelected(row) {
                outlineView.selectRowIndexes([row], byExtendingSelection: false)
            }
        } else {
            // No. We need to expand the category before selecting it.
            let categoryToExpand: Category
            if let category = selectedCategory, category.samples.contains(sample) {
                categoryToExpand = category
            } else {
                // This is a major hack. If the selected category isn't the
                // sample's category, assume that the sample was a selected
                // search result. In that case, we want to skip the "Featured"
                // category to get the sample's actual category.
                categoryToExpand = categories.dropFirst().first(where: { $0.samples.contains(sample) })!
            }
            outlineView.expandItem(boxedCategories[categoryToExpand]!)
            let index = outlineView.row(forItem: boxedSample)
            outlineView.selectRowIndexes([index], byExtendingSelection: false)
        }
    }
    
    /// The sample currently selected in the list or `nil` if no sample is
    /// selected.
    var selectedSample: Sample? {
        guard isViewLoaded else { return nil }
        let selectedRow = outlineView.selectedRow
        if selectedRow != -1, let selectedBox = outlineView.item(atRow: selectedRow) as? Box<Sample> {
            return selectedBox.value
        } else {
            return nil
        }
    }
    
    /// Indicates whether the given category is expanded.
    ///
    /// - Parameter category: A category in the list.
    /// - Returns: `true` if the category is expanded, otherwise `false`.
    func isExpanded(_ category: Category) -> Bool {
        guard isViewLoaded else { return false }
        guard let boxedCategory = boxedCategories[category] else { return false }
        return outlineView.isItemExpanded(boxedCategory)
    }
    
    @IBOutlet private weak var outlineView: NSOutlineView!
    
    private func categoriesDidChange() {
        // Box categories and samples.
        var boxedCategories = [Category: Box<Category>]()
        var boxedSamples = [Sample: Box<Sample>]()
        for category in categories {
            boxedCategories[category] = Box(value: category)
            for sample in category.samples {
                boxedSamples[sample] = Box(value: sample)
            }
        }
        self.boxedCategories = boxedCategories
        self.boxedSamples = boxedSamples
        // Reload the outline view (if it exists).
        guard isViewLoaded else { return }
        outlineView.reloadData()
        // Select the first category.
        select(categories.first!)
    }
    
    // Why manually box categories and samples? Good question.
    // While Swift would box them automatically, it would box into a new
    // instance each time. Because NSOutlineView compares items by their memory
    // address, two boxed instances of the same value would never be equal.
    // By boxing ourselves, we ensure that item comparison actually works.
    //
    // Why not make Category and Sample reference types? Another good question.
    // There are a number of reasons, but one reason is because they don't need
    // to be reference types anywhere else. Using value types is only
    // problematic for this class, so I've chosen to solve the problem inside of
    // this class. -Philip
    
    private class Box<T> {
        let value: T
        
        init(value: T) {
            self.value = value
        }
    }
    
    private var boxedCategories = [Category: Box<Category>]()
    private var boxedSamples = [Sample: Box<Sample>]()
}

extension SampleListViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let boxedCategory = item as? Box<Category> {
            return boxedCategory.value.samples.count
        } else {
            return categories.count
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return item is Box<Category>
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let boxedCategory = item as? Box<Category> {
            return boxedSamples[boxedCategory.value.samples[index]]!
        } else {
            return boxedCategories[categories[index]]!
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        switch item {
        case let boxedCategory as Box<Category>:
            return boxedCategory.value.name
        case let boxedSample as Box<Sample>:
            return boxedSample.value.name
        default:
            fatalError()
        }
    }
}

extension SampleListViewController: NSOutlineViewDelegate {
    func outlineViewSelectionDidChange(_ notification: Notification) {
        delegate?.sampleListViewControllerSelectionDidChange(self)
    }
}
