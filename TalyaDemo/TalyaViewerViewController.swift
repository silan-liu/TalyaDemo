//
//  ViewController.swift
//  TalyaDemo
//
//  Created by liusilan on 2025/9/7.
//

import UIKit
import UniformTypeIdentifiers
import ZIPFoundation

// MARK: - Main View Controller
class TalyaViewerViewController: UIViewController {
    
    // UI Components
  private var documentPicker: UIDocumentPickerViewController?

  private let canvasView = ScrollableCanvasView()
    private let pageNavigationView = PageNavigationView()
    private let zoomControlsView = ZoomControlsView()
    private let sidebarView = SidebarView()
    private let welcomeView = WelcomeView()
    private let loadingView = LoadingView()
    
    // Document State
//    private var currentDocument: TalyaDocument?
    private var currentPageIndex = 0
    private var currentScale: CGFloat = 1.0
    
    // Layout Constraints
    private var sidebarWidthConstraint: NSLayoutConstraint!
    
    private let documentManager = TalyaDocumentManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupGestures()
 
        if let testTalyaURL = Bundle.main .url(forResource: "document9_parallel", withExtension: "talya") {
//            talyaParser.loadTalyaDocument(talyaFileURL: testTalyaURL)
//            talyaParser.parseDocument(talyaFileURL: testTalyaURL)
            loadDocument(from: testTalyaURL)
            
        }
    }
    
    func loadDocument(from url: URL) {
        documentManager.loadDocument(from: url) { [weak self] result in
            switch result {
            case .success(let document):
//                self?.currentDocument = document
                self?.documentLoaded(document)
                
            case .failure(let error):
                self?.showError(error)
            }
        }
    }
    
    private func loadPage(at index: Int) {
        guard let document = documentManager.currentDocument,
                  index >= 0,
                  index < document.pageCount else { return }
                  
            currentPageIndex = index
            showLoading(true)
            
            documentManager.loadPage(at: index) { [weak self]  result in
                self?.showLoading(false)
                switch result {
                case .success(let page):
                    self?.displayPage(page)
                    
                case .failure(let error):
                    self?.showError(error)
                }
            }
        }
    
    private func documentLoaded(_ document: TalyaDocument) {
        print("Document loaded: \(document.manifest.title)")
        print("Pages: \(document.pageCount)")
        print("Search enabled: \(document.searchIndex != nil)")
        
//      canvasView.isHidden = false
      canvasView.resetScale()
        self.currentPageIndex = 0
        self.showViewer()
        self.loadPage(at: self.currentPageIndex)
        self.updateDocumentInfo()
    }
    
    private func displayPage(_ page: TalyaPage) {
        print("Displaying page with:")
        print("  Strokes: \(page.strokes.count)")
        print("  Text elements: \(page.textElements.count)")
        print("  Images: \(page.images.count)")
        
        self.canvasView.page = page
        self.renderCurrentPage()
        self.updateNavigation()
        self.updatePageStats(page)
        self.showLoading(false)
        self.updateToolbar()
    }
    
    private func showError(_ error: Error) {
        print("Error: \(error.localizedDescription)")
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.white
        
        // Add subviews
        [canvasView, welcomeView, loadingView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        // Initially hide canvas and sidebar
        canvasView.isHidden = true
        sidebarView.isHidden = true
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Sidebar
//            sidebarView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
//            sidebarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            sidebarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            sidebarView.widthAnchor.constraint(equalToConstant: 250),
//            
            // Canvas View
            canvasView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            canvasView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            
            // Welcome View
            welcomeView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            welcomeView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            welcomeView.widthAnchor.constraint(lessThanOrEqualToConstant: 500),
            welcomeView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            welcomeView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            // Loading View
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Setup controls
        pageNavigationView.delegate = self
        zoomControlsView.delegate = self
    }
    
    private func setupNavigationBar() {
        title = "Talya Document Viewer"
        
        // Add file picker button
        let openButton = UIBarButtonItem(title: "Open", style: .plain, target: self, action: #selector(openFilePicker))
        navigationItem.rightBarButtonItem = openButton
        
        // Add navigation controls to toolbar
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)
        
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // Configure toolbar items
        updateToolbar()
    }
    
    private func updateToolbar() {
        var items: [UIBarButtonItem] = []
        
        if documentManager.currentDocument != nil {
            items.append(contentsOf: pageNavigationView.toolbarItems)
            items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
            items.append(contentsOf: zoomControlsView.toolbarItems)
        }
        
        navigationController?.toolbar.items = items
      navigationController?.toolbar.backgroundColor = .white
        navigationController?.setToolbarHidden(documentManager.currentDocument == nil, animated: true)
    }
    
    private func setupGestures() {
        // Pinch to zoom
//        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
//        canvasView.addGestureRecognizer(pinchGesture)
        
        // Pan to scroll
//        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//        canvasView.addGestureRecognizer(panGesture)
    }
    
    @objc private func openFilePicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType(filenameExtension: "talya") ?? .data])
        documentPicker.delegate = self
        present(documentPicker, animated: true)
      
      self.documentPicker = documentPicker
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.state == .changed else { return }
        
        currentScale *= gesture.scale
        currentScale = max(0.3, min(currentScale, 3.0))
        gesture.scale = 1.0
        
        renderCurrentPage()
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
//        let translation = gesture.translation(in: canvasView)
//        canvasView.contentOffset = CGPoint(
//            x: canvasView.contentOffset.x - translation.x,
//            y: canvasView.contentOffset.y - translation.y
//        )
//        gesture.setTranslation(.zero, in: canvasView)
    }
    
