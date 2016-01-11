//
//  RootViewController.swift
//  Dormy
//
//  Created by Josh Siegel on 11/9/15.
//  Copyright © 2015 Dormy. All rights reserved.
//

import UIKit
import Parse

class RootViewController: UIViewController {

    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var buttonView: UIView!
    var pageVC: WelcomePageViewController?
    var mainVC: MainNavController?
    
    @IBAction func signupButton(sender: AnyObject) {
        
    }
    
    @IBAction func loginButton(sender: AnyObject) {
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if PFUser.currentUser() == nil {
            pageVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("WelcomePageViewController") as! WelcomePageViewController
            pageVC?.pageControl = self.pageControl
            self.addChildViewController(pageVC!)
            //???
            self.view.addSubview(pageVC!.view)
            self.pageVC!.didMoveToParentViewController(self)
        } else {
            mainVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("MainNavController") as! MainNavController
            //self.window?.rootViewController = mainVC
            self.addChildViewController(mainVC!)
            //???
            self.view.addSubview(mainVC!.view)
            //root.presentViewController(requestsVC, animated: true, completion: {
            //  nav.dismissViewControllerAnimated(true, completion: nil)
            //})
            //root.pageControl.hidden = true
            self.mainVC!.didMoveToParentViewController(self)
            //root.pageVC!.removeFromParentViewController()
            //root.pageVC = nil
        }
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        pageVC?.view.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height - self.buttonView.frame.height)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        pageVC?.view.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height - self.buttonView.frame.height)
        self.view.bringSubviewToFront(self.pageControl)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "RootNavSegue" {
            let navVC = segue.destinationViewController as! RootNavController
            navVC.parentDelegate = self
        }
        if segue.identifier == "LogInSegue" {
            let loginVC = segue.destinationViewController as! LogInViewController
            loginVC.parentDelegate = self
        }
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }


}