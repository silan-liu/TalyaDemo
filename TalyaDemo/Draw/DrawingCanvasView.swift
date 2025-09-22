//
//  DrawingCanvasView.swift
//  TalyaDemo
//
//  Created by lsl on 2025/9/22.
//

import Foundation

import UIKit
import PDFKit

// MARK: - 绘制数据模型
struct DrawingStroke {
    var path: UIBezierPath
    var color: UIColor
    var width: CGFloat
    var alpha: CGFloat
    
    init(color: UIColor = .red, width: CGFloat = 2.0, alpha: CGFloat = 1.0) {
        self.path = UIBezierPath()
        self.color = color
        self.width = width
        self.alpha = alpha
    }
}

// MARK: - 自定义绘制视图
class DrawingCanvasView: UIView {
    
    // 当前正在绘制的笔画
    private var currentStroke: DrawingStroke?
    
    // 所有完成的笔画
    private var strokes: [DrawingStroke] = []
    
    // 撤销的笔画（用于重做）
    private var undoneStrokes: [DrawingStroke] = []
    
    // 绘制配置
    var strokeColor: UIColor = .red
    var strokeWidth: CGFloat = 2.0
    var strokeAlpha: CGFloat = 1.0
    
    // 绘制模式
    var isDrawingEnabled: Bool = true
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = true
        isMultipleTouchEnabled = false
    }
    
    // MARK: - Drawing
    override func draw(_ rect: CGRect) {
        // 绘制所有完成的笔画
        for stroke in strokes {
            stroke.color.withAlphaComponent(stroke.alpha).setStroke()
            stroke.path.lineWidth = stroke.width
            stroke.path.lineCapStyle = .round
            stroke.path.lineJoinStyle = .round
            stroke.path.stroke()
        }
        
        // 绘制当前笔画
        if let current = currentStroke {
            current.color.withAlphaComponent(current.alpha).setStroke()
            current.path.lineWidth = current.width
            current.path.lineCapStyle = .round
            current.path.lineJoinStyle = .round
            current.path.stroke()
        }
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawingEnabled, let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        
        // 创建新笔画
        currentStroke = DrawingStroke(
            color: strokeColor,
            width: strokeWidth,
            alpha: strokeAlpha
        )
        currentStroke?.path.move(to: location)
        
        // 清空重做栈
        undoneStrokes.removeAll()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawingEnabled, let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        
        // 使用贝塞尔曲线平滑绘制
        if let previousLocation = touches.first?.previousLocation(in: self) {
            let midPoint = CGPoint(
                x: (location.x + previousLocation.x) / 2,
                y: (location.y + previousLocation.y) / 2
            )
            currentStroke?.path.addQuadCurve(to: midPoint, controlPoint: previousLocation)
        } else {
            currentStroke?.path.addLine(to: location)
        }
        
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawingEnabled, let stroke = currentStroke else { return }
        
        // 保存完成的笔画
        strokes.append(stroke)
        currentStroke = nil
        setNeedsDisplay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentStroke = nil
        setNeedsDisplay()
    }
    
    // MARK: - Public Methods
    func undo() {
        guard !strokes.isEmpty else { return }
        let stroke = strokes.removeLast()
        undoneStrokes.append(stroke)
        setNeedsDisplay()
    }
    
    func redo() {
        guard !undoneStrokes.isEmpty else { return }
        let stroke = undoneStrokes.removeLast()
        strokes.append(stroke)
        setNeedsDisplay()
    }
    
    func clear() {
        strokes.removeAll()
        undoneStrokes.removeAll()
        currentStroke = nil
        setNeedsDisplay()
    }
    
    func exportAsImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    // 获取所有绘制路径（用于保存到PDF）
    func getAllStrokes() -> [DrawingStroke] {
        return strokes
    }
    
    // 加载已保存的笔画
    func loadStrokes(_ strokes: [DrawingStroke]) {
        self.strokes = strokes
        setNeedsDisplay()
    }
}

// MARK: - PDF注释视图
class PDFDrawingAnnotationView: UIView {
    var annotation: PDFAnnotation?
    var strokes: [DrawingStroke] = []
    
    override func draw(_ rect: CGRect) {
        for stroke in strokes {
            stroke.color.withAlphaComponent(stroke.alpha).setStroke()
            stroke.path.lineWidth = stroke.width
            stroke.path.lineCapStyle = .round
            stroke.path.lineJoinStyle = .round
            stroke.path.stroke()
        }
    }
}

