import UIKit

protocol CanvasPageCellDelegate2: AnyObject {
    func canvasPageCellDidBeginDrawing(_ cell: CanvasPageCell2)
    func canvasPageCellDidEndDrawing(_ cell: CanvasPageCell2)
    func loadPageAtIndex(index:Int)
}

// MARK: - Page Cell
class CanvasPageCell2: UITableViewCell {
    
    static let identifier = "CanvasPageCell"
    
    // 页面视图
    private let pageView = UIView()
    private let canvasView = CanvasView()
    private let pageNumberLabel = UILabel()
    
    // 绘制层
    private var drawingLayer = CAShapeLayer()
    private var currentPath: UIBezierPath?
    
    // 橡皮擦相关 - 添加这两个属性
    private var eraserLayer = CAShapeLayer()
    private var eraserPath: UIBezierPath?
    private let eraserIndicatorView = UIView()
    
    private let loadButton = UIButton(type: .system)
  
    var panGesture: UIPanGestureRecognizer?
  

    // 当前页面数据
    var page: CanvasPage? {
        didSet {
            updatePageContent()
        }
    }
    
    // 当前工具
    var currentTool: DrawingTool = .pen
    
    // 绘制设置
    var penColor: UIColor = .black {
        didSet {
            drawingLayer.strokeColor = penColor.cgColor
        }
    }
    
    var penWidth: CGFloat = 2.0 {
        didSet {
            drawingLayer.lineWidth = penWidth
        }
    }
    
    var eraserWidth: CGFloat = 20.0 {
        didSet {
            if eraserLayer.superlayer != nil {
                eraserLayer.lineWidth = eraserWidth
            }
        }
    }
  
  var scale: CGFloat = 1.0 {
    didSet {
      canvasView.scale = scale
    }
  }
    
    // 是否允许编辑
  var isEditingEnabled: Bool = false {
    didSet {
      if isEditingEnabled {
        setupGestures()
      } else {
        removeGestures()
      }
    }
  }
    
    // 绘制代理
    weak var delegate: CanvasPageCellDelegate2?
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
  
  func updateTalyaPage(_ talyaPage: TalyaPage) {
    self.page?.talyaPage = talyaPage
    
    self.loadButton.isHidden = true
    canvasView.page = talyaPage
    canvasView.setNeedsDisplay()
  }
    
  private func setupViews() {
          selectionStyle = .none
          backgroundColor = .clear
          contentView.backgroundColor = .clear
          
          // 设置页面容器（带阴影）
          contentView.addSubview(pageView)
          pageView.backgroundColor = .white
          pageView.layer.shadowColor = UIColor.black.cgColor
          pageView.layer.shadowOpacity = 0.1
          pageView.layer.shadowOffset = CGSize(width: 0, height: 2)
          pageView.layer.shadowRadius = 4
          
          // 设置画布
          pageView.addSubview(canvasView)
          canvasView.backgroundColor = .white
          canvasView.clipsToBounds = true
          
          // 添加绘制层
          drawingLayer.strokeColor = UIColor.black.cgColor
          drawingLayer.fillColor = nil
          drawingLayer.lineWidth = 2.0
          drawingLayer.lineCap = .round
          drawingLayer.lineJoin = .round
          canvasView.layer.addSublayer(drawingLayer)
    
          // load button
          pageView.addSubview(loadButton)
          loadButton.frame = CGRectMake(0, 0, 200, 30)
          loadButton.setTitle("click to load page", for: .normal)
          loadButton.addTarget(self, action: #selector(loadPageAction), for: .touchUpInside)
          
//          // 配置并添加橡皮擦层（用于显示橡皮擦路径）
//          eraserLayer.strokeColor = UIColor.systemRed.cgColor  // 使用红色更明显
//          eraserLayer.fillColor = UIColor.red.cgColor
//          eraserLayer.lineWidth = 20.0
//          eraserLayer.lineCap = .round
//          eraserLayer.lineJoin = .round
//          eraserLayer.opacity = 1  // 半透明显示橡皮擦轨迹
//          eraserLayer.lineDashPattern = [5, 5]  // 虚线效果
//          pageView.layer.addSublayer(eraserLayer)  // 重要：添加到画布！
//    
          // 设置橡皮擦指示器视图
          eraserIndicatorView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
          eraserIndicatorView.layer.borderColor = UIColor.systemRed.cgColor
          eraserIndicatorView.layer.borderWidth = 2.0
          eraserIndicatorView.isHidden = true
          eraserIndicatorView.isUserInteractionEnabled = false
        
           eraserIndicatorView.frame = CGRect(
            x:0, y:0,
            width: eraserWidth,
               height: eraserWidth
           )
    
         eraserIndicatorView.layer.cornerRadius = eraserWidth/2
    
        pageView.addSubview(eraserIndicatorView)
          
          // 页码标签
          contentView.addSubview(pageNumberLabel)
          pageNumberLabel.font = .systemFont(ofSize: 12)
          pageNumberLabel.textColor = .systemGray
          pageNumberLabel.textAlignment = .center
      }
  
      @objc private func loadPageAction(sender: UIButton) {
        print("click load page")
        delegate?.loadPageAtIndex(index: page?.pageNumber ?? 0)
      }
    
    private func setupGestures() {
        // 添加绘制手势
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDrawing(_:)))
        panGesture.delegate = self
      
