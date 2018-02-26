//
//  ViewController.swift
//  iKnow
//
//  Created by Shao-Wei Liang on 2018-01-17.
//  Copyright © 2018 Shao-Wei Liang. All rights reserved.
//
import UIKit
import Vision
import ARKit
import SpriteKit

class CameraViewController: UIViewController, ARSKViewDelegate, ARSessionDelegate {
    
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var cameraView: ARSKView!
    private var currentBuffer: CVPixelBuffer?
    private let visionQueue = DispatchQueue(label: "Queue") // A Serial Queue
    private var suspended = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set up the SKScene to render the view
        let scene = SKScene()
        scene.scaleMode = .aspectFill
        
        //Set the View's delegate
        cameraView.delegate = self
        
        //Set the scene to the view
        cameraView.presentScene(scene)
        cameraView.session.delegate = self
        loopProcess()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Check if ARWorldTrackingConfiguration is supported in the device used
        if ARWorldTrackingConfiguration.isSupported{
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            cameraView.session.run(configuration)
        }else{
            let configuration = AROrientationTrackingConfiguration()
            cameraView.session.run(configuration)
        }
        
        if suspended == true{
            visionQueue.resume()
            suspended = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraView.session.pause()
        visionQueue.suspend()
        suspended = true
    }
    
    func loopProcess() {
        visionQueue.async {
            self.objectRecognition()
            self.loopProcess()
        }
    }
    
    func objectRecognition(){
        guard let pixelBuffer: CVPixelBuffer = cameraView.session.currentFrame?.capturedImage else {return}
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {return}
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            guard let results = finishedReq.results as? [VNClassificationObservation] else {return}
            guard let firstObservation = results.first else {return}
//            let confidence = firstObservation.confidence
            // Hash Map Method for Language Translation:
            var madarinCode = [
                "laptop" : "笔记本电脑"
            ]
            //change this string to the one that u obtain from the model
            let message = firstObservation.identifier.split(separator: ",")[0]
            var encodedMessage = ""
            //Split message String into words seperated by space(" ")
            let array = message.split(separator: " ")
            for singleWord in array {
                let word = String(singleWord)
                if let encodedWord = madarinCode[word] {
                    // word
                    encodedMessage += encodedWord
                } else {
                    // word not found in the map
                    encodedMessage += word
                }
                // seperate each word with a space
                encodedMessage += " "
            }
            DispatchQueue.main.async {
                self.detailLabel.text = encodedMessage
                print(encodedMessage)
            }
        }
        // Crop input images to square area at center, matching the way the ML model was trained.
        request.imageCropAndScaleOption = .centerCrop
        
        // Use CPU for Vision processing to ensure that there are adequate GPU resources for rendering.
        request.usesCPUOnly = true
        try? VNImageRequestHandler(ciImage: ciImage, options: [:]).perform([request])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //    func renderer(_ render: SCNSceneRenderer, updateAtTime time: TimeInterval){
    //        DispatchQueue.main.async {
    //            //add any updates to the SceneKit here.
    //        }
    //    }
}

