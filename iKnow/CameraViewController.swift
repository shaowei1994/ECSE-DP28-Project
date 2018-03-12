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
    private let visionQueue = DispatchQueue(label: "Queue") // A Serial Queue
    private var currentBuffer: CVPixelBuffer?
    private var anchorLabels = [UUID: String]()
    
    //    private var suspended = false
    //    private let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)
    
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
//        loopProcess()
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
        
//        if suspended == true{
//        visionQueue.resume()
//            suspended = false
//        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraView.session.pause()
//        visionQueue.suspend()
//        suspended = true
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do not enqueue other buffers for processing while another Vision task is still running.
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else { return }
        // Retain the image buffer for Vision processing.
        self.currentBuffer = frame.capturedImage
        classifyCurrentFrame()
    }
    
    // Vision classification request and model
    private lazy var classificationRequest: VNCoreMLRequest = {
        do {
            // Instantiate the model from its generated Swift class.
            let model = try VNCoreMLModel(for: Inceptionv3().model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            
            // Crop input images to square area at center, matching the way the ML model was trained.
            request.imageCropAndScaleOption = .centerCrop
            
            // Use CPU for Vision processing to ensure that there are adequate GPU resources for rendering.
            request.usesCPUOnly = true
            
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    // Run the Vision+ML classifier on the current image buffer.
    private func classifyCurrentFrame() {
        let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentBuffer!, orientation: orientation)
        visionQueue.async {
            do {
                // Release the pixel buffer when done, allowing the next buffer to be processed.
                defer { self.currentBuffer = nil }
                try requestHandler.perform([self.classificationRequest])
            } catch {
                print("Error: Vision request failed with error \"\(error)\"")
            }
        }
    }
    
    // Handle completion of the Vision request and choose results to display.
    func processClassifications(for request: VNRequest, error: Error?) {
        guard let results = request.results else {
            print("Unable to classify image.\n\(error!.localizedDescription)")
            return
        }
        // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
        let classifications = results as! [VNClassificationObservation]
        
        // Show a label for the highest-confidence result (but only above a minimum confidence threshold).
        guard let bestResult = classifications.first else { return }
        guard let label = bestResult.identifier.split(separator: ",").first else { return }
        let labelString = String(label)
        DispatchQueue.main.async { [weak self] in
            self?.detailLabel.text = labelString
            print(label, bestResult.confidence)
            
            self?.displayClassifiedLabels(labelString)
        }
    }
    
    func displayClassifiedLabels(_ label: String){
        
        //Set the label placing at the center of the frame
        let xCenter = cameraView.frame.maxX/2
        let yCenter = cameraView.frame.maxY/2
        let centerPoint = CGPoint(x: xCenter, y: yCenter)
        
        //Conduct a hit test at the destinated CGPoint
        let hitTestResults = cameraView.hitTest(centerPoint, types: [.featurePoint, .estimatedHorizontalPlane])
        if let result = hitTestResults.first {
            
            // Add a new anchor at the tap location.
            let anchor = ARAnchor(transform: result.worldTransform)
            cameraView.session.add(anchor: anchor)
            
            // Track anchor ID to associate text with the anchor after ARKit creates a corresponding SKNode.
            anchorLabels[anchor.identifier] = label
        }
    }
    
    func view(_ view: ARSKView, didAdd node: SKNode, for anchor: ARAnchor) {
        
        guard let labelText = anchorLabels[anchor.identifier] else {
            fatalError("missing expected associated label for anchor")
        }
        let label = TemplateLabelNode(text: labelText)
        node.addChild(label)
    }

    

//    func loopProcess() {
//        visionQueue.async {
//            self.objectRecognition()
//            self.loopProcess()
//        }
//    }
//
//    private func objectRecognition(){
//        guard let pixelBuffer: CVPixelBuffer = cameraView.session.currentFrame?.capturedImage else {return}
//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {return}
//        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
//            guard let results = finishedReq.results as? [VNClassificationObservation] else {return}
//            guard let firstObservation = results.first else {return}
//            DispatchQueue.main.async {
//                self.detailLabel.text = String(firstObservation.identifier.split(separator: ",")[0])
//                print(firstObservation.identifier.split(separator: ",")[0], firstObservation.confidence)
//            }
//        }
//        // Crop input images to square area at center, matching the way the ML model was trained.
//        request.imageCropAndScaleOption = .centerCrop
//
//        // Use CPU for Vision processing to ensure that there are adequate GPU resources for rendering.
//        request.usesCPUOnly = true
//        try? VNImageRequestHandler(ciImage: ciImage, orientation: orientation).perform([request])
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
}
