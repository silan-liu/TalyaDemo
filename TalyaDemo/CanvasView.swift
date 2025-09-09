//
//  CanvasView.swift
//  TalyaDemo
//
//  Created by liusilan on 2025/9/7.
//

import UIKit

// MARK: - Canvas View
class CanvasView: UIView {
    var page: TalyaPage?
  var scale: CGFloat = 1.0 {
    didSet {
      // 当缩放改变时重绘
      updateContentScale()
    }
  }
    
    private let contentView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .white
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 10)
        layer.shadowRadius = 20
        
        addSubview(contentView)
        contentView.backgroundColor = .white
    }
  
  // 🎯 核心方法：动态调整 contentScaleFactor
     private func updateContentScale() {
       // 根据缩放级别动态调整绘制分辨率
       let baseScale = UIScreen.main.scale
       let maxScale = UIScreen.main.scale * 2.5

       let targetScale = min(maxScale, baseScale * scale)
         
         // 平滑过渡，避免频繁重建图层
         if abs(contentScaleFactor - targetScale) > 0.3 {
             contentScaleFactor = targetScale
             setNeedsDisplay()
         }
     }
    
    override func draw(_ rect: CGRect) {
        guard let page = page,
              let context = UIGraphicsGetCurrentContext() else { return }
        
        // Apply scale
//        context.scaleBy(x: scale, y: scale)
      
      context.setAllowsAntialiasing(true)
      context.setAllowsFontSmoothing(true)
      context.interpolationQuality = .high
        
        // Clear background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(rect)
        
        // Render strokes
        for stroke in page.strokes {
            renderStroke(stroke, in: context)
        }
        
        // Render text
        for textElement in page.textElements {
            renderText(textElement, in: context)
        }
        
        // Render images
        for (id, imageData) in page.images {
            if let shape = page.shapes.first(where: { $0.id == id }) {
                renderImage(imageData, shape: shape, in: context)
            }
        }
    }
    
    private func renderStroke(_ stroke: Stroke, in context: CGContext) {
        guard !stroke.points.isEmpty else { return }
        
        var color = UIColor.white
        if stroke.color.count == 4 {
            color = UIColor(red: CGFloat(stroke.color[0]), green: CGFloat(stroke.color[1]), blue: CGFloat(stroke.color[2]), alpha: CGFloat(stroke.color[3]))
        }
        
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(CGFloat(stroke.width))
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        context.beginPath()
        
        let firstPoint = stroke.points[0]
        context.move(to: CGPoint(x: CGFloat(firstPoint.x), y: CGFloat(firstPoint.y)))
        
        for point in stroke.points.dropFirst() {
            context.addLine(to: CGPoint(x: CGFloat(point.x), y: CGFloat(point.y)))
        }
        
        context.strokePath()
    }
    
    private func convertColor(colors:[Int]?) -> UIColor {
        if let colors = colors, colors.count == 4 {
            let color = UIColor(red: CGFloat(colors[0]), green: CGFloat(colors[1]), blue: CGFloat(colors[2]), alpha: CGFloat(colors[3]))
            
            return color
        }
        
        return UIColor.black
    }
    
    private func renderText(_ textElement: TextElement, in context: CGContext) {
        let color = convertColor(colors: textElement.style.color)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: textElement.style.font ?? "", size: textElement.style.size) ?? UIFont.systemFont(ofSize: textElement.style.size),
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: textElement.text, attributes: attributes)
        
        var position = CGPointZero
        if textElement.position.count == 2 {
            position = CGPointMake(textElement.position[0], textElement.position[1])
        }
        
        attributedString.draw(at: position)
    }
    
    private func renderImage(_ imageData: Data, shape: Shape, in context: CGContext) {
        guard let image = UIImage(data: imageData) else { return }
        
        var position = CGPointZero
        if shape.position.count == 2 {
            position = CGPointMake(shape.position[0], shape.position[1])
        }
        
        var size = CGSizeZero
        if shape.dimensions.count == 2 {
            size = CGSizeMake(shape.dimensions[0], shape.dimensions[1])
        }
        
        image.draw(in: CGRect(origin: position, size: size))
    }
}

extension CanvasView: UIScrollViewDelegate {
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return contentView
  }
}


