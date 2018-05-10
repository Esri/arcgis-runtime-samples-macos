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

class CustomSegmentedCell: NSSegmentedCell {

    @IBInspectable
    var tintColor: NSColor = NSColor.secondaryBlue()
    
    override func drawSegment(_ segment: Int, inFrame frame: NSRect, with controlView: NSView) {
        
        let cornerRadius:CGFloat = 10

        var path: NSBezierPath
        
        //get path based on segment
        if segment == 0 {
            path = self.pathWithCurvesOnLeft(cornerRadius, frame: frame)
        }
        else if segment == self.segmentCount - 1 {
            path = self.pathWithCurvesOnRight(cornerRadius, frame: frame)
        }
        else {
            path = NSBezierPath(rect: frame)
        }
        
        //set path width
        path.lineWidth = 1
        
        //set stroke color
        self.tintColor.setStroke()
        
        //set background color based on selection
        if self.selectedSegment != segment {
            NSColor.white.setFill()
        }
        else {
            self.tintColor.setFill()
        }
        
        //fill and then stroke path
        path.fill()
        path.stroke()
        
        //textField
        let text = self.textForSegment(segment)
        
        let textFrame = NSRect(x: frame.origin.x,
                               y: -2,
                               width: frame.width,
                               height: 22)
        text.draw(in: textFrame)
    }
    
    private func pathWithCurvesOnLeft(_ radius: CGFloat, frame: NSRect) -> NSBezierPath {
        let path = NSBezierPath()
        
        path.move(to: NSPoint(x: frame.minX + radius, y: frame.minY))
        path.line(to: NSPoint(x: frame.maxX, y: frame.minY))
        path.line(to: NSPoint(x: frame.maxX, y: frame.maxY))
        path.line(to: NSPoint(x: frame.minX + radius, y: frame.maxY))
        path.curve(to: NSPoint(x: frame.minX, y: frame.maxY - radius),
                          controlPoint1: NSPoint(x: frame.minX, y: frame.maxY),
                          controlPoint2: NSPoint(x: frame.minX, y: frame.maxY))
        path.line(to: NSPoint(x: frame.minX, y: frame.minY + radius))
        path.curve(to: NSPoint(x: frame.minX + radius, y: frame.minY),
                          controlPoint1: frame.origin,
                          controlPoint2: frame.origin)
        return path
    }
    
    private func pathWithCurvesOnRight(_ radius: CGFloat, frame: NSRect) -> NSBezierPath {
        let path = NSBezierPath()
     
        path.move(to: frame.origin)
        path.line(to: NSPoint(x: frame.maxX - radius, y: frame.minY))
        path.curve(to: NSPoint(x: frame.maxX, y: frame.minY + radius),
                          controlPoint1: NSPoint(x: frame.maxX, y: frame.minY),
                          controlPoint2: NSPoint(x: frame.maxX, y: frame.minY))
        path.line(to: NSPoint(x: frame.maxX, y: frame.maxY - radius))
        path.curve(to: NSPoint(x: frame.maxX - radius, y: frame.maxY),
                          controlPoint1: NSPoint(x: frame.maxX, y: frame.maxY),
                          controlPoint2: NSPoint(x: frame.maxX, y: frame.maxY))
        path.line(to: NSPoint(x: frame.minX, y: frame.maxY))
        path.line(to: frame.origin)
        
        return path
    }
    
    private func textForSegment(_ segment:Int) -> NSAttributedString {
        let font = NSFont(name: "Avenir-Medium", size: 13)!
        
        var textColor: NSColor
        if self.selectedSegment == segment {
            textColor = NSColor.white
        }
        else {
            textColor = self.tintColor
        }
        
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        
        let attributes = [ NSAttributedStringKey.font.rawValue : font,
            NSAttributedStringKey.foregroundColor : textColor,
            NSAttributedStringKey.paragraphStyle : style ] as! [String : Any]
        
        let text = NSAttributedString(string: self.label(forSegment: segment)!, attributes: attributes)
        return text
    }
}
