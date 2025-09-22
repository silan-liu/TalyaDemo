import UIKit
import PDFKit

class CustomPDFDocumentDelegate: NSObject, PDFDocumentDelegate {
    
    // MARK: PDFDocumentDelegate 核心方法
    
    // 返回自定义的PDFPage子类
    func classForPage() -> AnyClass {
        return DrawablePDFPage.self
    }
    
    // 可选：返回特定页面的自定义类
    func classForPage(at pageIndex: Int) -> AnyClass? {
        return DrawablePDFPage.self
    }
    
    // 文档加载完成后调用
    func didMatchString(_ instance: PDFSelection) {
        print("Found match: \(instance.string ?? "")")
    }
}

// MARK: - 1. 自定义PDFPage子类（每页独立绘制层）
class DrawablePDFPage: PDFPage {
    
    // 每个页面有自己的绘制视图
    weak var drawingView: PageDrawingView?
    
    // 页面自己的绘制数据
  // 使用 Associated Objects 存储数据
      private struct AssociatedKeys {
          static var strokes = "strokes_key"
          static var annotations = "annotations_key"
      }
      
  private var strokes: [BinaryInkStroke] {
          get {
              if let strokes = objc_getAssociatedObject(self, &AssociatedKeys.strokes) as? [BinaryInkStroke] {
                  return strokes
              }
              let newStrokes = [BinaryInkStroke]()
              objc_setAssociatedObject(self, &AssociatedKeys.strokes, newStrokes, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
              return newStrokes
          }
          set {
              objc_setAssociatedObject(self, &AssociatedKeys.strokes, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
          }
      }
  
    private var customAnnotations: [CustomAnnotation] = []
    
    // 页面标识
  let pageIdentifier: UUID = UUID()
  
    override func draw(with box: PDFDisplayBox, to context: CGContext) {
        // 1. 先绘制原始PDF内容
        super.draw(with: box, to: context)
        
        // 2. 再绘制用户添加的内容（直接在PDF页面上下文中）
        drawStrokes(in: context, box: box)
//        drawAnnotations(in: context, box: box)
    }
    
    private func drawStrokes(in context: CGContext, box: PDFDisplayBox) {
        context.saveGState()
        
        let pageBounds = bounds(for: box)
        
        // PDF坐标系转换
        context.translateBy(x: 0, y: pageBounds.height)
        context.scaleBy(x: 1.0, y: -1.0)
              
        for stroke in strokes {
          let strokeColor = UIColor(rgba: stroke.color).cgColor
          
          print("drawStrokes:\(stroke.width)")

          context.setStrokeColor(strokeColor)
          context.setLineWidth(CGFloat(stroke.width))
          context.setLineCap(.round)
          context.setLineJoin(.round)
          context.addPath(stroke.path.cgPath)
          context.strokePath()
        }
        
        context.restoreGState()
    }
    
    private func drawAnnotations(in context: CGContext, box: PDFDisplayBox) {
        // 绘制其他注释（文本框、图片等）
        for annotation in customAnnotations {
            annotation.draw(in: context, box: box)
        }
    }
}

// MARK: - 2. 页面级绘制视图（覆盖在每个页面上）
class PageDrawingView: UIView {
    
    // 关联的PDF页面
    weak var pdfPage: DrawablePDFPage?
    
    // 当前页面的绘制数据
    private var currentStroke: BinaryInkStroke?
    private var strokes: [BinaryInkStroke] = []
    private var redoStack: [BinaryInkStroke] = []
    
    // 绘制配置
    var strokeColor: UIColor = .black
    var strokeWidth: CGFloat = 2.0
    var CustomDrawingTool: CustomDrawingTool = .pen
    
    // 页面变换（用于坐标转换）
    var pageTransform: CGAffineTransform = .identity
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
    }
    
    // MARK: - 绘制
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // 应用页面变换
        context.concatenate(pageTransform)
        
        // 绘制所有笔画
        for stroke in strokes {
            drawStroke(stroke, in: context)
        }
        
        // 绘制当前笔画
        if let currentStroke = currentStroke {
            drawStroke(currentStroke, in: context)
        }
    }
    
