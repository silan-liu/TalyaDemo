import Foundation
import ZIPFoundation

// MARK: - Data Models

struct TalyaDocument {
    let manifest: Manifest
    let pageIndex: [PageInfo]
    let searchIndex: SearchIndex?
    var pages: [Int: TalyaPage] = [:]
    let zipArchive: Archive
    
    var pageCount: Int { pageIndex.count }
}

struct Manifest: Codable {
    let version: Int
    let title: String
    let docId: String
    let createdAt: TimeInterval
    let modifiedAt: TimeInterval
    let processingMode: String
    let pageCount: Int
    let originalFile: String
    
    enum CodingKeys: String, CodingKey {
        case version
        case title
        case docId = "doc_id"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
        case processingMode = "processing_mode"
        case pageCount = "page_count"
        case originalFile = "original_file"
    }
}

struct PageInfo: Codable {
    let index: Int
    let filename: String
    let id: String
    let size: Int
    let checksum: String
    
    enum CodingKeys: String, CodingKey {
        case index
        case filename
        case id
        case size
        case checksum
    }
}

struct PageDimensions: Codable {
    let width: CGFloat
    let height: CGFloat
}

struct SearchIndex: Codable {
    let statistics: SearchStatistics
    let wordIndex: [String: [WordMatch]]
    let textElements: [String: [TextElementInfo]]
    
    enum CodingKeys: String, CodingKey {
        case statistics
        case wordIndex = "word_index"
        case textElements = "text_elements"
    }
}

struct SearchStatistics: Codable {
    let totalWords: Int
    let uniqueWords: Int
    let totalTextElements: Int
    
    enum CodingKeys: String, CodingKey {
        case totalWords = "total_words"
        case uniqueWords = "unique_words"
        case totalTextElements = "total_text_elements"
    }
}

struct WordMatch: Codable {
    let pageIndex: Int
    let elementId: String
    let wordPosition: Int?
    
    enum CodingKeys: String, CodingKey {
        case pageIndex = "page_index"
        case elementId = "element_id"
        case wordPosition = "word_position"
    }
}

struct TextElementInfo: Codable {
    let id: String
    let text: String
    let position: [CGFloat]
}

struct TalyaPage {
    var metadata: PageMetadata?
    var strokes: [Stroke] = []
    var textElements: [TextElement] = []
    var images: [String: Data] = [:]
    var shapes: [Shape] = []
}

struct PageMetadata: Codable {
    let dimensions: PageDimensions
    let originalPage: Int?
    
    enum CodingKeys: String, CodingKey {
        case dimensions
        case originalPage = "original_page"
    }
}

struct Stroke {
    let id: String
    let type: UInt8
    let color: [UInt8]
    let width: Float
    let timestamp: TimeInterval
    let points: [StrokePoint]
}

struct StrokePoint {
    let x: Float
    let y: Float
    let pressure: Float
}

struct TextElement: Codable {
    let id: String?
    let text: String
    let position: [CGFloat]
    let style: TextStyle
}

struct TextStyle: Codable {
    let font: String?
    let size: CGFloat
    let color: [Int]?
}

struct Shape: Codable {
    let id: String
    let type: String
    let position: [CGFloat]
    let dimensions: [CGFloat]
}

// MARK: - Document Loader

class TalyaDocumentLoader {
    
    // MARK: - Load Document
    
