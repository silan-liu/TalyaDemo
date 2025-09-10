//
//  CanvasView.swift
//  ImagePreviewer
//
//  Created by lsl on 2025/9/9.
//

import UIKit

class CanvasView2: UIView {
  
  var scale: CGFloat = 1.0 {
    didSet {
      // 当缩放改变时重绘
//      updateContentScale()
    }
  }
    
  private func updateContentScale() {
      // 根据缩放级别动态调整绘制分辨率
      let baseScale = UIScreen.main.scale
    let maxScale = UIScreen.main.scale * 1.5

      let targetScale = min(maxScale, baseScale * scale)
      
      // 平滑过渡，避免频繁重建图层
      let deltaScale = abs(contentScaleFactor - targetScale)
      print("deltaScale:\(deltaScale)")

      if deltaScale > 0.5 {
        contentScaleFactor = targetScale
        print("upadte contentScaleFactor:\(contentScaleFactor)")
        setNeedsDisplay()
      }
  }
  
  override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext() else {return}

    let renderScale = 2.0
      
    
    
//    context.scaleBy(x: renderScale, y: renderScale)

//    context.setAllowsAntialiasing(true)
//    context.setAllowsFontSmoothing(true)
//    context.interpolationQuality = .high

    // Clear background
    context.setFillColor(UIColor.white.cgColor)
    context.fill(rect)

    let scaleTransform = CGAffineTransform(scaleX: renderScale, y: renderScale)

    let image = UIImage(named: "IMG_3016AEED03A6-1")
    renderImage(image, in: context)
    
    renderText(text: "hello, talya", tansform2: scaleTransform)
  }
  
  private func renderText(text: String, tansform2: CGAffineTransform) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont(name:"", size: 12) ?? UIFont.systemFont(ofSize: 12),
        .foregroundColor: UIColor.red
    ]
    
    let attributedString = NSAttributedString(string: text, attributes: attributes)
    
    let point = CGPointMake(100, 50)
    let transformedPointed = point.applying(tansform2)
    
    attributedString.draw(at: transformedPointed)
    
    print("transformedPointed:\(transformedPointed)")
  }
  
  private func renderImage(_ image: UIImage?,  in context: CGContext, tansform: CGAffineTransform = CGAffineTransformIdentity) {
    guard let image = image else {
      return
    }
    
    image.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: bounds.size))
  }
}