    private func drawStroke(_ stroke: BinaryInkStroke, in context: CGContext) {
        context.saveGState()
        
      let strokeColor = UIColor(rgba: stroke.color).cgColor
        context.setStrokeColor(strokeColor)
      context.setLineWidth(CGFloat(stroke.width))
        context.setLineCap(.round)
        context.setLineJoin(.round)
      context.setAlpha(CGFloat(stroke.alpha))
        
        // 根据工具类型设置混合模式
//        switch stroke.tool {
//        case .highlighter:
//            context.setBlendMode(.multiply)
//        case .eraser:
//            context.setBlendMode(.clear)
//        default:
//            context.setBlendMode(.normal)
//        }
        
        context.addPath(stroke.path.cgPath)
        context.strokePath()
        
        context.restoreGState()
    }
    
    // MARK: - 触摸处理（页面坐标系）
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // 转换到页面坐标系
        let location = convertToPageCoordinate(touch.location(in: self))
        
      var newStroke = BinaryInkStroke(id: UUID())
      
        newStroke.color = strokeColor.rgba
        newStroke.width = Float16(strokeWidth)
        newStroke.addPoint(location)
        currentStroke = newStroke
        
        redoStack.removeAll()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let location = convertToPageCoordinate(touch.location(in: self))
        currentStroke?.addPoint(location)
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if var stroke = currentStroke {
            // 确保最后一个点被添加
            if let touch = touches.first {
                let location = convertToPageCoordinate(touch.location(in: self))
                stroke.addPoint(location)
            }
            strokes.append(stroke)
            saveToPage()
        }
        currentStroke = nil
        setNeedsDisplay()
    }
    
    // MARK: - 坐标转换
    private func convertToPageCoordinate(_ point: CGPoint) -> CGPoint {
        // 从视图坐标转换到PDF页面坐标
        guard let page = pdfPage else { return point }
        
        let pageBounds = page.bounds(for: .mediaBox)
        let viewBounds = bounds
        
        // 计算缩放比例
        let scaleX = pageBounds.width / viewBounds.width
        let scaleY = pageBounds.height / viewBounds.height
        
        // 转换坐标（注意PDF坐标系Y轴是反向的）
        return CGPoint(
            x: point.x * scaleX,
            y: (viewBounds.height - point.y) * scaleY
        )
    }
    
    // MARK: - 数据持久化
    private func saveToPage() {
        pdfPage?.addStrokes(strokes)
    }
    
    func loadFromPage() {
        if let pageStrokes = pdfPage?.getStrokes() {
            self.strokes = pageStrokes
            setNeedsDisplay()
        }
    }
}

// MARK: - 3. 自定义PDFView（管理多页面绘制）
class GoodNotesStylePDFView: PDFView {
    
    // 每个页面对应的绘制视图
    private var pageDrawingViews: [Int: PageDrawingView] = [:]
    
    // 当前可见页面
    private var visiblePageIndices: Set<Int> = []
    
