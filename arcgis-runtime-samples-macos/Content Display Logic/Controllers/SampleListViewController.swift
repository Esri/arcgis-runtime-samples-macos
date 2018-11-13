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
    
    func deselectAllOutlineViewCells() {
        outlineView.deselectAll(nil)
    }
    
    /// Selects the given category in the list.
    ///
    /// - Parameter category: The category to select.
    func select(_ category: Category) {
        guard isViewLoaded else { return }
        guard let categoryItem = categoryItems[category] else { return }
        let index = outlineView.row(forItem: categoryItem)
        outlineView.selectRowIndexes([index], byExtendingSelection: false)
    }
    
    /// The category currently selected in the list or `nil` if no category
    /// is selected.
    var selectedCategory: Category? {
        guard isViewLoaded else { return nil }
        let selectedRow = outlineView.selectedRow
        if selectedRow != -1, let selectedItem = outlineView.item(atRow: selectedRow) as? CategoryItem {
            return selectedItem.value
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
        guard let sampleItem = sampleItems[sample] else { return }
        
        let categoryToExpand: Category
        if let category = selectedCategory, category.samples.contains(sample) {
            categoryToExpand = category
        } else {
            categoryToExpand = categories.first(where: { $0.samples.contains(sample) })!
        }
        outlineView.expandItem(categoryItems[categoryToExpand]!)
        let index = outlineView.row(forItem: sampleItem)
        outlineView.selectRowIndexes([index], byExtendingSelection: false)
    }
    
    /// The sample currently selected in the list or `nil` if no sample is
    /// selected.
    var selectedSample: Sample? {
        guard isViewLoaded else { return nil }
        let selectedRow = outlineView.selectedRow
        if selectedRow != -1, let selectedItem = outlineView.item(atRow: selectedRow) as? SampleItem {
            return selectedItem.value
        } else {
            return nil
        }
    }
    
    func expand(_ category: Category) {
        guard let categoryItem = categoryItems[category] else { return }
        outlineView?.expandItem(categoryItem)
    }
    
    /// Indicates whether the given category is expanded.
    ///
    /// - Parameter category: A category in the list.
    /// - Returns: `true` if the category is expanded, otherwise `false`.
    func isExpanded(_ category: Category) -> Bool {
        guard isViewLoaded else { return false }
        guard let categoryItem = categoryItems[category] else { return false }
        return outlineView.isItemExpanded(categoryItem)
    }
    
    @IBOutlet private weak var outlineView: NSOutlineView!
    
    /// An item displayed in an outline view.
    ///
    /// `NSOutlineView` compares items based on identity. That means that two
    /// identical instances of a Swift value type passed to `NSOutlineView` will
    /// never compare as equal. Use this class to create wrapped instances of
    /// Swift value types that you can pass to `NSOutlineView` and compare to
    /// items returned by `NSOutlineView` methods.
    private class OutlineViewItem<T> {
        let value: T
        
        init(value: T) {
            self.value = value
        }
    }
    
    /// An `OutlineViewItem` that wraps an instace of `Category`.
    private typealias CategoryItem = OutlineViewItem<Category>
    /// An `OutlineViewItem` that wraps an instace of `Sample`.
    private typealias SampleItem = OutlineViewItem<Sample>
    
    /// The category items used to populate the outline view.
    private var categoryItems = [Category: CategoryItem]()
    /// The sample items used to populate the outline view.
    private var sampleItems = [Sample: SampleItem]()
    
    private func categoriesDidChange() {
        // Wrap categories and samples.
        let lazyCategories = categories.lazy
        categoryItems = Dictionary(uniqueKeysWithValues: lazyCategories.map { ($0, CategoryItem(value: $0)) })
        let allSamples = Set(lazyCategories.flatMap { $0.samples })
        sampleItems = Dictionary(uniqueKeysWithValues: allSamples.lazy.map { ($0, SampleItem(value: $0)) })
        // Reload the outline view (if it exists).
        guard isViewLoaded else { return }
        outlineView.reloadData()
        // Select the first category.
        select(categories.first!)
    }
}

extension SampleListViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let categoryItem = item as? CategoryItem {
            return categoryItem.value.samples.count
        } else {
            return categories.count
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return item is CategoryItem
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let categoryItem = item as? CategoryItem {
            return sampleItems[categoryItem.value.samples[index]]!
        } else {
            return categoryItems[categories[index]]!
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        switch item {
        case let categoryItem as CategoryItem:
            return categoryItem.value.name
        case let sampleItem as SampleItem:
            return sampleItem.value.name
        default:
            return nil
        }
    }
}

extension SampleListViewController: NSOutlineViewDelegate {
    func outlineViewSelectionDidChange(_ notification: Notification) {
        delegate?.sampleListViewControllerSelectionDidChange(self)
    }
}