      self.panGesture = panGesture
        canvasView.addGestureRecognizer(panGesture)
    }
  
  private func removeGestures() {
    if let panGesture = panGesture {
      canvasView.removeGestureRecognizer(panGesture)
    }
  }
  
  // MARK: - 复用准备
      override func prepareForReuse() {
          super.prepareForReuse()
          
          // 清理旧的绘制内容
          canvasView.layer.sublayers?.forEach { layer in
              if layer != drawingLayer {
                  layer.removeFromSuperlayer()
              }
          }
          
          // 重置状态
          drawingLayer.path = nil
          currentPath = nil
          eraserPath = nil
          eraserLayer.path = nil
          eraserIndicatorView.isHidden = true
          
          // 清除手势
          removeGestures()
          
          // 重置页面数据
          page = nil
          
          print("Cell 准备复用")
      }
      
      // MARK: - 内容更新优化
      private func updatePageContent() {
          guard let page = page else { return }
          
          // 使用 CATransaction 批量更新，提高性能
          CATransaction.begin()
          CATransaction.setDisableActions(true)
          
          // 清除旧内容
          canvasView.layer.sublayers?.forEach { layer in
              if layer != drawingLayer && layer != eraserLayer {
                  layer.removeFromSuperlayer()
              }
          }
          
          // 只在需要时加载 TalyaPage
          if let talyaPage = page.talyaPage {
              canvasView.page = talyaPage
              loadButton.isHidden = true
          } else {
              canvasView.page = nil
              loadButton.isHidden = false
          }
          
          // 恢复绘制内容
          page.drawings.forEach { layer in
              canvasView.layer.insertSublayer(layer, below: drawingLayer)
          }
          
          CATransaction.commit()
          
          // 设置其他属性
          canvasView.backgroundColor = page.backgroundColor
          pageNumberLabel.text = "Page \(page.pageNumber + 1)"
          
          canvasView.setNeedsDisplay()
      }
      
      func showLoadButton() {
          loadButton.isHidden = false
      }
      
      func hideLoadButton() {
          loadButton.isHidden = true
      }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 页面尺寸
      let pageSize = page?.size ?? CanvasPage.defaultSize
        
        // 页面位置（居中）
        let pageWidth = contentView.bounds.width - 40
        let pageHeight = pageWidth * (pageSize.height / pageSize.width)
        
        let x: CGFloat = 20
        let y: CGFloat = 20
        
        pageView.frame = CGRect(x: x, y: y, width: pageWidth, height: pageHeight)
        canvasView.frame = pageView.bounds
        
      let btnSize = CGSizeMake(150, 40)
      loadButton.frame = CGRectMake((pageView.bounds.size.width - btnSize.width) / 2, (pageView.bounds.size.height - btnSize.height) / 2, btnSize.width, btnSize.height)
              
