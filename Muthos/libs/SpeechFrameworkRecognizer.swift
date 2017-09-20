//
//  SpeechFrameworkRecognizer.swift
//  muthos
//
//  Created by shining on 2016. 11. 4..
//
//

import Foundation
import Speech
import AVFoundation

class SpeechFrameworkRecognizer : NSObject, SpeechRecognizing {
    internal func recognize(callback: @escaping Async.callbackFunc) -> Bool {
        recognized = ""
        currentCallback = callback
        startRecording()
        return true
    }

    internal func stopRecognizing() {
        ///// finishRecording()
        recognitionTask?.finish()
    }
    
    internal func setDelegate(_ delegate: SpeechRecognizingDelegate?) {
        self.delegate = delegate
    }
    
    var recognized:String = ""
    static var authorized:Bool = false
    var currentCallback:Async.callbackFunc?
    static var singleton:SpeechRecognizing?
    var finished:Bool = false

    var delegate: SpeechRecognizingDelegate?
    let audioSession = AVAudioSession.sharedInstance()

    static func instance() -> SpeechRecognizing {
        if (singleton == nil) {
            singleton = SpeechFrameworkRecognizer()
        }
        return singleton!
    }
    
    func getOnRecognize() -> Bool {
        return audioEngine.isRunning
    }
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var audioBuffers: [AVAudioPCMBuffer] = [AVAudioPCMBuffer]()
    
    override init() {
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            switch authStatus {
            case .authorized:
                SpeechFrameworkRecognizer.authorized = true
            case .denied:
                print("User denied access to speech recognition")
            case .restricted:
                print("Speech recognition restricted on this device")
            case .notDetermined:
                print("Speech recognition not yet authorized")
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
            if granted {
                print("yass")
            } else {
                print("Permission to record not granted")
            }
        })
    }
    
    func stopRecoding() {
        if audioEngine.isRunning {
            
            guard let inputNode = audioEngine.inputNode else {
                fatalError("Audio engine has no input node")
            }
            
            inputNode.removeTap(onBus: 0)
            
            audioEngine.stop()
            self.recognitionRequest?.endAudio()
            self.recognitionRequest = nil
        }
    }
    
    func startRecording() {
        let profiler = Profiler("recording")
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        profiler.begin()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true/*, with: .notifyOthersOnDeactivation*/)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }

        profiler.lap("audio session")

        let inputNode = audioEngine.inputNode!
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        do {
            try audioSession.setPreferredSampleRate(recordingFormat.sampleRate)
        } catch {
            print("Error setPreferredSampleRate")
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            //DispatchQueue.main.async {
                self.recognitionRequest?.append(buffer)
                
                print("OK delegate")
                if let delegate = self.delegate {
                    var level:Float = 0
                    for i in 0...1024 {
                        level += buffer.floatChannelData![0][i]
                    }
                    //print("OK level")
                    delegate.speechRecognizing(self, listening: self.recognized, level: level)
                }
            //}
        }
        
        finished = false
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
//            startCheckingTimeout()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }

        
        
        if self.recognitionRequest == nil {
            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        }
        
        guard let recognitionRequest = self.recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.taskHint = .unspecified
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            // guard let self = self else { return }
            
            var isFinal = false
            if result != nil {
                self.recognized = (result?.bestTranscription.formattedString)!
                print(self.recognized)
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                print(self.recognized)
                // self.recognitionTask = nil
                ////// hansj self.finishRecording()
                self.performSelector(onMainThread: #selector(SpeechFrameworkRecognizer.doFinishRecording), with: nil, waitUntilDone: false)
            }
        })
    }
    
    func startCheckingTimeout() {
        let controller = ApplicationContext.sharedInstance.sharedBookController
        var timeout = CMTimeGetSeconds(CMTimeAdd(controller.voicePlayer.currentItem!.duration, CMTimeMake(1,1)))
        
        if timeout.isNaN {
            timeout = 5
        }
        
        self.perform(#selector(SpeechFrameworkRecognizer.onTimeout), with:nil, afterDelay:timeout)
    }
    
    @objc
    func onTimeout() {
        ///// finishRecording()
        recognitionTask?.finish()
    }

    func finishRecording() {
        //// hansj self.performSelector(onMainThread: #selector(SpeechFrameworkRecognizer.doFinishRecording), with: nil, waitUntilDone: false)
    }
    
    func doFinishRecording() {
        guard !self.finished else { return }
        self.finished = true
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        inputNode.removeTap(onBus: 0)
        
        audioEngine.stop()
        
        self.recognitionRequest?.endAudio()
        self.recognitionRequest = nil
        self.recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setMode(AVAudioSessionModeDefault)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        _ = self.currentCallback!()
    }
    
}
