//
//  CGPathExtension.swift
//  TalyaDemo
//
//  Created by lsl on 2025/9/22.
//

import UIKit

// MARK: - 高级功能：导出为矢量图形
extension DrawingStroke {
    
    /// 转换为SVG路径字符串
    func toSVGPath() -> String {
        var svgPath = ""
        let points = path.cgPath.getPathPoints()
        
        if !points.isEmpty {
            svgPath = "M \(points[0].x) \(points[0].y)"
            for i in 1..<points.count {
                svgPath += " L \(points[i].x) \(points[i].y)"
            }
        }
        
        return svgPath
    }
    
    /// 转换为JSON格式（用于保存/恢复）
    func toJSON() -> [String: Any] {
        let points = path.cgPath.getPathPoints()
        return [
            "points": points.map { ["x": $0.x, "y": $0.y] },
            "color": color.hexString,
            "width": width,
            "alpha": alpha
        ]
    }
    
    /// 从JSON恢复
    static func fromJSON(_ json: [String: Any]) -> DrawingStroke? {
        guard let pointsData = json["points"] as? [[String: CGFloat]],
              let colorHex = json["color"] as? String,
              let width = json["width"] as? CGFloat,
              let alpha = json["alpha"] as? CGFloat else {
            return nil
        }
        
        var stroke = DrawingStroke(
            color: UIColor(hex: colorHex),
            width: width,
            alpha: alpha
        )
        
        if let firstPoint = pointsData.first,
           let x = firstPoint["x"], let y = firstPoint["y"] {
            stroke.path.move(to: CGPoint(x: x, y: y))
            
            for i in 1..<pointsData.count {
                if let x = pointsData[i]["x"], let y = pointsData[i]["y"] {
                    stroke.path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        
        return stroke
    }
}

// MARK: - CGPath扩展：提取路径点
extension CGPath {
    func getPathPoints() -> [CGPoint] {
        var points: [CGPoint] = []
        
        self.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                points.append(element.pointee.points[0])
            case .addLineToPoint:
                points.append(element.pointee.points[0])
            case .addQuadCurveToPoint:
                // 对于曲线，我们可以采样多个点
                let startPoint = points.last ?? .zero
                let controlPoint = element.pointee.points[0]
                let endPoint = element.pointee.points[1]
                
                // 贝塞尔曲线采样
                for t in stride(from: 0.0, through: 1.0, by: 0.1) {
                    let point = quadraticBezierPoint(
                        t: CGFloat(t),
                        start: startPoint,
                        control: controlPoint,
                        end: endPoint
                    )
                    points.append(point)
                }
            case .addCurveToPoint:
                // 三次贝塞尔曲线
                let startPoint = points.last ?? .zero
                let control1 = element.pointee.points[0]
                let control2 = element.pointee.points[1]
                let endPoint = element.pointee.points[2]
                
                for t in stride(from: 0.0, through: 1.0, by: 0.1) {
                    let point = cubicBezierPoint(
                        t: CGFloat(t),
                        start: startPoint,
                        control1: control1,
                        control2: control2,
                        end: endPoint
                    )
                    points.append(point)
                }
            default:
                break
            }
        }
        
        return points
    }
    
    // 二次贝塞尔曲线插值
    private func quadraticBezierPoint(t: CGFloat, start: CGPoint, control: CGPoint, end: CGPoint) -> CGPoint {
        let x = pow(1 - t, 2) * start.x + 2 * (1 - t) * t * control.x + pow(t, 2) * end.x
        let y = pow(1 - t, 2) * start.y + 2 * (1 - t) * t * control.y + pow(t, 2) * end.y
        return CGPoint(x: x, y: y)
    }
    
    // 三次贝塞尔曲线插值
    private func cubicBezierPoint(t: CGFloat, start: CGPoint, control1: CGPoint, control2: CGPoint, end: CGPoint) -> CGPoint {
        let x = pow(1 - t, 3) * start.x + 3 * pow(1 - t, 2) * t * control1.x + 3 * (1 - t) * pow(t, 2) * control2.x + pow(t, 3) * end.x
        let y = pow(1 - t, 3) * start.y + 3 * pow(1 - t, 2) * t * control1.y + 3 * (1 - t) * pow(t, 2) * control2.y + pow(t, 3) * end.y
        return CGPoint(x: x, y: y)
    }
}