// MARK: - 自定义PDFView带绘制功能
class DrawablePDFView: PDFView {
    
    private var drawingCanvas: DrawingCanvasView!
    private var drawingAnnotations: [Int: [DrawingStroke]] = [:] // 每页的绘制数据
    
    // 绘制工具配置
    var drawingEnabled: Bool = false {
        didSet {
            drawingCanvas.isDrawingEnabled = drawingEnabled
            // 切换交互模式
            if drawingEnabled {
                isUserInteractionEnabled = false
                drawingCanvas.isUserInteractionEnabled = true
            } else {
                isUserInteractionEnabled = true
                drawingCanvas.isUserInteractionEnabled = false
            }
        }
    }
    
    var strokeColor: UIColor = .red {
        didSet {
            drawingCanvas.strokeColor = strokeColor
        }
    }
    
    var strokeWidth: CGFloat = 2.0 {
        didSet {
            drawingCanvas.strokeWidth = strokeWidth
        }
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDrawingCanvas()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDrawingCanvas()
    }
    
    private func setupDrawingCanvas() {
        // 创建绘制层
        drawingCanvas = DrawingCanvasView(frame: bounds)
        drawingCanvas.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(drawingCanvas)
        
        // 监听页面变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pageChanged),
            name: .PDFViewPageChanged,
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
    
    // MARK: - Page Management
    @objc private func pageChanged() {
        saveCurrentPageDrawing()
        loadPageDrawing()
        updateCanvasTransform()
    }
    
    @objc private func scaleChanged() {
        updateCanvasTransform()
    }
    
    private func saveCurrentPageDrawing() {
        guard let page = currentPage,
              let document = document else { return }
      
      let pageIndex = document.index(for: page)
        
        let strokes = drawingCanvas.getAllStrokes()
        if !strokes.isEmpty {
            drawingAnnotations[pageIndex] = strokes
        }
    }
    
    private func loadPageDrawing() {
        guard let page = currentPage,
              let document = document
               else { return }
        
      let pageIndex = document.index(for: page)
        drawingCanvas.clear()
        if let strokes = drawingAnnotations[pageIndex] {
            drawingCanvas.loadStrokes(strokes)
        }
    }
    
    private func updateCanvasTransform() {
        guard let page = currentPage else { return }
        
        // 获取PDF页面在视图中的位置
        let pageBounds = convert(page.bounds(for: displayBox), from: page)
        
        // 更新绘制画布的frame
        drawingCanvas.frame = pageBounds
        drawingCanvas.setNeedsDisplay()
    }
    
    // MARK: - Drawing Operations
    func undoDrawing() {
        drawingCanvas.undo()
        saveCurrentPageDrawing()
    }
    
    func redoDrawing() {
        drawingCanvas.redo()
        saveCurrentPageDrawing()
    }
    
    func clearDrawing() {
        drawingCanvas.clear()
        saveCurrentPageDrawing()
    }
    
    func clearAllDrawings() {
        drawingAnnotations.removeAll()
        drawingCanvas.clear()
    }
    
    // MARK: - Export Functions
    func exportDrawingAsImage() -> UIImage? {
        return drawingCanvas.exportAsImage()
    }
    
    func saveDrawingsToPDF() {
        guard let document = document else { return }
        
        for (pageIndex, strokes) in drawingAnnotations {
            guard let page = document.page(at: pageIndex) else { continue }
            
            // 创建墨迹注释
            let inkAnnotation = PDFAnnotation(
                bounds: page.bounds(for: .mediaBox),
                forType: .ink,
                withProperties: nil
            )
            
            // 转换绘制路径为PDF注释路径
            var paths: [[NSValue]] = []
            for stroke in strokes {
                let cgPath = stroke.path.cgPath
                var points: [NSValue] = []
                
                cgPath.applyWithBlock { element in
                    switch element.pointee.type {
                    case .moveToPoint:
                        points.append(NSValue(cgPoint: element.pointee.points[0]))
                    case .addLineToPoint:
                        points.append(NSValue(cgPoint: element.pointee.points[0]))
                    case .addQuadCurveToPoint:
                        points.append(NSValue(cgPoint: element.pointee.points[0]))
                        points.append(NSValue(cgPoint: element.pointee.points[1]))
                    default:
                        break
                    }
                }
                
                if !points.isEmpty {
                    paths.append(points)
                }
            }
            
//            inkAnnotation.paths = paths
            inkAnnotation.color = strokeColor
            inkAnnotation.border = PDFBorder()
            inkAnnotation.border?.lineWidth = strokeWidth
            
            page.addAnnotation(inkAnnotation)
        }
    }
    
    // MARK: - Eraser Mode
    func enableEraser() {
        drawingCanvas.strokeColor = .clear
        drawingCanvas.strokeWidth = 20.0
        // 设置混合模式为清除
        drawingCanvas.layer.compositingFilter = "sourceAtop"
    }
    
    func disableEraser() {
        drawingCanvas.strokeColor = strokeColor
        drawingCanvas.strokeWidth = strokeWidth
        drawingCanvas.layer.compositingFilter = nil
    }
}

// MARK: - 完整的使用示例控制器
class PDFDrawingViewController: UIViewController {
    
