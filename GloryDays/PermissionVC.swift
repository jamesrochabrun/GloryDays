//
//  ViewController.swift
//  GloryDays
//
//  Created by James Rochabrun on 12/9/16.
//  Copyright © 2016 James Rochabrun. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

class PermissionVC: UIViewController {

    @IBOutlet weak var infoLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func askForPermissions(_ sender: Any) {
        self.askForPhotosPermission()
    }
    
    
    func askForPhotosPermission() {
        
        PHPhotoLibrary.requestAuthorization {[unowned self ] (authStatus) in
            
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.askForRecordPermission()
                } else {
                    self.infoLabel.text = "this app needs access to photos to work please change the configuration on your settings"
                }
            }
        }
    }
    
    func askForRecordPermission() {
        
        AVAudioSession.sharedInstance().requestRecordPermission {[unowned self ] (allowed) in
            
            DispatchQueue.main.async {
                
                if allowed {
                    self.askForTranscriptionPermission()
                } else {
                    self.infoLabel.text = "we need your acces to your recording settings"
                }
            }
        }
    }
    
    func askForTranscriptionPermission() {
        
        SFSpeechRecognizer.requestAuthorization {[unowned self ] (authStatus) in
            
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.authorizationGrantedCompleted()
                } else {
                    self.infoLabel.text = "we need acces to your text settings tooo!!"
                }
            }
        }
    }
    
    func authorizationGrantedCompleted() {
        
        dismiss(animated: true)
    }
    



    
    
    
    
    
    
    
    
    
    

}

