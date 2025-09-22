//
//  ColorExtension.swift
//  TalyaDemo
//
//  Created by liusilan on 2025/9/7.
//

import UIKit

extension UIColor {
  var hexString: String {
          var r: CGFloat = 0
          var g: CGFloat = 0
          var b: CGFloat = 0
          var a: CGFloat = 0
          getRed(&r, green: &g, blue: &b, alpha: &a)
          
          return String(format: "#%02X%02X%02X%02X",
                       Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
      }
  
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
    
    convenience init(gradientFrom start: UIColor, to end: UIColor) {
        self.init(red: (start.ciColor.red + end.ciColor.red) / 2,
                  green: (start.ciColor.green + end.ciColor.green) / 2,
                  blue: (start.ciColor.blue + end.ciColor.blue) / 2,
                  alpha: 1.0)
    }
}


// MARK: - 方法1: UIColor扩展 - RGBA转换
extension UIColor {
    
    // MARK: 转换为UInt32 (RGBA格式)
    var rgba: UInt32 {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // 获取颜色组件
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // 转换为0-255范围
        let r = UInt32(red * 255.0) & 0xFF
        let g = UInt32(green * 255.0) & 0xFF
        let b = UInt32(blue * 255.0) & 0xFF
        let a = UInt32(alpha * 255.0) & 0xFF
        
        // 组合成32位整数 (RGBA: R在高位)
        return (r << 24) | (g << 16) | (b << 8) | a
    }
    
    // MARK: 从UInt32创建UIColor (RGBA格式)
    convenience init(rgba: UInt32) {
        let red = CGFloat((rgba >> 24) & 0xFF) / 255.0
        let green = CGFloat((rgba >> 16) & 0xFF) / 255.0
        let blue = CGFloat((rgba >> 8) & 0xFF) / 255.0
        let alpha = CGFloat(rgba & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    // MARK: 方法2: ARGB格式（某些系统使用）
    var argb: UInt32 {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let a = UInt32(alpha * 255.0) & 0xFF
        let r = UInt32(red * 255.0) & 0xFF
        let g = UInt32(green * 255.0) & 0xFF
        let b = UInt32(blue * 255.0) & 0xFF
        
        // ARGB: Alpha在高位
        return (a << 24) | (r << 16) | (g << 8) | b
    }
    
    convenience init(argb: UInt32) {
        let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
        let red = CGFloat((argb >> 16) & 0xFF) / 255.0
        let green = CGFloat((argb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(argb & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    // MARK: 方法3: RGB格式（不包含Alpha）
    var rgb: UInt32 {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let r = UInt32(red * 255.0) & 0xFF
        let g = UInt32(green * 255.0) & 0xFF
        let b = UInt32(blue * 255.0) & 0xFF
        
        // RGB: 只包含颜色，不包含透明度
        return (r << 16) | (g << 8) | b
    }
    
    convenience init(rgb: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgb & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