//    private func loadTalyaDocument(from url: URL) {
//        showLoading(true)
//        
//        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//            do {
//                let data = try Data(contentsOf: url)
//                let document = try TalyaDocument.load(from: data)
//                
//                DispatchQueue.main.async {
//                    self?.currentDocument = document
//                    self?.currentPageIndex = 0
//                    self?.showViewer()
//                    self?.loadPage(at: 0)
//                    self?.updateDocumentInfo()
//                    self?.showLoading(false)
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    self?.showLoading(false)
//                    self?.showError("Failed to load document: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
    
//    private func loadPage(at index: Int) {
//        guard var document = currentDocument,
//              index >= 0,
//              index < document.pageCount else { return }
//        
//        showLoading(true)
//        currentPageIndex = index
//        
//        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//            do {
//                let page = try document.loadPage(at: index)
//                
//                DispatchQueue.main.async {
//                    self?.canvasView.page = page
//                    self?.renderCurrentPage()
//                    self?.updateNavigation()
//                    self?.updatePageStats(page)
//                    self?.showLoading(false)
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    self?.showLoading(false)
//                    self?.showError("Failed to load page: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
    
    private func renderCurrentPage() {
        canvasView.scale = currentScale
    }
    
    private func showViewer() {
        welcomeView.isHidden = true
        canvasView.isHidden = false
        sidebarView.isHidden = false
        updateToolbar()
    }
    
    private func showLoading(_ show: Bool) {
        loadingView.isHidden = !show
    }
    
    private func currentDocument() -> TalyaDocument? {
        return self.documentManager.currentDocument
    }
    
    private func updateDocumentInfo() {
        guard let document = documentManager.currentDocument else { return }
        sidebarView.updateDocumentInfo(document)
        pageNavigationView.totalPages = document.pageCount
    }
    
    private func updateNavigation() {
        pageNavigationView.currentPage = currentPageIndex + 1
        pageNavigationView.updateButtons()
    }
    
    private func updatePageStats(_ page: TalyaPage) {
        sidebarView.updatePageStats(
            strokes: page.strokes.count,
            textElements: page.textElements.count,
            images: page.images.count
        )
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Document Picker Delegate
extension TalyaViewerViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
          
      let result = DocumentManager.copyDocumentToSandbox(from: url, subdirectory:"picker")
      
      switch result {
      case let .success(destURL):
        print("begin load document from:\(destURL)")
        loadDocument(from: destURL)

        break
      case let .failure(error):
        break
      }
      
      print("copyDocumentToSandbox reuslt:\(result)")
      self.documentPicker = nil
    }
  
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    self.documentPicker = nil
  }
}

// MARK: - Page Navigation Delegate
extension TalyaViewerViewController: PageNavigationDelegate {
    func didTapPrevious() {
        guard currentPageIndex > 0 else { return }
      
            canvasView.resetScale()

        loadPage(at: currentPageIndex - 1)
    }
    
    func didTapNext() {
        guard let document = documentManager.currentDocument,
              currentPageIndex < document.pageCount - 1 else { return }
      
      canvasView.resetScale()

        loadPage(at: currentPageIndex + 1)
    }
}

// MARK: - Zoom Controls Delegate
extension TalyaViewerViewController: ZoomControlsDelegate {
    func didTapZoomIn() {
      currentScale = min(canvasView.scale * 1.2, 3.0)
        renderCurrentPage()
    }
    
    func didTapZoomOut() {
        currentScale = max(canvasView.scale / 1.2, 0.3)
        renderCurrentPage()
    }
    
    func didTapZoomReset() {
      currentScale = canvasView.minScale()
      renderCurrentPage()
    }
}

