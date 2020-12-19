//
//  InitialController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 04/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import AVFoundation
import MessageUI
import UIKit

class InitialController: UIViewController
{
    //==================================================//
    
    /* Interface Builder UI Elements */
    
    @IBOutlet weak var imageView: UIImageView!
    
    //==================================================//
    
    /* Class-level Variable Declarations */
    
    //Other Declarations
    let applicationDelegate = UIApplication.shared.delegate! as! AppDelegate
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    //==================================================//
    
    /* Overridden Functions */
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setNeedsStatusBarAppearanceUpdate()
        
        imageView.alpha = 0
        
        UIView.animate(withDuration: 1 /*3*/, delay: 0.3, options: UIView.AnimationOptions(), animations: { () -> Void in
            self.applicationDelegate.currentlyAnimating = true
            
            if !preReleaseApplication
            {
                if let soundURL = Bundle.main.url(forResource: "Chime", withExtension: "mp3")
                {
                    var playableSound: SystemSoundID = 0
                    
                    AudioServicesCreateSystemSoundID(soundURL as CFURL, &playableSound)
                    AudioServicesPlaySystemSound(playableSound)
                }
            }
            
            self.imageView.alpha = 1
        }, completion: { (finishedAnimating: Bool) -> Void in
            if finishedAnimating
            {
                self.applicationDelegate.currentlyAnimating = false
                
                self.performSegue(withIdentifier: "SignInSegue" /*"initialSegue"*/, sender: self)
            }
        })
    }
    
    //==================================================//
    
    /* Interface Builder Actions */
    
    @IBAction func skipButton(_ sender: Any)
    {
        //applicationDelegate.currentlyAnimating = false
        
        //self.performSegue(withIdentifier: "initialSegue", sender: self)
    }
}
