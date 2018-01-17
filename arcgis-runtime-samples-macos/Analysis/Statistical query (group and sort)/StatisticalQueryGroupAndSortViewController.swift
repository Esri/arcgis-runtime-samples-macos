//
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

class StatisticalQueryGroupAndSortViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate {
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var parametersLabel: NSTextField!
    @IBOutlet weak var resultsLabel: NSTextField!
    @IBOutlet private weak var splitView: NSSplitView!
    @IBOutlet private weak var fieldNamesComboBox: NSComboBox!
    @IBOutlet private weak var statisticTypeComboBox: NSComboBox!
    @IBOutlet private weak var statisticDefinitionsTableView: NSTableView!
    @IBOutlet private weak var groupByFieldsTableView: NSTableView!
    @IBOutlet private weak var orderByFieldsTableView: NSTableView!
    @IBOutlet private weak var statisticQueryResultsOutlineView: NSOutlineView!
    @IBOutlet private weak var removeStatisticDefinitionButton: NSButton!
    @IBOutlet private weak var getStatisticsButton: NSButton!

    private var serviceFeatureTable: AGSServiceFeatureTable!
    private var fieldNames = [String]()
    private var selectedGroupByFieldNames = [String]()
    private var orderByFields = [AGSOrderBy]()
    private var selectedOrderByFields = [AGSOrderBy]()
    private var statisticDefinitions = [AGSStatisticDefinition]()
    private var statisticTypes = ["Average", "Count", "Maximum", "Minimum", "StandardDeviation", "Sum", "Variance"]
    private var statisticRecords = [AGSStatisticRecord]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize feature table
        serviceFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer/3")!)
        
        // Load feature table
        serviceFeatureTable.load(completion: { [weak self] (error) in
            //
            // If there an error, display it
            guard error == nil else {
                self?.showAlert(messageText: "Error", informativeText: "Error while loading feature table :: \(String(describing: error?.localizedDescription))")
                return
            }
            
            // Set title
            let titleTable = self?.serviceFeatureTable.tableName
            let title = "Statistics: \(titleTable!)"
            let style = NSMutableParagraphStyle()
            style.alignment = NSTextAlignment.center
            let attributes = [NSUnderlineStyleAttributeName: NSNumber(value:NSUnderlineStyle.styleSingle.rawValue), NSParagraphStyleAttributeName: style]
            let attributedTitle = NSAttributedString(string: title, attributes: attributes)
            self?.titleLabel.attributedStringValue = attributedTitle
            
            // Get field names
            for field in (self?.serviceFeatureTable.fields)! {
                self?.fieldNames.append(field.name)
            }
            
            // Reload combo box
            self?.fieldNamesComboBox.addItems(withObjectValues: (self?.fieldNames)!)
            
            // Reload table"
            self?.groupByFieldsTableView.reloadData()
        })
        
