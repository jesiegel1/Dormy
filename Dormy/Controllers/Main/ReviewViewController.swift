//
//  ReviewViewController.swift
//  Dormy
//
//  Created by Josh Siegel on 1/15/16.
//  Copyright © 2016 Dormy. All rights reserved.
//

import UIKit
import Parse
import MBProgressHUD

class ReviewViewController: UIViewController, UITextViewDelegate, UINavigationBarDelegate, FloatRatingViewDelegate {
    
    var job: Job?
    var pageOneVC: ReviewViewControllerP1?
    var pageTwoVC: ReviewViewControllerP2?
    var pageThreeVC: ReviewViewControllerP2?
    
    @IBOutlet weak var cleanerLabel: UILabel!
    @IBOutlet weak var dateCleanedLabel: UILabel!
    @IBOutlet weak var packageLabel: UILabel!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var scrollView: UIScrollView!
    var activeTV: UITextView?
    var rightBarButton: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navBar.delegate = self
        
        self.navBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navBar.shadowImage = UIImage()
        self.navBar.translucent = true
        self.navBar.barTintColor = UIColor(rgba: "#0b376d")
        let submitButton = UIBarButtonItem(title: "Submit", style: .Done, target: self, action: Selector("submitReview"))
        let navItem = UINavigationItem()
        navItem.rightBarButtonItem = submitButton
        self.rightBarButton = navItem.rightBarButtonItem
        navItem.rightBarButtonItem!.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: UIControlState.Normal)
        navItem.rightBarButtonItem!.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor()], forState: UIControlState.Disabled)
        navItem.rightBarButtonItem!.enabled = false
        self.navBar.items = [navItem]
        
        if job == nil {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "hideKeyboard")
        tapGesture.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.registerForKeyboardNotifications()
        
        if let job = job {
            let package = job.package!
            let cleaner = job.cleaner!
            
            self.packageLabel.adjustsFontSizeToFitWidth = true
            self.dateCleanedLabel.adjustsFontSizeToFitWidth = true
            self.cleanerLabel.adjustsFontSizeToFitWidth = true
            
            self.cleanerLabel.text = cleaner["full_name"] as! String
            self.dateCleanedLabel.text = job.completedDate!
            self.packageLabel.text = package["name"] as! String + " - $\(package["price"] as! Int)"
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
    
    func submitReview() {
        let activityIndicator = MBProgressHUD(view: self.view)
        activityIndicator.labelText = "Submitting..."
        self.view.addSubview(activityIndicator)
        
        
        if let pageOne = self.pageOneVC {
            let currentRating = pageOne.starRatingView.rating
            if currentRating >= 1.0 && job != nil {
                
                activityIndicator.show(true)
                
                var review = PFObject(className: "Review")
                review["reviewing_user"] = PFUser.currentUser()
                review["reviewed_user"] = job!.cleaner
                review["review"] = pageOne.reviewTextView.text
                review["job"] = job!
                review["rating"] = currentRating
                review.saveInBackgroundWithBlock() { (success: Bool, error: NSError?) -> Void in
                    if success {
                        self.job!.review = review
                        self.job!.saveInBackgroundWithBlock() { (success: Bool, error: NSError?) -> Void in
                            if success {
                                activityIndicator.hide(true)
                                let alert = UIAlertController(title: "Success!", message: "Your review has been successfully recorded.", preferredStyle: UIAlertControllerStyle.Alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { void in
                                    self.dismissViewControllerAnimated(true, completion: nil)
                                }))
                                self.presentViewController(alert, animated: true, completion: nil)
                            } else {
                                activityIndicator.hide(true)
                                review.deleteEventually()
                                if let error = error {
                                    self.showAlertView(error.localizedDescription, message: error.localizedFailureReason)
                                }
                            }
                        }
                    } else {
                        activityIndicator.hide(true)
                        if let error = error {
                            self.showAlertView(error.localizedDescription, message: error.localizedFailureReason)
                        }
                    }
                }
            }
        }
    }
    
    func registerForKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func hideKeyboard() {
        self.pageOneVC?.reviewTextView.resignFirstResponder()
    }
    
    func keyboardWasShown(notification: NSNotification) {
        //Need to calculate keyboard exact size
        self.scrollView.scrollEnabled = true
        var info : NSDictionary = notification.userInfo!
        var keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size
        var contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize!.height + 15, 0.0)
        
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        if let activeTextViewPresent = activeTV {
            let relativeOrigin = pageOneVC!.view.convertPoint(activeTV!.frame.origin, toView: self.view)
            if (!CGRectContainsPoint(aRect, relativeOrigin)) {
                let relativeFrame = pageOneVC!.view.convertRect(activeTV!.frame, toView: self.view)
                self.scrollView.scrollRectToVisible(relativeFrame, animated: true)
            }
        }
    }
    
    
    func keyboardWillBeHidden(notification: NSNotification) {
        //Once keyboard disappears, restore original positions
        var info : NSDictionary = notification.userInfo!
        var keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size
        var contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, -keyboardSize!.height, 0.0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        self.scrollView.scrollEnabled = false
        
    }
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        activeTV = textView
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        activeTV = nil
    }
    
    
    func showAlertView(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func floatRatingView(ratingView: FloatRatingView, didUpdate rating: Float) {
        if rating != 0.0 {
            self.rightBarButton!.enabled = true
        }
    }

}
