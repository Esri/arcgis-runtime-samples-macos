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

extension NSApplication {
    //MARK: - Progres indicator
    
    func showProgressIndicator() {
        let controller = windows.compactMap { return $0.windowController as? WindowController }.first
        controller?.showProgressIndicator()
    }
    
    func hideProgressIndicator() {
        let controller = windows.compactMap { return $0.windowController as? WindowController }.first
        controller?.hideProgressIndicator()
    }
}

class WindowController: NSWindowController, NSSearchFieldDelegate, NSWindowDelegate, SuggestionsVCDelegate {
    let searchEngine = SearchEngine()
    
    @IBOutlet var searchField:NSSearchField!
    @IBOutlet private var progressIndicator:NSProgressIndicator!
    
    private var suggestionsWindowController: NSWindowController!
    private var suggestionsViewController: SuggestionsViewController!
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        self.window?.delegate = self
        
        self.suggestionsWindowController = self.storyboard?.instantiateController(withIdentifier: "SuggestionsWindowController") as? NSWindowController
        self.suggestionsViewController = self.suggestionsWindowController.contentViewController as? SuggestionsViewController
        self.suggestionsViewController.delegate = self
        
    }
    
    //MARK: - Progres indicator
    
    func showProgressIndicator() {
        progressIndicator.startAnimation(nil)
    }

    func hideProgressIndicator() {
        progressIndicator.stopAnimation(nil)
    }
    
    //MARK: - NSSearchFieldDelegate
    
    func controlTextDidChange(_ notification: Notification) {
        if let sender = notification.object as? NSSearchField , sender == self.searchField {
            if let suggestions = searchEngine.suggestionsForString(searchField.stringValue) , suggestions.count > 0 {
                self.showSuggestionsWindow(suggestions)
            } else {
                self.hideSuggestionsWindow()
            }
        }
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        self.hideSuggestionsWindow()
    }
    
    //MARK: - Actions
    
    @IBAction func searchAction(_ sender: NSSearchField) {
        if !sender.stringValue.isEmpty {
            self.searchSamples(sender.stringValue)
        }
    }
    
    private func searchSamples(_ searchString: String) {
        //hide suggestions window
        hideSuggestionsWindow()
        
        let mainViewController = contentViewController as! MainViewController
        
        let samples: [Sample]
        if let searchResults = searchEngine.searchForString(searchString) {
            let names = Set(searchResults)
            samples = mainViewController.categories.dropFirst().flatMap { $0.samples.filter { names.contains($0.name) } }
        } else {
            samples = []
        }
        mainViewController.show(Category(name: "", samples: samples))
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
            
            let originX = mainWindow.frame.origin.x + mainWindow.contentView!.convert(searchField.bounds.origin, from: searchField).x
            
            let originY:CGFloat = mainWindow.frame.maxY - searchField.frame.height - suggestionsWindow.frame.height - 10
            let frameOrigin = NSPoint(x: originX, y: originY)
            let frameSize = NSSize(width: searchField.frame.width, height: suggestionsWindow.frame.height)
            
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
