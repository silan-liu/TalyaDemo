import Foundation
import UIKit
import Compression

// MARK: - 1. 二进制文件格式定义
/*
 文件格式结构:
 ┌─────────────────────────────────┐
 │  Header (文件头)                 │
 ├─────────────────────────────────┤
 │  Magic Number (4 bytes)         │  识别文件格式
 │  Version (2 bytes)              │  格式版本
 │  Flags (2 bytes)                │  压缩等标志
 │  Stroke Count (4 bytes)         │  笔画总数
 │  Creation Time (8 bytes)        │  创建时间戳
 │  Reserved (12 bytes)            │  预留字段
 ├─────────────────────────────────┤
 │  Index Table (索引表)            │
 ├─────────────────────────────────┤
 │  Stroke 1 Offset (4 bytes)      │  笔画1的偏移量
 │  Stroke 1 Size (4 bytes)        │  笔画1的大小
 │  Stroke 2 Offset (4 bytes)      │  笔画2的偏移量
 │  Stroke 2 Size (4 bytes)        │  笔画2的大小
 │  ...                            │
 ├─────────────────────────────────┤
 │  Data Section (数据区)           │
 ├─────────────────────────────────┤
 │  Stroke 1 Data                  │  笔画1数据
 │  Stroke 2 Data                  │  笔画2数据
 │  ...                            │
 └─────────────────────────────────┘
*/

// MARK: - 文件头结构
struct BinaryFileHeader {
    static let magicNumber: UInt32 = 0x494E4B53  // "INKS" in ASCII
    static let currentVersion: UInt16 = 0x0001
    
    let magic: UInt32           // 4 bytes (offset: 0)
    let version: UInt16          // 2 bytes (offset: 4)
    let flags: UInt16            // 2 bytes (offset: 6)
    let strokeCount: UInt32      // 4 bytes (offset: 8)
    let reserved1: UInt32        // 4 bytes (offset: 12) - 用于对齐
    let creationTime: TimeInterval // 8 bytes (offset: 16) - 现在是8字节对齐的
    let reserved2: Data          // 8 bytes (offset: 24)
    
    static let headerSize = 32  // 总字节数
    
    init(strokeCount: UInt32, flags: UInt16 = 0) {
        self.magic = BinaryFileHeader.magicNumber
        self.version = BinaryFileHeader.currentVersion
        self.flags = flags
        self.strokeCount = strokeCount
        self.reserved1 = 0
        self.creationTime = Date().timeIntervalSince1970
        self.reserved2 = Data(repeating: 0, count: 8)
    }
    
    func serialize() -> Data {
        var data = Data()
        
        withUnsafeBytes(of: magic) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: version) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: flags) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: strokeCount) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: reserved1) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: creationTime) { data.append(contentsOf: $0) }
        data.append(reserved2)
        
        return data
    }
    
    static func deserialize(from data: Data) -> BinaryFileHeader? {
        guard data.count >= headerSize else { return nil }
        
        // 方法1: 安全的逐字节读取（避免对齐问题）
        var offset = 0
        
        let magic = data.readUInt32(at: &offset)
        guard magic == magicNumber else { return nil }
        
        let version = data.readUInt16(at: &offset)
        let flags = data.readUInt16(at: &offset)
        let strokeCount = data.readUInt32(at: &offset)
        let reserved1 = data.readUInt32(at: &offset)
        let creationTime = data.readDouble(at: &offset)
        let reserved2 = data[offset..<offset+8]
        
        return BinaryFileHeader(
            magic: magic,
            version: version,
            flags: flags,
            strokeCount: strokeCount,
            reserved1: reserved1,
            creationTime: creationTime,
            reserved2: reserved2
        )
    }
    
    private init(magic: UInt32, version: UInt16, flags: UInt16,
                 strokeCount: UInt32, reserved1: UInt32, creationTime: TimeInterval, reserved2: Data) {
        self.magic = magic
        self.version = version
        self.flags = flags
        self.strokeCount = strokeCount
        self.reserved1 = reserved1
        self.creationTime = creationTime
        self.reserved2 = reserved2
    }
}

// MARK: - 文件标志位
struct FileFlags: OptionSet {
    let rawValue: UInt16
    
