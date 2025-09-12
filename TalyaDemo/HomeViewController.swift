//
//  HomeViewController.swift
//  TalyaDemo
//
//  Created by lsl on 2025/9/10.
//

import UIKit

class HomeViewController: UIViewController {
  @IBAction func v1Action(_ sender: Any) {
    let vc1 = TalyaViewerViewController()
    self.navigationController?.pushViewController(vc1, animated: true)
  }
  
  @IBAction func v2Action(_ sender: Any) {
//    let vc2 = MultiPageCanvasViewController()
    let vc2 = CustomViewController()
    self.navigationController?.pushViewController(vc2, animated: true)
  }
}
