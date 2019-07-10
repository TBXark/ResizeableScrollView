//
//  ResizeableScrollView.swift
//  ResizeableScrollView
//
//  Created by Tbxark on 7/10/19.
//  Copyright © 2016 TBXark. All rights reserved.
//

import UIKit

public protocol ResizeableScrollViewDelegate: class {
    
    func numberOfItem(_ scrollView: ResizeableScrollView) -> Int
    func resizeView(_ scrollView: ResizeableScrollView, willChangeHeight height: CGFloat)
    func resizeView(_ scrollView: ResizeableScrollView, scaleForItemAtIndex index: Int) -> CGFloat
    func resizeView(_ scrollView: ResizeableScrollView, cellForItemAtIndex index: Int) -> UIView
    func resizeView(_ scrollView: ResizeableScrollView, didClick index: Int)
    
}

extension ResizeableScrollViewDelegate {
    public func resizeView(_ scrollView: ResizeableScrollView, didClick index: Int) {}
}

public class ResizeableScrollView: UIView, UIScrollViewDelegate {
    
    public weak var delegate: ResizeableScrollViewDelegate? {
        didSet {
            reloadData()
        }
    }
    public var contentHorizontalInset: CGFloat = 16 {
        didSet {
            reloadData()
        }
    }
    public var itemInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2) {
        didSet {
            reloadData()
        }
    }
    public override var frame: CGRect {
        didSet {
            var rect = frame
            rect.origin = CGPoint.zero
            scrollView.frame = rect.insetBy(dx: contentHorizontalInset, dy: 0)
            if !oldValue.height.isEqual(to: frame.height) {
                delegate?.resizeView(self, willChangeHeight: frame.height)
            }
        }
    }
    
    public override var bounds: CGRect {
        didSet {
            scrollView.frame = bounds.insetBy(dx: contentHorizontalInset, dy: 0)
            if !oldValue.height.isEqual(to: bounds.height) {
                delegate?.resizeView(self, willChangeHeight: bounds.height)
            }
        }
    }

    
    private var scaleCache = [CGFloat]()
    private let scrollView = UIScrollView()
    public private(set) var visibleItems = [UIView]()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        shareInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        shareInit()
    }
    
    private func shareInit() {
        clipsToBounds = true
        isUserInteractionEnabled = true
        scrollView.frame = bounds.insetBy(dx: contentHorizontalInset, dy: 0)
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false
        scrollView.bounces = false
        scrollView.isPagingEnabled = true
        scrollView.clipsToBounds = false
        scrollView.scrollsToTop = false
        addSubview(scrollView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(ResizeableScrollView.scrollViewDidTap(_:)))
        scrollView.addGestureRecognizer(tap)
        
    }
    
    @objc private func scrollViewDidTap(_ tap: UITapGestureRecognizer) {
        let index = scrollView.contentOffset.x / scrollView.frame.width
        delegate?.resizeView(self, didClick: Int(index))
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if bounds.contains(point) {
            return scrollView
        } else {
            return super.hitTest(point, with: event)
        }
    }
    
    
    //MARK: - Public
    public func setContentOffset(_ offset: CGFloat) {
        scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
        scrollViewDidScroll(scrollView)
    }
    
    public func reloadData() {
        guard let delegate = delegate else { return }
        scrollView.frame = bounds.insetBy(dx: contentHorizontalInset, dy: 0)
        let count = delegate.numberOfItem(self)
        visibleItems.forEach { $0.removeFromSuperview() }
        visibleItems.removeAll()
        scaleCache.removeAll()
        let h = scrollView.bounds.width
        var totalX: CGFloat = 0
        for i in 0..<count {
            let scale = delegate.resizeView(self, scaleForItemAtIndex: i)
            let w = h * scale
            let view = delegate.resizeView(self, cellForItemAtIndex: i)
            totalX += w
            if scale.isZero || scale.isNaN {
                scaleCache.append(1)
            } else {
                scaleCache.append(scale)
            }
            scrollView.addSubview(view)
            visibleItems.append(view)
        }
        scrollView.contentSize.width = CGFloat(scaleCache.count) * (scrollView.bounds.width)
        scrollViewDidScroll(scrollView)
    }
    
    
    // MARK: - Magical code
    private func xOffset(_ x: CGFloat) -> CGFloat {
        let w =  scrollView.bounds.width
        
        let s = (itemInset.left + itemInset.right)
        let beginI: Int = Int(x/w)
        let endI: Int = max(0, min((beginI + 1), scaleCache.count - 1))
        
        let beginX = w * CGFloat(beginI)
        let endX = w * CGFloat(endI)
        
        if beginI == endI && beginI == 0 {
            return 0
        } else if beginI == endI && beginI == scaleCache.count - 1 {
            let es =  scaleCache[0..<endI].reduce(0, {$0 + $1})
            let endY = CGFloat(endI) * w - (es * height(endX)  + CGFloat(endI) * s)
            return endY
        }
        
        let bs = scaleCache[0..<beginI].reduce(0, {$0 + $1})
        let es =  scaleCache[0..<endI].reduce(0, {$0 + $1})
        let beginY =  CGFloat(beginI) * w - (bs * height(beginX) + CGFloat(beginI) * s)
        let endY = CGFloat(endI) * w - (es * height(endX)  + CGFloat(endI) * s)
        
        let k = CGFloat(beginY - endY)/(beginX - endX)
        return  k * (x - CGFloat(beginX)) + beginY
        
    }
    
    private func height(_ x: CGFloat) -> CGFloat {
        let w =  scrollView.bounds.width
        
        let s = (itemInset.left + itemInset.right)
        let beginI: Int = Int(x/w)
        let endI: Int = max(0, min((beginI + 1), scaleCache.count - 1))
        
        if beginI == endI && beginI == 0 {
            return ((w - s) / scaleCache[0])
        } else if beginI == endI && beginI == (scaleCache.count - 1) {
            return ((w - s) / scaleCache.last!)
        }
        
        let beginX = CGFloat(beginI) * w
        let endX = CGFloat(endI) * w
        
        let beginY = ((w - s) / scaleCache[beginI])
        let endY = ((w - s) / scaleCache[endI])
        
        let k = CGFloat(endY - beginY)/(endX - beginX)
        return k * (x - CGFloat(beginX)) + beginY
    }
    
    private func scale(_ x: CGFloat) -> CGFloat {
        return height(x) /  scrollView.bounds.width
    }

    
    
    // MARK: - UIScrollViewDelegate
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scaleCache.count > 0 else { return }
        let x = scrollView.contentOffset.x
        
        let s = scale(x)
        let xf = xOffset(x)
        var rect = CGRect.zero
        
        rect.origin.x = xf
        let w = scrollView.bounds.width
        let h = w * s
        let y = itemInset.top
        for (i, itemView) in visibleItems.enumerated() {
            var itemFrame = CGRect.zero
            let scale = scaleCache[i] * s
            itemFrame.size.width = w * scale
            itemFrame.size.height = h
            itemFrame.origin.x = rect.maxX + itemInset.left
            itemFrame.origin.y = y
            itemView.frame = itemFrame
            itemFrame.size.width += itemInset.right
            rect = itemFrame
        }
        frame.size.height = rect.height + itemInset.top + itemInset.bottom
    }
    
}
