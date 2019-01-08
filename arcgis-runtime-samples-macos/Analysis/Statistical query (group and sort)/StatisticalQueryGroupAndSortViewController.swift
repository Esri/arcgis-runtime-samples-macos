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

import Cocoa
import ArcGIS

class StatisticalQueryGroupAndSortViewController: NSViewController {
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
    @IBOutlet private weak var addStatisticsDefinitionButton: NSButton!
    @IBOutlet private weak var removeStatisticDefinitionButton: NSButton!
    @IBOutlet private weak var getStatisticsButton: NSButton!

    private var serviceFeatureTable: AGSServiceFeatureTable?
    private var fieldNames = [String]()
    private var selectedGroupByFieldNames = [String]()
    private var orderByFields = [AGSOrderBy]()
    private var selectedOrderByFields = [AGSOrderBy]()
    private var statisticDefinitions = [AGSStatisticDefinition]()
    private var statisticTypes = ["Average", "Count", "Maximum", "Minimum", "StandardDeviation", "Sum", "Variance"]
    private var statisticRecords = [AGSStatisticRecord]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let serviceURL = URL(string: "https://services.arcgis.com/jIL9msH9OI208GCb/arcgis/rest/services/Counties_Obesity_Inactivity_Diabetes_2013/FeatureServer/0")!
        
        // Initialize feature table
        let serviceFeatureTable = AGSServiceFeatureTable(url: serviceURL)
        self.serviceFeatureTable = serviceFeatureTable
        
        // Load feature table
        serviceFeatureTable.load(completion: { [weak self] (error) in
            // If there an error, display it
            if let error = error {
                self?.showAlert(messageText: "Error", informativeText: "Error while loading feature table: \(error.localizedDescription)")
            } else {
                self?.didLoadServiceFeatureTable(serviceFeatureTable)
            }
        })
        
