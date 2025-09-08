//
//  DocumentManager.swift
//  TalyaDemo
//
//  Created by lsl on 2025/9/8.
//

import Foundation

enum DocumentCopyError: LocalizedError {
    case securityScopeAccessFailed
    case sourceFileNotFound
    case destinationFileExists
    case directoryCreationFailed
    case copyFailed
    
    var errorDescription: String? {
        switch self {
        case .securityScopeAccessFailed:
            return "无法访问安全作用域资源"
        case .sourceFileNotFound:
            return "源文件不存在"
        case .destinationFileExists:
            return "目标文件已存在"
        case .directoryCreationFailed:
            return "创建目录失败"
        case .copyFailed:
            return "文件复制失败"
        }
    }
}

class DocumentManager {
  
  // MARK: - 沙盒目录管理
  
  /// 获取文档目录
  static var documentsDirectory: URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
  }
  
  /// 获取应用支持目录
  static var applicationSupportDirectory: URL {
    let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    // 确保目录存在
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }
  
  /// 获取缓存目录
  static var cachesDirectory: URL {
    return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
  }
  
  /// 创建自定义子目录
  static func createSubdirectory(named name: String, in baseDirectory: URL) -> URL? {
    let subdirectory = baseDirectory.appendingPathComponent(name)
    
    do {
      try FileManager.default.createDirectory(
        at: subdirectory,
        withIntermediateDirectories: true,
        attributes: nil
      )
      return subdirectory
    } catch {
      print("❌ Failed to create directory: \(error)")
      return nil
    }
  }
  
  // MARK: - 文件复制方法
  
  /// 将文档复制到沙盒（主要方法）
  static func copyDocumentToSandbox(
    from sourceURL: URL,
    to destinationDirectory: URL = documentsDirectory,
    subdirectory: String? = nil,
    overwrite: Bool = true
  ) -> Result<URL, DocumentCopyError> {
    
    print("📂 Starting document copy process...")
    print("   Source: \(sourceURL.path)")
    
    // 1. 获取安全作用域访问权限
    guard sourceURL.startAccessingSecurityScopedResource() else {
      print("❌ Failed to access security scoped resource")
      return .failure(.securityScopeAccessFailed)
    }
    
    defer {
      sourceURL.stopAccessingSecurityScopedResource()
      print("🔒 Security scope access stopped")
    }
    
    do {
      // 2. 确定目标目录
      var targetDirectory = destinationDirectory
      if let subdirectory = subdirectory {
        guard let subDir = createSubdirectory(named: subdirectory, in: destinationDirectory) else {
          return .failure(.directoryCreationFailed)
        }
        targetDirectory = subDir
      }
      
      // 3. 生成目标文件URL
      let destinationURL = generateUniqueDestinationURL(
        for: sourceURL,
        in: targetDirectory,
        overwrite: overwrite
      )
      
      print("   Destination: \(destinationURL.path)")
      
      // 4. 检查源文件是否可访问
      guard FileManager.default.fileExists(atPath: sourceURL.path) else {
        return .failure(.sourceFileNotFound)
      }
      
      // 5. 如果目标文件存在且不允许覆盖，返回错误
      if FileManager.default.fileExists(atPath: destinationURL.path) && !overwrite {
        return .failure(.destinationFileExists)
      }
      
      // 6. 删除已存在的目标文件（如果覆盖）
      if FileManager.default.fileExists(atPath: destinationURL.path) {
        try FileManager.default.removeItem(at: destinationURL)
        print("🗑️ Removed existing file")
      }
      
      // 7. 执行文件复制
      try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
      
      // 8. 验证复制结果
      guard FileManager.default.fileExists(atPath: destinationURL.path) else {
        return .failure(.copyFailed)
      }
      

      print("✅ Document copied successfully")
      print("   Final path: \(destinationURL.path)")
      
      return .success(destinationURL)
      
    } catch {
      print("❌ Copy failed with error: \(error)")
      return .failure(.copyFailed)
    }
  }
  
  /// 生成唯一的目标文件URL
      private static func generateUniqueDestinationURL(
          for sourceURL: URL,
          in directory: URL,
          overwrite: Bool
      ) -> URL {
          
          let fileName = sourceURL.lastPathComponent
          let fileExtension = sourceURL.pathExtension
          let baseName = fileName.replacingOccurrences(of: ".\(fileExtension)", with: "")
          
          var destinationURL = directory.appendingPathComponent(fileName)
          
          // 如果允许覆盖，直接返回
          if overwrite {
              return destinationURL
          }
          
          // 如果不允许覆盖，生成唯一文件名
          var counter = 1
          while FileManager.default.fileExists(atPath: destinationURL.path) {
              let uniqueName: String
              if fileExtension.isEmpty {
                  uniqueName = "\(baseName)_\(counter)"
              } else {
                  uniqueName = "\(baseName)_\(counter).\(fileExtension)"
              }
              destinationURL = directory.appendingPathComponent(uniqueName)
              counter += 1
          }
          
          return destinationURL
      }
      
}