//        // 页码位置
//        pageNumberLabel.frame = CGRect(
//            x: x,
//            y: pageHeight + y + 5,
//            width: pageWidth,
//            height: 20
//        )
    }
    
    // MARK: - Drawing
    
  @objc private func handleDrawing(_ gesture: UIPanGestureRecognizer) {
          guard isEditingEnabled else { return }
          
          let location = gesture.location(in: canvasView)
          
          switch gesture.state {
          case .began:
              if currentTool == .pen {
                  startDrawing(at: location)
              } else {
                  startErasing(at: location)
              }
              
          case .changed:
              if currentTool == .pen {
                  continueDrawing(to: location)
              } else {
                  continueErasing(to: location)
              }
              
          case .ended, .cancelled:
              if currentTool == .pen {
                  finishDrawing()
              } else {
                  finishErasing()
              }
              
          default:
              break
          }
      }
  
  private func startErasing(at point: CGPoint) {
          print("开始擦除 at: \(point)")
    eraserIndicatorView.center = point

     
       eraserIndicatorView.isHidden = false
       canvasView.bringSubviewToFront(eraserIndicatorView)
    
//          // 创建新的橡皮擦路径
//          eraserPath = UIBezierPath()
//          eraserPath?.move(to: point)
//          eraserPath?.lineWidth = eraserWidth
//
//          // 显示橡皮擦轨迹
//          eraserLayer.path = eraserPath?.cgPath
//
          // 立即开始擦除
          eraseAtPoint(point)
          
          delegate?.canvasPageCellDidBeginDrawing(self)
      }
      
      private func continueErasing(to point: CGPoint) {
        // 更新橡皮擦指示器位置
           eraserIndicatorView.center = point
//
//          // 添加到橡皮擦路径
//          eraserPath?.addLine(to: point)
//
//          // 更新橡皮擦轨迹显示
//          eraserLayer.path = eraserPath?.cgPath
          
          // 持续擦除经过的点
          eraseAtPoint(point)
      }
      
      private func finishErasing() {
          print("结束擦除")
        
        // 隐藏橡皮擦指示器
           eraserIndicatorView.isHidden = true
          
          // 清除橡皮擦路径显示
          eraserLayer.path = nil
          eraserPath = nil
          
          delegate?.canvasPageCellDidEndDrawing(self)
      }
      
      private func eraseAtPoint(_ point: CGPoint) {
          // 创建橡皮擦的碰撞区域
          let eraserRadius = eraserWidth / 2
          
          print("擦除位置: \(point), 半径: \(eraserRadius)")
          print("当前绘制层数量: \(page?.drawings.count ?? 0)")
          
          // 需要删除的层
          var layersToRemove: [CAShapeLayer] = []
          
          // 检查所有绘制层
          for layer in page?.drawings ?? [] {
              guard let path = layer.path else {
                  continue
              }
              
              // 创建一个扩展的路径用于碰撞检测
              let strokedPath = path.copy(strokingWithWidth: eraserRadius * 2,
                                          lineCap: .round,
                                          lineJoin: .round,
                                          miterLimit: 10)
              
              // 检查点是否在扩展路径内
              if strokedPath.contains(point) {
                  layersToRemove.append(layer)
                  print("找到相交的层，将删除")
              }
          }
          
          // 移除相交的层
          print("将删除 \(layersToRemove.count) 个层")
          for layer in layersToRemove {
              layer.removeFromSuperlayer()
              if let index = page?.drawings.firstIndex(of: layer) {
                  page?.drawings.remove(at: index)
                  print("已删除层，剩余: \(page?.drawings.count ?? 0)")
              }
          }
      }
    
    private func startDrawing(at point: CGPoint) {
        currentPath = UIBezierPath()
        currentPath?.move(to: point)
        delegate?.canvasPageCellDidBeginDrawing(self)
    }
    
    private func continueDrawing(to point: CGPoint) {
        currentPath?.addLine(to: point)
        drawingLayer.path = currentPath?.cgPath
    }
    
    private func finishDrawing() {
        if let path = currentPath {
            // 保存绘制路径
            let newLayer = CAShapeLayer()
            newLayer.path = path.cgPath
            newLayer.strokeColor = drawingLayer.strokeColor
            newLayer.fillColor = drawingLayer.fillColor
            newLayer.lineWidth = drawingLayer.lineWidth
            newLayer.lineCap = drawingLayer.lineCap
            newLayer.lineJoin = drawingLayer.lineJoin
            
            canvasView.layer.addSublayer(newLayer)
            page?.drawings.append(newLayer)
            
            // 清除临时路径
            drawingLayer.path = nil
            currentPath = nil
            
            delegate?.canvasPageCellDidEndDrawing(self)
        }
    }
    
    // MARK: - Content Update
    
    // MARK: - Public Methods
    
    func clearDrawings() {
        page?.drawings.forEach { $0.removeFromSuperlayer() }
        page?.drawings.removeAll()
        drawingLayer.path = nil
        currentPath = nil
    }
    
    func exportAsImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(canvasView.bounds.size, true, 0)
        canvasView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK: - Gesture Recognizer Methods
extension CanvasPageCell2 {
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                   shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 绘制手势优先
        if gestureRecognizer is UIPanGestureRecognizer {
            return false
        }
        return true
    }
}

// MARK: - MultiPageCanvasView (带缩放的ScrollView包装)
class MultiPageCanvasView2: UIView {
    
    // MARK: - Properties
    
    // 使用 ScrollView 包装 TableView 实现缩放
    private let scrollView = UIScrollView()
    private let containerView = UIView()
    private let tableView = UITableView()
    private var pages: [CanvasPage] = []
  
  // 预加载管理
      private var loadingPages = Set<Int>()
      private let preloadOffset = 2 // 预加载前后2页
    
    // 当前工具
    var currentTool: DrawingTool = .pen
    
    // 绘制设置
    var penColor: UIColor = .black {
        didSet {
          updateAllCellsTools()
        }
    }
    
    var penWidth: CGFloat = 2.0 {
        didSet {
          updateAllCellsTools()
        }
    }
    
    var eraserWidth: CGFloat = 20.0 {
        didSet {
          updateAllCellsTools()
        }
    }
    
      // 缩放相关
      var minimumZoomScale: CGFloat = 0.5 {
          didSet {
              scrollView.minimumZoomScale = minimumZoomScale
          }
      }
      
      var maximumZoomScale: CGFloat = 3 {
          didSet {
              scrollView.maximumZoomScale = maximumZoomScale
          }
      }
      
      var currentZoomScale: CGFloat {
          return scrollView.zoomScale
      }
    
