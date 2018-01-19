//
//  ViewController.swift
//  iKnow
//
//  Created by Shao-Wei Liang on 2018-01-17.
//  Copyright © 2018 Shao-Wei Liang. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

import AVKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        enableCapturingSession()
        
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
           
            //integrate the .mlmodel into the app
            guard let model = try? VNCoreMLModel(for: Caltech().model) else {return}
            let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
                //initialize a "result" variable for the output of analysis
                guard let results = finishedReq.results as? [VNClassificationObservation] else {return}
                //takes the first parameters in "finished"
                guard let firstObservation = results.first else {return}
                let percentage = String(format: "%.2f", firstObservation.confidence*100)
                print(firstObservation.identifier, firstObservation.confidence)
                DispatchQueue.main.async {
                    self.detailLabel.text = String(firstObservation.identifier.split(separator: " ")[1]) + " " + percentage + "%"
                }
                
            }
            try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        }
    }
    
    func enableCapturingSession(){
        
        //initialize a Capture Session
        let captureSession = AVCaptureSession()
        
        //initialize a Capture Device
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        
        //enable auto-focus
        if captureDevice.isFocusModeSupported(.continuousAutoFocus){
            try! captureDevice.lockForConfiguration()
            captureDevice.focusMode = .continuousAutoFocus
            captureDevice.unlockForConfiguration()
        }
        
        //initialize an input for the captured frame
        guard let capturedInput = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        captureSession.addInput(capturedInput)
        
        //start the capturing session
        captureSession.startRunning()
        
        //initialize a layer for showing the camera captured frame
        let displayLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        //insert the displayLayer onto the screen at top level
        self.view.layer.insertSublayer(displayLayer, at: 0)
        displayLayer.frame = self.view.frame
        self.view.backgroundColor = .black
        
        //initialize an output for the captured frame
        let dataOutput = AVCaptureVideoDataOutput()
        
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
   

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
