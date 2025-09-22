//
//  DataExtension.swift
//  TalyaDemo
//
//  Created by lsl on 2025/9/22.
//

import Foundation

// MARK: - Data扩展（压缩支持）
extension Data {
  func compressed(using algorithm: NSData.CompressionAlgorithm) -> Data? {
      do {
        let data = try (self as NSData).compressed(using: algorithm) as Data?
        return data
      } catch {
        print("compressed using:\(algorithm), \(error)")
      }
    
      return nil
    }
    
  func decompressed(using algorithm: NSData.CompressionAlgorithm) -> Data? {
      do {
        let data =  try (self as NSData).decompressed(using: algorithm) as Data?
        return data
      } catch {
        print("decompressed using:\(algorithm), \(error)")
      }
    
      return nil
    }
}

// MARK: - Data扩展：安全读取方法
extension Data {
    // 安全读取方法，避免对齐问题
    func readUInt8(at offset: inout Int) -> UInt8 {
        guard offset < count else { return 0 }
      
        let value = self.withUnsafeBytes { bytes in
            var result: UInt8 = 0
            memcpy(&result, bytes.baseAddress!.advanced(by: offset), 1)
            return result.littleEndian
        }
      
        offset += 1

        return value
    }
    
    func readUInt16(at offset: inout Int) -> UInt16 {
        guard offset + 2 <= count else { return 0 }
      
        let value = self.withUnsafeBytes { bytes in
            var result: UInt16 = 0
            memcpy(&result, bytes.baseAddress!.advanced(by: offset), 2)
            return result.littleEndian
        }
      
        offset += 2
        return value
    }
    
    func readUInt32(at offset: inout Int) -> UInt32 {
        guard offset + 4 <= count else { return 0 }
        let value = self.withUnsafeBytes { bytes in
            var result: UInt32 = 0
            memcpy(&result, bytes.baseAddress!.advanced(by: offset), 4)
            return result.littleEndian
        }
        offset += 4
        return value
    }
    
    func readDouble(at offset: inout Int) -> Double {
        guard offset + 8 <= count else { return 0 }
        
        let value = self.withUnsafeBytes { bytes in
            var result: Double = 0
            memcpy(&result, bytes.baseAddress!.advanced(by: offset), 8)
            return result.littleEndian
        }
        
        offset += 8
        return value
    }
    
    func readFloat(at offset: inout Int) -> Float {
        guard offset + 4 <= count else { return 0 }
        
        let value = self.withUnsafeBytes { bytes in
            var result: Float32 = 0
            memcpy(&result, bytes.baseAddress!.advanced(by: offset), 4)
            return result.littleEndian
        }
        
        offset += 4
        return value
    }
    
    func readFloat16(at offset: inout Int) -> Float16 {
        guard offset + 2 <= count else { return 0 }
        
        let value = self.withUnsafeBytes { bytes in
            var result: Float16 = 0
            memcpy(&result, bytes.baseAddress!.advanced(by: offset), 2)
            return result.littleEndian
        }

        offset += 2
      return value
    }
}