        // Setup UI Controls
        setupUI()
    }
    
    private func didLoadServiceFeatureTable(_ serviceFeatureTable: AGSServiceFeatureTable) {
        // Set title
        let title = "Statistics: \(serviceFeatureTable.tableName)"
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .paragraphStyle: style
        ]
        let attributedTitle = NSAttributedString(string: title, attributes: attributes)
        titleLabel.attributedStringValue = attributedTitle
        
        var numericFieldNames = [String]()
        for field in serviceFeatureTable.fields {
            if field.type != .OID,
                field.type != .globalID {
                fieldNames.append(field.name)
            }
            if field.type == .double ||
                field.type == .float ||
                field.type == .int32 ||
                field.type == .int16 {
                numericFieldNames.append(field.name)
            }
        }
        // Load the combo box
        fieldNamesComboBox.addItems(withObjectValues: numericFieldNames)
        
        // Reload table"
        groupByFieldsTableView.reloadData()
    }
    
    private func setupUI() {
        // Add border and corner radius
        splitView.wantsLayer = true
        splitView.layer?.cornerRadius = 10
        splitView.layer?.borderWidth = 2
        splitView.layer?.borderColor = NSColor.primaryBlue.cgColor
        
        // Set values for combo box
        statisticTypeComboBox.addItems(withObjectValues: statisticTypes)
        
        // Attributes of string
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .paragraphStyle: style
        ]
        
        // Set parameters label
        let parametersLabelString = "Query Statistic Parameters"
        let attributedParametersString = NSAttributedString(string: parametersLabelString, attributes: attributes)
        parametersLabel.attributedStringValue = attributedParametersString
        
        // Set results label
        let resultsLabelString = "Query Statistic Results"
        let attributedResultsString = NSAttributedString(string: resultsLabelString, attributes: attributes)
        resultsLabel.attributedStringValue = attributedResultsString
    }
    
    // MARK: - Actions
    
    @IBAction func comboBoxAction(_ sender: NSComboBox) {
        // Both a field name and statistic type must be specified in order to add a definition
        let canAddDefinition = fieldNamesComboBox.indexOfSelectedItem >= 0 && statisticTypeComboBox.indexOfSelectedItem >= 0
        // Set the enabled state of the add button
        addStatisticsDefinitionButton.isEnabled = canAddDefinition
    }
    
    @IBAction func addStatisticDefinitionAction(_ sender: Any) {
        // Get the selected values
        guard let statisticType = AGSStatisticType(rawValue: statisticTypeComboBox.indexOfSelectedItem) else {
            print("Could not determine AGSStatisticType from UI: \(statisticTypeComboBox.indexOfSelectedItem)")
            return
        }
        let fieldName = fieldNamesComboBox.objectValues[fieldNamesComboBox.indexOfSelectedItem] as! String
        
        // Check whether same statistic definition is already added or not.
        let filteredStatisticDefinitions = statisticDefinitions.filter { $0.onFieldName == fieldName && $0.statisticType == statisticType }
        
        // Add only if it does not exist
        if filteredStatisticDefinitions.isEmpty {
            // Add statistic definition
            let statisticDefinition = AGSStatisticDefinition(onFieldName: fieldName, statisticType: statisticType, outputAlias: nil)
            statisticDefinitions.append(statisticDefinition)
            
            // Reload table
            statisticDefinitionsTableView.reloadData()
        }
        // Enable the removal button if needed
        setRemoveStatisticButtonEnabledState()
    }
    
    @IBAction func removeStatisticDefinitionAction(_ sender: Any) {
        // Get selected rows and remove them.
        let selectedIndexes = statisticDefinitionsTableView.selectedRowIndexes
        statisticDefinitionsTableView.beginUpdates()
        statisticDefinitionsTableView.removeRows(at: selectedIndexes, withAnimation: NSTableView.AnimationOptions.effectFade)
        statisticDefinitionsTableView.endUpdates()
        
        // Find and remove the selected statistic definitions
        let selectedDefinitions = Set(selectedIndexes.map { statisticDefinitions[$0] })
        statisticDefinitions.removeAll { (definition) -> Bool in
            selectedDefinitions.contains(definition)
        }

        // Disable the removal button if needed
        setRemoveStatisticButtonEnabledState()
    }
    
    @IBAction private func getStatisticsAction(_ sender: Any) {
        // There should be at least one statistic
        // definition added to execute the query
        guard !statisticDefinitions.isEmpty,
            !selectedGroupByFieldNames.isEmpty else {
            self.showAlert(messageText: "Error", informativeText: "There sould be at least one statistic definition and one group by field to execute the query.")
            return
        }
        
        guard let serviceFeatureTable = serviceFeatureTable else {
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
        serviceFeatureTable.queryStatistics(with: statisticsQueryParameters, completion: { [weak self] (statisticsQueryResult, error) in
            guard let self = self else {
                return
            }
            
            // Enable the button
            defer {
                self.getStatisticsButton.isEnabled = true
            }
            
            // If there an error, display it
            if let error = error {
                self.showAlert(messageText: "Error", informativeText: "Error while executing statistics query: \(error.localizedDescription)")
                return
            } else if let statisticRecords = statisticsQueryResult?.statisticRecordEnumerator().allObjects,
                !statisticRecords.isEmpty {
                //
                // Store results to show in the outline view
                self.statisticRecords = statisticRecords
                
                // Reload outline view data
                self.statisticQueryResultsOutlineView.reloadData()
            }
        })
    }
    
    @IBAction func resetAction(_ sender: Any) {
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
    
    private func showAlert(messageText: String, informativeText: String) {
        if let window = view.window {
            let alert = NSAlert()
            alert.messageText = messageText
            alert.informativeText = informativeText
            alert.beginSheetModal(for: window)
        }
    }
    
    private func stringFor(sortOrder: AGSSortOrder) -> String {
        switch sortOrder {
        case .ascending:
            return "Ascending"
        case .descending:
            return "Descending"
        }
    }
    
    private func setRemoveStatisticButtonEnabledState() {
        // Only allow definition removal if there is a selected definition
        removeStatisticDefinitionButton.isEnabled = !statisticDefinitionsTableView.selectedRowIndexes.isEmpty
    }
}

extension StatisticalQueryGroupAndSortViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == statisticDefinitionsTableView {
            return statisticDefinitions.count
        } else if tableView == groupByFieldsTableView {
            return fieldNames.count
        } else if tableView == orderByFieldsTableView {
            return orderByFields.count
        }
        return 0
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        if tableView == groupByFieldsTableView {
            let fieldName = fieldNames[row]
            if let buttonState = object as? Int, buttonState == 1 {
                // Add field to the selected group by fields
                selectedGroupByFieldNames.append(fieldName)
                
                // Add field to order by fields
                let orderBy = AGSOrderBy(fieldName: fieldName, sortOrder: .ascending)
                orderByFields.append(orderBy)
            } else {
                // Remove field from selected group by fields
                if let index = selectedGroupByFieldNames.index(of: fieldName) {
                    selectedGroupByFieldNames.remove(at: index)
                }
                
                // Remove field from the order by fields
                orderByFields.removeAll { $0.fieldName == fieldName }
                
                // Remove field from the selected order by fields
                selectedOrderByFields.removeAll { $0.fieldName == fieldName }
            }
            
            // Reload order by fields table
            orderByFieldsTableView.reloadData()
        }
        
        if tableView == orderByFieldsTableView {
            let orderByField = orderByFields[row]
            guard let tableColumnID = tableColumn?.identifier.rawValue else {
                return
            }
            if tableColumnID == "FieldNameCheckBox" {
                if let buttonState = object as? Int, buttonState == 1 {
                    selectedOrderByFields.append(orderByField)
                } else {
                    // Remove field from selected order by fields
                    if let index = selectedOrderByFields.index(of: orderByField) {
                        selectedOrderByFields.remove(at: index)
                    }
                }
            } else if tableColumnID == "SortOrder" {
                if let selectedIndex = object as? Int, let sortOrder = AGSSortOrder(rawValue: selectedIndex) {
                    orderByField.sortOrder = sortOrder
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
        } else if tableView == groupByFieldsTableView {
            let fieldName = fieldNames[row]
            if let buttonCell = tableColumn?.dataCell(forRow: row) as? NSButtonCell {
                buttonCell.title = fieldName
                return selectedGroupByFieldNames.contains(fieldName) ? 1 : 0
            }
        } else if tableView == orderByFieldsTableView {
            let orderByField = orderByFields[row]
            guard let tableColumnID = tableColumn?.identifier.rawValue else {
                return nil
            }
            if tableColumnID == "FieldNameCheckBox" {
                if let buttonCell = tableColumn?.dataCell(forRow: row) as? NSButtonCell {
                    buttonCell.title = orderByField.fieldName
                    return selectedOrderByFields.contains(orderByField) ? 1 : 0
                }
            } else if tableColumnID == "SortOrder" {
                if let popUpButtonCell = tableColumn?.dataCell(forRow: row) as? NSPopUpButtonCell {
                    return popUpButtonCell.indexOfItem(withTitle: stringFor(sortOrder: orderByField.sortOrder))
                }
            }
        }
        return nil
    }
}

extension StatisticalQueryGroupAndSortViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        if notification.object as? NSTableView == statisticDefinitionsTableView {
            // Enable or disable the removal button as needed
            setRemoveStatisticButtonEnabledState()
        }
    }
}

extension StatisticalQueryGroupAndSortViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let statisticRecord = item as? AGSStatisticRecord {
            return statisticRecord.statistics.keys.count
        } else {
            return self.statisticRecords.count
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let statisticRecord = item as? AGSStatisticRecord {
            let keys = Array(statisticRecord.statistics.keys)
            let values = Array(statisticRecord.statistics.values)
            return "\(keys[index]): \(values[index])"
        } else {
            return statisticRecords[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let statisticRecord = item as? AGSStatisticRecord {
            return !statisticRecord.statistics.keys.isEmpty
        } else {
            return false
        }
    }
}

extension StatisticalQueryGroupAndSortViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let cellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("StatisticRecordCellView"), owner: self) as? NSTableCellView else {
            return nil
        }
        
        if let statisticRecord = item as? AGSStatisticRecord {
            var groups = [String]()
            for fieldName in selectedGroupByFieldNames {
                if let value = statisticRecord.group[fieldName] as? String {
                    groups.append("\(value)")
                }
            }
            cellView.textField?.stringValue = groups.joined(separator: ", ")
        } else {
            if let string = item as? String {
                cellView.textField?.stringValue = string
            }
        }
        return cellView
    }
}
