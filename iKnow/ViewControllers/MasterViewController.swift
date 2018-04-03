//
//  MasterViewController.swift
//  iKnow
//
//  Created by Shao-Wei Liang on 2018-01-28.
//  Copyright © 2018 Shao-Wei Liang. All rights reserved.
//

import UIKit

class MasterViewController: UIViewController {
    
    @IBOutlet weak var settingsBtn: UIButton!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupSegmentedControl()
        updateView()
        UserDefaults.standard.removeObject(forKey: "LanguageSortOrder")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupSegmentedControl() {
        // Configure Segmented Control
        segmentedControl.removeAllSegments()
        segmentedControl.insertSegment(withTitle: "Track(Beta)", at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "Real-time", at: 1, animated: false)
        segmentedControl.insertSegment(withTitle: "Photo", at: 2, animated: false)

        // Select First Segment
        segmentedControl.selectedSegmentIndex = 0
        self.view.addSubview(segmentedControl)
        self.view.addSubview(settingsBtn)
    }
    
    private lazy var photoViewController: PhotoViewController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
    
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "PhotoViewController") as! PhotoViewController
        
        return viewController
    }()

    private lazy var ssdCameraViewController: SSDCameraViewController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "SSDCameraViewController") as! SSDCameraViewController
        
        return viewController
    }()
    
    private lazy var cameraViewController: CameraViewController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
        
        return viewController
    }()
    
    private func add(asChildViewController viewController: UIViewController) {
        // Add Child View Controller
        addChildViewController(viewController)
        
        // Add Child View as Subview
        view.addSubview(viewController.view)
        
        // Notify Child View Controller
        viewController.didMove(toParentViewController: self)
    }
    
    private func remove(asChildViewController viewController: UIViewController) {
        // Notify Child View Controller
        viewController.willMove(toParentViewController: nil)

        // Remove Child View From Superview
        viewController.view.removeFromSuperview()

        // Notify Child View Controller
        viewController.removeFromParentViewController()
    }
    
    @IBAction func layerChanged(_ sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex{
        case 0:
            print("Multi Camera View Active")
        case 1:
            print("Single Camera View Active")
        default:
            print("Photo View Active")
        }
        updateView()
    }
    
    private func updateView() {
        if segmentedControl.selectedSegmentIndex == 0 {
            add(asChildViewController: ssdCameraViewController)
            remove(asChildViewController: photoViewController)
            remove(asChildViewController: cameraViewController)
            
            
        } else if segmentedControl.selectedSegmentIndex == 1 {
            add(asChildViewController: cameraViewController)
            remove(asChildViewController: photoViewController)
            remove(asChildViewController: ssdCameraViewController)
            
            
        } else {
            add(asChildViewController: photoViewController)
            remove(asChildViewController: cameraViewController)
            remove(asChildViewController: ssdCameraViewController)
        }
        
        //Bring the buttons to the front layer everytime the mode(layer) changes
        self.view.bringSubview(toFront: segmentedControl)
        self.view.bringSubview(toFront: settingsBtn)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController, let settingsViewController = navController.viewControllers[0] as? SettingsViewController {
            settingsViewController.cameraVC = self.cameraViewController
            settingsViewController.ssdCameraVC = self.ssdCameraViewController
        }
    }
}
