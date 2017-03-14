//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

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
    let AfterpartDuration: Double = 0.3
    
    var CheckmarkPath: UIBezierPath {
        get {
            let CheckmarkSize  = CGSize(width: 20, height: 16)
            let checkmarkPath = UIBezierPath()
            let startPoint    = CGPoint(x: center.x - CheckmarkSize.width * 0.48,
                y: center.y + CheckmarkSize.height * 0.05)
            checkmarkPath.move(to: startPoint)
            let firstLineEndPoint = CGPoint(x: startPoint.x + CheckmarkSize.width * 0.36,
                y: startPoint.y + CheckmarkSize.height * 0.36)
            checkmarkPath.addLine(to: firstLineEndPoint)
            let secondLineEndPoint = CGPoint(x: firstLineEndPoint.x + CheckmarkSize.width * 0.64,
                y: firstLineEndPoint.y - CheckmarkSize.height)
            checkmarkPath.addLine(to: secondLineEndPoint)
            return checkmarkPath
        }
    }
    
    var duration: Double = 3.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
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
        circleOutlineLayer.backgroundColor = UIColor.clear.cgColor
        circleOutlineLayer.strokeColor     = UIColor.blue.cgColor
        circleOutlineLayer.fillColor       = UIColor.clear.cgColor
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
                                                        clockwise: true).cgPath
        circleOutlineLayer.transform       = CATransform3DMakeRotation(CGFloat(M_PI*1.5), 0, 0, 1.0)
        layer.addSublayer(circleOutlineLayer)
        // Inside
        let insideCircleRect = CGRect(origin: CGPoint(x: outLineWidth * 0.5, y: outLineWidth * 0.5),
                                      size: CGSize(width: circleOutlineLayer.bounds.width - outLineWidth,
                                        height: circleOutlineLayer.bounds.height - outLineWidth))
        let insideCirclePath = UIBezierPath(ovalIn: insideCircleRect).cgPath
        insideCircleShapeLayer.path = insideCirclePath
        insideCircleShapeLayer.fillColor = UIColor(hex: 0xf19b00, alpha: 1.0).cgColor
        insideCircleShapeLayer.opacity   = 0
        layer.addSublayer(insideCircleShapeLayer)
        // Checkmark
        checkmarkShapeLayer.strokeColor = UIColor.white.cgColor
        checkmarkShapeLayer.lineWidth   = 3.0
        checkmarkShapeLayer.fillColor   = UIColor.clear.cgColor
        checkmarkShapeLayer.path        = CheckmarkPath.cgPath
        checkmarkShapeLayer.strokeEnd   = 0
        layer.addSublayer(checkmarkShapeLayer)
    }
    
    func startAnimating(duration: Double) {
        self.duration = duration
        if layer.animation(forKey: "rotation") == nil {
            startColorAnimation()
            startStrokeAnimation()
            startRotatingAnimation()
        }
    }
    
    private func startColorAnimation() {
        let color      = CAKeyframeAnimation(keyPath: "strokeColor")
        color.duration = 10.0
        color.values   = [UIColor(hex: 0xf19b00, alpha: 1.0).cgColor]
        color.calculationMode = kCAAnimationPaced
        color.repeatCount     = Float.infinity
        circleOutlineLayer.add(color, forKey: "color")
    }
    
    private func startRotatingAnimation() {
        let rotation            = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue        = M_PI*6.0
        rotation.duration       = (duration - AfterpartDuration) * 0.77
        rotation.isCumulative   = true
        rotation.isAdditive     = true
        rotation.isRemovedOnCompletion = false
        rotation.fillMode       = kCAFillModeForwards
        rotation.timingFunction = CAMediaTimingFunction(controlPoints: 0.39, 0.575, 0.565, 1.0)
        circleOutlineLayer.add(rotation, forKey: "rotation")
    }
    
    private func startStrokeAnimation() {
        let easeInOutSineTimingFunc = CAMediaTimingFunction(controlPoints: 0.39, 0.575, 0.565, 1.0)
        let progress: CGFloat     = MaxStrokeLength
        let endFromValue: CGFloat = circleOutlineLayer.strokeEnd
        let endToValue: CGFloat   = endFromValue + progress
        let strokeEnd                   = CABasicAnimation(keyPath: "strokeEnd")
        strokeEnd.fromValue             = endFromValue
        strokeEnd.toValue               = endToValue
        strokeEnd.duration              = duration - AfterpartDuration
        strokeEnd.fillMode              = kCAFillModeForwards
        strokeEnd.timingFunction        = easeInOutSineTimingFunc
        strokeEnd.isRemovedOnCompletion = false
        let pathAnim                   = CAAnimationGroup()
        pathAnim.animations            = [strokeEnd]
        pathAnim.duration              = duration - AfterpartDuration
        pathAnim.fillMode              = kCAFillModeForwards
        pathAnim.isRemovedOnCompletion = false
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.startCompletionAnimation()
        }
        circleOutlineLayer.add(pathAnim, forKey: "stroke")
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
        fadeOutAnimation.duration = AfterpartDuration
        fadeOutAnimation.fillMode = kCAFillModeForwards
        fadeOutAnimation.isRemovedOnCompletion = false
        fadeOutAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        circleOutlineLayer.add(fadeOutAnimation, forKey: "fadeOut")
    }
    
    private func startFillCircleAnimation() {
        let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
        fadeInAnimation.toValue  = 1.0
        fadeInAnimation.duration = AfterpartDuration
        fadeInAnimation.fillMode = kCAFillModeForwards
        fadeInAnimation.isRemovedOnCompletion = false
        fadeInAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        insideCircleShapeLayer.add(fadeInAnimation, forKey: "fadeOut")
    }
    
    private func startDrawingCheckmarkAnimation() {
        let drawPathAnimation = CABasicAnimation(keyPath: "strokeEnd")
        drawPathAnimation.toValue = 1.0
        drawPathAnimation.fillMode = kCAFillModeForwards
        drawPathAnimation.isRemovedOnCompletion = false
        drawPathAnimation.duration = AfterpartDuration
        checkmarkShapeLayer.add(drawPathAnimation, forKey: "strokeEnd")
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
PlaygroundPage.current.liveView = view
progress.startAnimating(duration: 3.0)