        // Setup UI Controls
        setupUI()
    }
    
    private func setupUI() {
        //
        // Add border and corner radius
        splitView.wantsLayer = true
        splitView.layer?.cornerRadius = 10
        splitView.layer?.borderWidth = 2
        splitView.layer?.borderColor = NSColor.primaryBlue().cgColor
        
        // Set values for combo boxs
        fieldNamesComboBox.addItems(withObjectValues: fieldNames)
        statisticTypeComboBox.addItems(withObjectValues: statisticTypes)
        
        // Attributes of string
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.center
        let attributes = [NSUnderlineStyleAttributeName: NSNumber(value:NSUnderlineStyle.styleSingle.rawValue), NSParagraphStyleAttributeName: style]
        
        // Set parameters label
        let parametersLabelString = "Query Statistic Parameters"
        let attributedParametersString = NSAttributedString(string: parametersLabelString, attributes: attributes)
        self.parametersLabel.attributedStringValue = attributedParametersString
        
        // Set results label
        let resultsLabelString = "Query Statistic Results"
        let attributedResultsString = NSAttributedString(string: resultsLabelString, attributes: attributes)
        self.resultsLabel.attributedStringValue = attributedResultsString
    }
    
    // MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == statisticDefinitionsTableView {
            return statisticDefinitions.count
        }
        else if tableView == groupByFieldsTableView {
            return fieldNames.count
        }
        else if tableView == orderByFieldsTableView {
            return orderByFields.count
        }
        return 0
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        if tableView == groupByFieldsTableView {
            let buttonState = object as! Int?
            let fieldName = fieldNames[row]
            if buttonState == 1 {
                //
                // Add field to the selected group by fields
                selectedGroupByFieldNames.append(fieldName)
                
                // Add field to order by fields
                let orderBy = AGSOrderBy(fieldName: fieldName, sortOrder: .ascending)
                orderByFields.append(orderBy)
            }
            else {
                //
                // Remove field from selected group by fields
                let index = selectedGroupByFieldNames.index(of: fieldName)
                selectedGroupByFieldNames.remove(at: index!)
                
                // Remove field from the order by fields
                for (i,orderByField) in orderByFields.enumerated().reversed() {
                    if orderByField.fieldName == fieldName {
                        orderByFields.remove(at: i)
                    }
                }
                
                // Remove field from the selected order by fields
                for (i,selectedOrderByField) in selectedOrderByFields.enumerated().reversed() {
                    if selectedOrderByField.fieldName == fieldName {
                        selectedOrderByFields.remove(at: i)
                    }
                }
            }
            
            // Reload order by fields table
            orderByFieldsTableView.reloadData()
        }
        
        if tableView == orderByFieldsTableView {
            let orderByField = orderByFields[row]
            if tableColumn?.identifier == "FieldNameCheckBox" {
                let buttonState = object as! Int?
                if buttonState == 1 {
                    selectedOrderByFields.append(orderByField)
                }
                else {
                    //
                    // Remove field from selected order by fields
                    let index = selectedOrderByFields.index(of: orderByField)
                    selectedOrderByFields.remove(at: index!)
                }
            }
            else if tableColumn?.identifier == "SortOrder" {
                let selectedIndex = object as! Int?
                if let selectedIndex = selectedIndex {
                    orderByField.sortOrder = AGSSortOrder(rawValue: selectedIndex)!
                }
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if tableView == statisticDefinitionsTableView {
            let statisticDefinition = statisticDefinitions[row]
            let statisticTypeString = statisticTypes[statisticDefinition.statisticType.rawValue]
            let stringValue = "\(statisticDefinition.onFieldName) (\(statisticTypeString))"
            return stringValue
        }
        else if tableView == groupByFieldsTableView {
            let fieldName = fieldNames[row]
            let buttonCell = tableColumn?.dataCell(forRow: row) as! NSButtonCell
            buttonCell.title = fieldName
            if selectedGroupByFieldNames.contains(fieldName) {
                return 1
            }
            else {
                return 0
            }
        }
        else if tableView == orderByFieldsTableView {
            let orderByField = orderByFields[row]
            if tableColumn?.identifier == "FieldNameCheckBox" {
                let buttonCell = tableColumn?.dataCell(forRow: row) as! NSButtonCell
                buttonCell.title = orderByField.fieldName
                if selectedOrderByFields.contains(orderByField) {
                    return 1
                }
                else {
                    return 0
                }
            }
            else if tableColumn?.identifier == "SortOrder" {
                let popUpButtonCell = tableColumn?.dataCell(forRow: row) as! NSPopUpButtonCell
                return popUpButtonCell.indexOfItem(withTitle: stringFor(sortOrder: orderByField.sortOrder))
            }
        }
        return nil
    }
    
    // MARK: - NSOutlineViewDataSource
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let statisticRecord = item as? AGSStatisticRecord {
            return statisticRecord.statistics.keys.count
        }
        else {
            return self.statisticRecords.count
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let statisticRecord = item as? AGSStatisticRecord {
            let keys = Array(statisticRecord.statistics.keys)
            let values = Array(statisticRecord.statistics.values)
            return "\(keys[index]): \(values[index])"
        }
        else {
            return statisticRecords[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let statisticRecord = item as? AGSStatisticRecord {
            return statisticRecord.statistics.keys.count > 0
        }
        else {
            return false
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cellView = outlineView.make(withIdentifier: "StatisticRecordCellView", owner: self) as! NSTableCellView
        if let statisticRecord = item as? AGSStatisticRecord {
            var groups = [String]()
            for fieldName in selectedGroupByFieldNames {
                let value = statisticRecord.group[fieldName] as! String
                groups.append("\(value)")
            }
            cellView.textField?.stringValue = groups.joined(separator: ", ")
        }
        else {
            cellView.textField?.stringValue = item as! String
        }
        return cellView
    }
    
    // MARK: - Actions
    
    @IBAction func addStatisticDefinitionAction(_ sender: Any) {
        //
        // Get the selected values
        let fieldName = fieldNames[fieldNamesComboBox.indexOfSelectedItem]
        let statisticType = AGSStatisticType(rawValue: statisticTypeComboBox.indexOfSelectedItem)
        
        // Check whether same statistic definition is already added or not.
        let filteredStatisticDefinitions = statisticDefinitions.filter { $0.onFieldName == fieldName && $0.statisticType == statisticType }
        
        // Add only if it does not exist
        if filteredStatisticDefinitions.isEmpty {
            //
            // Add statistic definition
            let statisticDefinition = AGSStatisticDefinition(onFieldName: fieldName, statisticType: statisticType!, outputAlias: nil)
            statisticDefinitions.append(statisticDefinition)
            
            // Reload table
            statisticDefinitionsTableView.reloadData()
        }
        
        // Enable remove button
        if statisticDefinitions.count > 0 {
            removeStatisticDefinitionButton.isEnabled = true
        }
    }
    
    @IBAction func removeStatisticDefinitionAction(_ sender: Any) {
        //
        // Get selected rows and remove them.
        let selectedIndexes = statisticDefinitionsTableView.selectedRowIndexes
        statisticDefinitionsTableView.beginUpdates()
        statisticDefinitionsTableView.removeRows(at: selectedIndexes, withAnimation: .effectFade)
        statisticDefinitionsTableView.endUpdates()
        
        // Remove selected statistic definitions
        selectedIndexes.forEach { (index) in
            statisticDefinitions.remove(at: index)
        }
        
        // Disable remove button if there is no
        // statistic definitions
        if statisticDefinitions.count == 0 {
            removeStatisticDefinitionButton.isEnabled = false
        }
    }
    
    @IBAction private func getStatisticsAction(_ sender: Any) {
        //
        // There should be at least one statistic
        // definition added to execute the query
        if statisticDefinitions.count == 0 || selectedGroupByFieldNames.count == 0 {
            self.showAlert(messageText: "Error", informativeText: "There sould be at least one statistic definition and one group by field to execute the query.")
            return
        }
        
        // Disable the button
        getStatisticsButton.isEnabled = false
        
        // Create the parameters with statistic definitions
        let statisticsQueryParameters = AGSStatisticsQueryParameters(statisticDefinitions: statisticDefinitions)
        
        // Set selected group by fields
        statisticsQueryParameters.groupByFieldNames = selectedGroupByFieldNames
        
        // Set selected order by fields
        statisticsQueryParameters.orderByFields = selectedOrderByFields
        
        // Execute the statistical query with parameters
        serviceFeatureTable?.queryStatistics(with: statisticsQueryParameters, completion: { [weak self] (statisticsQueryResult, error) in
            //
            // Enable the button
            self?.getStatisticsButton.isEnabled = true
            
            // If there an error, display it
            guard error == nil else {
                self?.showAlert(messageText: "Error", informativeText: "Error while executing statistics query :: \(String(describing: error?.localizedDescription))")
                return
            }
            
            let statisticRecords = statisticsQueryResult?.statisticRecordEnumerator().allObjects
            if let statisticRecords = statisticRecords, statisticRecords.count > 0 {
                //
                // Store results to show in the outline view
                self?.statisticRecords = statisticRecords
                
                // Reload outline view data
                self?.statisticQueryResultsOutlineView.reloadData()
            }
        })
    }
    
    @IBAction func resetAction(_ sender: Any) {
        //
        // Reset all collections and reload tables
        statisticDefinitions.removeAll()
        statisticDefinitionsTableView.reloadData()
        selectedGroupByFieldNames.removeAll()
        groupByFieldsTableView.reloadData()
        orderByFields.removeAll()
        selectedOrderByFields.removeAll()
        orderByFieldsTableView.reloadData()
        statisticRecords.removeAll()
        statisticQueryResultsOutlineView.reloadData()
        
        // Select first item of the combo boxes
        fieldNamesComboBox.selectItem(at: 0)
        statisticTypeComboBox.selectItem(at: 0)
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(messageText:String, informativeText:String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
    
    private func stringFor(sortOrder: AGSSortOrder) -> String {
        switch sortOrder {
        case .ascending:
            return "Ascending"
        case .descending:
            return "Descending"
        }
    }
}