    // 绘制模式
    var isDrawingMode: Bool = false {
        didSet {
            updateDrawingMode()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // 监听页面变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(visiblePagesChanged),
            name: .PDFViewVisiblePagesChanged,
            object: self
        )
        
        // 监听缩放变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scaleChanged),
            name: .PDFViewScaleChanged,
            object: self
        )
    }
    
    // MARK: - 页面绘制视图管理
    @objc private func visiblePagesChanged() {
        updateVisibleDrawingViews()
    }
    
    @objc private func scaleChanged() {
        updateDrawingViewsTransform()
    }
    
    private func updateVisibleDrawingViews() {
        guard let document = document else { return }
        
        // 获取当前可见页面
        let newVisiblePages = getVisiblePageIndices()
        
        // 移除不可见页面的绘制视图（内存优化）
        for pageIndex in visiblePageIndices.subtracting(newVisiblePages) {
            removeDrawingView(for: pageIndex)
        }
        
        // 添加新可见页面的绘制视图
        for pageIndex in newVisiblePages.subtracting(visiblePageIndices) {
            if let page = document.page(at: pageIndex) {
                addDrawingView(for: page, at: pageIndex)
            }
        }
        
        visiblePageIndices = newVisiblePages
        
        // 更新所有绘制视图的位置
        updateDrawingViewsPosition()
    }
    
    private func addDrawingView(for page: PDFPage, at index: Int) {
        // 创建页面绘制视图
        let drawingView = PageDrawingView()
        
        // 如果使用自定义PDFPage
        if let drawablePage = page as? DrawablePDFPage {
            drawingView.pdfPage = drawablePage
            drawablePage.drawingView = drawingView
            drawingView.loadFromPage()
        }
        
        // 计算绘制视图的frame
        let pageRect = convert(page.bounds(for: displayBox), from: page)
        drawingView.frame = pageRect
        
        // 添加到PDFView的文档视图
        documentView?.addSubview(drawingView)
        
        // 保存引用
        pageDrawingViews[index] = drawingView
        
        // 设置交互
        drawingView.isUserInteractionEnabled = isDrawingMode
    }
    
    private func removeDrawingView(for pageIndex: Int) {
        if let drawingView = pageDrawingViews[pageIndex] {
            drawingView.removeFromSuperview()
            pageDrawingViews.removeValue(forKey: pageIndex)
        }
    }
    
    private func updateDrawingViewsPosition() {
        guard let document = document else { return }
        
        for (pageIndex, drawingView) in pageDrawingViews {
            if let page = document.page(at: pageIndex) {
                // 更新每个绘制视图的位置
                let pageRect = convert(page.bounds(for: displayBox), from: page)
                drawingView.frame = pageRect
                
                // 更新变换矩阵
                drawingView.pageTransform = calculatePageTransform(for: page)
            }
        }
    }
    
    private func updateDrawingViewsTransform() {
        // 缩放变化时更新所有绘制视图
        for drawingView in pageDrawingViews.values {
            drawingView.setNeedsDisplay()
        }
    }
    
    // MARK: - 辅助方法
    private func getVisiblePageIndices() -> Set<Int> {
        guard let document = document else { return [] }
        
        var indices: Set<Int> = []
        
        // 获取可见区域
      let visibleRect = documentView?.layer.visibleRect ?? .zero
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                let pageRect = convert(page.bounds(for: displayBox), from: page)
                if pageRect.intersects(visibleRect) {
                    indices.insert(i)
                }
            }
        }
        
        return indices
    }
    
    private func calculatePageTransform(for page: PDFPage) -> CGAffineTransform {
        // 计算页面的变换矩阵
        let scale = self.scaleFactor
        return CGAffineTransform(scaleX: scale, y: scale)
    }
    
    private func updateDrawingMode() {
        // 切换绘制模式
        for drawingView in pageDrawingViews.values {
            drawingView.isUserInteractionEnabled = isDrawingMode
        }
        
        // 禁用/启用PDFView的交互
        isUserInteractionEnabled = !isDrawingMode
    }
}

// MARK: - 4. 数据存储管理
class PageDrawingDataManager {
    
    // 页面级数据存储
    private var pageData: [UUID: PageDrawingData] = [:]
    
    struct PageDrawingData: Codable {
        let pageId: UUID
        let pageIndex: Int
        let strokes: [InkStroke]
        let annotations: [CustomAnnotation]
        let lastModified: Date
        
        // 计算数据大小（用于内存管理）
        var estimatedSize: Int {
            var size = 0
            for stroke in strokes {
                size += stroke.points.count * MemoryLayout<CGPoint>.size
            }
            return size
        }
    }
    
    // 保存页面数据
    func savePageData(_ data: PageDrawingData) {
        pageData[data.pageId] = data
        
        // 异步持久化到磁盘
        persistToDisk(data)
    }
    
    // 加载页面数据
    func loadPageData(pageId: UUID) -> PageDrawingData? {
        // 先从内存缓存读取
        if let data = pageData[pageId] {
            return data
        }
        
        // 从磁盘加载
        return loadFromDisk(pageId: pageId)
    }
    
    private func persistToDisk(_ data: PageDrawingData) {
        // 实现持久化逻辑
        DispatchQueue.global(qos: .background).async {
            // 保存到文件系统或数据库
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(data) {
                // 保存到对应的页面文件
                let url = self.getPageDataURL(pageId: data.pageId)
                try? encoded.write(to: url)
            }
        }
    }
    
    private func loadFromDisk(pageId: UUID) -> PageDrawingData? {
        let url = getPageDataURL(pageId: pageId)
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(PageDrawingData.self, from: data)
    }
    
    private func getPageDataURL(pageId: UUID) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath
            .appendingPathComponent("Pages")
            .appendingPathComponent("\(pageId.uuidString).json")
    }
}

// MARK: - 5. 优化的笔画数据结构
struct InkStroke: Codable {
    let id: UUID
    var points: [CGPoint] = []  // 原始点数据
    var color: UIColor
    var width: CGFloat
    var alpha: CGFloat
    var tool: CustomDrawingTool
    var timestamp: Date
    
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
    
    init(tool: CustomDrawingTool) {
        self.id = UUID()
        self.tool = tool
        self.color = .black
        self.width = 2.0
        self.alpha = 1.0
        self.timestamp = Date()
        self.points = []
    }
    
