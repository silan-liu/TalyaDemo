//
//  OptimizedInkStroke.swift
//  TalyaDemo
//
//  Created by lsl on 2025/9/22.
//

import Foundation


import UIKit


// MARK: - 高效的笔画存储实现
struct OptimizedInkStroke {
    var id: UUID
    var points: [CGPoint]
    var colorValue: UInt32  // 使用UInt32存储颜色
    var width: Float16       // 使用Float16节省空间
    var alpha: Float16
    var tool: CustomDrawingTool
    var timestamp: TimeInterval
    
    // 计算属性获取UIColor
    var color: UIColor {
        return UIColor(rgba: colorValue)
    }
    
    init(color: UIColor, width: CGFloat, tool: CustomDrawingTool) {
        self.id = UUID()
        self.points = []
        self.colorValue = color.rgba
        self.width = Float16(width)
        self.alpha = Float16(1.0)
        self.tool = tool
        self.timestamp = Date().timeIntervalSince1970
    }
    
    // MARK: 二进制序列化（最高效）
    func serialize() -> Data {
        var data = Data()
        
        // 1. 写入ID (16 bytes)
        withUnsafeBytes(of: id.uuid) { data.append(contentsOf: $0) }
        
        // 2. 写入颜色 (4 bytes)
        withUnsafeBytes(of: colorValue) { data.append(contentsOf: $0) }
        
        // 3. 写入宽度和透明度 (2 + 2 = 4 bytes)
        withUnsafeBytes(of: width) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: alpha) { data.append(contentsOf: $0) }
        
        // 4. 写入工具类型 (1 byte)
        data.append(UInt8(tool.rawValue))
        
        // 5. 写入时间戳 (8 bytes)
        withUnsafeBytes(of: timestamp) { data.append(contentsOf: $0) }
        
        // 6. 写入点数量 (4 bytes)
        withUnsafeBytes(of: Int32(points.count)) { data.append(contentsOf: $0) }
        
        // 7. 写入点数据（每个点8 bytes，使用Float32）
        for point in points {
            withUnsafeBytes(of: Float32(point.x)) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: Float32(point.y)) { data.append(contentsOf: $0) }
        }
        
        return data
    }
    
    // MARK: 反序列化
    static func deserialize(from data: Data) -> OptimizedInkStroke? {
        guard data.count >= 37 else { return nil } // 最小大小检查
        
        var offset = 0
        
        // 1. 读取ID
        let uuid = data.subdata(in: offset..<offset+16).withUnsafeBytes { $0.load(as: UUID.self) }
        offset += 16
        
        // 2. 读取颜色
        let colorValue = data.subdata(in: offset..<offset+4).withUnsafeBytes { $0.load(as: UInt32.self) }
        offset += 4
        
        // 3. 读取宽度和透明度
        let width = data.subdata(in: offset..<offset+2).withUnsafeBytes { $0.load(as: Float16.self) }
        offset += 2
        let alpha = data.subdata(in: offset..<offset+2).withUnsafeBytes { $0.load(as: Float16.self) }
        offset += 2
        
        // 4. 读取工具类型
        let toolRawValue = data[offset]
        guard let tool = CustomDrawingTool(rawValue: Int(toolRawValue)) else { return nil }
        offset += 1
        
        // 5. 读取时间戳
        let timestamp = data.subdata(in: offset..<offset+8).withUnsafeBytes { $0.load(as: TimeInterval.self) }
        offset += 8
        
        // 6. 读取点数量
        let pointCount = data.subdata(in: offset..<offset+4).withUnsafeBytes { $0.load(as: Int32.self) }
        offset += 4
        
        // 7. 读取点数据
        var points: [CGPoint] = []
        for _ in 0..<pointCount {
            guard offset + 8 <= data.count else { break }
            
            let x = data.subdata(in: offset..<offset+4).withUnsafeBytes { $0.load(as: Float32.self) }
            offset += 4
            let y = data.subdata(in: offset..<offset+4).withUnsafeBytes { $0.load(as: Float32.self) }
            offset += 4
            
            points.append(CGPoint(x: CGFloat(x), y: CGFloat(y)))
        }
        
        var stroke = OptimizedInkStroke(
            color: UIColor(rgba: colorValue),
            width: CGFloat(width),
            tool: tool
        )
        stroke.id = uuid
        stroke.points = points
        stroke.alpha = alpha
        stroke.timestamp = timestamp
        
        return stroke
    }
}

// MARK: - 压缩优化版本
extension OptimizedInkStroke {
    