    static let compressed = FileFlags(rawValue: 1 << 0)      // 使用压缩
    static let encrypted = FileFlags(rawValue: 1 << 1)       // 加密
    static let differential = FileFlags(rawValue: 1 << 2)    // 差分编码
    static let hasIndex = FileFlags(rawValue: 1 << 3)        // 包含索引
}

// MARK: - 2. 索引表结构
struct StrokeIndex {
    let offset: UInt32      // 在文件中的偏移位置
    let size: UInt32        // 数据大小
    let timestamp: UInt32   // 时间戳（节省空间用UInt32）
    let flags: UInt8        // 笔画标志
    
    static let indexSize = 13  // 每个索引项的大小
    
    func serialize() -> Data {
        var data = Data()
        withUnsafeBytes(of: offset) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: size) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: timestamp) { data.append(contentsOf: $0) }

        data.append(flags)
      
        return data
    }
    
    static func deserialize(from data: Data, at offset: Int) -> StrokeIndex? {
        guard offset + indexSize <= data.count else { return nil }
        
        let range = offset..<(offset + indexSize)
        let indexData = data[range]
                    
        var offset1 = 0
        let indexOffset = indexData.readUInt32(at: &offset1)
        let size = indexData.readUInt32(at: &offset1)
        let timestamp = indexData.readUInt32(at: &offset1)
        let flags = indexData.readUInt8(at: &offset1)
        
        return StrokeIndex(
          offset: indexOffset,
          size: size,
          timestamp: timestamp,
          flags: flags
        )
    }
}

// MARK: - 3. InkStroke二进制表示
struct BinaryInkStroke {
    let id: UUID
    var points: [CGPoint] = []
    var color: UInt32 = UIColor.black.rgba
    var width: Float16 = 2.0
    var alpha: Float16 = 1.0
    var tool: UInt8 = 0
    var timestamp: TimeInterval = Date().timeIntervalSince1970
  
    // 运行时属性（不需要编码）
    var path: UIBezierPath {
        let bezierPath = UIBezierPath()
        if let first = points.first {
            bezierPath.move(to: first)
            for point in points.dropFirst() {
                bezierPath.addLine(to: point)
            }
        }
        return bezierPath
    }

  
  // 添加点
  mutating func addPoint(_ point: CGPoint) {
      points.append(point)
  }
    
    // 优化的序列化（使用差分编码）
    func serialize(useDifferential: Bool = true) -> Data {
        var data = Data()
        
        // 1. ID (16 bytes)
        withUnsafeBytes(of: id.uuid) { data.append(contentsOf: $0) }
        
        // 2. 元数据 (13 bytes)
        withUnsafeBytes(of: color) { data.append(contentsOf: $0) }          // 4 bytes
        withUnsafeBytes(of: width) { data.append(contentsOf: $0) }          // 2 bytes
        withUnsafeBytes(of: alpha) { data.append(contentsOf: $0) }          // 2 bytes
        data.append(tool)                                                    // 1 byte
        withUnsafeBytes(of: Float32(timestamp)) { data.append(contentsOf: $0) } // 4 bytes
        
        // 3. 点数量 (2 bytes - 最多65535个点)
        withUnsafeBytes(of: UInt16(points.count)) { data.append(contentsOf: $0) }
        
        // 4. 点数据
        if useDifferential && points.count > 1 {
            // 差分编码
            serializeDifferentialPoints(to: &data)
        } else {
            // 绝对坐标
            serializeAbsolutePoints(to: &data)
        }
        
        return data
    }
    
    private func serializeDifferentialPoints(to data: inout Data) {
        guard !points.isEmpty else { return }
        
        // 第一个点用Float32存储绝对坐标
        withUnsafeBytes(of: Float32(points[0].x)) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: Float32(points[0].y)) { data.append(contentsOf: $0) }
        