    // 添加点
    mutating func addPoint(_ point: CGPoint) {
        points.append(point)
    }
    
    // 自定义编码解码
    enum CodingKeys: String, CodingKey {
        case id, points, colorData, width, alpha, tool, timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        points = try container.decode([CGPoint].self, forKey: .points)
        
        // 解码颜色
        if let colorData = try? container.decode(Data.self, forKey: .colorData),
           let decodedColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor {
            color = decodedColor
        } else {
            color = .black
        }
        
        width = try container.decode(CGFloat.self, forKey: .width)
        alpha = try container.decode(CGFloat.self, forKey: .alpha)
        tool = try container.decode(CustomDrawingTool.self, forKey: .tool)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(points, forKey: .points)
        
        // 编码颜色
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) {
            try container.encode(colorData, forKey: .colorData)
        }
        
        try container.encode(width, forKey: .width)
        try container.encode(alpha, forKey: .alpha)
        try container.encode(tool, forKey: .tool)
        try container.encode(timestamp, forKey: .timestamp)
    }
}


// CGPoint扩展使其支持Codable
extension CGPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
}

// CGRect扩展使其支持Codable
extension CGRect: Codable {
    enum CodingKeys: String, CodingKey {
        case origin, size
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let origin = try container.decode(CGPoint.self, forKey: .origin)
        let size = try container.decode(CGSize.self, forKey: .size)
        self.init(origin: origin, size: size)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(origin, forKey: .origin)
        try container.encode(size, forKey: .size)
    }
}

// CGSize扩展使其支持Codable
extension CGSize: Codable {
    enum CodingKeys: String, CodingKey {
        case width, height
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.init(width: width, height: height)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
}

// MARK: - 6. 支持类型
enum CustomDrawingTool: Int, Codable {
    case pen
    case pencil
    case highlighter
    case eraser
    case lasso
}

struct CustomAnnotation: Codable {
    let id: UUID
    let type: AnnotationType
    let frame: CGRect
    let content: Data
    
    func draw(in context: CGContext, box: PDFDisplayBox) {
        // 实现绘制逻辑
    }
}

enum AnnotationType: String, Codable {
    case textBox
    case image
    case shape
    case sticker
}

// MARK: - 7. PDFPage扩展
extension DrawablePDFPage {
  func addStrokes(_ strokes: [BinaryInkStroke]) {
        self.strokes.append(contentsOf: strokes)
    }
    
    func getStrokes() -> [BinaryInkStroke] {
        return strokes
    }
    
    func clearStrokes() {
        strokes.removeAll()
    }
}

class PDFViewerViewController: UIViewController {
    
    @IBOutlet weak var pdfView: PDFView!
    private let documentDelegate = CustomPDFDocumentDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPDFView()
    }
    
    private func setupPDFView() {
        // 加载PDF
        guard let url = Bundle.main.url(forResource: "cnmemst", withExtension: "pdf"),
              let document = PDFDocument(url: url) else {
            return
        }
        
        // 设置delegate以使用自定义页面类
        document.delegate = documentDelegate
        
        // 重新加载文档以应用自定义页面类
        if let newDocument = PDFDocument(url: url) {
            newDocument.delegate = documentDelegate
            pdfView.document = newDocument
            
            // 现在每个页面都是DrawablePDFPage实例
            testCustomPages()
        }
    }
    
    private func testCustomPages() {
        guard let document = pdfView.document else { return }
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) as? DrawablePDFPage {
                print("Page \(i) is DrawablePDFPage")
                
                // 添加测试绘制
              let testStroke = createTestStrokes(count: 10)
              page.addStrokes(testStroke)
            }
        }
        
        pdfView.setNeedsDisplay()
    }
  
  func createTestStrokes(count: Int) -> [BinaryInkStroke] {
      var strokes: [BinaryInkStroke] = []
      var y = 0
      for i in 0..<count {
          var stroke = BinaryInkStroke(
              id: UUID(),
              points: [],
              color: 0xFF0000FF,
              width: Float16(10.0),
              alpha: Float16(1.0),
              tool: 0,
              timestamp: Date().timeIntervalSince1970
          )
          
          for j in 0..<200 {
              stroke.points.append(CGPoint(x: Double(j), y: Double(y)))
          }
        
          y += 20
          strokes.append(stroke)
      }
      return strokes
  }
    
    private func createTestPath() -> CGPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 100, y: 100))
        path.addLine(to: CGPoint(x: 200, y: 200))
        return path.cgPath
    }
}
