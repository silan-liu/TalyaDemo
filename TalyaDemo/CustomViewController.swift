//
//  CustomViewController.swift
//  TalyaDemo
//
//  Created by lsl on 2025/9/12.
//

import UIKit


class CustomViewController : UIViewController {
      
      let customTableView: OptimizedTableScrollView = OptimizedTableScrollView()
      private var data = Array(0..<1000).map { "Row \($0)" }
      
      override func viewDidLoad() {
          super.viewDidLoad()
          
        customTableView.frame = self.view.bounds
        self.view.addSubview(customTableView)
        
          customTableView.tableDataSource = self
          customTableView.tableDelegate = self
          customTableView.rowHeight = 60
          customTableView.reloadData()
      }
  }

extension CustomViewController: TableDataSource {
    func numberOfRows(in tableScrollView: OptimizedTableScrollView) -> Int {
        return data.count
    }
    
    func tableScrollView(_ tableScrollView: OptimizedTableScrollView, cellForRowAt indexPath: IndexPath) -> UIView {
        // 尝试复用
        let identifier = "Cell"
        let cell = tableScrollView.dequeueReusableCell(withIdentifier: identifier) ?? createCell()
        
        // 配置cell
        if let label = cell.subviews.first as? UILabel {
            label.text = data[indexPath.row]
        }
        
        return cell
    }
    
    private func createCell() -> UIView {
        let cell = UIView()
        cell.backgroundColor = .white
        
        let label = UILabel()
        label.frame = CGRect(x: 16, y: 20, width: 200, height: 20)
        cell.addSubview(label)
        
        return cell
    }
}

extension CustomViewController: TableDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("Scrolling... offset: \(scrollView.contentOffset.y)")
    }
}