    // 当前页面
    var currentPageIndex: Int {
        let visibleRect = CGRect(
            origin: scrollView.contentOffset,
            size: scrollView.bounds.size
        )
        let visiblePoint = CGPoint(
            x: visibleRect.midX,
            y: visibleRect.midY
        )
        
        // 转换坐标到 tableView
        let tablePoint = containerView.convert(visiblePoint, to: tableView)
        
        if let indexPath = tableView.indexPathForRow(at: tablePoint) {
            return indexPath.row
        }
        return 0
    }
  
    func updateZoomScale(zoomScale: CGFloat) {
      scrollView.zoomScale = zoomScale
      updateAllCellsScale()
    }
    
    func clearCurrentPageDrawings() {
        let currentIndex = currentPageIndex
        let indexPath = IndexPath(row: currentIndex, section: 0)
        if let cell = tableView.cellForRow(at: indexPath) as? CanvasPageCell {
            cell.clearDrawings()
        }
    }
  
    func updateTalyaPage(index: NSInteger, talyaPage: TalyaPage) {
      let indexPath = IndexPath(row: index, section: 0)
      if let cell = tableView.cellForRow(at: indexPath) as? CanvasPageCell {
        cell.updateTalyaPage(talyaPage)
        
        print("cell updateTalyaPage:\(index)")
      }
    }
    
