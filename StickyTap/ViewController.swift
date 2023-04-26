//
//  ViewController.swift
//  StickyTap
//
//  Created by Igor Postoev on 14.12.2021.
//

import UIKit

class ViewController: UIViewController, CAAnimationDelegate {
    
    private var animationContainers: [RotatingAnimationContainer] = []
    private let topStraightLayer = CAShapeLayer()
    
    private let button = UIButton()
    private let circleMovementLayer = CAShapeLayer()
    
    private var checkingIntersectTimer: Timer?
    var topToBottomAnimation = CABasicAnimation(keyPath: "position")
    
    var intersectedCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupButton()
        
        let rotatingRadius = CGFloat(80)
        let targetDiameter = CGFloat(40)
        setupCircleMovementLayer(radius: rotatingRadius)
        
        let movementCenter = circleMovementLayer.convert(view.center, from: view.layer)
        let layer1 = createRotatingLayer(position: CGPoint(x: movementCenter.x - rotatingRadius,
                                                           y: movementCenter.y),
                                         diameter: targetDiameter)
        let layer2 = createRotatingLayer(position: CGPoint(x: movementCenter.x + rotatingRadius,
                                                           y: movementCenter.y),
                                         diameter: targetDiameter)
        circleMovementLayer.addSublayer(layer1)
        circleMovementLayer.addSublayer(layer2)
        animationContainers.append(RotatingAnimationContainer(layer: layer1,
                                                              center: movementCenter,
                                                              rotatingRadius: rotatingRadius))
        animationContainers.append(RotatingAnimationContainer(layer: layer2,
                                                              center: movementCenter,
                                                              rotatingRadius: rotatingRadius))
        
        animationContainers.forEach {
            $0.applyAnimation()
        }

        //top-to-bottom straight
        
        topStraightLayer.bounds = CGRect(x: 0,
                                         y: 0,
                                         width: targetDiameter,
                                         height: targetDiameter)
        topStraightLayer.position = CGPoint(x: view.center.x,
                                            y: -targetDiameter)
        topStraightLayer.path = UIBezierPath(ovalIn: topStraightLayer.bounds).cgPath
        topStraightLayer.fillColor = UIColor.green.cgColor
        view.layer.addSublayer(topStraightLayer)

        //top-to-bottom animation
        topToBottomAnimation.fromValue = topStraightLayer.position
        topToBottomAnimation.toValue = CGPoint(x: view.center.x,
                                               y: view.bounds.height)
        topToBottomAnimation.duration = 5
        topToBottomAnimation.repeatDuration = .infinity
        topToBottomAnimation.delegate = self
        topStraightLayer.add(topToBottomAnimation, forKey: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        let timer = Timer(timeInterval: 0.05, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        checkingIntersectTimer = timer
        RunLoop.current.add(timer, forMode: .default)
    }
    
    @objc
    func timerFired() {
        guard let avoidPresentationFrame = topStraightLayer.presentation()?.frame else {
            checkingIntersectTimer?.invalidate()
            return
        }
        animationContainers.forEach {
            if let presentation = $0.presentation {
                //let frameInSameSpace = presentation.convert(presentation.frame, to: view.layer)
                let superLayerFrame = presentation.superlayer!.frame
                let frameInSameSpace = CGRect(x: superLayerFrame.minX + (160 - presentation.frame.midX),
                                              y: superLayerFrame.minY + (160 - presentation.frame.midY),
                                              width: 30, height: 30)
                if avoidPresentationFrame.intersects(frameInSameSpace) {
                    intersectedCount += 1
                    print("InterSECT \(intersectedCount)")
                    topStraightLayer.removeAllAnimations()
                    return
                }
            }
        }
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        CATransaction.setDisableActions(true)
        topStraightLayer.position = CGPoint(x: view.center.x, y: -30)
        topStraightLayer.add(topToBottomAnimation, forKey: nil)
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        checkingIntersectTimer?.invalidate()
        checkingIntersectTimer = nil
    }
    
    private func setupButton() {
        //view.addSubview(button)
        button.center = view.center
        button.center.y += 200
        button.setTitle("push me", for: .normal)
        button.backgroundColor = .gray
        button.bounds = CGRect(x: 0, y: 0, width: 100, height: 50)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    private func setupCircleMovementLayer(radius: CGFloat) {
        // rotating path layer
        let circleMovementRect = CGRect(x: 0,
                                        y: 0,
                                        width: radius * 2,
                                        height: radius * 2)
        circleMovementLayer.bounds = circleMovementRect
        circleMovementLayer.position = view.center
        circleMovementLayer.path = UIBezierPath(ovalIn: circleMovementRect).cgPath
        circleMovementLayer.strokeColor = UIColor.clear.cgColor
        circleMovementLayer.lineDashPattern = [3, 5]
        circleMovementLayer.fillColor = UIColor.clear.cgColor
        
        //rotate for using canonical coordinate space
        circleMovementLayer.transform = CATransform3DRotate(circleMovementLayer.transform,
                                                            .pi, 0.0, 1.0, 0.0)
        circleMovementLayer.transform = CATransform3DRotate(circleMovementLayer.transform,
                                                            .pi, 0.0, 0.0, 1.0)
        view.layer.addSublayer(circleMovementLayer)
    }
    
    func createRotatingLayer(position: CGPoint, diameter: CGFloat) -> CAShapeLayer {
        let rotatingRect = CGRect(x: 0,
                                  y: 0,
                                  width: diameter,
                                  height: diameter)
        let layer = CAShapeLayer()
        layer.bounds = rotatingRect
        layer.position = position
        layer.path = UIBezierPath(ovalIn: rotatingRect).cgPath
        layer.fillColor = CGColor(red: 0, green: 0, blue: 1, alpha: 0.5)
        return layer
    }
    
    //MARK: -UIResponder
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        buttonTapped()
    }
    
    @objc
    func buttonTapped() {
        CATransaction.setDisableActions(true)
        animationContainers.forEach {
            $0.setLayerPresentationPosition()
            $0.removeAnimations()
        }
    }
}

class RotatingAnimationContainer: NSObject, CAAnimationDelegate {
    
