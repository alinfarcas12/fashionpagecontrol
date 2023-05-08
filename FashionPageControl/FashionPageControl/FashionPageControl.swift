//
//  FashionPageControl.swift
//  FashionPageControl
//
//  Created by George-Marian Prisacariu on 16.09.2021.
//

import UIKit

open class FashionPageControl: UIControl {
    fileprivate let limit = 5
    fileprivate var fullScaleIndex = [0, 1, 2]
    fileprivate var dotLayers: [CALayer] = []
    fileprivate var diameter: CGFloat { return radius * 2 }
    fileprivate var centerIndex: Int { return fullScaleIndex[1] }
    
    open var currentPage = 0 {
        didSet {
            guard numberOfPages > currentPage else {
                return
            }
            update()
        }
    }
    
    public struct AssociatedObjectKeys {
        static public var currentPageChanged = "currentPageChangedAssociatedObjectKey"
    }
    
    public typealias Action = (() -> Void)?
    
    @objc public var currentPageChangedClosure: (() -> Void)? {
        get {
            let currentPageActionInstance =
                objc_getAssociatedObject(self,
                                         &AssociatedObjectKeys.currentPageChanged) as? Action
            return currentPageActionInstance!
        }
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self, &AssociatedObjectKeys.currentPageChanged,
                                         newValue,
                                         objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            }
        }
    }
    
    @IBInspectable open var inactiveTintColor: UIColor = UIColor(red: 197/255,
                                                                 green: 195/255,
                                                                 blue: 192/255,
                                                                 alpha: 1.0) {
        didSet {
            setNeedsLayout()
        }
    }
    
    @IBInspectable open var currentPageTintColor: UIColor = .black {
        didSet {
            setNeedsLayout()
        }
    }
    
    @IBInspectable open var radius: CGFloat = 4 {
        didSet {
            updateDotLayersLayout()
        }
    }
    
    @IBInspectable open var padding: CGFloat = 6 {
        didSet {
            updateDotLayersLayout()
        }
    }
    
    @IBInspectable open var minScaleValue: CGFloat = 0.4 {
        didSet {
            setNeedsLayout()
        }
    }
    
    @IBInspectable open var middleScaleValue: CGFloat = 0.7 {
        didSet {
            setNeedsLayout()
        }
    }
    
    @IBInspectable open var numberOfPages: Int = 0 {
        didSet {
            setupDotLayers()
            isHidden = hideForSinglePage && numberOfPages <= 1
        }
    }
    
    @IBInspectable open var hideForSinglePage: Bool = true {
        didSet {
            setNeedsLayout()
        }
    }
    
    @IBInspectable open var inactiveTransparency: CGFloat = 0.4 {
        didSet {
            setNeedsLayout()
        }
    }
    
    @IBInspectable open var borderWidth: CGFloat = 1 {
        didSet {
            setNeedsLayout()
        }
    }
    
    @IBInspectable open var borderColor: UIColor = UIColor.white {
        didSet {
            setNeedsLayout()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required public init(frame: CGRect, numberOfPages: Int) {
        super.init(frame: frame)
        self.numberOfPages = numberOfPages
        setupDotLayers()
    }
    
    override open var intrinsicContentSize: CGSize {
        return sizeThatFits(CGSize.zero)
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        let minValue = min(7, numberOfPages)
        return CGSize(width: CGFloat(minValue) * diameter + CGFloat(minValue - 1) * padding, height: diameter)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        dotLayers.forEach {
            if borderWidth > 0 {
                $0.borderWidth = borderWidth
                $0.borderColor = borderColor.cgColor
            }
        }
        
        update()
    }
}

private extension FashionPageControl {
    func setupDotLayers() {
        dotLayers.forEach { $0.removeFromSuperlayer() }
        dotLayers.removeAll()
        
        (0..<numberOfPages).forEach { _ in
            let dotLayer = CALayer()
            layer.addSublayer(dotLayer)
            dotLayers.append(dotLayer)
        }
        
        updateDotLayersLayout()
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }
    
    func updateDotLayersLayout() {
        let floatCount = CGFloat(numberOfPages)
        let x = (bounds.size.width - diameter * floatCount - padding * (floatCount - 1)) * 0.5
        let y = (bounds.size.height - diameter) * 0.5
        var frame = CGRect(x: x, y: y, width: diameter, height: diameter)
        
        dotLayers.forEach {
            $0.cornerRadius = radius
            $0.frame = frame
            frame.origin.x += diameter + padding
        }
    }
    
    func update() {
        dotLayers.enumerated().forEach() {
            let inactiveTintColor = inactiveTintColor.withAlphaComponent(inactiveTransparency).cgColor
            $0.element.backgroundColor = $0.offset == currentPage ? currentPageTintColor.cgColor : inactiveTintColor
        }
        
        dotLayers.enumerated().forEach() {
            let selectedFrame = $0.element.frame
            let floatCount = CGFloat(numberOfPages)
            var x = selectedFrame.origin.x
            if $0.offset == 0 {
                x = (bounds.size.width - diameter * floatCount - padding * (floatCount - 1)) * 0.5
            }
            if $0.offset == currentPage {
                if $0.offset != 0 {
                    x = dotLayers[$0.offset - 1].frame.origin.x + diameter + padding
                }
                $0.element.frame = CGRect(x: x,
                                          y: selectedFrame.origin.y,
                                          width: diameter*2.5,
                                          height: diameter)
            } else {
                if $0.offset != 0 {
                    let previousX = dotLayers[$0.offset - 1].frame.origin.x
                    let previous = $0.offset - 1 == currentPage
                    $0.element.frame = CGRect(x: previousX + diameter + padding + (previous ? diameter*1.5 : 0),
                                              y: selectedFrame.origin.y,
                                              width: diameter,
                                              height: diameter)
                } else {
                    $0.element.frame = CGRect(x: x,
                                              y: selectedFrame.origin.y,
                                              width: diameter,
                                              height: diameter)
                }
            }
        }
        
        guard numberOfPages > limit else {
            return
        }
        
        changeFullScaleIndexsIfNeeded()
        setupDotLayersPosition()
    }
    
    func setupDotLayersPosition() {
        let centerLayer = dotLayers[centerIndex]
        centerLayer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        dotLayers.enumerated().forEach {
            let currentPageOffSet = $0.offset >= currentPage || $0.offset != 0 || true
            let index = abs($0.offset - centerIndex)
            let size = currentPageOffSet ? diameter*1.5 + padding : diameter + padding
            let interval = $0.offset >= centerIndex ? size : -(size)
            
            $0.element.position = CGPoint(x: centerLayer.position.x + interval * CGFloat(index),
                                          y: $0.element.position.y)
        }
    }

    func changeFullScaleIndexsIfNeeded() {
        guard !fullScaleIndex.contains(currentPage) else {
            return
        }
        
        let moreThanBefore = (fullScaleIndex.last ?? 0) < currentPage
        if moreThanBefore {
            fullScaleIndex[0] = currentPage - 2
            fullScaleIndex[1] = currentPage - 1
            fullScaleIndex[2] = currentPage
        } else {
            fullScaleIndex[0] = currentPage
            fullScaleIndex[1] = currentPage + 1
            fullScaleIndex[2] = currentPage + 2
        }
    }
}
