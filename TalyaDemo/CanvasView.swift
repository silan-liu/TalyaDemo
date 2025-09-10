//
//  CanvasView.swift
//  TalyaDemo
//
//  Created by liusilan on 2025/9/7.
//

import UIKit

// MARK: - Canvas View
class CanvasView: UIView {
  var resizeImages: [String: UIImage] = [:]
  var page: TalyaPage? {
    didSet {
      processImage()
      
      // 计算初始缩放比例
      calZoomScale()
    }
  }
  
  var scale: CGFloat = 1.0 {
    didSet {
      // 当缩放改变时重绘
      updateContentScale()
    }
  }
  
  var resizedImage: UIImage?
  
  var zoomScale: CGFloat = 0
//  var zoomScale: CGFloat = 780.0 / 612.0
  
  private func calZoomScale() {
    // 计算 zoomScale
    if let page = page {
      let pageWidth = page.metadata?.dimensions.width ?? 595
      let pageHeight = page.metadata?.dimensions.height ?? 842
      
      let targetSize = self.bounds.size
      if targetSize.width == 0 || targetSize.height == 0 {
        return
      }
      
      let wRatio = targetSize.width / pageWidth
      let hRatio = targetSize.height / pageHeight
      let aspectRatio = min(wRatio, hRatio)
      self.zoomScale = aspectRatio
      
      print("CanvasView zoomScale:\(self.zoomScale)")
    }
  }

    // 🎯 核心方法：动态调整 contentScaleFactor
     private func updateContentScale() {
       // 根据缩放级别动态调整绘制分辨率
       let baseScale = UIScreen.main.scale
       let maxScale = UIScreen.main.scale * 2.2

       let targetScale = min(maxScale, baseScale * scale)
         
         // 平滑过渡，避免频繁重建图层
       if abs(contentScaleFactor - targetScale) > 0.8 {
             contentScaleFactor = targetScale
             setNeedsDisplay()
         
            print("canvas updateContentScale:\(targetScale), \(page?.metadata?.originalPage ?? -1)")
         }
     }
    
    override func draw(_ rect: CGRect) {
        guard let page = page,
              let context = UIGraphicsGetCurrentContext() else { return }
        
      print("canvasView draw zoomscale:\(zoomScale)")
      
        // Apply scale
//        context.scaleBy(x: scale, y: scale)
      
//      context.setAllowsAntialiasing(true)
//      context.setAllowsFontSmoothing(true)
//      context.interpolationQuality = .high
        
        // Clear background
        let bgColor = UIColor.init(hex: "eeeeee")
        context.setFillColor(bgColor.cgColor)
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
                renderImage(id, imageData, shape: shape, in: context)
            }
        }
    }
  
  private func processImage() {
    guard let page = page else {return}
    
    // Render images
    DispatchQueue.global(qos: .userInitiated).async {
      for (id, imageData) in page.images {
       
        if let shape = page.shapes.first(where: { $0.id == id }) {
          
          guard let image = UIImage(data: imageData) else { return }

          var size = CGSizeZero
          if shape.dimensions.count == 2 {
            size = CGSizeMake(shape.dimensions[0], shape.dimensions[1])
          }
          
          let newSize = self.convertSize(size)
          
          var resizedImage = image.threadSafeResizeWithAspectRatio(to: newSize)
          if resizedImage == nil {
            resizedImage = image
          }
          
          self.resizeImages[id] = resizedImage!
        }
      }
      
      print("processImage finished:\(self.resizeImages.count)")
      
      DispatchQueue.main.async {
        self.setNeedsDisplay()
      }
    }
  }
  
    private func renderStroke(_ stroke: Stroke, in context: CGContext) {
        guard !stroke.points.isEmpty else { return }
        
      var color = UIColor.black
        if stroke.color.count == 4 {
            color = UIColor(red: CGFloat(stroke.color[0]), green: CGFloat(stroke.color[1]), blue: CGFloat(stroke.color[2]), alpha: CGFloat(stroke.color[3]))
        }
              
        let strokeWidth = CGFloat(stroke.width * Float(self.zoomScale))
      
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(strokeWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        context.beginPath()
        
        let firstPoint = stroke.points[0]
        let startPoint = CGPoint(x: CGFloat(firstPoint.x), y: CGFloat(firstPoint.y))
      let newStartPoint = convertPoint(startPoint)
      context.move(to: newStartPoint)
        
        for point in stroke.points.dropFirst() {
          let toPoint = CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
          let newToPoint = convertPoint(toPoint)

          context.addLine(to: newToPoint)
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
  
    private func convertPoint(_ point: CGPoint) -> CGPoint {
      let scaledTransform = CGAffineTransform(scaleX: zoomScale, y: zoomScale)
      let newPosition = point.applying(scaledTransform)
      
      return newPosition
    }
  
  private func convertSize(_ size: CGSize) -> CGSize {
    let scaledTransform = CGAffineTransform(scaleX: zoomScale, y: zoomScale)
    let newSize = size.applying(scaledTransform)
    
    return newSize
  }
    
    private func renderText(_ textElement: TextElement, in context: CGContext) {
        let color = convertColor(colors: textElement.style.color)
        let attributes: [NSAttributedString.Key: Any] = [
          .font: UIFont(name: textElement.style.font ?? "", size: textElement.style.size * zoomScale) ?? UIFont.systemFont(ofSize: textElement.style.size * zoomScale),
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: textElement.text, attributes: attributes)
        
        var position = CGPointZero
        if textElement.position.count == 2 {
            position = CGPointMake(textElement.position[0], textElement.position[1])
        }
      
      let newPosition = convertPoint(position)
        
        attributedString.draw(at: newPosition)
    }
    
  private func renderImage(_ id: String, _ imageData: Data, shape: Shape, in context: CGContext) {
    guard let image = resizeImages[id] else { return }
    
    var position = CGPointZero
    if shape.position.count == 2 {
      position = CGPointMake(shape.position[0], shape.position[1])
    }
    
    let newPosition = convertPoint(position)
    
    var size = CGSizeZero
    if shape.dimensions.count == 2 {
      size = CGSizeMake(shape.dimensions[0], shape.dimensions[1])
    }
    
    let newSize = convertSize(size)
    
    print("renderImage original imageSize:\(image.size), to size:\(newSize)")
    image.draw(in: CGRect(origin: newPosition, size: newSize))
  }
}


