//
//  ViewController.swift
//  CoreImageVoronoi
//
//  Created by Simon Gladman on 08/04/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//


import UIKit
import GLKit

class ViewController: UIViewController
{
    var time: CGFloat = 0

    let imageView = OpenGLImageView()
    
    let voronoiKernel: CIColorKernel =
    {
        let shaderPath = NSBundle.mainBundle().pathForResource("Voronoi", ofType: "cikernel")
        
        guard let path = shaderPath,
            code = try? String(contentsOfFile: path),
            kernel = CIColorKernel(string: code) else
        {
            fatalError("Unable to build Voronoi shader")
        }
        
        return kernel
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.addSubview(imageView)
        
        let displayLink = CADisplayLink(target: self, selector: #selector(ViewController.step))
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }

    
    // MARK: Step
    
    func step()
    {
        time += 0.05

        let arguments = [time]
        
        let image = voronoiKernel.applyWithExtent(view.bounds, arguments: arguments)
        
        imageView.image = image
    }
    
    override func viewDidLayoutSubviews()
    {
        imageView.frame = view.bounds
    }
    
    override func prefersStatusBarHidden() -> Bool
    {
        return true
    }
}

// -----

class OpenGLImageView: GLKView
{
    let eaglContext = EAGLContext(API: .OpenGLES2)
    
    lazy var ciContext: CIContext =
    {
        [unowned self] in
        
        return CIContext(EAGLContext: self.eaglContext,
            options: [kCIContextWorkingColorSpace: NSNull()])
        }()
    
    override init(frame: CGRect)
    {
        super.init(frame: frame, context: eaglContext)
        
        context = self.eaglContext
        delegate = self
    }
    
    override init(frame: CGRect, context: EAGLContext)
    {
        fatalError("init(frame:, context:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// The image to display
    var image: CIImage?
        {
        didSet
        {
            setNeedsDisplay()
        }
    }
}

extension OpenGLImageView: GLKViewDelegate
{
    func glkView(view: GLKView, drawInRect rect: CGRect)
    {
        guard let image = image else
        {
            return
        }
        
        let targetRect = image.extent.aspectFitInRect(
            target: CGRect(origin: CGPointZero,
                size: CGSize(width: drawableWidth,
                    height: drawableHeight)))
        
        let ciBackgroundColor = CIColor(
            color: backgroundColor ?? UIColor.whiteColor())
        
        ciContext.drawImage(CIImage(color: ciBackgroundColor),
            inRect: CGRect(x: 0,
                y: 0,
                width: drawableWidth,
                height: drawableHeight),
            fromRect: CGRect(x: 0,
                y: 0,
                width: drawableWidth,
                height: drawableHeight))
        
        ciContext.drawImage(image,
            inRect: targetRect,
            fromRect: image.extent)
    }
}

extension CGRect
{
    func aspectFitInRect(target target: CGRect) -> CGRect
    {
        let scale: CGFloat =
        {
            let scale = target.width / self.width
            
            return self.height * scale <= target.height ?
                scale :
                target.height / self.height
        }()
        
        let width = self.width * scale
        let height = self.height * scale
        let x = target.midX - width / 2
        let y = target.midY - height / 2
        
        return CGRect(x: x,
            y: y,
            width: width,
            height: height)
    }
}
