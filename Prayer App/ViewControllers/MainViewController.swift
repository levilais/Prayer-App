//
//  MainViewController.swift
//  Prayer App
//
//  Created by Levi on 10/23/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation
import UIKit
import StoreKit
import CoreData
import Firebase
import FirebaseDatabase

class MainViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    // Main View
    @IBOutlet weak var textField: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    var firstAppear = true
    
    // Undo Send Popup Button
    @IBOutlet weak var undoSendPopupButton: UIButton!
    @IBOutlet weak var undoSendPopupCountdownLabel: UILabel!
    var undoSendString = ""
    var undoTimerIsRunning = false
    var undoTimerSeconds = 10
    var undoTimer = Timer()
    
    // Header
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var titleImage: UIImageView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var touchToPrayButton: UIButton!
    
    // Toolbar
    @IBOutlet weak var toolbarView: UIView!
    @IBOutlet weak var toolbarBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var timerIcon: UIButton!
    @IBOutlet weak var undoButtonBottomLayoutConstraint: NSLayoutConstraint!
    var toolbarBottomConstraintInitialValue: CGFloat?
    var undoButtonBottomLayoutConstraintInitialValue: CGFloat?
    
    // Timer & Popup
    @IBOutlet weak var timerPreferencesSelectionView: UIView!
    @IBOutlet var timerButtons: [UIButton]!
    @IBOutlet weak var timerHeaderButton: UIButton!
    @IBOutlet weak var timerPreferencesBackgroundButton: UIButton!
    var timerChanged = false
    var timerPopupShowing = false
    
    // Save To Journal Popup
    @IBOutlet weak var categoryCreationTextField: UITextField!
    @IBOutlet weak var saveToJournalView: UIView!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var categoryLabelScrollView: UIScrollView!
    @IBOutlet weak var saveToJournalSubview: UIView!
    @IBOutlet weak var saveToJournalBackgroundButton: UIButton!
    var categoryTextfieldCharacterLimit = 24
    var categoryTitles = [String]()
    var categoryButtons: [UIButton] = [UIButton]()
    var categoryInputIsTextfield = true
    var chosenCategory = String()
    
    // Post To Prayer Circle Popup
    @IBOutlet weak var postToPrayerCircleView: UIView!
    @IBOutlet weak var postToPrayerCirclePopupBackgroundButton: UIButton!
    @IBOutlet var postToPrayerCircleMembers: [UIImageView]!
    @IBOutlet weak var postToPrayerCircleSubview: UIView!
    
    // Data Variables
    var prayer: Prayer?
    var managedObjectContext: NSManagedObjectContext?
    var ref: DatabaseReference!
    
    // Gestures
    var tapGesture = UITapGestureRecognizer()
    var longGesture = UILongPressGestureRecognizer()
    var swipeRight = UISwipeGestureRecognizer()
    var swipeLeft = UISwipeGestureRecognizer()
    var swipeDown = UISwipeGestureRecognizer()
    
    // Segue Variables
    var signupShowing = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()

        textField.delegate = self
        touchToPrayButton.setTitleColor(UIColor.lightGray, for: .normal)
        
        self.toolbarBottomConstraintInitialValue = toolbarBottomLayoutConstraint.constant
        self.undoButtonBottomLayoutConstraintInitialValue = undoButtonBottomLayoutConstraint.constant
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(normalTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        timerIcon.addGestureRecognizer(tapGesture)
        
        longGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap(_:)))
        timerIcon.addGestureRecognizer(longGesture)
        
        swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(swipeRight)
        
        swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        self.view.addGestureRecognizer(swipeLeft)
        
        swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        self.view.addGestureRecognizer(swipeDown)
        
        DispatchQueue.main.async {
            if Loads.firstLoadPresented == false {
                if Auth.auth().currentUser == nil {
                    self.performSegue(withIdentifier: "mainToFirstLoadSegue", sender: self)
                }
            }
        }
        
        Loads.loadCount += 1
        UserDefaultsHelper().saveLoad()
        
        UserDefaultsHelper().getPreferredTimerDuration()
        
        TimerStruct().resetSeconds()
        TimerStruct().updateTimerPreferencesDisplay(buttons: timerButtons)
        Utilities().setupTextFieldLook(textField: categoryCreationTextField)
        
        self.countLabel.text = String(categoryTextfieldCharacterLimit)
        self.categoryCreationTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        categoryTitles = []
        getSectionHeaders()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification2(_:)), name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "clearTextViewOnLogOut"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification3(_:)), name: NSNotification.Name(rawValue: "clearTextViewOnLogOut"), object: nil)
        
        touchToPrayButton.alpha = 0
        
        titleImage.isHidden = true
        if !firstAppear {
            titleImage.isHidden = false
        }
        
        UIView.animate(withDuration: 0.0, delay: 0.5, options: [], animations: {
            self.textField.becomeFirstResponder()
        }, completion: nil)
        
        TimerStruct().showTimerIfRunning(timerHeaderButton: timerHeaderButton, titleImage: titleImage)
        if !TimerStruct.timerIsRunning {
            timerIcon.setBackgroundImage(UIImage(named: "timerIcon.pdf"), for: .normal)
        } else {
            timerIcon.setBackgroundImage(UIImage(named: "timerIconSelected.pdf"), for: .normal)
        }
        TimerStruct().updateTimerButtonLabel(timerButton: timerHeaderButton)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if firstAppear {
            Animations().animateLoad(doneButton: doneButton, titleImage: titleImage, toolbarView: toolbarView, view: self.view, textView: textField)
        } else {
            titleImage.alpha = 1
            titleImage.isHidden = false
            doneButton.alpha = 1
            doneButton.isHidden = false
        }
        firstAppear = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mainViewToSignupViewSegue" {
            let destinationVC = segue.destination as? LoginViewController
            destinationVC?.signupShowing = signupShowing
        }
    }
    
    @IBAction func doneButtonDidPress(_ sender: Any) {
        if textField.isFirstResponder {
            textField.resignFirstResponder()
        } else {
            textField.becomeFirstResponder()
        }
    }
    
    @IBAction func touchToPrayButtonDidPress(_ sender: Any) {
        if textField.isFirstResponder {
            textField.resignFirstResponder()
        } else {
            textField.becomeFirstResponder()
        }
    }
    
    @IBAction func timerHeaderButtonPressed(_ sender: Any) {
        TimerStruct().stopTimer(timerButton: timerHeaderButton, titleImageView: titleImage)
        timerIcon.setBackgroundImage(UIImage(named: "timerIcon.pdf"), for: .normal)
    }
    @IBAction func doneDidPress(_ sender: Any) {
        if touchToPrayButton.isHidden == true {
            touchToPrayButton.isHidden = false
        }
        textField.resignFirstResponder()
    }
    
    @IBAction func timerButtonTapped(_ sender: Any) {
        if let tag = (sender as AnyObject).tag {
            TimerStruct().toggleTimerPreferences(buttons: timerButtons, sender: tag)
            timerChanged = true
        }
    }
    
    @IBAction func undoSendDidPress(_ sender: Any) {
        textField.alpha = 0
        textField.text = undoSendString
        if touchToPrayButton.alpha == 1 {
            textField.becomeFirstResponder()
        }
        stopUndoTimer()
    }
    
    @IBAction func ideaDidPress(_ sender: Any) {
        if !textField.isFirstResponder {
            textField.becomeFirstResponder()
        }
        stopUndoTimer()
        let i = Int(arc4random_uniform(UInt32(TopicIdeas().topicArray.count)))
        if let currentText = textField.text {
            if currentText != "" {
                textField.text = "\(currentText)\n\n\(TopicIdeas().topicArray[i])"
            } else {
                textField.text = TopicIdeas().topicArray[i]
            }
        }
    }
    @IBAction func sendButtonDidPress(_ sender: Any) {
        sendText()
    }
    
    @IBAction func shareButtonDidPress(_ sender: Any) {
        shareText()
    }
    
    @IBAction func addButtonDidPress(_ sender: Any) {
        self.swipeLeft.isEnabled = false
        self.swipeRight.isEnabled = false
        launchAddButtonPressed()
    }
    
    func launchAddButtonPressed() {
        if textField.text != "" {
            Animations().animateCustomAlertPopup(view: saveToJournalView, backgroundButton: saveToJournalBackgroundButton, subView: saveToJournalSubview, viewController: self, textField: categoryCreationTextField, textView: textField)
            createCategoryButtons()
        } else {
            let alert = UIAlertController(title: "Nothing To Save", message: "Please enter text and try again.", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
            textField.becomeFirstResponder()
        }
    }
    
    @IBAction func shareToPrayerCircleBackgroundButtonDidPress(_ sender: Any) {
        dismissShareToPrayerCirclePopup()
    }
    
    @IBAction func shareToPrayerCircleButtonDidPress(_ sender: Any) {
        // post the share here
        dismissShareToPrayerCirclePopup()
    }
    
    @IBAction func cancelShareToPrayerCircleButtonDidPress(_ sender: Any) {
        dismissShareToPrayerCirclePopup()
    }
    
    func dismissShareToPrayerCirclePopup() {
        self.postToPrayerCircleView.alpha = 0
        self.swipeLeft.isEnabled = true
        self.swipeRight.isEnabled = true
        textField.becomeFirstResponder()
    }
    
    func getSectionHeaders() {
        if let userID = Auth.auth().currentUser?.uid {
            Database.database().reference().child("users").child(userID).child("prayers").observe(.childAdded) { (snapshot) in
                if let userDictionary = snapshot.value as? NSDictionary {
                    let snapshotPrayer = FirebaseHelper().prayerFromDictionary(userDictionary: userDictionary)
                    if let category = snapshotPrayer.prayerCategory {
                        if !self.categoryTitles.contains(category) {
                            self.categoryTitles.append(category)
                        }
                    }
                }
            }
        }
    }
    
    func createCategoryButtons() {
        for button in categoryButtons {
            button.removeFromSuperview()
        }
        
        categoryButtons = [UIButton]()
        var xOffset: CGFloat = 0
        var buttonWidth: CGFloat = 0
        
        if categoryTitles.count > 0 {
        
        categoryLabelScrollView.translatesAutoresizingMaskIntoConstraints = false
        var i = 0
        
        for prayerCategory in categoryTitles {
            let button = UIButton()
            button.frame = CGRect(x: xOffset, y: 0, width: buttonWidth, height: categoryLabelScrollView.frame.height)
            button.tag = i
            button.setTitle(prayerCategory, for: .normal)
            button.backgroundColor = UIColor.StyleFile.LightGrayColor
            button.titleLabel?.font = UIFont.StyleFile.ButtonFont
            button.setTitleColor(UIColor.StyleFile.DarkGrayColor, for: .normal)
            button.sizeToFit()
            buttonWidth = button.frame.size.width + 10
            button.addTarget(self, action: #selector(categoryButtonTapped(sender:)), for: .touchUpInside)
            button.frame = CGRect(x: button.frame.minX, y: button.frame.minY, width: buttonWidth, height: button.frame.size.height)
            categoryLabelScrollView.addSubview(button)
            categoryButtons.append(button)
            
            xOffset = xOffset + buttonWidth + 10
            i += 1
        }
        categoryLabelScrollView.contentSize = CGSize(width: xOffset - 10, height: categoryLabelScrollView.frame.height)
        } else {
            let button = UIButton()
            button.frame = CGRect(x: xOffset, y: 0, width: buttonWidth, height: categoryLabelScrollView.frame.height)
            button.tag = 0
            button.setTitle("General Prayers", for: .normal)
            button.backgroundColor = UIColor.StyleFile.LightGrayColor
            button.titleLabel?.font = UIFont.StyleFile.ButtonFont
            button.setTitleColor(UIColor.StyleFile.DarkGrayColor, for: .normal)
            button.sizeToFit()
            buttonWidth = button.frame.size.width + 10
            button.addTarget(self, action: #selector(categoryButtonTapped(sender:)), for: .touchUpInside)
            button.frame = CGRect(x: button.frame.minX, y: button.frame.minY, width: buttonWidth, height: button.frame.size.height)
            categoryLabelScrollView.addSubview(button)
            categoryButtons.append(button)
            
            xOffset = xOffset + buttonWidth + 10
            categoryLabelScrollView.contentSize = CGSize(width: xOffset - 10, height: categoryLabelScrollView.frame.height)
        }
        
    }
    
    @objc func categoryButtonTapped(sender: UIButton) {
        categoryCreationTextField.text = ""
        categoryCreationTextField.resignFirstResponder()
        resetCountLabel()
        
        for button in categoryButtons {
            if button.tag == sender.tag {
                sender.backgroundColor = UIColor(red:0.75, green:0.75, blue:0.75, alpha:1.0)
                if let titleLabelCheck = button.titleLabel?.text {
                    chosenCategory = titleLabelCheck
                }
            } else {
                button.backgroundColor = UIColor(red:0.87, green:0.87, blue:0.87, alpha:1.0)
            }
        }
        categoryInputIsTextfield = false
    }
    
    @objc func normalTap(_ sender: UIGestureRecognizer){
        if TimerStruct.timerIsRunning == false {
            TimerStruct().startTimer(timerButton: timerHeaderButton, titleImageView: titleImage)
            timerIcon.setBackgroundImage(UIImage(named: "timerIconSelected.pdf"), for: .normal)
        } else {
            TimerStruct().stopTimer(timerButton: timerHeaderButton, titleImageView: titleImage)
            timerIcon.setBackgroundImage(UIImage(named: "timerIcon.pdf"), for: .normal)
        }
    }
    
    @objc func longTap(_ sender: UIGestureRecognizer){
        if sender.state == .ended {
        }
        else if sender.state == .began {
            self.view.bringSubview(toFront: timerPreferencesSelectionView)
            timerPopupShowing = true
            TimerStruct().updateTimerPreferencesDisplay(buttons: timerButtons)
            self.swipeLeft.isEnabled = false
            self.swipeRight.isEnabled = false
            textField.resignFirstResponder()
            UIView.animate(withDuration: 0.3, animations: {
                self.timerPreferencesSelectionView.alpha = 1
            })
        }
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                sendText()
            case UISwipeGestureRecognizerDirection.down:
                textField.resignFirstResponder()
            case UISwipeGestureRecognizerDirection.left:
                launchAddButtonPressed()
            default:
                break
            }
        }
    }
    
    @IBAction func saveToJournalBackgroundShadowDidPress(_ sender: Any) {
        resetCountLabel()
        dismissSaveToJournalPopup()
    }
    
    @IBAction func cancelSaveToJournalDidPress(_ sender: Any) {
        self.swipeLeft.isEnabled = true
        self.swipeRight.isEnabled = true
        resetCountLabel()
        dismissSaveToJournalPopup()
    }
    
    @IBAction func confirmSaveToJournalDidPress(_ sender: Any) {
        savePrayer(prayerText: textField, prayerHeader: categoryCreationTextField)
        UIView.animate(withDuration: 0.33) {
            self.dismissSaveToJournalPopup()
        }
        Animations().showPopup(labelText: "Saved!", presentingVC: self)
        dismissSaveToJournalPopup()
        resetCountLabel()
        categoryCreationTextField.text = ""
    }
    
    @IBAction func timerPreferenceBackgroundShadowDidPress(_ sender: Any) {
        dismissTimerPopup()
        if timerChanged == true {
            TimerStruct().stopTimer(timerButton: timerHeaderButton, titleImageView: titleImage)
            TimerStruct().startTimer(timerButton: timerHeaderButton, titleImageView: titleImage)
            timerIcon.setBackgroundImage(UIImage(named: "timerIconSelected.pdf"), for: .normal)
            timerChanged = false
        }
    }
    
    @objc func dismissSaveToJournalPopup() {
        self.saveToJournalView.alpha = 0
        self.categoryCreationTextField.text = ""
        self.swipeLeft.isEnabled = true
        self.swipeRight.isEnabled = true
        self.categoryLabelScrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        textField.becomeFirstResponder()
    }
    
    @objc func dismissTimerPopup() {
        self.timerPreferencesSelectionView.alpha = 0
        self.swipeLeft.isEnabled = true
        self.swipeRight.isEnabled = true
        timerPopupShowing = false
        textField.becomeFirstResponder()
    }
    
    @objc func keyboardWillShow(notification:NSNotification){
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset: UIEdgeInsets = self.scrollView.contentInset
        var textViewInset: UIEdgeInsets = self.textField.contentInset
        
        contentInset.bottom = keyboardFrame.size.height + 5 + toolbarView.frame.height
        textViewInset.bottom = keyboardFrame.size.height + 5 + toolbarView.frame.height
        
        self.toolbarBottomLayoutConstraint.constant = keyboardFrame.size.height - view.safeAreaInsets.bottom
        self.view.layoutIfNeeded()
        
        if let constraint2 = undoButtonBottomLayoutConstraintInitialValue {
            self.undoButtonBottomLayoutConstraint.constant = constraint2
            self.view.layoutIfNeeded()
        }
      
        textField.contentInset = textViewInset
        scrollView.contentInset = contentInset
        
        self.touchToPrayButton.alpha = 0
        UIView.animate(withDuration: 0.33) {
            self.toolbarView.alpha = 1
            self.doneButton.alpha = 1
        }
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        if let constraint = toolbarBottomConstraintInitialValue {
            self.toolbarBottomLayoutConstraint.constant = constraint
            self.view.layoutIfNeeded()
        }
        
        self.undoButtonBottomLayoutConstraint.constant = undoButtonBottomLayoutConstraint.constant - self.toolbarView.frame.height
        self.view.layoutIfNeeded()
        
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
        
        if textField.text == "" && timerPopupShowing == false {
            self.touchToPrayButton.alpha = 1
        }
        
        UIView.animate(withDuration: 0.33) {
            self.toolbarView.alpha = 0
            self.doneButton.alpha = 0
        }
    }
    
    func savePrayer(prayerText: UITextView, prayerHeader: UITextField) {
        setCategoryIfFromText(prayerHeader: prayerHeader)
        let prayerID = NSUUID().uuidString
        FirebaseHelper().saveNewPrayerToFirebase(prayerText: prayerText.text, prayerCategory: chosenCategory, prayerID: prayerID, ref: ref)
        getSectionHeaders()
    }
    
    func setCategoryIfFromText(prayerHeader: UITextField) {
        if categoryInputIsTextfield == true {
            let capitalizedText = prayerHeader.text?.capitalized
            var trimmedText = capitalizedText?.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedText == "" {
                trimmedText = "General Prayers"
            }
            chosenCategory = trimmedText!
        }
    }
    
    func shareText() {
        if CurrentUser.firebaseCircleMembers.count > 0 {
            var actualMembers = [CircleUser]()
            for circleUser in CurrentUser.firebaseCircleMembers {
                if let relationship = circleUser.relationshipToCurrentUser {
                    if relationship == CircleUser.userRelationshipToCurrentUser.myCircleMember.rawValue {
                        actualMembers.append(circleUser)
                    }
                }
            }
            
            if actualMembers.count > 0 {
                print("firebase circle member count: \(CurrentUser.firebaseCircleMembers.count)")
                if textField.text != "" {
                    for imageView in postToPrayerCircleMembers {
                        imageView.layer.cornerRadius = imageView.frame.height / 2
                        imageView.clipsToBounds = true
                    }
                    
                    var i = 0
                    for circleUser in actualMembers {
                        if let image = circleUser.profileImageAsImage {
                            postToPrayerCircleMembers[i].image = image
                        }
                        i += 1
                    }
                    
                    Animations().animateShareToCirclePopup(view: postToPrayerCircleView, backgroundButton: postToPrayerCirclePopupBackgroundButton, subView: postToPrayerCircleSubview, viewController: self, textView: textField)
                    self.swipeLeft.isEnabled = false
                    self.swipeRight.isEnabled = false
                    //            displayShareSheet(shareContent: textField.text!)
                } else {
                    let alert = UIAlertController(title: "Nothing To Share", message: "Please enter text and try again.", preferredStyle: .alert)
                    let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(action)
                    self.present(alert, animated: true, completion: nil)
                    alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
                }
            } else {
                let alert = UIAlertController(title: "No Circle Members Found", message: "You will need to add Circle Members in order to share Prayers to your Circle.", preferredStyle: .alert)
                let action = UIAlertAction(title: "Add Members", style: .default, handler: { (action) in
                    self.performSegue(withIdentifier: "mainViewToAddContactsViewSegue", sender: self)
                })
                alert.addAction(action)
                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
            }
        } else if Auth.auth().currentUser != nil {
            let alert = UIAlertController(title: "No Circle Members Found", message: "You will need to add Circle Members in order to share Prayers to your Circle.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Add Members", style: .default, handler: { (action) in
                self.performSegue(withIdentifier: "mainViewToAddContactsViewSegue", sender: self)
            })
            alert.addAction(action)
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
            alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
        } else {
            let alert = UIAlertController(title: "No Account Found", message: "You will need to create an account and add Circle Members in order to share Prayers to your Circle.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Create Account", style: .default, handler: { (action) in
                self.performSegue(withIdentifier: "mainViewToSignupViewSegue", sender: self)
            })
            alert.addAction(action)
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
            alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
        }
    }
    
    func displayShareSheet(shareContent: String) {
        let activityViewController = UIActivityViewController(activityItems: [shareContent as NSString], applicationActivities: nil)
        activityViewController.completionWithItemsHandler = {(activityType: UIActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            if !completed {
                return
            }
            Animations().showPopup(labelText: "Shared!", presentingVC: self)
            self.textField.becomeFirstResponder()
        }
        present(activityViewController, animated: true, completion: nil)
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
                label.textColor = UIColor.StyleFile.DarkGrayColor
                label.alpha = 1
                scrollView.addSubview(label)
                labels.append(label)
                i += 1
            }
            undoSendString = textField.text
            textField.text = ""
            textField.isHidden = true
            touchToPrayButton.isHidden = true
            let arrayOfLabelArrays = splitLabelsIntoQuadrants(labels: labels, vc: self)
            Animations().AnimateLabels(labelArrays: arrayOfLabelArrays, viewController: self, textView: textField, touchToPrayButton: touchToPrayButton)
            showUndoButton(undoButton: undoSendPopupButton, undoCountdownLabel: undoSendPopupCountdownLabel)
        } else {
            let alert = UIAlertController(title: "Nothing To Send", message: "Please enter text and try again.", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            alert.view.tintColor = UIColor.StyleFile.DarkGrayColor

        }
    }
    
    func showUndoButton(undoButton: UIButton, undoCountdownLabel: UILabel) {
        UIView.animate(withDuration: 1.0, delay: 3.5, options: [.curveEaseIn], animations: {
            undoButton.alpha = 1
            undoCountdownLabel.alpha = 1
        }) { (completed) in
            self.startUndoTimer()
        }
    }
    
    func runUndoTimer() {
        undoTimer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(MainViewController.updateUndoTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateUndoTimer() {
        if undoTimerSeconds < 1 {
            undoTimer.invalidate()
            undoTimerIsRunning = false
            stopUndoTimer()
        } else {
            undoTimerSeconds -= 1
            undoSendPopupCountdownLabel.text = String(undoTimerSeconds)
        }
    }
    
    func startUndoTimer() {
        undoSendPopupCountdownLabel.text = String(undoTimerSeconds)
        undoTimerIsRunning = true
        runUndoTimer()
    }
    
    func stopUndoTimer() {
        UIView.animate(withDuration: 1.0, animations: {
            self.undoSendPopupButton.alpha = 0
            self.undoSendPopupCountdownLabel.alpha = 0
            self.textField.alpha = 1
        }) { (completed) in
            self.undoTimerSeconds = 10
            self.undoSendPopupCountdownLabel.text = String(self.undoTimerSeconds)
        }
        undoTimerIsRunning = false
        undoTimer.invalidate()
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
    
    func resetCountLabel() {
        countLabel.text = String(categoryTextfieldCharacterLimit)
        countLabel.textColor = UIColor.gray
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if undoTimerIsRunning {
             stopUndoTimer()
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let characterLimit = categoryTextfieldCharacterLimit
        let newLength = (textField.text?.count)! + string.count - range.length
        let charactersLeft = characterLimit - newLength
        
        if newLength <= characterLimit {
            self.countLabel.text = "\(charactersLeft)"
            for button in categoryButtons {
                button.backgroundColor = UIColor.StyleFile.LightGrayColor
                categoryInputIsTextfield = true
            }
            if charactersLeft <= 5 {
                self.countLabel.textColor = UIColor.StyleFile.WineColor

            } else {
                self.countLabel.textColor = UIColor.gray
            }
            return true
        } else {
            return false
        }
    }
    
    @objc func handleNotification(_ notification: NSNotification) {
        TimerStruct().updateTimerButtonLabel(timerButton: timerHeaderButton)
    }
    
    @objc func handleNotification2(_ notification: NSNotification) {
        Animations().endTimerMainViewAnimation(timerIcon: timerIcon, timerButton: timerHeaderButton, titleImage: titleImage)
    }
    
    @objc func handleNotification3(_ notification: NSNotification) {
        textField.text = ""
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        textField.resignFirstResponder()
        if timerPopupShowing == true {
            dismissTimerPopup()
        }
        dismissShareToPrayerCirclePopup()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
}
