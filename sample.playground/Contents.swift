//: Playground - noun: a place where people can play

import UIKit
import XCPlayground

extension UIColor {
    
    convenience init(hex: UInt, alpha: CGFloat) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: CGFloat(alpha)
        )
    }
    
}

final class MaterialCircularProgress: UIView {
    
    let MinStrokeLength: CGFloat = 0.01
    let MaxStrokeLength: CGFloat = 1.0
    let circleOutlineLayer     = CAShapeLayer()
    let insideCircleShapeLayer = CAShapeLayer()
    let checkmarkShapeLayer    = CAShapeLayer()
    
    var CheckmarkPath: UIBezierPath {
        get {
            let CheckmarkSize  = CGSize(width: 20, height: 16)
            let checkmarkPath = UIBezierPath()
            let startPoint    = CGPoint(x: center.x - CheckmarkSize.width * 0.48,
                y: center.y + CheckmarkSize.height * 0.05)
            checkmarkPath.moveToPoint(startPoint)
            let firstLineEndPoint = CGPoint(x: startPoint.x + CheckmarkSize.width * 0.36,
                y: startPoint.y + CheckmarkSize.height * 0.36)
            checkmarkPath.addLineToPoint(firstLineEndPoint)
            let secondLineEndPoint = CGPoint(x: firstLineEndPoint.x + CheckmarkSize.width * 0.64,
                y: firstLineEndPoint.y - CheckmarkSize.height)
            checkmarkPath.addLineToPoint(secondLineEndPoint)
            return checkmarkPath
        }
    }
    
    var duration: Double = 3.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clearColor()
        initShapeLayer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initShapeLayer() {
        // Outline
        let outLineWidth: CGFloat = 5
        circleOutlineLayer.actions = ["strokeEnd" : NSNull(),
                                    "strokeStart" : NSNull(),
                                    "transform" : NSNull(),
                                    "strokeColor" : NSNull()]
        circleOutlineLayer.backgroundColor = UIColor.clearColor().CGColor
        circleOutlineLayer.strokeColor     = UIColor.blueColor().CGColor
        circleOutlineLayer.fillColor       = UIColor.clearColor().CGColor
        circleOutlineLayer.lineWidth       = outLineWidth
        circleOutlineLayer.strokeStart     = 0
        circleOutlineLayer.strokeEnd       = MinStrokeLength
        let center                         = CGPoint(x: bounds.width*0.5, y: bounds.height*0.5)
        circleOutlineLayer.frame           = bounds
        circleOutlineLayer.lineCap         = kCALineCapButt
        circleOutlineLayer.path            = UIBezierPath(arcCenter: center,
                                                        radius: center.x,
                                                        startAngle: 0,
                                                        endAngle: CGFloat(M_PI*2),
                                                        clockwise: true).CGPath
        circleOutlineLayer.transform       = CATransform3DMakeRotation(CGFloat(M_PI*1.5), 0, 0, 1.0)
        layer.addSublayer(circleOutlineLayer)
        // Inside
        let insideCircleRect = CGRect(origin: CGPoint(x: outLineWidth * 0.5, y: outLineWidth * 0.5),
                                      size: CGSize(width: circleOutlineLayer.bounds.width - outLineWidth,
                                        height: circleOutlineLayer.bounds.height - outLineWidth))
        let insideCirclePath = UIBezierPath(ovalInRect: insideCircleRect).CGPath
        insideCircleShapeLayer.path = insideCirclePath
        insideCircleShapeLayer.fillColor = UIColor(hex: 0xf19b00, alpha: 1.0).CGColor
        insideCircleShapeLayer.opacity   = 0
        layer.addSublayer(insideCircleShapeLayer)
        // Checkmark
        checkmarkShapeLayer.strokeColor = UIColor.whiteColor().CGColor
        checkmarkShapeLayer.lineWidth   = 3.0
        checkmarkShapeLayer.fillColor   = UIColor.clearColor().CGColor
        checkmarkShapeLayer.path        = CheckmarkPath.CGPath
        checkmarkShapeLayer.strokeEnd   = 0
        layer.addSublayer(checkmarkShapeLayer)
    }
    
    func startAnimating(duration: Double) {
        self.duration = duration
        if layer.animationForKey("rotation") == nil {
            startColorAnimation()
            startStrokeAnimation()
            startRotatingAnimation()
        }
    }
    