    // 代理
    weak var delegate: MultiPageCanvasViewDelegate2?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        createInitialPages()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        createInitialPages()
    }
    
    private func setupViews() {
        backgroundColor = .systemGray6
        
        addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemGray6
        tableView.showsVerticalScrollIndicator = true
        tableView.isScrollEnabled = true
        
        // 注册 Cell
        tableView.register(CanvasPageCell.self, forCellReuseIdentifier: CanvasPageCell.identifier)
        
        // 添加双击手势
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
      
        setupZoomGesture()
    }
  
  // MARK: - 缩放处理
      private var currentScale: CGFloat = 1.0
      private var pinchGesture: UIPinchGestureRecognizer!
      
      private func setupZoomGesture() {
          pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
          tableView.addGestureRecognizer(pinchGesture)
      }
      
      @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
          switch gesture.state {
          case .began, .changed:
              let newScale = currentScale * gesture.scale
              let clampedScale = max(minimumZoomScale, min(maximumZoomScale, newScale))
              
              // 只更新可见的 cells
              updateVisibleCellsScale(clampedScale)
              
              if gesture.state == .changed {
                  gesture.scale = 1.0
              }
              
          case .ended:
              currentScale = currentScale * gesture.scale
              currentScale = max(minimumZoomScale, min(maximumZoomScale, currentScale))
              
              // 刷新所有可见 cells
              tableView.visibleCells.forEach { cell in
                  if let canvasCell = cell as? CanvasPageCell {
                      canvasCell.scale = currentScale
                  }
              }
              
          default:
              break
          }
      }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        scrollView.frame = bounds
        updateContentSize()
    }
  
  func updatePages(_ pages: [CanvasPage]) {
    self.pages = pages
    updateContentSize()
  }
    
    private func updateContentSize() {
        // 计算 TableView 的总高度
//        var totalHeight: CGFloat = 0
//        for i in 0..<pages.count {
//            totalHeight += tableHeightForRow(at: i)
//        }
//        
//        // 设置容器和 TableView 的大小
//        containerView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: totalHeight)
//        tableView.frame = containerView.bounds
//        
//        // 设置 ScrollView 的 contentSize
//        scrollView.contentSize = containerView.frame.size
//        
//        // 刷新 TableView
//        tableView.reloadData()
    }
    
    private func tableHeightForRow(at index: Int) -> CGFloat {
        let pageSize = pages[index].size
        let pageWidth = bounds.width - 40
        let pageHeight = pageWidth * (pageSize.height / pageSize.width)
        return pageHeight + 40 // 页面高度 + 上下边距 + 页码空间
    }
    
    private func createInitialPages() {
        // 创建初始页面
        for i in 0..<3 {
            let page = CanvasPage(pageNumber: i)
            pages.append(page)
        }
        updateContentSize()
    }
    
    // MARK: - Zoom Handling
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            // 恢复到最小缩放
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            // 放大到点击位置
            let location = gesture.location(in: containerView)
            let zoomRect = zoomRectForScale(2.0, center: location)
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    private func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.width = scrollView.frame.width / scale
        zoomRect.size.height = scrollView.frame.height / scale
        zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    // MARK: - Tool Management
    
    private func updateAllCellsTools() {
      let cells = visibleCells()
      cells.forEach { cell in
            if let canvasCell = cell as? CanvasPageCell {
                canvasCell.currentTool = currentTool
                canvasCell.penColor = penColor
                canvasCell.penWidth = penWidth
                canvasCell.eraserWidth = eraserWidth
            }
        }
    }
    
    func switchToPen() {
        currentTool = .pen
        updateAllCellsTools()
    }
    
    func switchToEraser() {
        currentTool = .eraser
        updateAllCellsTools()
    }
  
    private func updateAllCellsScale() {
      let cells = visibleCells()
      cells.forEach { cell in
            if let canvasCell = cell as? CanvasPageCell {
              canvasCell.scale = scrollView.zoomScale
              
              print("updateAllCellsScale cell:\(canvasCell.page?.pageNumber ?? -1), \(scrollView.zoomScale)")
            }
        }
    }
    
    private func updateAllCellsEditEnabled(_ enabled: Bool) {
      let cells = visibleCells()
      cells.forEach { cell in
            if let canvasCell = cell as? CanvasPageCell {
              canvasCell.isEditingEnabled = enabled
              
              print("updateAllCellsEditEnabled cell:\(canvasCell.page?.pageNumber ?? -1), \(scrollView.zoomScale)")
            }
        }
    }
  
  func visibleCells() -> [UITableViewCell] {
    guard let indexPaths = tableView.indexPathsForVisibleRows else { return [] }
      
      return indexPaths.compactMap { indexPath in
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
          
          // 检查cell是否完全可见
        let visibleRect = self.frame
        
        // 转换cell的frame到tableView坐标系
        let cellFrame = cell.convert(cell.bounds, to: self)
        
        print("visibleRect:\(visibleRect), cellRect:\(cellFrame),  frame:\(self.frame)")

        // 检查是否在可见区域内
        if visibleRect.intersects(cellFrame) {
              return cell
          }
          return nil
      }
  }
    
    // MARK: - Page Management
    
    func addNewPage(at index: Int? = nil) {
        let pageIndex = index ?? pages.count
        let newPage = CanvasPage(pageNumber: pageIndex)
        
        pages.insert(newPage, at: pageIndex)
        
        // 更新后续页码
        for i in pageIndex..<pages.count {
            pages[i].pageNumber = i
        }
        
        updateContentSize()
        delegate?.multiPageCanvasView(self, didAddPageAt: pageIndex)
    }
    
    func removePage(at index: Int) {
        guard index < pages.count && pages.count > 1 else { return }
        
        pages.remove(at: index)
        
        // 更新后续页码
        for i in index..<pages.count {
            pages[i].pageNumber = i
        }
        
        updateContentSize()
        delegate?.multiPageCanvasView(self, didRemovePageAt: index)
    }
    
    func scrollToPage(_ index: Int, animated: Bool = true) {
        guard index < pages.count else { return }
      
      loadPageAtIndex(index: index)
        
        var yOffset: CGFloat = 0
        for i in 0..<index {
            yOffset += tableHeightForRow(at: i)
        }
        
        let targetRect = CGRect(
            x: 0,
            y: yOffset,
            width: scrollView.bounds.width,
            height: tableHeightForRow(at: index)
        )
        
        scrollView.scrollRectToVisible(targetRect, animated: animated)
    }
    
    // MARK: - Zoom Methods
    
    func resetZoom(animated: Bool = true) {
        scrollView.setZoomScale(1.0, animated: animated)
    }
    
    func fitToWidth(animated: Bool = true) {
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: animated)
    }
    
    func zoomIn(animated: Bool = true) {
        let newScale = min(scrollView.zoomScale * 1.5, scrollView.maximumZoomScale)
        scrollView.setZoomScale(newScale, animated: animated)
    }
    
    func zoomOut(animated: Bool = true) {
        let newScale = max(scrollView.zoomScale / 1.5, scrollView.minimumZoomScale)
        scrollView.setZoomScale(newScale, animated: animated)
    }
    
    // MARK: - Export
    
    func exportAllPages() -> [UIImage] {
        var images: [UIImage] = []
        
        for i in 0..<pages.count {
            let indexPath = IndexPath(row: i, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) as? CanvasPageCell,
               let image = cell.exportAsImage() {
                images.append(image)
            }
        }
        
        return images
    }
    
    func exportAsPDF() -> Data? {
        let pdfData = NSMutableData()
        
        UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)
        
        for page in pages {
            UIGraphicsBeginPDFPageWithInfo(CGRect(origin: .zero, size: page.size), nil)
            
            if let context = UIGraphicsGetCurrentContext() {
                context.setFillColor(page.backgroundColor.cgColor)
                context.fill(CGRect(origin: .zero, size: page.size))
                
                page.drawings.forEach { layer in
                    layer.render(in: context)
                }
            }
        }
        
        UIGraphicsEndPDFContext()
        
        return pdfData as Data
    }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
          preloadPagesIfNeeded()