    static func loadTalyaDocument(from url: URL, completion: @escaping (Result<TalyaDocument, Error>) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Verify file extension
                guard url.pathExtension == "talya" else {
                    throw TalyaError.invalidFileType
                }
                
                // Open ZIP archive
              do {
                let  archive = try Archive(url: url, accessMode: .read)
                
                // Load manifest
                let manifest = try loadManifest(from: archive)
                print("Loaded manifest: \(manifest.title)")
                
                // Load search index if available
                let searchIndex = try? loadSearchIndex(from: archive)
                if searchIndex != nil {
                    print("Search index loaded: \(searchIndex!.statistics)")
                } else {
                    print("No search index found")
                }
                
                // Load page index
                let pageIndex = try loadPageIndex(from: archive)
                print("Loaded \(pageIndex.count) pages")
                
                // Create document
                let document = TalyaDocument(
                    manifest: manifest,
                    pageIndex: pageIndex,
                    searchIndex: searchIndex,
                    pages: [:],
                    zipArchive: archive
                )
                
                DispatchQueue.main.async {
                    completion(.success(document))
                }
              } catch {
                throw TalyaError.failedToOpenArchive
              }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Load Manifest
    
    static func loadManifest(from archive: Archive) throws -> Manifest {
        guard let entry = archive["manifest.json"] else {
            throw TalyaError.missingManifest
        }
        
        var manifestData = Data()
        _ = try archive.extract(entry) { data in
            manifestData.append(data)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(Manifest.self, from: manifestData)
    }
    
    // MARK: - Load Search Index
    
     static func loadSearchIndex(from archive: Archive) throws -> SearchIndex {
        guard let entry = archive["search_index.json"] else {
            throw TalyaError.missingSearchIndex
        }
        
        var indexData = Data()
        _ = try archive.extract(entry) { data in
            indexData.append(data)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(SearchIndex.self, from: indexData)
    }
    
    // MARK: - Load Page Index
    
    static func loadPageIndex(from archive: Archive) throws -> [PageInfo] {
        guard let entry = archive["pages/index.json"] else {
            throw TalyaError.missingPageIndex
        }
        
        var indexData = Data()
        _ = try archive.extract(entry) { data in
            indexData.append(data)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([PageInfo].self, from: indexData)
    }
    
    // MARK: - Load Page
    
    static func loadPage(at index: Int, from document: TalyaDocument, completion: @escaping (Result<(TalyaPage, TalyaDocument), Error>) -> Void) {
            print("loadPage at:\(index)")
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    guard index >= 0 && index < document.pageIndex.count else {
                        throw TalyaError.invalidPageIndex
                    }
                    
                    // Check if page is already cached
                    if let cachedPage = document.pages[index] {
                        DispatchQueue.main.async {
                            completion(.success((cachedPage, document)))
                        }
                        return
                    }
                    
                    let pageInfo = document.pageIndex[index]
                    
                    // Extract page bundle from main archive
                    guard let pageEntry = document.zipArchive[pageInfo.filename] else {
                        throw TalyaError.pageNotFound(pageInfo.filename)
                    }
                    
                    var pageData = Data()
                    _ = try document.zipArchive.extract(pageEntry) { data in
                        pageData.append(data)
                    }
                    
                    // Load page bundle
                    let page = try loadPageBundle(from: pageData)
                    
                    // Create updated document with cached page
                    var updatedDocument = document
                    updatedDocument.pages[index] = page
                    
                    DispatchQueue.main.async {
                        completion(.success((page, updatedDocument)))
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    
    // MARK: - Load Page Bundle
    
    static func loadPageBundle(from data: Data) throws -> TalyaPage {
        // Create archive from page bundle data
        guard let pageArchive = Archive(data: data, accessMode: .read) else {
            throw TalyaError.failedToOpenPageBundle
        }
        
        var page = TalyaPage()
        
        // Load metadata
        if let metadataEntry = pageArchive["metadata.json"] {
            var metadataData = Data()
            _ = try pageArchive.extract(metadataEntry) { data in
                metadataData.append(data)
            }
            let decoder = JSONDecoder()
            page.metadata = try decoder.decode(PageMetadata.self, from: metadataData)
        }
        
        // Load strokes
        if let strokesEntry = pageArchive["strokes.bin"] {
            var strokesData = Data()
            _ = try pageArchive.extract(strokesEntry) { data in
                strokesData.append(data)
            }
            page.strokes = parseStrokesWithReader(from: strokesData)
        }
     
        // Load text elements
        if let textEntry = pageArchive["text.json"] {
            var textData = Data()
            _ = try pageArchive.extract(textEntry) { data in
                textData.append(data)
            }
            let decoder = JSONDecoder()
            page.textElements = try decoder.decode([TextElement].self, from: textData)
        }
        
        // Load shapes
        if let shapesEntry = pageArchive["shapes.json"] {
            var shapesData = Data()
            _ = try pageArchive.extract(shapesEntry) { data in
                shapesData.append(data)
            }
            let decoder = JSONDecoder()
            page.shapes = try decoder.decode([Shape].self, from: shapesData)
        }
        
        // Load images
        for entry in pageArchive where entry.path.hasPrefix("images/") {
            let imageName = entry.path
                .replacingOccurrences(of: "images/", with: "")
                .replacingOccurrences(of: ".webp", with: "")
            
            var imageData = Data()
            _ = try pageArchive.extract(entry) { data in
                imageData.append(data)
            }
            page.images[imageName] = imageData
        }
        
        return page
    }
    
    // MARK: - Parse Strokes
    
    private static func parseStrokes(from data: Data) -> [Stroke] {
            var strokes: [Stroke] = []
            
            guard data.count >= 4 else {
                print("Stroke data too short to contain count")
                return strokes
            }
            
            var offset = 0
            
            // Read stroke count safely
            let strokeCount = data.withUnsafeBytes { bytes in
                // Create aligned buffer for reading
                var value: UInt32 = 0
                memcpy(&value, bytes.baseAddress!.advanced(by: offset), MemoryLayout<UInt32>.size)
                return value.littleEndian
            }
            offset += 4
            
            print("Parsing \(strokeCount) strokes from \(data.count) bytes")
            
            guard strokeCount <= 10000 else {
                print("Suspicious stroke count: \(strokeCount)")
                return strokes
            }
            
            for i in 0..<strokeCount {
                guard offset + 4 <= data.count else {
                    print("Not enough data for stroke \(i) length")
                    break
                }
                
                // Read stroke length safely
                let strokeLen = data.withUnsafeBytes { bytes in
                    var value: UInt32 = 0
                    memcpy(&value, bytes.baseAddress!.advanced(by: offset), MemoryLayout<UInt32>.size)
                    return value.littleEndian
                }
                offset += 4
                
                guard Int(strokeLen) <= data.count - offset else {
                    print("Stroke \(i) length \(strokeLen) exceeds remaining buffer")
                    break
                }
                
                // Parse individual stroke
                let strokeData = data.subdata(in: offset..<(offset + Int(strokeLen)))
                if let stroke = parseStrokeData(from: strokeData) {
                    strokes.append(stroke)
                }
                
                offset += Int(strokeLen)
            }
            
            print("Successfully parsed \(strokes.count) strokes")
            return strokes
        }
        
        // MARK: - Parse Individual Stroke (Fixed)
        
        private static func parseStrokeData(from data: Data) -> Stroke? {
            guard data.count >= 53 else { return nil }
            
            var offset = 0
            
            // Read ID (36 bytes)
            let idData = data.subdata(in: offset..<(offset + 36))
            let id = String(data: idData, encoding: .utf8)?
                .trimmingCharacters(in: CharacterSet(charactersIn: "\0")) ?? ""
            offset += 36
            
            // Read type
            let type = data[offset]
            offset += 1
            
            // Read color (RGBA)
            let color = [
                data[offset],
                data[offset + 1],
                data[offset + 2],
                data[offset + 3]
            ]
            offset += 4
            
            // Read width (Float32) safely
            let width = data.withUnsafeBytes { bytes in
                var value: Float32 = 0
                memcpy(&value, bytes.baseAddress!.advanced(by: offset), MemoryLayout<Float32>.size)
                return value
            }
            offset += 4
            
            // Read timestamp (Double) safely
            let timestamp = data.withUnsafeBytes { bytes in
                var value: Double = 0
                memcpy(&value, bytes.baseAddress!.advanced(by: offset), MemoryLayout<Double>.size)
                return value
            }
            offset += 8
            
            // Read point count safely
            let pointCount = data.withUnsafeBytes { bytes in
                var value: UInt32 = 0
                memcpy(&value, bytes.baseAddress!.advanced(by: offset), MemoryLayout<UInt32>.size)
                return value
            }
            offset += 4
            
            // Read points
            var points: [StrokePoint] = []
            for _ in 0..<pointCount {
                guard offset + 5 <= data.count else { break }
                
                // Read x coordinate (UInt16) safely
                let x = data.withUnsafeBytes { bytes in
                    var value: UInt16 = 0
                    memcpy(&value, bytes.baseAddress!.advanced(by: offset), MemoryLayout<UInt16>.size)
                    return Float(value.littleEndian) / 10.0
                }
                
                // Read y coordinate (UInt16) safely
                let y = data.withUnsafeBytes { bytes in
                    var value: UInt16 = 0
                    memcpy(&value, bytes.baseAddress!.advanced(by: offset + 2), MemoryLayout<UInt16>.size)
                    return Float(value.littleEndian) / 10.0
                }
                
                // Read pressure (UInt8)
                let pressure = Float(data[offset + 4]) / 255.0
                
                points.append(StrokePoint(x: x, y: y, pressure: pressure))
                offset += 5
            }
            
            return Stroke(
                id: id,
                type: type,
                color: color,
                width: width,
                timestamp: timestamp,
                points: points
            )
        }
    
    static func parseStrokesWithReader(from data: Data) -> [Stroke] {
           var strokes: [Stroke] = []
           let reader = DataReader(data: data)
           
           guard let strokeCount = reader.readUInt32() else {
               print("Failed to read stroke count")
               return strokes
           }
           
           print("Parsing \(strokeCount) strokes")
           
           guard strokeCount <= 10000 else {
               print("Suspicious stroke count: \(strokeCount)")
               return strokes
           }
           
           for i in 0..<strokeCount {
               guard let strokeLen = reader.readUInt32() else {
                   print("Failed to read stroke \(i) length")
                   break
               }
               
               guard let strokeData = reader.readBytes(count: Int(strokeLen)) else {
                   print("Failed to read stroke \(i) data")
                   break
               }
               
               if let stroke = parseStrokeDataWithReader(from: strokeData) {
                   strokes.append(stroke)
               }
           }
           
           return strokes
       }
       
       static func parseStrokeDataWithReader(from data: Data) -> Stroke? {
           let reader = DataReader(data: data)
           
           guard let id = reader.readString(length: 36),
                 let type = reader.readUInt8(),
                 let r = reader.readUInt8(),
                 let g = reader.readUInt8(),
                 let b = reader.readUInt8(),
                 let a = reader.readUInt8(),
                 let width = reader.readFloat32(),
                 let timestamp = reader.readDouble(),
                 let pointCount = reader.readUInt32() else {
               return nil
           }
           
           var points: [StrokePoint] = []
           
           for _ in 0..<pointCount {
               guard let xRaw = reader.readUInt16(),
                     let yRaw = reader.readUInt16(),
                     let pressureRaw = reader.readUInt8() else {
                   break
               }
               
               let x = Float(xRaw) / 10.0
               let y = Float(yRaw) / 10.0
               let pressure = Float(pressureRaw) / 255.0
               
               points.append(StrokePoint(x: x, y: y, pressure: pressure))
           }
           
           return Stroke(
               id: id,
               type: type,
               color: [r, g, b, a],
               width: width,
               timestamp: timestamp,
               points: points
           )
       }
}

// MARK: - Error Types

enum TalyaError: LocalizedError {
    case invalidFileType
    case failedToOpenArchive
    case missingManifest
    case missingPageIndex
    case missingSearchIndex
    case invalidPageIndex
    case pageNotFound(String)
    case failedToOpenPageBundle
    case noDocumentLoaded
    
    var errorDescription: String? {
        switch self {
        case .invalidFileType:
            return "Please select a valid .talya file"
        case .failedToOpenArchive:
            return "Failed to open the archive"
        case .missingManifest:
            return "Invalid Talya file: missing manifest"
        case .missingPageIndex:
            return "Invalid Talya file: missing page index"
        case .missingSearchIndex:
            return "Search index not found (this is optional)"
        case .invalidPageIndex:
            return "Invalid page index"
        case .pageNotFound(let filename):
            return "Page file not found: \(filename)"
        case .failedToOpenPageBundle:
            return "Failed to open page bundle"
        case .noDocumentLoaded:
            return "no Document Loaded"
        }
    }
}
