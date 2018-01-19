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

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    @IBOutlet weak var detailLabel: UILabel!
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let captureSession = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        
        if captureDevice.isFocusModeSupported(.continuousAutoFocus){
            try! captureDevice.lockForConfiguration()
            captureDevice.focusMode = .continuousAutoFocus
            captureDevice.unlockForConfiguration()
        }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        captureSession.addInput(input)
        captureSession.startRunning()
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        self.view.layer.insertSublayer(previewLayer, at: 0)
        previewLayer.frame = self.view.frame
        //        previewLayer.frame = self.view.bounds
        self.view.backgroundColor = .black
        
        let dataOutput = AVCaptureVideoDataOutput()
        
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        captureSession.addOutput(dataOutput)
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        guard let model = try? VNCoreMLModel(for: Caltech().model) else {return}
        
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else {return}
            
            guard let firstObservation = results.first else {return}
            
            let percentage = String(format: "%.2f", firstObservation.confidence*100)
            
            print(firstObservation.identifier, firstObservation.confidence)
            DispatchQueue.main.async {
                
                self.detailLabel.text = String(firstObservation.identifier.split(separator: " ")[1]) + " " + percentage + "%"
            }
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
    //
    //        layer.videoOrientation = orientation
    //
    //        previewLayer.frame = self.view.bounds
    //
    //    }
    //
    //    override func viewDidLayoutSubviews() {
    //        super.viewDidLayoutSubviews()
    //
    //        if let connection =  self.previewLayer?.connection  {
    //
    //            let currentDevice: UIDevice = UIDevice.current
    //
    //            let orientation: UIDeviceOrientation = currentDevice.orientation
    //
    //            let previewLayerConnection : AVCaptureConnection = connection
    //
    //            if previewLayerConnection.isVideoOrientationSupported {
    //
    //                switch (orientation) {
    //                case .portrait: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
    //
    //                    break
    //
    //                case .landscapeRight: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
    //
    //                    break
    //
    //                case .landscapeLeft: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
    //
    //                    break
    //
    //                case .portraitUpsideDown: updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
    //
    //                    break
    //
    //                default: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
    //
    //                    break
    //                }
    //            }
    //        }
    //    }
}