//          updateVisibleCellsScale(currentScale)
  }
      
      private func preloadPagesIfNeeded() {
          guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else { return }
          
          // 计算需要预加载的范围
          let minRow = (visibleIndexPaths.min { $0.row < $1.row }?.row ?? 0) - preloadOffset
          let maxRow = (visibleIndexPaths.max { $0.row < $1.row }?.row ?? 0) + preloadOffset
          
          let preloadRange = max(0, minRow)...min(pages.count - 1, maxRow)
          
          for index in preloadRange {
              if pages[index].talyaPage == nil && !loadingPages.contains(index) {
                  loadingPages.insert(index)
                  
                  // 异步加载页面
                  delegate?.multiPageCanvasView(self, loadPageAtIndex: index)
              }
          }
          
          // 清理不需要的页面（可选，用于内存优化）
          cleanupDistantPages(visibleRange: preloadRange)
      }
      
      private func cleanupDistantPages(visibleRange: ClosedRange<Int>) {
          for (index, page) in pages.enumerated() {
              if !visibleRange.contains(index) && page.talyaPage != nil {
                  // 可以选择清理远离可见区域的页面
                  // 但要保留用户的绘制内容
                  if page.drawings.isEmpty {
                      // page.talyaPage = nil  // 根据需要决定是否清理
                  }
              }
          }
      }
}


// MARK: - UITableViewDataSource
extension MultiPageCanvasView2: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pages.count
    }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
          let cell = tableView.dequeueReusableCell(withIdentifier: CanvasPageCell.identifier, for: indexPath) as! CanvasPageCell
          
          // ✅ 重置 cell 状态（重要！）
          cell.prepareForReuse()
          
          // 配置 cell
          cell.page = pages[indexPath.row]
          cell.delegate = self
          cell.scale = scrollView.zoomScale
          cell.currentTool = currentTool
          cell.penColor = penColor
          cell.penWidth = penWidth
          cell.eraserWidth = eraserWidth
          
          // 检查是否需要加载页面内容
//          if pages[indexPath.row].talyaPage == nil {
//              // 显示加载按钮
//              cell.showLoadButton()
//          } else {
//              // 显示内容
//              cell.hideLoadButton()
//          }
          
          print("配置 cell: \(indexPath.row), 复用: \(cell.reuseIdentifier ?? "")")
          
          return cell
      }
}

// MARK: - UITableViewDelegate
extension MultiPageCanvasView2: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableHeightForRow(at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.multiPageCanvasView(self, didSelectPageAt: indexPath.row)
    }
}

// MARK: - CanvasPageCellDelegate
extension MultiPageCanvasView2: CanvasPageCellDelegate {
    
    func canvasPageCellDidBeginDrawing(_ cell: CanvasPageCell) {
        // 绘制时禁用滚动和缩放
        scrollView.isScrollEnabled = false
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    
    func canvasPageCellDidEndDrawing(_ cell: CanvasPageCell) {
        // 恢复滚动和缩放
        scrollView.isScrollEnabled = true
        scrollView.pinchGestureRecognizer?.isEnabled = true
    }
  
  func loadPageAtIndex(index: Int) {
    delegate?.multiPageCanvasView(self, loadPageAtIndex: index)
  }
}

extension MultiPageCanvasView2 {
    
    // 更高效的可见 cells 获取
    func getVisibleCells() -> [CanvasPageCell] {
        // 直接使用 tableView 的 visibleCells
        return tableView.visibleCells.compactMap { $0 as? CanvasPageCell }
    }
    
    // 只更新可见 cells 的工具状态
    private func updateVisibleCellsTools() {
        getVisibleCells().forEach { cell in
            cell.currentTool = currentTool
            cell.penColor = penColor
            cell.penWidth = penWidth
            cell.eraserWidth = eraserWidth
        }
    }
    
    // 只更新可见 cells 的缩放
    private func updateVisibleCellsScale(_ scale: CGFloat) {
        getVisibleCells().forEach { cell in
            cell.scale = scale
        }
    }
    
    // 只更新可见 cells 的编辑状态
    func updateEnabled(_ enabled: Bool) {
        getVisibleCells().forEach { cell in
            cell.isEditingEnabled = enabled
        }
    }
}

// MARK: - Delegate Protocol
protocol MultiPageCanvasViewDelegate2: AnyObject {
    func multiPageCanvasView(_ canvasView: MultiPageCanvasView2, didSelectPageAt index: Int)
    func multiPageCanvasView(_ canvasView: MultiPageCanvasView2, didAddPageAt index: Int)
    func multiPageCanvasView(_ canvasView: MultiPageCanvasView2, didRemovePageAt index: Int)
    func multiPageCanvasView(_ canvasView: MultiPageCanvasView2, loadPageAtIndex: Int)
}

// MARK: - View Controller Example
class MultiPageCanvasViewController2: UIViewController {
    
    private let canvasView = MultiPageCanvasView2()
    private let toolbar = UIToolbar()
    private let drawingToolbar = UIToolbar()
    
    // 工具按钮
    private var enableButton: UIBarButtonItem!
    private var penButton: UIBarButtonItem!
    private var eraserButton: UIBarButtonItem!
    private var colorButton: UIBarButtonItem!
    private var editEnabled = false
    
    private let documentManager = TalyaDocumentManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupToolbar()
        setupDrawingToolbar()
        setupNavigationBar()
      
      if let testTalyaURL = Bundle.main .url(forResource: "document9_parallel", withExtension: "talya") {
          loadDocument(from: testTalyaURL)
      }
    }
  

