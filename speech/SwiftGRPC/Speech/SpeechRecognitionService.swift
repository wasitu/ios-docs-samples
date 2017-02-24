//
// Copyright 2017 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import Foundation
import gRPC

let API_KEY : String = "YOUR_API_KEY"
let HOST = "speech.googleapis.com:443"

typealias SpeechRecognitionCompletionHandler =
  (Google_Cloud_Speech_V1beta1_StreamingRecognizeResponse?,
  NSError?)
  -> (Void)

class SpeechRecognitionService {
  var sampleRate: Int = 16000
  private var nowStreaming = false

  var service: Google_Cloud_Speech_V1Beta1_SpeechService!
  var call: Google_Cloud_Speech_V1Beta1_SpeechStreamingRecognizeCall!

  var completion: SpeechRecognitionCompletionHandler!

  static let sharedInstance = SpeechRecognitionService()

  private var sendQueue: DispatchQueue
  private var receiveQueue: DispatchQueue

  private init() {
    let bundle = Bundle.main
    let url = bundle.url(forResource: "roots", withExtension: "pem")!
    let data = try! Data(contentsOf: url)
    let certificates = String(data: data, encoding: .utf8)!

    service = Google_Cloud_Speech_V1Beta1_SpeechService(address:HOST, certificates:certificates, host:nil)
    service.metadata = Metadata(["x-goog-api-key":API_KEY,
                                 "x-ios-bundle-identifier":Bundle.main.bundleIdentifier!])

    sendQueue = DispatchQueue(label: "com.google.send")
    receiveQueue = DispatchQueue(label: "com.google.receive")
  }

  func streamAudioData(_ audioData: NSData, completion: @escaping SpeechRecognitionCompletionHandler) {
    self.completion = completion

    self.sendQueue.async {
      do {

        if (!self.nowStreaming) {
          // if we aren't already streaming, set up a gRPC connection
          self.call = try self.service.streamingrecognize() { result in
            print("started \(result)")
          }
          if let call = self.call {
            var recognitionConfig = Google_Cloud_Speech_V1beta1_RecognitionConfig()
            recognitionConfig.encoding = .linear16
            recognitionConfig.sampleRate = Int32(self.sampleRate)
            recognitionConfig.languageCode = "en-US"
            recognitionConfig.maxAlternatives = 30

            var streamingRecognitionConfig = Google_Cloud_Speech_V1beta1_StreamingRecognitionConfig()
            streamingRecognitionConfig.config = recognitionConfig
            streamingRecognitionConfig.singleUtterance = false
            streamingRecognitionConfig.interimResults = true

            var streamingRecognizeRequest = Google_Cloud_Speech_V1beta1_StreamingRecognizeRequest()
            streamingRecognizeRequest.streamingConfig = streamingRecognitionConfig
            try! call.send(streamingRecognizeRequest)
            self.nowStreaming = true
            self.receiveMessages()
          }
        }

        if let call = self.call {
          var streamingRecognizeRequest = Google_Cloud_Speech_V1beta1_StreamingRecognizeRequest()
          streamingRecognizeRequest.audioContent = audioData as Data
          do {
            try call.send(streamingRecognizeRequest)
          } catch (let error) {
            print("Call error: \(error)")
          }
        }
      } catch (let error) {
        print("Call error: \(error)")
      }
    }
  }

  func receiveMessages() {
    self.receiveQueue.async {
      var running = true
      while (running) {
        do {
          let response = try self.call.receive()

          self.completion(response, nil)
        } catch (let error) {
          print("Receive error: \(error)")
          running = false
          DispatchQueue.main.async {
            self.stopStreaming()
          }
        }
      }
    }
  }

  func stopStreaming() {
    if (!nowStreaming) {
      return
    }
    nowStreaming = false
    if let call = call {
      do {
        try call.closeSend()
      } catch (let error) {
        print("call error \(error)")
      }
    }
  }
  
  func isStreaming() -> Bool {
    return nowStreaming
  }
}

