//
//  Animations.swift
//  Prayer App
//
//  Created by Levi on 10/24/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation
import UIKit

class Animations {
    func animateFirstLoad(journalIcon: UIButton, settingsIcon: UIButton, timerIcon: UIButton, titleImage: UIImageView, toolbarView: UIView, view: UIView) {
        view.layoutIfNeeded()
        
        let titleImageStartingPoint = CGPoint(x: titleImage.center.x, y: titleImage.center.y)
        let dismissLeftPoint = CGPoint(x: view.frame.minX - titleImage.frame.width, y: titleImage.frame.width)
        let dismissRightPoint = CGPoint(x: view.frame.maxX + titleImage.frame.width, y: titleImage.frame.width)
        
        titleImage.image = UIImage(named: "swipeToSave.pdf")
        titleImage.alpha = 0
        toolbarView.alpha = 0
        timerIcon.alpha = 0
        settingsIcon.alpha = 0
        journalIcon.alpha = 0
        
        titleImage.isHidden = false
        settingsIcon.isHidden = false
        
        UIView.animate(withDuration: 1.0, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            titleImage.alpha = 1
        }, completion: { finish in
            UIView.animate(withDuration: 0.5, delay: 2.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                titleImage.center.x = dismissLeftPoint.x
            }, completion: { finish in
                UIView.animate(withDuration: 0.0, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                    titleImage.alpha = 0
                    titleImage.center = titleImageStartingPoint
                    titleImage.image = UIImage(named: "swipeToSend.pdf")
                }, completion: { finish in
                    UIView.animate(withDuration: 1.0, delay: 1.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                        titleImage.alpha = 1
                    }, completion: { finish in
                        UIView.animate(withDuration: 0.5, delay: 2.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                            titleImage.center.x = dismissRightPoint.x
                        }, completion: { finish in
                            UIView.animate(withDuration: 0.0, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                                titleImage.alpha = 0
                                titleImage.center = titleImageStartingPoint
                                titleImage.image = UIImage(named: "prayerTitle.pdf")
                            }, completion: { finish in
                                UIView.animate(withDuration: 1.5, delay: 1.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                                    titleImage.alpha = 1
                                }, completion: { finish in
                                    UIView.animate(withDuration: 1.5, delay: 1.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                                        toolbarView.alpha = 1
                                        timerIcon.alpha = 1
                                        settingsIcon.alpha = 1
                                        journalIcon.alpha = 1
                                    })
                                })
                            })
                        })
                    })
                })
            })
        })
    }
    
    func animateLoad(journalIcon: UIButton, settingsIcon: UIButton, timerIcon: UIButton, titleImage: UIImageView, toolbarView: UIView, view: UIView) {
        view.layoutIfNeeded()
        titleImage.alpha = 0
        titleImage.isHidden = false
        settingsIcon.alpha = 0
        settingsIcon.isHidden = false
        toolbarView.alpha = 0
        timerIcon.alpha = 0
        journalIcon.alpha = 0
        
        UIView.animate(withDuration: 0.0, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            titleImage.image = UIImage(named: "prayerTitle.pdf")
        }, completion: { finish in
            UIView.animate(withDuration: 1.0, delay: 1.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                titleImage.alpha = 1
            }, completion: { finish in
                UIView.animate(withDuration: 1.0, delay: 1.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                    toolbarView.alpha = 1
                    timerIcon.alpha = 1
                    settingsIcon.alpha = 1
                    journalIcon.alpha = 1
                }, completion: nil)
            })
        })
    }
    
    func AnimateLabels(labelArrays: [Array<UILabel>], viewController: UIViewController, textView: UITextView) {
        var delay1 = 0.0
        textView.resignFirstResponder()
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            textView.isHidden = false
            textView.becomeFirstResponder()
        }
        
        for i in 0..<labelArrays.count {
                for label in labelArrays[i] {
                    let duration2: Double = Double(arc4random_uniform(UInt32(30) - UInt32(18) + 1) + 18) / Double(10)
                    let delay2: Double = Double(arc4random_uniform(UInt32(100) - UInt32(70) + 1) + 70) / Double(100) + delay1
                    
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: label.center.x, y: label.center.y))
                    path.addQuadCurve(to: CGPoint(x: label.center.x + 400, y: label.center.y - 500), controlPoint: CGPoint(x: viewController.view.frame.maxX, y: label.center.y))
                    
                    let animation = CAKeyframeAnimation(keyPath: "position")
                    animation.path = path.cgPath
                    animation.repeatCount = 0
                    animation.duration = duration2
                    animation.fillMode = kCAFillModeForwards
                    animation.isRemovedOnCompletion = false
                    animation.beginTime = CACurrentMediaTime() + delay2
                    label.layer.add(animation, forKey: "animate position along path")
                    
                    let alphaAnimation = CAKeyframeAnimation(keyPath: "opacity")
                    alphaAnimation.duration = duration2
                    alphaAnimation.isRemovedOnCompletion = false
                    alphaAnimation.autoreverses = false
                    alphaAnimation.values = [1.0, 0.0]
                    alphaAnimation.keyTimes = [0.0, 1.0]
                    alphaAnimation.repeatCount = 0
                    alphaAnimation.fillMode = kCAFillModeForwards
                    label.layer.add(alphaAnimation, forKey: "animate opacity")
                }
            delay1 += 0.1
        }
        CATransaction.commit()
    }
    
    func endTimerMainViewAnimation(timerIcon: UIButton, timerButton: UIButton, titleImage: UIImageView) {
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            titleImage.alpha = 0
            titleImage.isHidden = false
            UIView.animate(withDuration: 1.5, animations: {
                timerButton.alpha = 0
                timerIcon.alpha = 0
            }, completion: { (finish) in
                timerButton.isHidden = true
                timerIcon.setBackgroundImage(UIImage(named: "timerIcon.pdf"), for: .normal)
                UIView.animate(withDuration: 1.5, delay: 1.0, options: [], animations: {
                    timerIcon.setBackgroundImage(UIImage(named: "timerIcon.pdf"), for: .normal)
                    timerIcon.alpha = 1
                    titleImage.alpha = 1
                }, completion: { (finish) in
                    TimerStruct().resetSeconds()
                    timerButton.setTitle(TimerStruct().timeString(time: TimeInterval(TimerStruct.seconds)), for: .normal)
                })
            })
        }
        
        let pulseAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        pulseAnimation.duration = 0.5
        pulseAnimation.fromValue = 1
        pulseAnimation.toValue = 0
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = 3
        timerButton.layer.add(pulseAnimation, forKey: "animateOpacity")
        
        CATransaction.commit()
    }
    
    func endTimerAnimation(timerButton: UIButton, titleImage: UIImageView) {
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            titleImage.alpha = 0
            titleImage.isHidden = false
            UIView.animate(withDuration: 1.5, animations: {
                timerButton.alpha = 0
            }, completion: { (finish) in
                timerButton.isHidden = true
                UIView.animate(withDuration: 1.5, delay: 1.0, options: [], animations: {
                    titleImage.alpha = 1
                }, completion: { (finish) in
                    TimerStruct().resetSeconds()
                    timerButton.setTitle(TimerStruct().timeString(time: TimeInterval(TimerStruct.seconds)), for: .normal)
                })
            })
        }
        
        let pulseAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        pulseAnimation.duration = 0.5
        pulseAnimation.fromValue = 1
        pulseAnimation.toValue = 0
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = 3
        timerButton.layer.add(pulseAnimation, forKey: "animateOpacity")
        
        CATransaction.commit()
    }
    
    func animateSaveToJournalPopup(view: UIView, backgroundButton: UIButton, subView: UIView, viewController: UIViewController, textField: UITextField, textView: UITextView) {
        textView.resignFirstResponder()
        UIView.animate(withDuration: 0.33, animations: {
             backgroundButton.alpha = 0.66
        }) { (success) in
            view.alpha = 1
            subView.alpha = 1
        }
        UIView.animate(withDuration: 0.33, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 10, options: UIViewAnimationOptions(rawValue: 0), animations: {
            subView.center = CGPoint(x: viewController.view.center.x, y: viewController.view.bounds.height / 3 + 20)
        }, completion: { (completed) in
            subView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            subView.alpha = 0.0
            UIView.animate(withDuration: 0.33, animations: {
                subView.alpha = 1.0
                subView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                textField.becomeFirstResponder()
            }, completion: nil)
        })
    }
    
    func animateSpinner(spinnerView: UIView, spinnerImage: UIImageView, spinnerLabel: UILabel, spinnerString: String, textView: UITextView, viewController: UIViewController) {
        spinnerLabel.text = spinnerString
        UIView.animate(withDuration: 0.8, delay: 0.0, options: [.curveEaseIn], animations: {
            spinnerImage.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            spinnerLabel.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            spinnerView.alpha = 1.0
            spinnerImage.alpha = 1.0
            spinnerLabel.alpha = 1.0
        }) { (completed) in
            UIView.animate(withDuration: 0.5, delay: 1.0, options: [.curveEaseIn], animations: {
                spinnerImage.alpha = 0
                spinnerLabel.alpha = 0
                spinnerView.alpha = 0
            }, completion: { (completed) in
                textView.becomeFirstResponder()
            })
        }
    }
}