    private func startColorAnimation() {
        let color      = CAKeyframeAnimation(keyPath: "strokeColor")
        color.duration = 10.0
        color.values   = [UIColor(hex: 0xf19b00, alpha: 1.0).CGColor]
        color.calculationMode = kCAAnimationPaced
        color.repeatCount     = Float.infinity
        circleOutlineLayer.addAnimation(color, forKey: "color")
    }
    
    private func startRotatingAnimation() {
        let rotation            = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue        = M_PI*6.0
        rotation.duration       = duration * 0.77
        rotation.cumulative     = true
        rotation.additive       = true
        rotation.removedOnCompletion = false
        rotation.fillMode       = kCAFillModeForwards
        rotation.timingFunction = CAMediaTimingFunction(controlPoints: 0.39, 0.575, 0.565, 1.0)
        circleOutlineLayer.addAnimation(rotation, forKey: "rotation")
    }
    
    private func startStrokeAnimation() {
        let easeInOutSineTimingFunc = CAMediaTimingFunction(controlPoints: 0.39, 0.575, 0.565, 1.0)
        let progress: CGFloat     = MaxStrokeLength
        let endFromValue: CGFloat = circleOutlineLayer.strokeEnd
        let endToValue: CGFloat   = endFromValue + progress
        let strokeEnd                   = CABasicAnimation(keyPath: "strokeEnd")
        strokeEnd.fromValue             = endFromValue
        strokeEnd.toValue               = endToValue
        strokeEnd.duration              = duration
        strokeEnd.fillMode              = kCAFillModeForwards
        strokeEnd.timingFunction        = easeInOutSineTimingFunc
        strokeEnd.removedOnCompletion   = false
        let pathAnim                 = CAAnimationGroup()
        pathAnim.animations          = [strokeEnd]
        pathAnim.duration            = duration
        pathAnim.fillMode            = kCAFillModeForwards
        pathAnim.removedOnCompletion = false
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.startCompletionAnimation()
        }
        circleOutlineLayer.addAnimation(pathAnim, forKey: "stroke")
        CATransaction.commit()
    }
    
    private func startCompletionAnimation() {
        startFadeOutOutSideLineAnimation()
        startFillCircleAnimation()
        startDrawingCheckmarkAnimation()
    }

    private func startFadeOutOutSideLineAnimation() {
        let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
        fadeOutAnimation.toValue  = 0
        fadeOutAnimation.duration = 0.3
        fadeOutAnimation.fillMode = kCAFillModeForwards
        fadeOutAnimation.removedOnCompletion = false
        fadeOutAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        circleOutlineLayer.addAnimation(fadeOutAnimation, forKey: "fadeOut")
    }
    
    private func startFillCircleAnimation() {
        let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
        fadeInAnimation.toValue  = 1.0
        fadeInAnimation.duration = 0.3
        fadeInAnimation.fillMode = kCAFillModeForwards
        fadeInAnimation.removedOnCompletion = false
        fadeInAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        insideCircleShapeLayer.addAnimation(fadeInAnimation, forKey: "fadeOut")
    }
    
    private func startDrawingCheckmarkAnimation() {
        let drawPathAnimation = CABasicAnimation(keyPath: "strokeEnd")
        drawPathAnimation.toValue = 1.0
        drawPathAnimation.fillMode = kCAFillModeForwards
        drawPathAnimation.removedOnCompletion = false
        drawPathAnimation.duration = 0.3
        checkmarkShapeLayer.addAnimation(drawPathAnimation, forKey: "strokeEnd")
    }
    
    func stopAnimating() {
        layer.removeAllAnimations()
        circleOutlineLayer.removeAllAnimations()
        insideCircleShapeLayer.removeAllAnimations()
        checkmarkShapeLayer.removeAllAnimations()
        circleOutlineLayer.transform = CATransform3DIdentity
        layer.transform              = CATransform3DIdentity
    }
    
}

let view = UIView(frame: CGRect(origin: CGPoint.zero,
    size: CGSize(width: 300, height: 300)))
let progress = MaterialCircularProgress(frame: CGRect(origin: CGPoint.zero,
    size: CGSize(width: 80, height: 80)))
progress.center = CGPoint(x: view.bounds.width * 0.5, y: view.bounds.height * 0.5)
view.addSubview(progress)
XCPlaygroundPage.currentPage.liveView = view
progress.startAnimating(3.0)
