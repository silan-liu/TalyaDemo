//
//  PageNavigationView.swift
//  TalyaDemo
//
//  Created by liusilan on 2025/9/7.
//

import UIKit

// MARK: - UI Components
class PageNavigationView: UIView {
    weak var delegate: PageNavigationDelegate?
    
    var currentPage = 1 {
        didSet { updateLabel() }
    }
    
    var totalPages = 1 {
        didSet { updateLabel() }
    }
    
    private let prevButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let pageLabel = UILabel()
    
    var toolbarItems: [UIBarButtonItem] {
        [
            UIBarButtonItem(customView: prevButton),
            UIBarButtonItem(customView: pageLabel),
            UIBarButtonItem(customView: nextButton)
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
        prevButton.setTitle("◀", for: .normal)
        prevButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        
        nextButton.setTitle("▶", for: .normal)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        
        pageLabel.textAlignment = .center
        pageLabel.font = .systemFont(ofSize: 14, weight: .medium)
        
        updateLabel()
        updateButtons()
    }
    
    @objc private func prevTapped() {
        delegate?.didTapPrevious()
    }
    
    @objc private func nextTapped() {
        delegate?.didTapNext()
    }
    
    func updateLabel() {
        pageLabel.text = "\(currentPage)/\(totalPages)"
    }
    
    func updateButtons() {
        prevButton.isEnabled = currentPage > 1
        nextButton.isEnabled = currentPage < totalPages
    }
}
