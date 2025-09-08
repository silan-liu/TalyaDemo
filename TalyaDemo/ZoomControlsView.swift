//
//  ZoomControlsView.swift
//  TalyaDemo
//
//  Created by liusilan on 2025/9/7.
//

import UIKit

class ZoomControlsView: UIView {
    weak var delegate: ZoomControlsDelegate?
    
    private let zoomInButton = UIButton(type: .system)
    private let zoomOutButton = UIButton(type: .system)
    private let zoomResetButton = UIButton(type: .system)
    
    var toolbarItems: [UIBarButtonItem] {
        [
            UIBarButtonItem(customView: zoomOutButton),
            UIBarButtonItem(customView: zoomResetButton),
            UIBarButtonItem(customView: zoomInButton)
        ]
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
//        zoomInButton.setTitle("+", for: .normal)
//        zoomInButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
//        zoomInButton.addTarget(self, action: #selector(zoomInTapped), for: .touchUpInside)
        
//        zoomOutButton.setTitle("−", for: .normal)
//        zoomOutButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
//        zoomOutButton.addTarget(self, action: #selector(zoomOutTapped), for: .touchUpInside)
        
        zoomResetButton.setTitle("⟲", for: .normal)
        zoomResetButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        zoomResetButton.addTarget(self, action: #selector(zoomResetTapped), for: .touchUpInside)
    }
    
    @objc private func zoomInTapped() {
        delegate?.didTapZoomIn()
    }
    
    @objc private func zoomOutTapped() {
        delegate?.didTapZoomOut()
    }
    
    @objc private func zoomResetTapped() {
        delegate?.didTapZoomReset()
    }
}