  func loadDocument(from url: URL) {
      documentManager.loadDocument(from: url) { [weak self] result in
          switch result {
          case .success(let document):
            print("load document success")
              self?.documentLoaded(document)

          case .failure(let error):
              self?.showError(error)
          }
      }
  }

  private func showError(_ error: Error) {
      print("Error: \(error.localizedDescription)")
  }

  private func loadPage(at index: Int) {
      guard let document = documentManager.currentDocument,
                index >= 0,
                index < document.pageCount else { return }

          documentManager.loadPage(at: index) { [weak self]  result in
              switch result {
              case .success(let page):
                  self?.displayPage(page, index)

              case .failure(let error):
                  self?.showError(error)
              }
          }
      }

  private func documentLoaded(_ document: TalyaDocument) {
      print("Document loaded: \(document.manifest.title)")
      print("Pages: \(document.pageCount)")
      print("Search enabled: \(document.searchIndex != nil)")
      
    self.createPages(document)
  }
  
  private func createPages(_ document: TalyaDocument) {
    var pages: [CanvasPage] = []
    let pageCount = document.pageCount
    
    // 创建初始页面
    for i in 0..<pageCount {
        let page = CanvasPage(pageNumber: i)
        pages.append(page)
    }
    
    self.canvasView.updatePages(pages)
  }
  
  private func displayPage(_ page: TalyaPage, _ index: Int) {
      print("Displaying page with:")
      print("  Index: \(index)")
      print("  Strokes: \(page.strokes.count)")
      print("  Text elements: \(page.textElements.count)")
      print("  Images: \(page.images.count)")
      
      self.canvasView.updateTalyaPage(index: index, talyaPage: page)
  }
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        title = "Multi-Page Canvas"
        
        // 添加画布
        view.addSubview(canvasView)
        canvasView.delegate = self
//
//        // 添加工具栏
        view.addSubview(toolbar)
        view.addSubview(drawingToolbar)
//
//        // 布局
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        drawingToolbar.translatesAutoresizingMaskIntoConstraints = false
//
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            drawingToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            drawingToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            drawingToolbar.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            
            canvasView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: drawingToolbar.topAnchor)
        ])
      
