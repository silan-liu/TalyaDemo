//
//  TalyaDelegate.swift
//  TalyaDemo
//
//  Created by liusilan on 2025/9/7.
//

import Foundation

// MARK: - Protocols
protocol PageNavigationDelegate: AnyObject {
    func didTapPrevious()
    func didTapNext()
}

protocol ZoomControlsDelegate: AnyObject {
    func didTapZoomIn()
    func didTapZoomOut()
    func didTapZoomReset()
}
