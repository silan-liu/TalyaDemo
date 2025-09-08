//
//  SidebarView.swift
//  TalyaDemo
//
//  Created by liusilan on 2025/9/7.
//

import UIKit

class SidebarView: UIView {
    private let titleLabel = UILabel()
    private let docIdLabel = UILabel()
    private let createdLabel = UILabel()
    private let modeLabel = UILabel()
    private let strokesLabel = UILabel()
    private let textLabel = UILabel()
    private let imagesLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = UIColor.white.withAlphaComponent(0.95)
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
        
        // Document Info Section
        let docInfoHeader = createSectionHeader("DOCUMENT INFO")
        stack.addArrangedSubview(docInfoHeader)
        
        stack.addArrangedSubview(createInfoRow("Title", label: titleLabel))
        stack.addArrangedSubview(createInfoRow("Document ID", label: docIdLabel))
        stack.addArrangedSubview(createInfoRow("Created", label: createdLabel))
        stack.addArrangedSubview(createInfoRow("Mode", label: modeLabel))
        
        // Page Stats Section
        let statsHeader = createSectionHeader("PAGE STATISTICS")
        stack.addArrangedSubview(statsHeader)
        
        stack.addArrangedSubview(createStatRow("Strokes", label: strokesLabel))
        stack.addArrangedSubview(createStatRow("Text Elements", label: textLabel))
        stack.addArrangedSubview(createStatRow("Images", label: imagesLabel))
    }
    
    private func createSectionHeader(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .darkGray
        return label
    }
    
    private func createInfoRow(_ title: String, label: UILabel) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemGray6
        container.layer.cornerRadius = 6
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 11)
        titleLabel.textColor = .systemGray
        
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .label
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, label])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        
        return container
    }
    
    private func createStatRow(_ title: String, label: UILabel) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemGray6
        container.layer.cornerRadius = 6
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = .systemGray
        
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor(hex: "#667eea")
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, label])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        
        return container
    }
    
    func updateDocumentInfo(_ document: TalyaDocument) {
        titleLabel.text = document.manifest.title
        docIdLabel.text = String(document.manifest.docId.prefix(8)) + "..."
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        createdLabel.text = formatter.string(from: Date(timeIntervalSince1970: document.manifest.createdAt))
        
        modeLabel.text = document.manifest.processingMode.uppercased()
    }
    
    func updatePageStats(strokes: Int, textElements: Int, images: Int) {
        strokesLabel.text = "\(strokes)"
        textLabel.text = "\(textElements)"
        imagesLabel.text = "\(images)"
    }
}