        // 后续点用Int16存储差值（精度：0.1像素）
        for i in 1..<points.count {
            let deltaX = Int16((points[i].x - points[i-1].x) * 10)  // 0.1像素精度
            let deltaY = Int16((points[i].y - points[i-1].y) * 10)
            
            withUnsafeBytes(of: deltaX) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: deltaY) { data.append(contentsOf: $0) }
        }
    }
    
    private func serializeAbsolutePoints(to data: inout Data) {
        for point in points {
            withUnsafeBytes(of: Float32(point.x)) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: Float32(point.y)) { data.append(contentsOf: $0) }
        }
    }
    
    static func deserialize(from data: Data, useDifferential: Bool = true) -> BinaryInkStroke? {
        guard data.count >= 31 else { return nil }  // 最小大小
        
        var offset = 0
        
        // 1. ID - 使用安全读取
        guard offset + 16 <= data.count else { return nil }
        let idBytes = data[offset..<offset+16]
        let id = idBytes.withUnsafeBytes { bytes in
            // 创建对齐的缓冲区
            var uuid = uuid_t(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
            withUnsafeMutableBytes(of: &uuid) { dest in
                dest.copyMemory(from: bytes)
            }
            return UUID(uuid: uuid)
        }
        offset += 16
        
        // 2. 元数据 - 使用安全读取方法
        let color = data.readUInt32(at: &offset)
        let width = data.readFloat16(at: &offset)
        let alpha = data.readFloat16(at: &offset)
        let tool = data.readUInt8(at: &offset)
        let timestampFloat = data.readFloat(at: &offset)
        let timestamp = TimeInterval(timestampFloat)
        
        // 3. 点数量
        let pointCount = data.readUInt16(at: &offset)
        
        // 4. 点数据
        var points: [CGPoint] = []
        if useDifferential && pointCount > 0 {
            points = deserializeDifferentialPoints(from: data, offset: &offset, count: Int(pointCount))
        } else {
            points = deserializeAbsolutePoints(from: data, offset: &offset, count: Int(pointCount))
        }
        
        return BinaryInkStroke(
            id: id,
            points: points,
            color: color,
            width: width,
            alpha: alpha,
            tool: tool,
            timestamp: timestamp
        )
    }
    
    private static func deserializeDifferentialPoints(from data: Data, offset: inout Int, count: Int) -> [CGPoint] {
        var points: [CGPoint] = []
        guard offset + 8 <= data.count else { return points }
        
        // 第一个点 - 使用安全读取
        let x0 = CGFloat(data.readFloat(at: &offset))
        let y0 = CGFloat(data.readFloat(at: &offset))
        
        var currentPoint = CGPoint(x: x0, y: y0)
        points.append(currentPoint)
        
        // 后续点 - 读取Int16差值
        for _ in 1..<count {
            guard offset + 4 <= data.count else { break }
            
            // 读取Int16需要特殊处理
            let deltaXBytes = data[offset..<offset+2]
            let deltaX = deltaXBytes.withUnsafeBytes { bytes in
                let value = Int16(bytes[0]) | (Int16(bytes[1]) << 8)
                return CGFloat(value) / 10.0
            }
            offset += 2
            
            let deltaYBytes = data[offset..<offset+2]
            let deltaY = deltaYBytes.withUnsafeBytes { bytes in
                let value = Int16(bytes[0]) | (Int16(bytes[1]) << 8)
                return CGFloat(value) / 10.0
            }
            offset += 2
            
            currentPoint.x += deltaX
            currentPoint.y += deltaY
            points.append(currentPoint)
        }
        
        return points
    }
    
    private static func deserializeAbsolutePoints(from data: Data, offset: inout Int, count: Int) -> [CGPoint] {
        var points: [CGPoint] = []
        
        for _ in 0..<count {
            guard offset + 8 <= data.count else { break }
            
            let x = CGFloat(data.readFloat(at: &offset))
            let y = CGFloat(data.readFloat(at: &offset))
            
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
}

// MARK: - 4. 批量存储管理器
class BinaryStrokeStorage {
    
    private let fileURL: URL
    private var loadedStrokes: [BinaryInkStroke] = []
    private var indices: [StrokeIndex] = []
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    // MARK: 保存多个笔画
    func save(strokes: [BinaryInkStroke], compressed: Bool = true) throws {
        var fileData = Data()
        var strokeDataArray: [Data] = []
        
        // 1. 序列化所有笔画
        for stroke in strokes {
            let strokeData = stroke.serialize(useDifferential: true)
            strokeDataArray.append(strokeData)
        }
        
        // 2. 创建文件头
        var flags: UInt16 = 0
        if compressed { flags |= FileFlags.compressed.rawValue }
        flags |= FileFlags.differential.rawValue
        flags |= FileFlags.hasIndex.rawValue
        
        let header = BinaryFileHeader(strokeCount: UInt32(strokes.count), flags: flags)
        fileData.append(header.serialize())
        
        // 3. 计算索引表
        let indexTableOffset = BinaryFileHeader.headerSize
        let dataOffset = indexTableOffset + (StrokeIndex.indexSize * strokes.count)
        
        var currentOffset = UInt32(dataOffset)
        var indexTable = Data()
        
        for (i, strokeData) in strokeDataArray.enumerated() {
            let finalData = compressed ? compress(strokeData) : strokeData
            
            let index = StrokeIndex(
                offset: currentOffset,
                size: UInt32(finalData.count),
                timestamp: UInt32(strokes[i].timestamp),
                flags: 0
            )
            
            indexTable.append(index.serialize())
            currentOffset += UInt32(finalData.count)
        }
        
        // 4. 组装文件
        fileData.append(indexTable)
        
        // 5. 添加压缩后的数据
        for strokeData in strokeDataArray {
            let finalData = compressed ? compress(strokeData) : strokeData
            fileData.append(finalData)
        }
        
        // 6. 写入文件
        try fileData.write(to: fileURL)
        
        print("Saved \(strokes.count) strokes, file size: \(fileData.count) bytes")
    }
    
    // MARK: 加载所有笔画
    func loadAll() throws -> [BinaryInkStroke] {
        let fileData = try Data(contentsOf: fileURL)
        
        // 1. 解析文件头
        guard let header = BinaryFileHeader.deserialize(from: fileData) else {
            throw StorageError.invalidFileFormat
        }
        
        let flags = FileFlags(rawValue: header.flags)
        let isCompressed = flags.contains(.compressed)
        let isDifferential = flags.contains(.differential)
        
        // 2. 解析索引表
        var indices: [StrokeIndex] = []
        let indexOffset = BinaryFileHeader.headerSize
        
        for i in 0..<Int(header.strokeCount) {
            let offset = indexOffset + (i * StrokeIndex.indexSize)
            if let index = StrokeIndex.deserialize(from: fileData, at: offset) {
                indices.append(index)
            }
        }
        
        // 3. 加载笔画数据
        var strokes: [BinaryInkStroke] = []
        
        for index in indices {
            let dataRange = Int(index.offset)..<Int(index.offset + index.size)
            guard dataRange.upperBound <= fileData.count else { continue }
            
            var strokeData = fileData[dataRange]
            
            if isCompressed {
                strokeData = decompress(strokeData)
            }
            
            if let stroke = BinaryInkStroke.deserialize(from: strokeData, useDifferential: isDifferential) {
                strokes.append(stroke)
            }
        }
        
        self.loadedStrokes = strokes
        self.indices = indices
        
        return strokes
    }
    
    // MARK: 增量加载（按需加载特定笔画）
    func loadStroke(at index: Int) throws -> BinaryInkStroke? {
        guard index < indices.count else { return nil }
        
        let fileData = try Data(contentsOf: fileURL)
        
        // 解析文件头获取标志
        guard let header = BinaryFileHeader.deserialize(from: fileData) else {
            throw StorageError.invalidFileFormat
        }
        
        let flags = FileFlags(rawValue: header.flags)
        let isCompressed = flags.contains(.compressed)
        let isDifferential = flags.contains(.differential)
        
        // 获取指定笔画的数据
        let strokeIndex = indices[index]
        let dataRange = Int(strokeIndex.offset)..<Int(strokeIndex.offset + strokeIndex.size)
        guard dataRange.upperBound <= fileData.count else { return nil }
        
        var strokeData = fileData[dataRange]
        
        if isCompressed {
            strokeData = decompress(strokeData)
        }
        
        return BinaryInkStroke.deserialize(from: strokeData, useDifferential: isDifferential)
    }
    
    // MARK: 追加新笔画（不重写整个文件）
    func appendStroke(_ stroke: BinaryInkStroke, compressed: Bool = true) throws {
        // 实现增量追加逻辑
        var strokes = try loadAll()
        strokes.append(stroke)
        try save(strokes: strokes, compressed: compressed)
    }
    
    // MARK: 压缩/解压
    private func compress(_ data: Data) -> Data {
      return data.compressed(using: .zlib) ?? data
    }
    
    private func decompress(_ data: Data) -> Data {
      return data.decompressed(using: .zlib) ?? data
    }
}

// MARK: - 5. 错误定义
enum StorageError: Error {
    case invalidFileFormat
    case corruptedData
    case versionMismatch
    case compressionFailed
}

// MARK: - 6. Data扩展（压缩支持）
//extension Data {
//    func compress(using algorithm: NSData.CompressionAlgorithm) -> Data? {
//        return (self as NSData).compressed(using: algorithm) as Data?
//    }
//    
//    func decompress(using algorithm: NSData.CompressionAlgorithm) -> Data? {
//        return (self as NSData).decompressed(using: algorithm) as Data?
//    }
//}

// MARK: - 7. 使用示例
class StorageExample {
    
    static func demonstrateBinaryStorage() {
        // 创建测试数据
        var strokes: [BinaryInkStroke] = []
        
        for i in 0..<100 {
            var stroke = BinaryInkStroke(
                id: UUID(),
                points: [],
                color: 0xFF0000FF,  // 红色
                width: Float16(2.0),
                alpha: Float16(1.0),
                tool: 0,  // pen
                timestamp: Date().timeIntervalSince1970
            )
            
            // 生成测试点
            for j in 0..<50 {
                let x = CGFloat(j) + CGFloat(i * 10)
                let y = sin(CGFloat(j) * 0.1) * 20 + CGFloat(i * 5)
                stroke.points.append(CGPoint(x: x, y: y))
            }
            
            strokes.append(stroke)
        }
        
        // 保存到文件
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("strokes.ink")
      
        print("save fileURL:\(fileURL)")
        
        let storage = BinaryStrokeStorage(fileURL: fileURL)
        
        do {
            // 保存
            let startSave = Date()
            try storage.save(strokes: strokes, compressed: true)
            print("Save time: \(Date().timeIntervalSince(startSave))s")
            
            // 加载
            let startLoad = Date()
            let loadedStrokes = try storage.loadAll()
            print("Load time: \(Date().timeIntervalSince(startLoad))s")
            print("Loaded \(loadedStrokes.count) strokes")
            
            // 验证
            if let fileSize = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int {
                print("File size: \(fileSize) bytes")
                print("Average per stroke: \(fileSize / strokes.count) bytes")
            }
            
        } catch {
            print("Error: \(error)")
        }
    }
    
    // 对比不同存储方式
    static func compareStorageMethods() {
        let strokes = createTestStrokes(count: 100)
        
        // 方法1: JSON
//        let jsonStart = Date()
//        let jsonData = try? JSONEncoder().encode(strokes)
//        let jsonTime = Date().timeIntervalSince(jsonStart)
//        print("JSON size: \(jsonData?.count ?? 0) bytes, time: \(jsonTime)s")
        
        // 方法2: 二进制（未压缩）
        var binaryData = Data()
        let binaryStart = Date()
        for stroke in strokes {
            binaryData.append(stroke.serialize(useDifferential: false))
        }
        let binaryTime = Date().timeIntervalSince(binaryStart)
        print("Binary size: \(binaryData.count) bytes, time: \(binaryTime)s")
        
        // 方法3: 二进制（差分编码+压缩）
        var compressedData = Data()
        let compressedStart = Date()
        for stroke in strokes {
            let strokeData = stroke.serialize(useDifferential: true)
          compressedData.append(strokeData.compressed(using: .zlib) ?? strokeData)
        }
        let compressedTime = Date().timeIntervalSince(compressedStart)
        print("Compressed size: \(compressedData.count) bytes, time: \(compressedTime)s")
        
        // 计算压缩率
//        if let jsonSize = jsonData?.count {
//            let compressionRatio = Double(compressedData.count) / Double(jsonSize) * 100
//            print("Compression ratio: \(String(format: "%.1f", compressionRatio))%")
//        }
    }
    
    private static func createTestStrokes(count: Int) -> [BinaryInkStroke] {
        var strokes: [BinaryInkStroke] = []
        for i in 0..<count {
            var stroke = BinaryInkStroke(
                id: UUID(),
                points: [],
                color: 0xFF0000FF,
                width: Float16(2.0),
                alpha: Float16(1.0),
                tool: 0,
                timestamp: Date().timeIntervalSince1970
            )
            
            for j in 0..<100 {
                stroke.points.append(CGPoint(x: Double(j), y: Double(i)))
            }
            strokes.append(stroke)
        }
        return strokes
    }
}
