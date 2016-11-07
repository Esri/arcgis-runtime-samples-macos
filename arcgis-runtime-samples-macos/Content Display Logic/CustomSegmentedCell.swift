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
    
    override func drawSegment(segment: Int, inFrame frame: NSRect, withView controlView: NSView) {
        
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
            NSColor.whiteColor().setFill()
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
        text.drawInRect(textFrame)
    }
    
    private func pathWithCurvesOnLeft(radius: CGFloat, frame: NSRect) -> NSBezierPath {
        let path = NSBezierPath()
        
        path.moveToPoint(NSPoint(x: frame.minX + radius, y: frame.minY))
        path.lineToPoint(NSPoint(x: frame.maxX, y: frame.minY))
        path.lineToPoint(NSPoint(x: frame.maxX, y: frame.maxY))
        path.lineToPoint(NSPoint(x: frame.minX + radius, y: frame.maxY))
        path.curveToPoint(NSPoint(x: frame.minX, y: frame.maxY - radius),
                          controlPoint1: NSPoint(x: frame.minX, y: frame.maxY),
                          controlPoint2: NSPoint(x: frame.minX, y: frame.maxY))
        path.lineToPoint(NSPoint(x: frame.minX, y: frame.minY + radius))
        path.curveToPoint(NSPoint(x: frame.minX + radius, y: frame.minY),
                          controlPoint1: frame.origin,
                          controlPoint2: frame.origin)
        return path
    }
    
    private func pathWithCurvesOnRight(radius: CGFloat, frame: NSRect) -> NSBezierPath {
        let path = NSBezierPath()
     
        path.moveToPoint(frame.origin)
        path.lineToPoint(NSPoint(x: frame.maxX - radius, y: frame.minY))
        path.curveToPoint(NSPoint(x: frame.maxX, y: frame.minY + radius),
                          controlPoint1: NSPoint(x: frame.maxX, y: frame.minY),
                          controlPoint2: NSPoint(x: frame.maxX, y: frame.minY))
        path.lineToPoint(NSPoint(x: frame.maxX, y: frame.maxY - radius))
        path.curveToPoint(NSPoint(x: frame.maxX - radius, y: frame.maxY),
                          controlPoint1: NSPoint(x: frame.maxX, y: frame.maxY),
                          controlPoint2: NSPoint(x: frame.maxX, y: frame.maxY))
        path.lineToPoint(NSPoint(x: frame.minX, y: frame.maxY))
        path.lineToPoint(frame.origin)
        
        return path
    }
    
    private func textForSegment(segment:Int) -> NSAttributedString {
        let font = NSFont(name: "Avenir-Medium", size: 13)!
        
        var textColor: NSColor
        if self.selectedSegment == segment {
            textColor = NSColor.whiteColor()
        }
        else {
            textColor = self.tintColor
        }
        
        let style = NSMutableParagraphStyle()
        style.alignment = .Center
        
        let attributes = [ NSFontAttributeName : font,
            NSForegroundColorAttributeName : textColor,
            NSParagraphStyleAttributeName : style ]
        
        let text = NSAttributedString(string: self.labelForSegment(segment)!, attributes: attributes)
        return text
    }
}
