//
//  TalyaDocumentManager.swift
//  TalyaDemo
//
//  Created by liusilan on 2025/9/7.
//

import Foundation
import ZIPFoundation

// Alternative approach using a DocumentManager class
class TalyaDocumentManager {
    var currentDocument: TalyaDocument?
    private let loadingQueue = DispatchQueue(label: "com.talya.documentLoader")
    
    func loadDocument(from url: URL, completion: @escaping (Result<TalyaDocument, Error>) -> Void) {
        loadingQueue.async {
            do {
                guard url.pathExtension == "talya" else {
                    throw TalyaError.invalidFileType
                }
                
              do {
                let archive = try Archive(url: url, accessMode: .read)

                let manifest = try TalyaDocumentLoader.loadManifest(from: archive)
                let searchIndex = try? TalyaDocumentLoader.loadSearchIndex(from: archive)
                let pageIndex = try TalyaDocumentLoader.loadPageIndex(from: archive)
                
                let document = TalyaDocument(
                    manifest: manifest,
                    pageIndex: pageIndex,
                    searchIndex: searchIndex,
                    zipArchive: archive
                )
                
                self.currentDocument = document
                
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
    
    func loadPage(at index: Int, completion: @escaping (Result<TalyaPage, Error>) -> Void) {
        print("[TalyaDocumentManager] loadPage at:\(index)")
        guard var document = currentDocument else {
            print("[TalyaDocumentManager] loadPage, at:\(index), noDocumentLoaded")
            completion(.failure(TalyaError.noDocumentLoaded))
            return
        }
        
        // Check cache first
        if let cachedPage = document.pages[index] {
            print("[TalyaDocumentManager] loadPage, at:\(index), cache")
            completion(.success(cachedPage))
            return
        }
        
        loadingQueue.async { [weak self] in
            do {
                guard index >= 0 && index < document.pageIndex.count else {
                    print("[TalyaDocumentManager] loadPage, at:\(index), invalidPageIndex")
                    throw TalyaError.invalidPageIndex
                }
                
                let pageInfo = document.pageIndex[index]
                
                guard let pageEntry = document.zipArchive[pageInfo.filename] else {
                    print("[TalyaDocumentManager] loadPage, at:\(index), pageNotFound")
                    throw TalyaError.pageNotFound(pageInfo.filename)
                }
                
                print("[TalyaDocumentManager] begin extract:\(pageInfo.filename), at:\(index)")
              
                var i = 0
                var pageData = Data()
                _ = try document.zipArchive.extract(pageEntry) { data in
                    i += 1
                    pageData.append(data)
                }
              
                print("[TalyaDocumentManager] do next, loadPageBundle from data, at:\(index)")
                
                let page = try TalyaDocumentLoader.loadPageBundle(from: pageData)
                
                // Cache the page
                self?.loadingQueue.async(flags: .barrier) {
                    print("[TalyaDocumentManager] loadPage, at:\(index), finished, cache page")
                    document.pages[index] = page
                }
                
                DispatchQueue.main.async {
                    completion(.success(page))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
