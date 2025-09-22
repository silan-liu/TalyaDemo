//
//  ImageExtension.swift
//  TalyaDemo
//
//  Created by lsl on 2025/9/10.
//

import Foundation

import UIKit

extension UIImage {
    
    // MARK: - 基础缩放方法
    func resized(to targetSize: CGSize) -> UIImage? {
        // 创建图形上下文
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        // 绘制图片到新尺寸
        self.draw(in: CGRect(origin: .zero, size: targetSize))
        
        // 获取新图片
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: - 保持宽高比缩放
    func resizedWithAspectRatio(to targetSize: CGSize) -> UIImage? {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        // 选择较小的比例以保持宽高比
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(
            width: size.width * ratio,
            height: size.height * ratio
        )
        
        return resized(to: newSize)
    }
}

extension UIImage {
    
    // MARK: - 线程安全的宽高比缩放
    func threadSafeResizeWithAspectRatio(to targetSize: CGSize, contentMode: ContentMode = .scaleAspectFit) -> UIImage? {
        let newSize = calculateAspectRatioSize(targetSize: targetSize, contentMode: contentMode)
        
        // 使用 UIGraphicsImageRenderer (线程安全)
        let renderer = UIGraphicsImageRenderer(size: newSize.canvasSize)
        
        return renderer.image { context in
            draw(in: CGRect(origin: newSize.origin, size: newSize.drawSize))
        }
    }
    
    // MARK: - 计算保持比例的尺寸
    private func calculateAspectRatioSize(targetSize: CGSize, contentMode: ContentMode = .scaleAspectFit) -> (canvasSize: CGSize, drawSize: CGSize, origin: CGPoint) {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        switch contentMode {
        case .scaleAspectFit:
            // 完全显示图片，可能有留白
            let ratio = min(widthRatio, heightRatio)
            let drawSize = CGSize(width: size.width * ratio, height: size.height * ratio)
            let origin = CGPoint(
                x: (targetSize.width - drawSize.width) / 2,
                y: (targetSize.height - drawSize.height) / 2
            )
            return (targetSize, drawSize, origin)
            
        case .scaleAspectFill:
            // 填满目标区域，可能裁剪
            let ratio = max(widthRatio, heightRatio)
            let drawSize = CGSize(width: size.width * ratio, height: size.height * ratio)
            let origin = CGPoint(
                x: (targetSize.width - drawSize.width) / 2,
                y: (targetSize.height - drawSize.height) / 2
            )
            return (targetSize, drawSize, origin)
            
        case .scaleToFill:
            // 拉伸填充，不保持比例
            return (targetSize, targetSize, .zero)
        }
    }
}

enum ContentMode {
    case scaleAspectFit   // 保持比例，完全显示
    case scaleAspectFill  // 保持比例，填满裁剪
    case scaleToFill      // 拉伸填充
}