    // 使用差分编码压缩点数据
    func compressedSerialize() -> Data {
        var data = Data()
        
        // 头部信息（同上）
        withUnsafeBytes(of: id.uuid) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: colorValue) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: width) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: alpha) { data.append(contentsOf: $0) }
        data.append(UInt8(tool.rawValue))
        withUnsafeBytes(of: timestamp) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: Int32(points.count)) { data.append(contentsOf: $0) }
        
        // 差分编码点数据
        if !points.isEmpty {
            // 第一个点使用绝对坐标
            withUnsafeBytes(of: Float32(points[0].x)) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: Float32(points[0].y)) { data.append(contentsOf: $0) }
            
            // 后续点使用差分（通常很小，可以用Float16）
            for i in 1..<points.count {
                let deltaX = Float16(points[i].x - points[i-1].x)
                let deltaY = Float16(points[i].y - points[i-1].y)
                withUnsafeBytes(of: deltaX) { data.append(contentsOf: $0) }
                withUnsafeBytes(of: deltaY) { data.append(contentsOf: $0) }
            }
        }
        
        // 使用zlib压缩
        return data.compressed(using: .zlib) ?? data
    }
}

// MARK: - 使用示例
class ColorStorageExample {
    
    func demonstrateColorConversion() {
        // 创建颜色
        let redColor = UIColor.red
        let customColor = UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8)
        
        // 转换为UInt32
        let redValue = redColor.rgba
        let customValue = customColor.rgba
        
        print("Red RGBA: 0x\(String(redValue, radix: 16))")
        print("Custom RGBA: 0x\(String(customValue, radix: 16))")
        
        // 从UInt32还原
        let restoredRed = UIColor(rgba: redValue)
        let restoredCustom = UIColor(rgba: customValue)
        
        // 验证
        print("Colors match: \(redColor == restoredRed)")
    }
    
    func demonstrateStrokeStorage() {
        // 创建笔画
        var stroke = OptimizedInkStroke(
            color: .blue,
            width: 2.5,
            tool: .pen
        )
        
        // 添加点
        for i in 0..<100 {
            stroke.points.append(CGPoint(x: Double(i), y: sin(Double(i) * 0.1) * 50))
        }
        
        // 序列化
        let serialized = stroke.serialize()
        print("Serialized size: \(serialized.count) bytes")
        
        // 压缩版本
        let compressed = stroke.compressedSerialize()
        print("Compressed size: \(compressed.count) bytes")
        print("Compression ratio: \(Double(compressed.count) / Double(serialized.count) * 100)%")
        
        // 反序列化
        if let restored = OptimizedInkStroke.deserialize(from: serialized) {
            print("Successfully restored stroke with \(restored.points.count) points")
        }
    }
}

// MARK: - 颜色格式对比
/*
 不同颜色格式的内存布局：
 
 RGBA (0xRRGGBBAA):
 ┌──────┬──────┬──────┬──────┐
 │  R   │  G   │  B   │  A   │
 │ 8bit │ 8bit │ 8bit │ 8bit │
 └──────┴──────┴──────┴──────┘
 31-24   23-16   15-8    7-0
 
 ARGB (0xAARRGGBB):
 ┌──────┬──────┬──────┬──────┐
 │  A   │  R   │  G   │  B   │
 │ 8bit │ 8bit │ 8bit │ 8bit │
 └──────┴──────┴──────┴──────┘
 31-24   23-16   15-8    7-0
 
 RGB (0x00RRGGBB):
 ┌──────┬──────┬──────┬──────┐
 │  0   │  R   │  G   │  B   │
 │ 8bit │ 8bit │ 8bit │ 8bit │
 └──────┴──────┴──────┴──────┘
 31-24   23-16   15-8    7-0
*/

// MARK: - 性能测试
class PerformanceTest {
    
    static func compareStorageMethods() {
        let color = UIColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 0.8)
        
        // 方法1: NSKeyedArchiver (最慢，最大)
        let start1 = Date()
        for _ in 0..<10000 {
            let data = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
            _ = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data!) as? UIColor
        }
        print("NSKeyedArchiver: \(Date().timeIntervalSince(start1))s")
        
        // 方法2: UInt32 (最快，最小)
        let start2 = Date()
        for _ in 0..<10000 {
            let value = color.rgba
            _ = UIColor(rgba: value)
        }
        print("UInt32: \(Date().timeIntervalSince(start2))s")
        
        // 存储大小对比
        let archivedSize = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false).count
        let uint32Size = MemoryLayout<UInt32>.size
        
        print("Archived size: \(archivedSize ?? 0) bytes")
        print("UInt32 size: \(uint32Size) bytes")
        print("Size ratio: \((archivedSize ?? 0) / uint32Size)x")
    }
}
