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
    let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml") // A Serial Queue
    var suspended = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //===================================================================================
        
        //Set up the AR Session
        cameraView.delegate = self
        let scene = SCNScene()
        //Set the scene to the view
        cameraView.scene = scene
        cameraView.autoenablesDefaultLighting = true
        loopProcess()
        
        //        //instantiate a Capture Session
        //        let captureSession = AVCaptureSession()
        //
        //        //instantiate a Capturing Device
        //        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        //
        //        //enable auto-focus mode
        //        if captureDevice.isFocusModeSupported(.continuousAutoFocus){
        //            try! captureDevice.lockForConfiguration()
        //            captureDevice.focusMode = .continuousAutoFocus
        //            captureDevice.unlockForConfiguration()
        //        }
        //
        //        //instantiate the camera as a capture input for the capture session
        //        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        //        captureSession.addInput(input)
        //        captureSession.startRunning()
        //
        //        //Set up the display layer on screen
        //        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        //        self.view.layer.addSublayer(previewLayer)
        //        previewLayer.frame = cameraView.frame
        //        previewLayer.videoGravity = AVLayerVideoGravity.resize
        //        self.view.backgroundColor = .black
        //        self.view.addSubview(detailLabel)
        //
        //        //instantiate an "output" to be fed into capture session
        //        let dataOutput = AVCaptureVideoDataOutput()
        //        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "Queue"))
        //        captureSession.addOutput(dataOutput)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("View Appeared")
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        cameraView.session.run(configuration)
        if suspended == true{
            dispatchQueueML.resume()
            suspended = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraView.session.pause()
        dispatchQueueML.suspend()
        suspended = true
        print("View disappeared")
    }
    
    func loopProcess() {
        // Continuously run CoreML whenever it's ready. (Preventing 'hiccups' in Frame Rate)
        dispatchQueueML.async {
            // 1. Run Update.
            self.objectRecognition()
            // 2. Loop this function.
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
            //            let confidence = String(format: "%.2f", firstObservation.confidence*100)
            DispatchQueue.main.async {
                self.detailLabel.text = String(firstObservation.identifier.split(separator: ",")[0])
                print(firstObservation.identifier.split(separator: ",")[0], firstObservation.confidence)
            }
        }
        try? VNImageRequestHandler(ciImage: ciImage, options: [:]).perform([request])
    }
    
    //    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    //        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
    //        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {return}
    //        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
    //            guard let results = finishedReq.results as? [VNClassificationObservation] else {return}
    //            guard let firstObservation = results.first else {return}
    ////            let confidence = String(format: "%.2f", firstObservation.confidence*100)
    ////            print(firstObservation.identifier.split(separator: ",")[0], firstObservation.confidence)
    ////========================================================================================================
    //            var madarinCode = [
    //                "laptop" : "笔记本电脑"
    //            ]
    //            //change this string to the one that u obtain from the model
    //            let message = firstObservation.identifier.split(separator: ",")[0]
    //            var encodedMessage = ""
    //            //Split message String into words seperated by space(" ")
    //            let array = message.split(separator: " ")
    //            for singleWord in array {
    //                let word = String(singleWord)
    //                if let encodedWord = madarinCode[word] {
    //                    // word
    //                    encodedMessage += encodedWord
    //                } else {
    //                    // word not found in the map
    //                    encodedMessage += word
    //                }
    //                // seperate each word with a space
    //                encodedMessage += " "
    //            }
    ////===========================================================================================================
    //            DispatchQueue.main.async {
    ////                self.detailLabel.text = String(firstObservation.identifier.split(separator: ",")[0]) + " " + confidence + "%"
    //                self.detailLabel.text = encodedMessage
    //                print(firstObservation.identifier.split(separator: ",")[0], firstObservation.confidence)
    //            }
    //        }
    //        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    //    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    //    func renderer(_ render: SCNSceneRenderer, updateAtTime time: TimeInterval){
    //        DispatchQueue.main.async {
    //            //add any updates to the SceneKit here.
    //        }
    //    }
}
