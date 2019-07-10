//
//  ViewController.swift
//  ResizeableScrollView
//
//  Created by TBXark on 07/10/2019.
//  Copyright (c) 2019 TBXark. All rights reserved.
//

import UIKit
import ResizeableScrollView

class ViewController: UITableViewController {
    
    let scales: [CGFloat] = Array(repeating: 0, count: 10).map({ _ in CGFloat.random(in: 0.5...2) })
    let resizeableScrollView = ResizeableScrollView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width/2))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resizeableScrollView.itemInset = UIEdgeInsets(top: 0, left: 5, bottom: 10, right: 5)
        resizeableScrollView.delegate = self
        tableView.tableHeaderView = resizeableScrollView
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = indexPath.description
        return cell
    }

}


extension ViewController: ResizeableScrollViewDelegate {
    func numberOfItem(_ scrollView: ResizeableScrollView) -> Int {
        return scales.count
    }
    func resizeView(_ scrollView: ResizeableScrollView, willChangeHeight height: CGFloat) {
        tableView.tableHeaderView = resizeableScrollView
    }
    func resizeView(_ scrollView: ResizeableScrollView, scaleForItemAtIndex index: Int) -> CGFloat {
        return scales[index]
    }
    func resizeView(_ scrollView: ResizeableScrollView, cellForItemAtIndex index: Int) -> UIView {
        let view = UILabel()
        view.backgroundColor = UIColor(red: CGFloat.random(in: 0.2...0.8),
                                       green: CGFloat.random(in: 0.2...0.8),
                                       blue: CGFloat.random(in: 0.2...0.8),
                                       alpha: 1)
        view.textAlignment = .center
        view.text = scales[index].description
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }
    func resizeView(_ scrollView: ResizeableScrollView, didClick index: Int) {
        print("<ResizeableScrollView> didClick index: \(index)")
    }

}