    @IBOutlet weak var pdfView: DrawablePDFView!
    @IBOutlet weak var toolbar: UIToolbar!
    
    // 工具按钮
    var drawButton: UIBarButtonItem!
    var colorButton: UIBarButtonItem!
    var eraserButton: UIBarButtonItem!
    var undoButton: UIBarButtonItem!
    var redoButton: UIBarButtonItem!
    var saveButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPDFView()
        setupToolbar()
        loadPDF()
    }
    
    private func setupPDFView() {
        // 如果使用Storyboard，确保pdfView是DrawablePDFView类型
        // 或者程序化创建
        if pdfView == nil {
            pdfView = DrawablePDFView(frame: view.bounds)
            pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(pdfView)
        }
        
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
    }
    
    private func setupToolbar() {
        // 创建工具栏按钮
        drawButton = UIBarButtonItem(
            image: UIImage(systemName: "pencil"),
            style: .plain,
            target: self,
            action: #selector(toggleDrawing)
        )
        
        colorButton = UIBarButtonItem(
            image: UIImage(systemName: "paintpalette"),
            style: .plain,
            target: self,
            action: #selector(selectColor)
        )
        
        eraserButton = UIBarButtonItem(
            image: UIImage(systemName: "eraser"),
            style: .plain,
            target: self,
            action: #selector(toggleEraser)
        )
        
        undoButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.uturn.backward"),
            style: .plain,
            target: self,
            action: #selector(undo)
        )
        
        redoButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.uturn.forward"),
            style: .plain,
            target: self,
            action: #selector(redo)
        )
        
        saveButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.down"),
            style: .plain,
            target: self,
            action: #selector(savePDF)
        )
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
      self.navigationController?.toolbar.items = [
            drawButton, flexibleSpace,
            colorButton, flexibleSpace,
            eraserButton, flexibleSpace,
            undoButton, redoButton, flexibleSpace,
            saveButton
        ]
    }
    
    private func loadPDF() {
        // 加载PDF文件
        if let url = Bundle.main.url(forResource: "cnmemst", withExtension: "pdf") {
            pdfView.document = PDFDocument(url: url)
        }
    }
    
    // MARK: - Actions
    @objc private func toggleDrawing() {
        pdfView.drawingEnabled.toggle()
        drawButton.tintColor = pdfView.drawingEnabled ? .systemBlue : .label
    }
    
    @objc private func selectColor() {
        // 显示颜色选择器
        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        colorPicker.selectedColor = pdfView.strokeColor
        present(colorPicker, animated: true)
    }
    
    @objc private func toggleEraser() {
        if eraserButton.tintColor == .systemBlue {
            pdfView.disableEraser()
            eraserButton.tintColor = .label
        } else {
            pdfView.enableEraser()
            eraserButton.tintColor = .systemBlue
        }
    }
    
    @objc private func undo() {
        pdfView.undoDrawing()
    }
    
    @objc private func redo() {
        pdfView.redoDrawing()
    }
    
    @objc private func savePDF() {
        // 保存绘制到PDF
        pdfView.saveDrawingsToPDF()
        
        // 导出PDF
        if let document = pdfView.document,
           let data = document.dataRepresentation() {
            
            // 保存到文档目录
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let pdfPath = documentsPath.appendingPathComponent("annotated.pdf")
            
            do {
                try data.write(to: pdfPath)
                
                // 显示分享界面
                let activityVC = UIActivityViewController(activityItems: [pdfPath], applicationActivities: nil)
                present(activityVC, animated: true)
            } catch {
                print("保存失败: \(error)")
            }
        }
    }
}

// MARK: - Color Picker Delegate
extension PDFDrawingViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        pdfView.strokeColor = viewController.selectedColor
    }
}
