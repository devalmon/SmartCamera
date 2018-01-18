//
//  ViewController.swift
//  SmartCamera
//
//  Created by Alexey Baryshnikov on 03/01/2018.
//  Copyright © 2018 Alexey Baryshnikov. All rights reserved.
//

import UIKit
import AVKit
import Vision

//UIApplication.shared.isIdleTimerDisabled = true

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    var txtResult = UILabel()
    var percentValue = UILabel()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black

        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
//        guard let captureDevice = AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType, position: .back) else { return }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        
//        VNImageRequestHandler(cgImage: <#T##CGImage#>, options: [ : ]).perform(<#T##requests: [VNRequest]##[VNRequest]#>)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        print("Camera was able to capture a frame:", Date())
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }
        let request = VNCoreMLRequest(model: model) { (finishedReq, error) in
            // perhaps check the error
//            print(finishedReq.results)
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            
            guard let firstObservation = results.first else { return }
            
            let observationText = "\(firstObservation.identifier)"
            let percentText = "\(firstObservation.confidence * 100)%"
//            print(firstObservation.identifier, firstObservation.confidence * 100)
            DispatchQueue.main.async {
                self.txtResult.frame = CGRect(x: 10, y: 60, width: 260, height: 70)
                self.txtResult.text = observationText
                self.txtResult.backgroundColor = UIColor.lightGray
                self.txtResult.textAlignment = .center
                self.txtResult.layer.masksToBounds = true
                self.txtResult.layer.borderWidth = 2
                self.txtResult.layer.cornerRadius = 18
                
                
                self.percentValue.frame = CGRect(x: 270, y: 60, width: 100, height: 70)
                self.percentValue.text = percentText
                self.percentValue.backgroundColor = UIColor.orange
                self.percentValue.textAlignment = .center
                self.percentValue.layer.masksToBounds = true
                self.percentValue.layer.borderWidth = 2
                self.percentValue.layer.cornerRadius = 18
                
                self.view.addSubview(self.txtResult)
                self.view.addSubview(self.percentValue)
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}

