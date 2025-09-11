//
//  EnhancedScrollView.swift
//  TalyaDemo
//
//  Created by lsl on 2025/9/11.
//

import UIKit

class SimultaneousScrollView: UIScrollView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestures()
    }
    
    private func setupGestures() {
        // 允许同时识别手势
        self.panGestureRecognizer.cancelsTouchesInView = false
        self.pinchGestureRecognizer?.cancelsTouchesInView = false
    }
    
    // 覆写这个方法让手势能同时工作
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
