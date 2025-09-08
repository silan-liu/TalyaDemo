//
//  ScrollableCanvasView.swift
//  TalyaDemo
//
//  Created by lsl on 2025/9/8.
//

import Foundation
import UIKit

class ScrollableCanvasView: UIView {
  private var isUpdatingZoom = false

  var page: TalyaPage? {
    didSet {
      self.updateContentSizeAndZoom()

      self.contentView.page = page
      self.contentView.setNeedsDisplay()
    }
  }
  
  var scale: CGFloat = 1.0 {
    didSet {
      self.scrollView.zoomScale = scale
      
      self.contentView.scale = scale
    }
  }
  
  private let scrollView = UIScrollView()
  private let contentView = CanvasView()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
  func minScale() -> CGFloat {
    return self.scrollView.minimumZoomScale
  }
  
  func resetScale() {
    let minScale = minScale()
    if minScale > 0 {
      self.updateScale(fitScale: self.scrollView.minimumZoomScale)
    }
  }
  
  private func setup() {
    scrollView.zoomScale = 1.0
    scrollView.minimumZoomScale = 0.3
    scrollView.maximumZoomScale = 3
    scrollView.backgroundColor = .white
    scrollView.delegate = self
  
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    contentView.translatesAutoresizingMaskIntoConstraints = true

    addSubview(scrollView)
    
    scrollView.addSubview(contentView)
    
    NSLayoutConstraint.activate([
      scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
      scrollView.topAnchor.constraint(equalTo: self.topAnchor),
      scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
      
//      contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//      contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
//      contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
//      contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
    ])
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
//    contentView.frame = self.scrollView.bounds
    
//    self.scrollView.zoomScale = self.scrollView.minimumZoomScale
  }
  
  private func updateZoomScale() {
      let scrollViewFrame = scrollView.frame
      guard scrollViewFrame.width > 0 && scrollViewFrame.height > 0 else { return }
      
    let width = self.page?.metadata?.dimensions.width ?? 400
    let height = self.page?.metadata?.dimensions.height ?? 600
    
    let contentViewWidth = max(width, bounds.size.width)
    let contentViewHeight = max(height, bounds.size.height)
    
    print("page size:\(width), \(height)")
        
    scrollView.zoomScale = 1
    
//    scrollView.contentSize = CGSizeMake(contentViewWidth, contentViewHeight)
    contentView.bounds = CGRectMake(0, 0, contentViewWidth, contentViewHeight)
        
    let scaleWidth = scrollViewFrame.width / width
    let scaleHeight = scrollViewFrame.height / height
      let minScale = min(scaleWidth, scaleHeight)
      
      scrollView.minimumZoomScale = minScale
      scrollView.maximumZoomScale = max(minScale * 3, 3.0)
      
      // 设置初始缩放以适应页面宽度
    scrollView.setZoomScale(minScale, animated: false)
    scrollView.contentOffset = CGPointZero
  }
  
  private func updateContentSizeAndZoom() {
          let pageWidth = page?.metadata?.dimensions.width ?? 400
          let pageHeight = page?.metadata?.dimensions.height ?? 600
    
    let contentViewWidth = max(pageWidth, bounds.size.width)
    let contentViewHeight = max(pageHeight, bounds.size.height)
    
          
          contentView.frame = CGRect(x: 0, y: 0, width: contentViewWidth, height: contentViewHeight)
//          scrollView.contentSize = CGSize(width: contentViewWidth, height: contentViewHeight)

          let scaleWidth = scrollView.frame.width / pageWidth
          let scaleHeight = scrollView.frame.height / pageHeight
          let fitScale = min(scaleWidth, scaleHeight)
          
          scrollView.minimumZoomScale = fitScale
          scrollView.maximumZoomScale = max(fitScale * 3, 3.0)
          
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
      self.updateScale(fitScale: fitScale)
    }
         
          
//          centerContent()
      }
  
  private func updateScale(fitScale: CGFloat) {
    self.isUpdatingZoom = true

    self.scrollView.contentOffset = CGPointZero
    self.scrollView.setZoomScale(fitScale, animated: false)
    self.isUpdatingZoom = false
    
    self.scale = fitScale
    self.contentView.scale = fitScale
  }
      
      private func centerContent() {
          let scrollViewSize = scrollView.frame.size
          let contentSize = scrollView.contentSize
          let scaledContentSize = CGSize(
              width: contentSize.width * scrollView.zoomScale,
              height: contentSize.height * scrollView.zoomScale
          )
          
          var contentInset = UIEdgeInsets.zero
          
          if scaledContentSize.width < scrollViewSize.width {
              contentInset.left = (scrollViewSize.width - scaledContentSize.width) / 2
              contentInset.right = contentInset.left
          }
          
          if scaledContentSize.height < scrollViewSize.height {
              contentInset.top = (scrollViewSize.height - scaledContentSize.height) / 2
              contentInset.bottom = contentInset.top
          }
          
          scrollView.contentInset = contentInset
      }
}

extension ScrollableCanvasView: UIScrollViewDelegate {
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return contentView
  }
  
  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    print("scrollViewDidZoom: \(scrollView.zoomScale)")
    
    self.contentView.scale = scrollView.zoomScale
  }
}
  
