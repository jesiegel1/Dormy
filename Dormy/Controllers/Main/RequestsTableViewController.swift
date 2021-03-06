//
//  RequestsTableViewController.swift
//  Dormy
//
//  Created by Josh Siegel on 11/24/15.
//  Copyright © 2015 Dormy. All rights reserved.
//

import UIKit
import Parse
import ParseFacebookUtilsV4

class RequestsTableViewController: UITableViewController {

    var jobs: [Job] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "reload", forControlEvents: .ValueChanged)
        
        let nibName = UINib(nibName: "InProgressCell", bundle:nil)
        self.tableView.registerNib(nibName, forCellReuseIdentifier: "InProgressTableViewCell")
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
        let nibName2 = UINib(nibName: "WaitingCell", bundle:nil)
        self.tableView.registerNib(nibName2, forCellReuseIdentifier: "WaitingTableViewCell")

        let nibName3 = UINib(nibName: "CompletedCell", bundle:nil)
        self.tableView.registerNib(nibName3, forCellReuseIdentifier: "CompletedTableViewCell")
        
        self.tableView.estimatedRowHeight = 156.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadNewestUserData()
        
        refreshControl?.tintColor = UIColor.whiteColor()
        self.tableView.contentOffset = CGPointMake(0, -self.refreshControl!.frame.size.height)
        
        self.refreshControl?.beginRefreshing()
        self.loadJobs()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.jobs.count == 0 {
            self.refreshControl?.endRefreshing()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    func setEmailVerificationAlert(user: PFUser) {
        if user["emailVerified"]?.boolValue != true {
            let imageView = UIImageView(image: UIImage(named: "verification-alert"))
            imageView.contentMode = UIViewContentMode.ScaleAspectFit

            var imageHeight: CGFloat?
            if imageView.image!.size.height < tableView.frame.size.height {
                imageHeight = imageView.image!.size.height
            } else {
                imageHeight = tableView.frame.size.height - 10
            }
            
            imageView.frame = CGRectMake(0, 20, tableView.frame.size.width, imageHeight!)

            tableView.scrollEnabled = false
            let requestsVC = self.parentViewController as! RequestsViewController
            requestsVC.getCleanButton.enabled = false
            tableView.backgroundView = UIView()
            tableView.backgroundView?.addSubview(imageView)
            if PFFacebookUtils.isLinkedWithUser(user) {
                self.showAlertView("Logged in with Facebook?", message: "Tap the gear icon at the top of the page in order to ensure that you have properly filled out your profile information in order to schedule a cleaning.")
            }
        } else {
            let requestsVC = self.parentViewController as! RequestsViewController
            requestsVC.getCleanButton.enabled = true
            tableView.scrollEnabled = true
            tableView.backgroundView = nil
        }
        self.tableView.reloadData()
    }
    
    func loadNewestUserData() {
        let user = PFUser.currentUser()!
        if !user.dataAvailable || user["emailVerified"]?.boolValue != true {
            user.fetchInBackgroundWithBlock() { success, error in
                if let error = error {
                    print(error.localizedDescription)
                    print(error.localizedFailureReason)
                }
                if let success = success {
                    let updatedUser = success as! PFUser
                    self.setEmailVerificationAlert(updatedUser)
                }
            }
        } else {
            self.setEmailVerificationAlert(user)
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let user = PFUser.currentUser() {
            if user["emailVerified"]?.boolValue != true {
                return 0
            } else {
                if self.jobs.count == 0 {
                    let imageView = UIImageView(image: UIImage(named: "empty-alert"))
                    imageView.contentMode = UIViewContentMode.ScaleAspectFit
                    var imageHeight: CGFloat?
                    if imageView.image!.size.height < tableView.frame.size.height {
                        imageHeight = imageView.image!.size.height
                    } else {
                        imageHeight = tableView.frame.size.height - 10
                    }
                    imageView.frame = CGRectMake(0, 20, tableView.frame.size.width, imageHeight!)
                    tableView.scrollEnabled = false
                    let requestsVC = self.parentViewController as! RequestsViewController
                    tableView.backgroundView = UIView()
                    tableView.backgroundView?.addSubview(imageView)
                } else {
                    tableView.scrollEnabled = true
                    tableView.backgroundView = nil
                }
                return self.jobs.count
            }
        } else {
            self.showAlertView("Error", message: "Please ensure you have network connectivity.")
            return 0
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let job = self.jobs[indexPath.row]
        
        switch job.status! {
        case JobStatus.Waiting.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier("WaitingTableViewCell", forIndexPath: indexPath) as! WaitingTableViewCell
            cell.requestedDateLabel.text = job.requestedDate!
            let package = job.package!
            cell.packageLabel.text = package["name"] as! String + " - $\(package["price"] as! Int)"
            return cell
        case JobStatus.InProgress.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier("InProgressTableViewCell", forIndexPath: indexPath) as! InProgressTableViewCell
            let cleaner = job.cleaner!
            let package = job.package!
            
            cell.cleanerLabel.text = cleaner["full_name"] as! String
            cell.requestedDateLabel.text = job.requestedDate!
            cell.packageLabel.text = package["name"] as! String + " - $\(package["price"] as! Int)"
            
            return cell
        case JobStatus.Completed.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier("CompletedTableViewCell", forIndexPath: indexPath) as! CompletedTableViewCell
            let package = job.package!
            let cleaner = job.cleaner!
            
            cell.cleanerLabel.text = cleaner["full_name"] as! String
            cell.dateCleanedLabel.text = job.completedDate!
            cell.packageLabel.text = package["name"] as! String + " - $\(package["price"] as! Int)"
            
            
            return cell
        default:
            let cell = UITableViewCell()
            return cell
        }

    }
    
    func reload() {
        self.loadJobs()
    }
    
    func loadJobs() {
        ParseRequest.loadJobs() { data, error in
            if let error = error {
                self.showAlertView(error.localizedDescription, message: error.localizedFailureReason)
            } else {
                if let jobs = data {
                    self.jobs = []
                    for job in jobs {
                        if job["status"] as! String == JobStatus.Completed.rawValue && job.objectForKey("review") == nil {
                            // Prompt review if job completed and not reviewed yet
                            let reviewVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ReviewViewController") as! ReviewViewController
                            reviewVC.job = job as? Job
                            self.presentViewController(reviewVC, animated: true, completion: nil)
                            self.refreshControl?.endRefreshing()
                            return
                        }
                        let localJob = job as! Job
                        self.jobs.append(localJob)
                    }
                    if self.jobs.count == 0 {
                        self.refreshControl?.endRefreshing()
                    }
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                }
            }
        }
    }
    
    
        
    func showAlertView(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
        

}
