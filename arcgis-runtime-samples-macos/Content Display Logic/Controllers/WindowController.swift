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

import Cocoa

extension NSWindow {
    //MARK: - Progres indicator
    
    func showProgressIndicator() {
        if let controller = self.windowController as? WindowController {
            controller.showProgressIndicator()
        }
    }
    
    func hideProgressIndicator() {
        if let controller = self.windowController as? WindowController {
            controller.hideProgressIndicator()
        }
    }
}

class WindowController: NSWindowController, NSSearchFieldDelegate, NSWindowDelegate, SuggestionsVCDelegate {

    @IBOutlet var searchField:NSSearchField!
    @IBOutlet private var progressIndicator:NSProgressIndicator!
    
    private var suggestionsWindowController: NSWindowController!
    private var suggestionsViewController: SuggestionsViewController!
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        self.window?.delegate = self
        self.window?.isMovableByWindowBackground = false
        self.window?.titleVisibility = .hidden
        self.window?.titlebarAppearsTransparent = true
        self.window?.backgroundColor = NSColor.primaryBlue()
        
        self.suggestionsWindowController = self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "SuggestionsWindowController")) as! NSWindowController
        self.suggestionsViewController = self.suggestionsWindowController.contentViewController as! SuggestionsViewController
        self.suggestionsViewController.delegate = self
        
        //progress indicator
        self.progressIndicator.startAnimation(nil)
    }
    
    //MARK: - Progres indicator
    
    func showProgressIndicator() {
        self.progressIndicator.isHidden = false
    }

    func hideProgressIndicator() {
        self.progressIndicator.isHidden = true
    }
    
    //MARK: - NSSearchFieldDelegate
    
    override func controlTextDidChange(_ notification: Notification) {
        if let sender = notification.object as? NSSearchField , sender == self.searchField {
            if let suggestions = SearchEngine.sharedInstance().suggestionsForString(self.searchField.stringValue) , suggestions.count > 0 {
            
                self.showSuggestionsWindow(suggestions)
            }
            else {
                self.hideSuggestionsWindow()
            }
        }
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        self.hideSuggestionsWindow()
    }
    
    //MARK: - Actions
    
    @IBAction func searchAction(_ sender: NSSearchField) {
        if !sender.stringValue.isEmpty {
            self.searchSamples(sender.stringValue)
        }
    }
    
    private func searchSamples(_ searchString: String) {
        //hide segment control
        (self.contentViewController as! MainViewController).toggleSegmentedControl(.Off)
        
        //hide suggestions window
        self.hideSuggestionsWindow()
        
        let mainVC = self.contentViewController as! MainViewController
        mainVC.searchSamplesForString(searchString)
    }
    
    //MARK: Suggestions window controller
    
    func showSuggestionsWindow(_ suggestions: [String]) {

        //assign the suggestions to the view controller
        self.suggestionsViewController.suggestions = suggestions
        
        //If the window is not visible
        //show the window
        let suggestionsWindow = self.suggestionsWindowController.window!
        
        if !suggestionsWindow.isVisible {
            
            let mainWindow = NSApplication.shared.mainWindow!
            
            //frame calculations
            let originX = mainWindow.frame.origin.x + mainWindow.frame.width - self.searchField.frame.width - 6
            let originY:CGFloat = mainWindow.frame.origin.y + mainWindow.frame.height - self.searchField.frame.height - suggestionsWindow.frame.height - 10
            let frameOrigin = NSPoint(x: originX, y: originY)
            let frameSize = NSSize(width: self.searchField.frame.width, height: suggestionsWindow.frame.height)
            
            //set frame
            suggestionsWindow.setFrame(NSRect(origin: frameOrigin, size: frameSize), display: true)
            
            //add window as child window
            mainWindow.addChildWindow(suggestionsWindow, ordered: .above)
    
            self.suggestionsWindowController.window?.makeKeyAndOrderFront(self)
        }
    }
    
    func hideSuggestionsWindow() {
        if let window = self.suggestionsWindowController?.window , window.isVisible {
            window.orderOut(self)
        }
    }
    
    //MARK: - NSWindowDelegate

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        
        //hide suggestion window instead of updating the window frame
        self.hideSuggestionsWindow()
        
        return frameSize
    }
    
    //MARK: - SuggestionsVCDelegate
    
    func suggestionsViewController(_ suggestionsViewController: SuggestionsViewController, didSelectSuggestion suggestion: String) {
        
        self.searchField.stringValue = suggestion
        self.searchSamples(suggestion)
    }
}
