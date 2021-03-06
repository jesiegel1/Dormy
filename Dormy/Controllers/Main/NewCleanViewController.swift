//
//  NewCleanViewController.swift
//  Dormy
//
//  Created by Josh Siegel on 11/25/15.
//  Copyright © 2015 Dormy. All rights reserved.
//

import UIKit
import Parse
import MBProgressHUD

class NewCleanViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UINavigationBarDelegate {

    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var specialInstructions: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var packageTF: UITextField!
    @IBOutlet weak var dateField: UITextField!
    @IBOutlet weak var timeField: UITextField!
    var downPicker: DownPicker?
    var packages: [PFObject]?
    var packageDict = [String: PFObject]()
    var activeField: UITextField?
    var activeTV: UITextView?
    
    var customer: Customer?
    var customerLoaded: Bool = false
    
    @IBAction func requestJob(sender: AnyObject) {
        let activityIndicator = MBProgressHUD(view: self.view)
        activityIndicator.labelText = "Loading"
        self.view.addSubview(activityIndicator)
        activityIndicator.show(true)
        
        if !validateUserInfo() {
            activityIndicator.hide(true)
            self.showAlertView("Error", message: "Please fill out all of the required fields in your user profile to place a cleaning request.")
            return
        }
        
        let textFields: [UITextField] = [self.dateField, self.timeField, self.packageTF]
    
        let currentUser = PFUser.currentUser()
        
        let job = Job()
        job.dormer = currentUser
        job.requestedDate = dateField.text
        job.requestedTime = timeField.text
        job.status = JobStatus.Waiting.rawValue
        job.package = self.packageDict[packageTF.text!]
        job.instructions = specialInstructions.text
        job.college = currentUser!["college"] as? PFObject
        
        let isValidated = job.validate()
        if isValidated && self.customerLoaded {
            self.customer!.chargeCustomer(job) { success in
                if success {
                    job.saveInBackgroundWithBlock() { success, error in
                        if let error = error {
                            if let errorString = error.userInfo["error"] as? String {
                                activityIndicator.hide(true)
                                self.showAlertView("Error", message: errorString)
                            }
                        } else {
                            let relation = currentUser!.relationForKey("jobs")
                            relation.addObject(job)
                            currentUser!.saveInBackground()
                            activityIndicator.hide(true)
                            let alert = UIAlertController(title: "Success!", message: "Your request has been successfully recorded.", preferredStyle: UIAlertControllerStyle.Alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { void in
                                self.dismissViewControllerAnimated(true, completion: nil)
                            }))
                            self.presentViewController(alert, animated: true, completion: nil) 
                        }
                    }
                } else {
                    activityIndicator.hide(true)
                    print("Couldn't charge the customer")
                }
            }
        } else {
            activityIndicator.hide(true)
            if isValidated == true && self.customerLoaded != true {
                self.showAlertView("Error", message: "Please verify within your profile that your payment information has been submitted successfully.")
            } else if isValidated != true && self.customerLoaded == true {
                self.showAlertView("Error", message: "Please make sure all required fields are filled out.")
            } else {
                self.showAlertView("Error", message: "Please make sure all required fields are filled out and your payment information has been submitted successfully.")
            }
            for textField in textFields {
                if textField.text!.isEmpty {
                    textField.layer.borderWidth = 2.0
                    textField.layer.borderColor = UIColor.redColor().CGColor
                }
            }
        }
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navBar.delegate = self
        