//      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
//        self.canvasView.updateZoomScale(zoomScale: 1.5)
//      })
    }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
  }
    
    private func setupNavigationBar() {
        // 缩放控制
        let zoomInButton = UIBarButtonItem(
            image: UIImage(systemName: "plus.magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(zoomIn)
        )
        
        let zoomOutButton = UIBarButtonItem(
            image: UIImage(systemName: "minus.magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(zoomOut)
        )
        
        let resetZoomButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.left.and.arrow.down.right"),
            style: .plain,
            target: self,
            action: #selector(resetZoom)
        )
        
        navigationItem.rightBarButtonItems = [resetZoomButton, zoomOutButton, zoomInButton]
    }
    
    private func setupToolbar() {
//        let addPageButton = UIBarButtonItem(
//            image: UIImage(systemName: "doc.badge.plus"),
//            style: .plain,
//            target: self,
//            action: #selector(addPage)
//        )
        
        let scrollToTopButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.to.line"),
            style: .plain,
            target: self,
            action: #selector(scrollToTop)
        )
        
        let currentPageButton = UIBarButtonItem(
            title: "Page 1",
            style: .plain,
            target: self,
            action: #selector(showPagePicker)
        )
        currentPageButton.tag = 100 // 用于后续更新
        
//        let exportButton = UIBarButtonItem(
//            image: UIImage(systemName: "square.and.arrow.up"),
//            style: .plain,
//            target: self,
//            action: #selector(exportPages)
//        )
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.items = [flexSpace, scrollToTopButton, flexSpace, currentPageButton]
    }
    
    private func setupDrawingToolbar() {
      enableButton = UIBarButtonItem(
            image: UIImage(named: "enable"),
            style: .plain,
            target: self,
            action: #selector(selectEnable)
        )
      
      enableButton.tintColor = .systemBlue
      
        // 画笔按钮
        penButton = UIBarButtonItem(
            image: UIImage(systemName: "pencil"),
            style: .plain,
            target: self,
            action: #selector(selectPen)
        )
      penButton.tintColor = .systemRed
        
        // 橡皮擦按钮
        eraserButton = UIBarButtonItem(
            image: UIImage(systemName: "eraser"),
            style: .plain,
            target: self,
            action: #selector(selectEraser)
        )
        
        // 颜色选择按钮
        colorButton = UIBarButtonItem(
            image: UIImage(systemName: "paintpalette"),
            style: .plain,
            target: self,
            action: #selector(selectColor)
        )
        
        // 线宽按钮
        let lineWidthButton = UIBarButtonItem(
            image: UIImage(systemName: "lineweight"),
            style: .plain,
            target: self,
            action: #selector(selectLineWidth)
        )
        
        // 清除按钮
        let clearButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(clearCurrentPage)
        )
        clearButton.tintColor = .systemRed
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        drawingToolbar.items = [
            enableButton, flexSpace,
            penButton, flexSpace,
            eraserButton, flexSpace,
            colorButton, flexSpace,
            lineWidthButton, flexSpace,
            clearButton
        ]
    }
    
    // MARK: - Drawing Tool Actions
  @objc private func selectEnable() {
    editEnabled = !editEnabled
    canvasView.updateEnabled(editEnabled)
    
    enableButton.tintColor = editEnabled ? .systemRed : .systemBlue
  }
    
    @objc private func selectPen() {
        canvasView.switchToPen()
      penButton.tintColor = .systemRed
      eraserButton.tintColor = .systemBlue
    }
    
    @objc private func selectEraser() {
        canvasView.switchToEraser()
      eraserButton.tintColor = .systemRed
      penButton.tintColor = .systemBlue
    }
    
    @objc private func selectColor() {
        let colorPicker = UIColorPickerViewController()
        colorPicker.selectedColor = canvasView.penColor
        colorPicker.delegate = self
        present(colorPicker, animated: true)
    }
    
    @objc private func selectLineWidth() {
        let alert = UIAlertController(title: "选择线宽", message: nil, preferredStyle: .actionSheet)
        
        let widths: [(String, CGFloat)] = [
            ("细", 1.0),
            ("普通", 2.0),
            ("粗", 4.0),
            ("特粗", 8.0)
        ]
        
        for (title, width) in widths {
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                if self.canvasView.currentTool == .pen {
                    self.canvasView.penWidth = width
                } else {
                    self.canvasView.eraserWidth = width * 10 // 橡皮擦更宽
                }
            })
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = drawingToolbar.items?[6] // lineWidthButton
        }
        
        present(alert, animated: true)
    }
    
    @objc private func clearCurrentPage() {
        let alert = UIAlertController(
            title: "清除当前页面",
            message: "确定要清除当前页面的所有绘制内容吗？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "清除", style: .destructive) { _ in
            // 清除当前页面
          self.canvasView.clearCurrentPageDrawings()
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    // MARK: - Other Actions
    
    @objc private func zoomIn() {
        canvasView.zoomIn()
    }
    
    @objc private func zoomOut() {
        canvasView.zoomOut()
    }
    
    @objc private func resetZoom() {
        canvasView.resetZoom()
    }
    
    @objc private func scrollToTop() {
        canvasView.scrollToPage(0)
    }
    
    @objc private func showPagePicker() {
        // 显示页面选择器
      if let pageCount = documentManager.currentDocument?.pageCount, pageCount > 0 {
        let alert = UIAlertController(title: "跳转到页面", message: nil, preferredStyle: .actionSheet)
        
        for i in 0..<pageCount { // 假设有10页
            alert.addAction(UIAlertAction(title: "第 \(i + 1) 页", style: .default) { _ in
                self.canvasView.scrollToPage(i)
            })
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = toolbar.items?.first { $0.tag == 100 }
        }
        
        present(alert, animated: true)
      }
        
    }
    
    @objc private func addPage() {
        canvasView.addNewPage()
        
        // 滚动到新页面
        if let lastIndex = (0..<10).last {
            canvasView.scrollToPage(lastIndex)
        }
    }
    
    @objc private func exportPages() {
        let images = canvasView.exportAllPages()
        print("Exported \(images.count) pages")
        
        if !images.isEmpty {
            let activityVC = UIActivityViewController(activityItems: images, applicationActivities: nil)
            present(activityVC, animated: true)
        }
    }
  
  
}

// MARK: - UIColorPickerViewControllerDelegate
extension MultiPageCanvasViewController2: UIColorPickerViewControllerDelegate {
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        canvasView.penColor = viewController.selectedColor
        colorButton.tintColor = viewController.selectedColor
    }
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        canvasView.penColor = viewController.selectedColor
        colorButton.tintColor = viewController.selectedColor
    }
}

// MARK: - MultiPageCanvasViewDelegate
extension MultiPageCanvasViewController2: MultiPageCanvasViewDelegate2 {
    
    func multiPageCanvasView(_ canvasView: MultiPageCanvasView2, didSelectPageAt index: Int) {
        print("Selected page \(index + 1)")
        
        // 更新当前页面显示
        if let pageButton = toolbar.items?.first(where: { $0.tag == 100 }) {
            pageButton.title = "Page \(index + 1)"
        }
    }
    
    func multiPageCanvasView(_ canvasView: MultiPageCanvasView2, didAddPageAt index: Int) {
        print("Added page at index \(index)")
    }
    
    func multiPageCanvasView(_ canvasView: MultiPageCanvasView2, didRemovePageAt index: Int) {
        print("Removed page at index \(index)")
    }
  
  func multiPageCanvasView(_ canvasView: MultiPageCanvasView2, loadPageAtIndex: Int) {
    loadPage(at: loadPageAtIndex)
  }
}