    var presentation: CALayer? {
        return layerToAnimate.presentation()
    }
    
    private var clockwise = true
    private var center: CGPoint = .zero
    
    private let layerToAnimate: CALayer
    private let rotatingRadius: CGFloat
    
    init(layer: CALayer, center: CGPoint, rotatingRadius: CGFloat) {
        self.layerToAnimate = layer
        self.rotatingRadius = rotatingRadius
        self.center = center
    }
    
    private lazy var rotatingAnimation: CAKeyframeAnimation = {
        let rotatingAnimation = CAKeyframeAnimation(keyPath: "position")
        rotatingAnimation.calculationMode = .paced
        rotatingAnimation.duration = 5
        rotatingAnimation.repeatDuration = .infinity
        rotatingAnimation.delegate = self
        return rotatingAnimation
    }()
    
    //MARK: -Animation config
    
    func setLayerPresentationPosition() {
        layerToAnimate.position = layerToAnimate.presentation()!.position
    }
    
    func removeAnimations() {
        layerToAnimate.removeAllAnimations()
    }
    
    func applyAnimation() {
        rotatingAnimation.path = createRotatingPath(with: layerToAnimate.position, clockwise)
        layerToAnimate.add(rotatingAnimation, forKey: "position")
    }
    
    func updateAnimation(center: CGPoint) {
        self.center = center
    }
    
    //MARK: -CAAnimationDelegate
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        clockwise.toggle()
        applyAnimation()
    }
    
    private func createRotatingPath(with position: CGPoint, _ clockwise: Bool) -> CGPath {
        
        //build arc path beginning with same position
        let dx = center.x - position.x
        let dy = center.y - position.y
        
        let cosVal = -dx / rotatingRadius
        let sinVal = -dy / rotatingRadius
        
        //sin abs can be < 0 or > 1 in edge cases
        let restricted = max(min(abs(sinVal), 1.0), 0.0)
        var currentAngle = asin(sinVal.sign == .minus ? -restricted : restricted)
        
        //change angle with respect to position quarter
        if cosVal < 0 && sinVal >= 0 {
            currentAngle = .pi - currentAngle
        } else if cosVal <= 0 && sinVal < 0 {
            currentAngle = -.pi - currentAngle
        }
        
        let path = CGMutablePath()
        path.addArc(center: center,
                    radius: rotatingRadius,
                    startAngle: currentAngle,
                    endAngle: currentAngle + (clockwise ? -1 : 1) * .pi * 2,
                    clockwise: clockwise)
        return path
    }
}

