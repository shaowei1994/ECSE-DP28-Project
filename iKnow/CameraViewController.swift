//
//  ViewController.swift
//  iKnow
//
//  Created by Shao-Wei Liang on 2018-01-17.
//  Copyright © 2018 Shao-Wei Liang. All rights reserved.
//
import UIKit
import AVKit
import Vision
import ARKit
import SceneKit

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, ARSCNViewDelegate {
    
    
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var cameraView: ARSCNView!
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        //==========================================================================================================================================
        
        //Set up the AR Session
        cameraView.delegate = self
        //Show FPS and other information
//        cameraView.showsStatistics = true
        let scene = SCNScene()
        //Set the scene to the view
        cameraView.scene = scene
        cameraView.autoenablesDefaultLighting = true
        
        //==========================================================================================================================================
        
        //Tap - to tag the object
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognizer:)))
//        view.addGestureRecognizer(tapGesture)
        
        //==========================================================================================================================================
        
        //instantiate a Capture Session
        let captureSession = AVCaptureSession()
        
        //instantiate a Capturing Device
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        
        //enable auto-focus mode
        if captureDevice.isFocusModeSupported(.continuousAutoFocus){
            try! captureDevice.lockForConfiguration()
            captureDevice.focusMode = .continuousAutoFocus
            captureDevice.unlockForConfiguration()
        }
        
        //instantiate the camera as a capture input for the capture session
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        captureSession.addInput(input)
        captureSession.startRunning()
        
        
        
        //Set up the display layer on screen
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(previewLayer)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.frame = cameraView.frame
        self.view.backgroundColor = .black
        self.view.addSubview(detailLabel)
        
        //instantiate an "output" to be fed into capture session
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "Queue"))
        captureSession.addOutput(dataOutput)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {return}
        
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else {return}
            guard let firstObservation = results.first else {return}
            let confidence = String(format: "%.2f", firstObservation.confidence*100)
            
            print(firstObservation.identifier.split(separator: ",")[0], firstObservation.confidence)

//============================================================================================================================================
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
//============================================================================================================================================

            DispatchQueue.main.async {
//                self.detailLabel.text = String(firstObservation.identifier.split(separator: ",")[0]) + " " + confidence + "%"
                self.detailLabel.text = encodedMessage
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
  
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        let configuration = ARWorldTrackingConfiguration()
//        configuration.planeDetection = .horizontal
//        cameraView.session.run(configuration)
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        cameraView.session.pause()
//
//    }
//
//    func renderer(_ render: SCNSceneRenderer, updateAtTime time: TimeInterval){
//        DispatchQueue.main.async {
//            //add any updates to the SceneKit here.
//        }
//    }
//
}
