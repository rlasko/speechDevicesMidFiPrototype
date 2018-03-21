//
//  ViewController.swift
//  speechDevicesMidFi
//
//  Created by Rae  Lasko on 3/21/18.
//  Copyright © 2018 Rae  Lasko. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController {
  let synth = AVSpeechSynthesizer()
  let audioEngine = AVAudioEngine()
  let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
  var request = SFSpeechAudioBufferRecognitionRequest()
  var recognitionTask: SFSpeechRecognitionTask?
  var userText = AVSpeechUtterance(string: "")

  enum Status {
    case listening
    case ready
    case unavailable
    case undetermined
  }
  var status = Status.undetermined

  @IBOutlet weak var userTextField: UITextField!

  @IBOutlet weak var listenButton: UIButton!
  
  @IBOutlet weak var spinner: UIActivityIndicatorView!

  @IBOutlet weak var detectedTextField: UITextView!

  @IBAction func sayItClicked(_ sender: Any) {
    userText = AVSpeechUtterance(string: userTextField.text!)
    userText.rate = 0.3
    synth.speak(userText)
    self.userTextField.text = ""
  }

  @IBAction func listenForSpeech(_ sender: Any) {
    switch status {
    case .ready:
      self.spinner.startAnimating()
      self.detectedTextField.text = ""
      listenButton.setTitle("Stop Listening", for: UIControlState.normal)
      self.recordAndRecognizeSpeech()
      status = .listening
    case .listening:
      cancelRecording()
      status = .ready
      self.spinner.stopAnimating()
      listenButton.setTitle("Listen", for: UIControlState.normal)
    default:
      break
    }
  }

  func cancelRecording() {
    request.endAudio()
    request = SFSpeechAudioBufferRecognitionRequest()
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    recognitionTask?.cancel()
  }

  func recordAndRecognizeSpeech() {
    print("attempting to listen...")

    let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
    audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in self.request.append(buffer)
    }

    audioEngine.prepare()
    do {
      try audioEngine.start()
    } catch {
      print("error")
      return print(error)
    }

    guard let myRecognizer = SFSpeechRecognizer() else {
      // recognizer not supported for locale
      print("recognizer not supported")
      return
    }
    if !myRecognizer.isAvailable {
      // recognizer not available right now
      print("recognizer not available")
      return
    }

    recognitionTask = (speechRecognizer?.recognitionTask(with: request, resultHandler: {result, error in
      if result != nil {
        if let result = result {
          print("working!")
          let bestString = result.bestTranscription.formattedString
          print(bestString)
          self.detectedTextField.text = bestString
        } else if let error = error {
          print(error)
        }
      } else {
        print("nil")
      }
    }))!
  }

  func askSpeechPermission() {
    SFSpeechRecognizer.requestAuthorization { status in
      OperationQueue.main.addOperation {
        switch status {
        case .authorized:
          self.status = .ready
        default:
          self.status = .unavailable
        }
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    self.spinner.hidesWhenStopped = true
    userTextField.becomeFirstResponder()

    switch SFSpeechRecognizer.authorizationStatus() {
    case .notDetermined:
      askSpeechPermission()
    case .authorized:
      self.status = .ready
    case .denied, .restricted:
      self.status = .unavailable
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

