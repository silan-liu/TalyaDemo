//
//  CustomScrollView.swift
//  TalyaDemo
//
//  Created by lsl on 2025/9/12.
//

import UIKit

class OptimizedTableScrollView: UIScrollView {
    
    private var visibleCells: [IndexPath: UIView] = [:]
    private var reusablePool: [String: [UIView]] = [:]
    private var cellFrames: [IndexPath: CGRect] = [:]  // 缓存cell位置
    
    weak var tableDataSource: TableDataSource?
    weak var tableDelegate: TableDelegate?
    
    var rowHeight: CGFloat = 44
    private var isUpdating = false  // 防止重复更新
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // ✅ 关键：必须设置delegate
        self.delegate = self
        self.showsVerticalScrollIndicator = true
        self.alwaysBounceVertical = true
    }
    
    // MARK: - Reload Data
    func reloadData() {
        // 清理现有内容
        visibleCells.values.forEach { $0.removeFromSuperview() }
        visibleCells.removeAll()
        cellFrames.removeAll()
        
        // 预计算所有cell的frame
        precalculateCellFrames()
        
        // 设置contentSize
        let lastFrame = cellFrames.values.max { $0.maxY < $1.maxY }
        contentSize = CGSize(width: frame.width, height: lastFrame?.maxY ?? 0)
        
        // 初始加载
        updateVisibleCells()
    }
    
    private func precalculateCellFrames() {
        guard let dataSource = tableDataSource else { return }
        
        var yOffset: CGFloat = 0
        let numberOfRows = dataSource.numberOfRows(in: self)
        
        for row in 0..<numberOfRows {
            let indexPath = IndexPath(row: row, section: 0)
            let height = tableDelegate?.tableScrollView?(self, heightForRowAt: indexPath) ?? rowHeight
            
            let frame = CGRect(x: 0, y: yOffset, width: frame.width, height: height)
            cellFrames[indexPath] = frame
            
            yOffset += height
        }
    }
    
    // MARK: - ✅ 核心方法：更新可见cells
    private func updateVisibleCells() {
        guard !isUpdating else { return }  // 防止重复调用
        isUpdating = true
        defer { isUpdating = false }
        
        let visibleRect = CGRect(origin: contentOffset, size: bounds.size)
        
        // 扩展可见区域以预加载
        let extendedRect = visibleRect.insetBy(dx: 0, dy: -100)
        
        // 1. 找出应该显示的cells
        var cellsToShow: [IndexPath] = []
        for (indexPath, frame) in cellFrames {
            if frame.intersects(extendedRect) {
                cellsToShow.append(indexPath)
            }
        }
        
        // 2. 移除不再可见的cells
        var cellsToRemove: [IndexPath] = []
        for (indexPath, cell) in visibleCells {
            if !cellsToShow.contains(indexPath) {
                recycleCell(cell)
                cellsToRemove.append(indexPath)
            }
        }
        cellsToRemove.forEach { visibleCells.removeValue(forKey: $0) }
        
        // 3. 添加新的可见cells
        for indexPath in cellsToShow {
            if visibleCells[indexPath] == nil {
                if let cell = tableDataSource?.tableScrollView(self, cellForRowAt: indexPath) {
                    cell.frame = cellFrames[indexPath] ?? .zero
                    addSubview(cell)
                    visibleCells[indexPath] = cell
                    
                    // 添加动画效果（可选）
                    cell.alpha = 0
                    UIView.animate(withDuration: 0.2) {
                        cell.alpha = 1
                    }
                }
            }
        }
    }
    
    // MARK: - Cell Reuse
    func dequeueReusableCell(withIdentifier identifier: String) -> UIView? {
        if var pool = reusablePool[identifier], !pool.isEmpty {
          print("reuse cell")
            let cell = pool.removeLast()
            reusablePool[identifier] = pool
            return cell
        }
        return nil
    }
    
    private func recycleCell(_ cell: UIView) {
        cell.removeFromSuperview()
        
        let identifier = String(describing: type(of: cell))
        if reusablePool[identifier] == nil {
            reusablePool[identifier] = []
        }
        reusablePool[identifier]?.append(cell)
    }
}

// MARK: - ✅ UIScrollViewDelegate 实现
extension OptimizedTableScrollView: UIScrollViewDelegate {
    
    // 滚动时调用 - 这是最重要的方法！
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateVisibleCells()  // ✅ 在滚动时更新可见cells
        
        // 转发给外部delegate
        tableDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    // 开始拖动
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        tableDelegate?.scrollViewWillBeginDragging?(scrollView)
    }
    
    // 结束拖动
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            // 如果没有减速，立即更新
            updateVisibleCells()
        }
        tableDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    // 减速结束
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateVisibleCells()  // 确保最终状态正确
        tableDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }
}

// MARK: - 协议定义
protocol TableDataSource: AnyObject {
    func numberOfRows(in tableScrollView: OptimizedTableScrollView) -> Int
    func tableScrollView(_ tableScrollView: OptimizedTableScrollView, cellForRowAt indexPath: IndexPath) -> UIView
}

@objc protocol TableDelegate: AnyObject {
    @objc optional func tableScrollView(_ tableScrollView: OptimizedTableScrollView, heightForRowAt indexPath: IndexPath) -> CGFloat
    @objc optional func tableScrollView(_ tableScrollView: OptimizedTableScrollView, didSelectRowAt indexPath: IndexPath)
    
    // 转发UIScrollViewDelegate方法
    @objc optional func scrollViewDidScroll(_ scrollView: UIScrollView)
    @objc optional func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    @objc optional func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool)
    @objc optional func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
}
