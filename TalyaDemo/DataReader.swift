//
//  DataReader.swift
//  TalyaDemo
//
//  Created by liusilan on 2025/9/7.
//

import Foundation

class DataReader {
    private let data: Data
    private var offset: Int = 0
    
    init(data: Data) {
        self.data = data
    }
    
    var bytesRemaining: Int {
        return data.count - offset
    }
    
    func readUInt8() -> UInt8? {
        guard bytesRemaining >= 1 else { return nil }
        let value = data.withUnsafeBytes { bytes in
            var result: UInt8 = 0
            memcpy(&result, bytes.baseAddress!.advanced(by: offset), 1)
            return result.littleEndian
        }
      
        offset += 1
        return value
    }
    
    func readUInt16() -> UInt16? {
        guard bytesRemaining >= 2 else { return nil }
        
        let value = data.withUnsafeBytes { bytes in
            var result: UInt16 = 0
            memcpy(&result, bytes.baseAddress!.advanced(by: offset), 2)
            return result.littleEndian
        }
        offset += 2
        return value
    }
    
    func readUInt32() -> UInt32? {
        guard bytesRemaining >= 4 else { return nil }
        
        let value = data.withUnsafeBytes { bytes in
            var result: UInt32 = 0
            memcpy(&result, bytes.baseAddress!.advanced(by: offset), 4)
            return result.littleEndian
        }
        offset += 4
        return value
    }
    
    func readFloat32() -> Float32? {
        guard bytesRemaining >= 4 else { return nil }
        
        let value = data.withUnsafeBytes { bytes in
            var result: Float32 = 0
            memcpy(&result, bytes.baseAddress!.advanced(by: offset), 4)
            return result.littleEndian
        }
        offset += 4
        return value
    }
    
    func readDouble() -> Double? {
        guard bytesRemaining >= 8 else { return nil }
        
        let value = data.withUnsafeBytes { bytes in
            var result: Double = 0
            memcpy(&result, bytes.baseAddress!.advanced(by: offset), 8)
            return result.littleEndian
        }
        offset += 8
        return value
    }
    
    func readBytes(count: Int) -> Data? {
        guard bytesRemaining >= count else { return nil }
        let result = data.subdata(in: offset..<(offset + count))
        offset += count
        return result
    }
    
    func readString(length: Int) -> String? {
        guard let data = readBytes(count: length) else { return nil }
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
    }
}

extension Float32 {
    var littleEndian: Float32 {
        let bits = self.bitPattern.littleEndian
        return Float32(bitPattern: bits)
    }
}

extension Float16 {
    var littleEndian: Float16 {
        let bits = self.bitPattern.littleEndian
        return Float16(bitPattern: bits)
    }
}

extension Double {
    var littleEndian: Double {
        let bits = self.bitPattern.littleEndian
        return Double(bitPattern: bits)
    }
}