        self.navBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navBar.shadowImage = UIImage()
        self.navBar.translucent = true
        self.navBar.barTintColor = UIColor(rgba: "#0b376d")
        let doneButton = UIBarButtonItem(title: "Done", style: .Done, target: self, action: Selector("closeNewCleanView"))
        let navItem = UINavigationItem()
        navItem.rightBarButtonItem = doneButton
        navItem.rightBarButtonItem!.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: .Normal)
        self.navBar.items = [navItem]
        
        self.specialInstructions.inputAccessoryView = self.getKeyboardAccessoryWithTitle("Done", selector: Selector("hideKeyboard"))
        
        // Do any additional setup after loading the view.
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = UIDatePickerMode.Date
        datePicker.addTarget(self, action: Selector("dateTextField:"), forControlEvents: UIControlEvents.ValueChanged)
        self.dateField.inputAccessoryView = self.getKeyboardAccessoryWithTitle("Done", selector: Selector("hideKeyboard"))
        self.dateField.inputView = datePicker
        
        let timePicker = UIDatePicker()
        timePicker.datePickerMode = UIDatePickerMode.Time
        timePicker.minuteInterval = 15
        timePicker.addTarget(self, action: Selector("dateTextField:"), forControlEvents: UIControlEvents.ValueChanged)
        self.timeField.inputAccessoryView = self.getKeyboardAccessoryWithTitle("Done", selector: Selector("hideKeyboard"))
        self.timeField.inputView = timePicker
        
        self.dateField.delegate = self
        self.timeField.delegate = self
        self.packageTF.delegate = self
        //self.packageTF.
        self.specialInstructions.delegate = self
        
        Customer.getStripeCustomerInfo() { customer, error in
            if let customer = customer {
                self.customer = customer
                self.customerLoaded = true
            }
            if let error = error {
                print(error.localizedDescription)
                print(error.localizedFailureReason)
            }
        }
        
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
    
    func closeNewCleanView() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    
    func getKeyboardAccessoryWithTitle(title: String, selector: Selector) -> UIToolbar {
        let toolbar = UIToolbar(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, 50))
        toolbar.barStyle = UIBarStyle.Default
        let item1 = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let item2 = UIBarButtonItem(title: title, style: UIBarButtonItemStyle.Done, target: self, action: selector)
        toolbar.items = [item1, item2]
        toolbar.sizeToFit()
        return toolbar
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.bringSubviewToFront(self.navBar)
        self.registerForKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.getPackageOptions()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dateTextField(sender: UIDatePicker) {
        if sender == self.dateField.inputView {
            let picker = self.dateField.inputView as! UIDatePicker
            let date = NSDateFormatter.localizedStringFromDate(picker.date, dateStyle: NSDateFormatterStyle.MediumStyle, timeStyle: NSDateFormatterStyle.NoStyle)
            self.dateField.text = date
        } else {
            let picker = self.timeField.inputView as! UIDatePicker
            let time = NSDateFormatter.localizedStringFromDate(picker.date, dateStyle: NSDateFormatterStyle.NoStyle, timeStyle: NSDateFormatterStyle.ShortStyle)
            self.timeField.text = time
        }
    }

    func registerForKeyboardNotifications() {
        //Adding notifies on keyboard appearing
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    
    func deregisterFromKeyboardNotifications() {
        //Removing notifies on keyboard appearing
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWasShown(notification: NSNotification) {
        //Need to calculate keyboard exact size due to Apple suggestions
        self.scrollView.scrollEnabled = true
        var info : NSDictionary = notification.userInfo!
        var keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size
        var contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize!.height + 15, 0.0)
        
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        if let activeFieldPresent = activeField {
            var toolbar = CGFloat(0.0)
            if activeFieldPresent == self.packageTF {
                if let downPicker = self.packageTF.inputAccessoryView {
                    toolbar = downPicker.frame.size.height
                    aRect.size.height -= toolbar
                } else {
                    self.showAlertView("Error", message: "Please check your network connection to ensure packages are properly loaded.")
                }
            }
            if (!CGRectContainsPoint(aRect, activeField!.frame.origin)) {
                self.scrollView.scrollRectToVisible(activeField!.frame, animated: true)
            }
        }
        if let activeTextViewPresent = activeTV {
            if (!CGRectContainsPoint(aRect, activeTV!.frame.origin)) {
                self.scrollView.scrollRectToVisible(activeTV!.frame, animated: true)
            }
        }
        self.scrollView.scrollEnabled = true
        
    }
    
    
    func keyboardWillBeHidden(notification: NSNotification) {
        //Once keyboard disappears, restore original positions
        var info : NSDictionary = notification.userInfo!
        var keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size
        var contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, -keyboardSize!.height, 0.0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        //self.view.endEditing(true)
        self.scrollView.scrollEnabled = true
        
    }

    func downPickerEditingBegan(sender: DownPicker) {
        let textField = self.packageTF
        activeField = textField
    }
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        activeTV = textView
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        activeTV = nil
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        activeField = textField
        if textField == self.dateField {
            if textField.text!.isEmpty {
                let picker = self.dateField.inputView as! UIDatePicker
                let currentDate = NSDateFormatter.localizedStringFromDate(picker.date, dateStyle: NSDateFormatterStyle.MediumStyle, timeStyle: NSDateFormatterStyle.NoStyle)
                textField.text = currentDate
            }
        }
        if textField == self.timeField {
            if textField.text!.isEmpty {
                let picker = self.timeField.inputView as! UIDatePicker
                let currentTime = NSDateFormatter.localizedStringFromDate(picker.date, dateStyle: NSDateFormatterStyle.NoStyle, timeStyle: NSDateFormatterStyle.ShortStyle)
                textField.text = currentTime
            }
        }
    }
    
    // Prevent user edit of picker enabled fields.
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        return false
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        activeField = nil
    }

    func showAlertView(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: { void in
            //self.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    func validateUserInfo() -> Bool {
        let user = PFUser.currentUser()!
        let keys = user.allKeys
        for key in keys {
            if user[key] == nil {
                return false
            }
        }
        return true
    }
    
    func getPackageOptions() {
        ParseRequest.getPackageOptions() { data, error in
            if let error = error {
                self.showAlertView(error.localizedDescription, message: error.localizedFailureReason)
            } else {
                if let packages = data {
                    self.packages = packages
                    var packageNames: [String] = []
                    for package in self.packages! {
                        let display = package["name"] as! String + " - $\(package["price"] as! Int)"
                        self.packageDict[display] = package
                        packageNames.append(display)
                    }
                    self.downPicker = DownPicker(textField: self.packageTF, withData: packageNames)
                    self.downPicker!.setPlaceholder("")
                    self.downPicker!.addTarget(self, action: Selector("downPickerEditingBegan:"), forControlEvents: UIControlEvents.EditingDidBegin)
                }
            }
        }
    }

}
