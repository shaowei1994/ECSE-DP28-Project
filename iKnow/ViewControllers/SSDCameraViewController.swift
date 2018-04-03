//
/*  Created by Dennis Liu on 2018-03-20.
 Copyright © 2017 Dennis Liu. All rights reserved.
 */
//  

import UIKit
import Vision
import ARKit
import SpriteKit
import Accelerate

class SSDCameraViewController: UIViewController, ARSKViewDelegate, ARSessionDelegate {
    
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var cameraView: ARSKView!
    
    private let visionQueue = DispatchQueue(label: "Queue") // A Serial Queue
    private var currentBuffer: CVPixelBuffer?
    private var anchorLabels = [UUID: String]()
    private var localizedLabel: String? = ""
    private var frames = 0.0
    private var ARButton = false
    private let tolerance: CGFloat = 30
    
//    var lastExecution = Date()
    var screenHeight: Double?
    var screenWidth: Double?
    let ssdPostProcessor = SSDPostProcessor(numAnchors: 1917, numClasses: 90)
    var visionModel:VNCoreMLModel?
    
    let numBoxes = 50
    var boundingBoxes: [BoundingBox] = []
    let multiClass = true
    var selectedLang: String = ""
    
    @IBAction func addLabel(_ sender: UIButton) {
        self.ARButton = true
    }
    
    @IBAction func clearAllLabels(_ sender: UIButton) {
        cameraView.scene?.removeAllChildren()
        self.anchorLabels = [UUID: String]()
    }
    
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
        
        setupBoxes()
        setupVision()
        
