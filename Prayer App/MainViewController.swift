//
//  MainViewController.swift
//  Prayer App
//
//  Created by Levi on 10/23/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import StoreKit

class MainViewController: UIViewController {
    
    @IBOutlet var timerButtons: [UIButton]!
    
    @IBOutlet weak var textField: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var settingsIcon: UIButton!
    @IBOutlet weak var titleImage: UIImageView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var ideaIcon: UIButton!
    @IBOutlet weak var timerIcon: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var timerPreferencesSelectionView: UIView!
    
    var firstAppear = true
    var passFirstResonder = true
    var timerIsRunning = false
    var resumeTapped = false
    var timerChanged = false
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(normalTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        timerIcon.addGestureRecognizer(tapGesture)
        
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap(_:)))
        timerIcon.addGestureRecognizer(longGesture)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        self.view.addGestureRecognizer(swipeDown)
        
        UserDefaultsHelper().getLoads()
        Loads.loadCount += 1
        UserDefaultsHelper().saveLoad()
        
        UserDefaultsHelper().getPreferredTimerDuration()
        
        TimerStruct().resetSeconds()
        TimerStruct().updateTimerPreferencesDisplay(buttons: timerButtons)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        titleImage.isHidden = true
        settingsIcon.isHidden = true
        if !firstAppear {
            titleImage.isHidden = false
            settingsIcon.isHidden = false
        }
        
        if Loads.loadCount == 3 && passFirstResonder == true {
            SKStoreReviewController.requestReview()
            passFirstResonder = false
        } else {
            textField.becomeFirstResponder()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if firstAppear {
            if Loads.loadCount == 1 {
                Animations().animateFirstLoad(settingsIcon: settingsIcon, ideaIcon: ideaIcon, timerIcon: timerIcon, titleImage: titleImage, view: self.view)
            } else if Loads.loadCount == 3 {
                Animations().animateLoad(settingsIcon: settingsIcon, ideaIcon: ideaIcon, timerIcon: timerIcon, titleImage: titleImage, view: self.view)
            } else {
                Animations().animateLoad(settingsIcon: settingsIcon, ideaIcon: ideaIcon, timerIcon: timerIcon, titleImage: titleImage, view: self.view)
            }
        }
        firstAppear = false
    }
    
    @IBAction func timerButtonTapped(_ sender: Any) {
        if let tag = (sender as AnyObject).tag {
            TimerStruct().toggleTimerPreferences(buttons: timerButtons, sender: tag)
            timerChanged = true
        }
    }
    
    @IBAction func ideaDidPress(_ sender: Any) {
        let i = Int(arc4random_uniform(UInt32(TopicIdeas().topicArray.count)))
        if let currentText = textField.text {
            if currentText != "" {
                textField.text = "\(currentText)\n\n\(TopicIdeas().topicArray[i])"
            } else {
                textField.text = TopicIdeas().topicArray[i]
            }
        }
    }
    
    @objc func normalTap(_ sender: UIGestureRecognizer){
        if timerIsRunning == false {
            startTimer()
        } else {
            stopTimer()
        }
    }
    
    @objc func longTap(_ sender: UIGestureRecognizer){
        if sender.state == .ended {
        }
        else if sender.state == .began {
            TimerStruct().updateTimerPreferencesDisplay(buttons: timerButtons)
            textField.resignFirstResponder()
            UIView.animate(withDuration: 0.3, animations: {
                self.timerPreferencesSelectionView.alpha = 1
            })
        }
    }
    
    @IBAction func timerPreferenceBackgroundShadowDidPress(_ sender: Any) {
        dismissTimerPopup()
        if timerChanged == true {
            stopTimer()
            startTimer()
            timerChanged = false
        }
    }
    
    @objc func dismissTimerPopup() {
        self.timerPreferencesSelectionView.alpha = 0
        textField.becomeFirstResponder()
    }
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(MainViewController.updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        if TimerStruct.seconds < 1 {
            timer.invalidate()
            timerIsRunning = false
            Animations().endTimerAnimation(timerIcon: timerIcon, timerLabel: timerLabel, titleImage: titleImage)
            // Do Animation
        } else {
            TimerStruct.seconds -= 1
            timerLabel.text = TimerStruct().timeString(time: TimeInterval(TimerStruct.seconds))
        }
    }
    
    func startTimer() {
        TimerStruct().resetSeconds()
        titleImage.isHidden = true
        timerLabel.text = TimerStruct().timeString(time: TimeInterval(TimerStruct.seconds))
        timerLabel.alpha = 1
        timerLabel.isHidden = false
        timerIcon.setBackgroundImage(UIImage(named: "timerIconSelected.pdf"), for: .normal)
        timerIsRunning = true
        runTimer()
    }
    
    func stopTimer() {
        titleImage.isHidden = false
        timerLabel.isHidden = true
        timerIcon.setBackgroundImage(UIImage(named: "timerIcon.pdf"), for: .normal)
        timerIsRunning = false
        timer.invalidate()
        TimerStruct().resetSeconds()    //Here we manually enter the restarting point for the seconds, but it would be wiser to make this a variable or constant.
        timerLabel.text = "\(TimerStruct.seconds)"
    }
    
    
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                sendText()
            case UISwipeGestureRecognizerDirection.down:
                textField.resignFirstResponder()
            case UISwipeGestureRecognizerDirection.left:
                shareText()
            default:
                break
            }
        }
    }
    
    @objc func keyboardWillShow(notification:NSNotification){
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset: UIEdgeInsets = self.scrollView.contentInset
        var textViewInset: UIEdgeInsets = self.textField.contentInset
        
        contentInset.bottom = keyboardFrame.size.height + 5
        textViewInset.bottom = keyboardFrame.size.height + 5
        
        textField.contentInset = textViewInset
        scrollView.contentInset = contentInset
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
    }
    
    func shareText() {
        if textField.text != "" {
            displayShareSheet(shareContent: textField.text!)
        } else {
            let alert = UIAlertController(title: "Nothing To Save", message: "Please enter text and try again.", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func displayShareSheet(shareContent: String) {
        let activityViewController = UIActivityViewController(activityItems: [shareContent as NSString], applicationActivities: nil)
        present(activityViewController, animated: true, completion: {})
    }
    
    func sendText() {
        if textField.text != "" {
            var labels = [UILabel]()
            var i = 0
            for character in textField.text! {
                let rect = textField.boundingRectForCharacterRange(index: i)
                let cgRect = CGRect(x: rect!.minX, y: rect!.minY - 1.3, width: rect!.width + 3, height: rect!.height)
                let label = UILabel(frame: cgRect)
                label.text = String(character)
                label.alpha = 1
                scrollView.addSubview(label)
                labels.append(label)
                i += 1
            }
            textField.text = ""
            textField.isHidden = true
            let arrayOfLabelArrays = splitLabelsIntoQuadrants(labels: labels, vc: self)
            Animations().AnimateLabels(labelArrays: arrayOfLabelArrays, viewController: self, textView: textField)
        } else {
            let alert = UIAlertController(title: "Nothing To Send", message: "Please enter text and try again.", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        textField.resignFirstResponder()
        stopTimer()
    }
}

func splitLabelsIntoQuadrants(labels: [UILabel], vc: UIViewController) -> [Array<UILabel>] {
    var arrayOfLabels = [Array<UILabel>]()
    let height = vc.view.frame.height / 3
    let width = vc.view.frame.width / 3
    
    var section1Array = [UILabel]()
    let section1 = CGRect(x: 0, y: 0, width: width, height: height)
    
    var section3Array = [UILabel]()
    let section3 = CGRect(x: vc.view.frame.width / 3, y: 0, width: width, height: height)
    
    var section4Array = [UILabel]()
    let section4 = CGRect(x: (vc.view.frame.width / 3) * 2, y: 0, width: width, height: height)
    
    var section2Array = [UILabel]()
    let section2 = CGRect(x: 0, y: vc.view.frame.height / 3, width: width, height: height)
    
    var section5Array = [UILabel]()
    let section5 = CGRect(x: vc.view.frame.width / 3, y: vc.view.frame.height / 3, width: width, height: height)
    
    var section7Array = [UILabel]()
    let section7 = CGRect(x: (vc.view.frame.width / 3) * 2, y: vc.view.frame.height / 3, width: width, height: height)
    
    var section6Array = [UILabel]()
    let section6 = CGRect(x: 0, y: (vc.view.frame.height / 3) * 2, width: width, height: height)
    
    var section8Array = [UILabel]()
    let section8 = CGRect(x: vc.view.frame.width / 3, y: (vc.view.frame.height / 3) * 2, width: width, height: height)
    
    var section9Array = [UILabel]()
    let section9 = CGRect(x: (vc.view.frame.width / 3) * 2, y: (vc.view.frame.height / 3) * 2, width: width, height: height)
    
    for label in labels {
        switch (label) {
        case _ where section1.contains(label.center):
            section1Array.append(label)
        case _ where section2.contains(label.center):
            section2Array.append(label)
        case _ where section3.contains(label.center):
            section3Array.append(label)
        case _ where section4.contains(label.center):
            section4Array.append(label)
        case _ where section5.contains(label.center):
            section5Array.append(label)
        case _ where section6.contains(label.center):
            section6Array.append(label)
        case _ where section7.contains(label.center):
            section7Array.append(label)
        case _ where section8.contains(label.center):
            section8Array.append(label)
        case _ where section9.contains(label.center):
            section9Array.append(label)
        default:
            break
        }
    }
    
    arrayOfLabels.append(section1Array)
    arrayOfLabels.append(section2Array)
    arrayOfLabels.append(section3Array)
    arrayOfLabels.append(section4Array)
    arrayOfLabels.append(section5Array)
    arrayOfLabels.append(section6Array)
    arrayOfLabels.append(section7Array)
    arrayOfLabels.append(section8Array)
    arrayOfLabels.append(section9Array)
    
    return arrayOfLabels
}


    
extension UITextView {
    func boundingRectForCharacterRange(index: Int) -> CGRect? {
        let range = NSRange(location: index, length: 1)
        guard let attributedText = attributedText else { return nil }

        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: bounds.size)

        layoutManager.addTextContainer(textContainer)
        var glyphRange = NSRange()
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)

        let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        let adjustedRect = CGRect(x: boundingRect.minX, y: boundingRect.minY + boundingRect.height / 2 - 1, width: boundingRect.width, height: boundingRect.height)

        return adjustedRect
    }
}
