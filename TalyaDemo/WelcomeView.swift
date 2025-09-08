//
//  WelcomeView.swift
//  TalyaDemo
//
//  Created by liusilan on 2025/9/7.
//

import UIKit

class WelcomeView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = UIColor.white.withAlphaComponent(0.95)
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 10)
        layer.shadowRadius = 20
        
        let titleLabel = UILabel()
        titleLabel.text = "Welcome to Talya Viewer"
        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        titleLabel.textAlignment = .center
        
        let descLabel = UILabel()
        descLabel.text = "Click \"Open\" to load and view your converted document."
        descLabel.font = .systemFont(ofSize: 16)
        descLabel.textColor = .systemGray
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        
        let infoLabel = UILabel()
        infoLabel.text = "Supports viewing of strokes, text, and images from converted PDF documents."
        infoLabel.font = .systemFont(ofSize: 14)
        infoLabel.textColor = .systemGray2
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, descLabel, infoLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 32),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -32)
        ])
    }
}