        screenWidth = Double(self.cameraView!.frame.width)
        screenHeight = Double(self.cameraView!.frame.height)
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraView.session.pause()
    }
    
    func setupBoxes() {
        // Create shape layers for the bounding boxes.
        for _ in 0..<numBoxes {
            let box = BoundingBox()
            box.addToLayer(view.layer)
            self.boundingBoxes.append(box)
        }
    }
    
    func setupVision() {
        guard let visionModel = try? VNCoreMLModel(for: ssd_mobilenet_feature_extractor().model)
            else { fatalError("Can't load VisionML model") }
        self.visionModel = visionModel
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
        // Instantiate the CoreML request from model
        let trackingRequest = VNCoreMLRequest(model: self.visionModel!) { (request, error) in
            guard let predictions = self.processClassifications(for: request, error: error) else { return }
            DispatchQueue.main.async {
                self.drawBoxes(predictions: predictions)
            }
        }
        
        return trackingRequest
    }()
    
    var isProcessing: Bool = false
    
    var nextDispatchItem: DispatchWorkItem?
    
    private func createWorkItem(for buffer: CVPixelBuffer) -> DispatchWorkItem {
        return DispatchWorkItem { [unowned self] in
            self.isProcessing = true
            do {
                // Release the pixel buffer when done, allowing the next buffer to be processed.
                defer { self.currentBuffer = nil }
                let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)
                let requestHandler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: orientation)
                try requestHandler.perform([self.classificationRequest])
                self.isProcessing = false
                if let item = self.nextDispatchItem {
                    self.nextDispatchItem = nil
                    self.classifyCurrentFrame(item: item)
                }
            } catch {
                print("Error: Vision request failed with error \"\(error)\"")
            }
        }
    }
    
    // Run the Vision+ML classifier on the current image buffer.
    private func classifyCurrentFrame(item: DispatchWorkItem? = nil) {
        guard let buffer = self.currentBuffer else { return }
        if isProcessing {
            self.nextDispatchItem = createWorkItem(for: buffer)
        } else {
            let workItem = item ?? createWorkItem(for: buffer)
            visionQueue.async(execute: workItem)
        }
    }
    
    // Handle completion of the Vision request and choose results to display.
    func processClassifications(for request: VNRequest, error: Error?) -> [Prediction]? {
//        let thisExecution = Date()
//        let executionTime = thisExecution.timeIntervalSince(lastExecution)
//        let framesPerSecond:Double = 1/executionTime
//        lastExecution = thisExecution
        guard let results = request.results as? [VNCoreMLFeatureValueObservation] else {
            return nil
        }
        guard results.count == 2 else {
            return nil
        }
        guard let boxPredictions = results[1].featureValue.multiArrayValue,
            let classPredictions = results[0].featureValue.multiArrayValue else {
                return nil
        }
//        DispatchQueue.main.async {
//            self.detailLabel.text = "Identifying..."
//            self.frames = framesPerSecond
//        }
        
        let predictions = self.ssdPostProcessor.postprocess(boxPredictions: boxPredictions, classPredictions: classPredictions)
        return predictions
    }
    
    var lastLabel: String = ""
    var latestLocation = CGPoint(x: 0.0, y: 0.0)
    
    func drawBoxes(predictions: [Prediction]) {
        for (index, prediction) in predictions.enumerated() {
            if let classNames = self.ssdPostProcessor.classNames {
                let label = classNames[prediction.detectedClass]
                print("Class: \(label)")
                let boundingBox = prediction.finalPrediction

//                let score = self.sigmoid(prediction.score)
//                let textColor: UIColor
//                let textLabel = String(format: "%.2f - %@", score, label)
//                textColor = UIColor.black
//
//                // draw bounding box and label
                let rect = boundingBox.toCGRect(imgWidth: self.screenWidth!,
                                                 imgHeight: self.screenWidth!,
                                                 xOffset: 0,
                                                 yOffset: (self.screenHeight! - self.screenWidth!)/2)

//                self.boundingBoxes[index].show(frame: rect,
//                                               label: textLabel,
//                                               color: UIColor.red,
//                                               textColor: textColor)

                // localize label to selected language
                let language = self.selectedLang
                self.localizedLabel = { self.localization(for: label, to: language)! }()
                self.detailLabel.text = ""

                let boxOrigin = rect.origin
                let xOffSet = rect.width/2
                let yOffSet = rect.height/2
                let currentPoint = CGPoint(x: boxOrigin.x + xOffSet, y: boxOrigin.y + yOffSet)
                
                print("Last: \(self.latestLocation)")
                print("Current: \(currentPoint)")
                print("Distance: \(self.SDistanceBetweenPoints(currentPoint, self.latestLocation))")
                
                if label != self.lastLabel ||
                    (label == self.lastLabel && self.SDistanceBetweenPoints(currentPoint, self.latestLocation) >= self.tolerance ){
                    self.tagObjectsInAR(with: rect)
                    self.lastLabel = label
                    self.latestLocation = currentPoint
                }
            }
        }
        
        for index in predictions.count..<self.numBoxes {
            self.boundingBoxes[index].hide()
        }
    }
    
    func SDistanceBetweenPoints(_ first: CGPoint, _ second: CGPoint) -> CGFloat {
        return CGFloat(hypotf(Float(second.x - first.x), Float(second.y - first.y)));
    }
    
    func tagObjectsInAR(with boundingBox: CGRect){
        cameraView.scene?.removeAllChildren()

        let boxOrigin = boundingBox.origin
        let xOffSet = boundingBox.width/2
        let yOffSet = boundingBox.height/2
        let centerPoint = CGPoint(x: boxOrigin.x + xOffSet, y: boxOrigin.y + yOffSet)

        let hitTestResults = cameraView.hitTest(centerPoint, types: [.featurePoint, .estimatedHorizontalPlane])
        if let result = hitTestResults.first {
            
            // Add a new anchor at the tap location.
            let anchor = ARAnchor(transform: result.worldTransform)
            cameraView.session.add(anchor: anchor)
            
            // Track anchor ID to associate text with the anchor after ARKit creates a corresponding SKNode.
            anchorLabels[anchor.identifier] = self.localizedLabel
        }
    }
    
    func localization(for label: String, to language: String) -> String? {
        //change this string to the one that u obtain from the model
        if let chosenLanguage = languageList[language]{
            var localizedLabel = ""
            //Split message String into words seperated by space(" ")
            let array = label.split(separator: " ")
            for singleWord in array {
                let word = String(singleWord)
                if let encodedWord = chosenLanguage[word] {
                    localizedLabel += encodedWord
                } else {
                    localizedLabel += word
                }
                localizedLabel += " "
            }
            return localizedLabel
        }else{
            return label
        }
    }
    
    func view(_ view: ARSKView, didAdd node: SKNode, for anchor: ARAnchor) {
        
        guard let labelText = anchorLabels[anchor.identifier] else {
            print("missing expected associated label for anchor")
            return self.restartSession()
        }
        
        let label = TemplateLabelNode(text: labelText)
        node.addChild(label)
        label.xScale = 0.5
        label.yScale = 0.5
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func restartSession() {
        print("Restarting Session")
        anchorLabels = [UUID: String]()
        guard let cameraView = self.view as? ARSKView else {
            return
        }
        let configuration = ARWorldTrackingConfiguration()
        cameraView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        self.detailLabel.text = "RESTARTING SESSION"
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func sigmoid(_ val:Double) -> Double {
        return 1.0/(1.0 + exp(-val))
    }
    
    func softmax(_ values:[Double]) -> [Double] {
        if values.count == 1 { return [1.0]}
        guard let maxValue = values.max() else {
            fatalError("Softmax error")
        }
        let expValues = values.map { exp($0 - maxValue)}
        let expSum = expValues.reduce(0, +)
        return expValues.map({$0/expSum})
    }
    
    public static func softmax2(_ x: [Double]) -> [Double] {
        var x:[Float] = x.flatMap{Float($0)}
        let len = vDSP_Length(x.count)
        
        // Find the maximum value in the input array.
        var max: Float = 0
        vDSP_maxv(x, 1, &max, len)
        
        // Subtract the maximum from all the elements in the array.
        // Now the highest value in the array is 0.
        max = -max
        vDSP_vsadd(x, 1, &max, &x, 1, len)
        
        // Exponentiate all the elements in the array.
        var count = Int32(x.count)
        vvexpf(&x, x, &count)
        
        // Compute the sum of all exponentiated values.
        var sum: Float = 0
        vDSP_sve(x, 1, &sum, len)
        
        // Divide each element by the sum. This normalizes the array contents
        // so that they all add up to 1.
        vDSP_vsdiv(x, 1, &sum, &x, 1, len)
        
        let y:[Double] = x.flatMap{Double($0)}
        return y
    }
    
}
