//
//  AudioUnitTool.m
//  Muthos
//
//  Created by Youngjune Kwon on 2016. 3. 7..
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

AudioUnit _rioUnit;

OSStatus	performRender (void                         *inRefCon,
                           AudioUnitRenderActionFlags 	*ioActionFlags,
                           const AudioTimeStamp 		*inTimeStamp,
                           UInt32 						inBusNumber,
                           UInt32 						inNumberFrames,
                           AudioBufferList              *ioData)
{
    OSStatus err = noErr;
    NSLog(@"== perform Render ==");
    return err;
}

void setupAudioSession();
void initAudioUnit() {
    setupAudioSession();
    // Create a new instance of AURemoteIO
    
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    
    AudioComponent comp = AudioComponentFindNext(NULL, &desc);
    AudioComponentInstanceNew(comp, &_rioUnit);
    
    //  Enable input and output on AURemoteIO
    //  Input is enabled on the input scope of the input element
    //  Output is enabled on the output scope of the output element
    
    UInt32 one = 1;
    AudioUnitSetProperty(_rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one));
    AudioUnitSetProperty(_rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one));
    
    AudioStreamBasicDescription ioFormat;
    ioFormat.mSampleRate = 44100;
    ioFormat.mChannelsPerFrame = 1;
    ioFormat.mFormatFlags |= kAudioFormatFlagIsFloat;
    ioFormat.mChannelsPerFrame = false;
    ioFormat.mFormatID = kAudioFormatLinearPCM;
    ioFormat.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    ioFormat.mFramesPerPacket = 1;
    ioFormat.mBytesPerFrame = ioFormat.mBytesPerPacket = 0;
    ioFormat.mReserved = 0;
    
    AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &ioFormat, sizeof(ioFormat));
    AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &ioFormat, sizeof(ioFormat));
    
    // Set the MaximumFramesPerSlice property. This property is used to describe to an audio unit the maximum number
    // of samples it will be asked to produce on any single given call to AudioUnitRender
    UInt32 maxFramesPerSlice = 4096;
    AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, sizeof(UInt32));
    
    // Get the property value back from AURemoteIO. We are going to use this value to allocate buffers accordingly
    UInt32 propSize = sizeof(UInt32);
    AudioUnitGetProperty(_rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, &propSize);
    
    // Set the render callback on AURemoteIO
    AURenderCallbackStruct renderCallback;
    renderCallback.inputProc = performRender;
    renderCallback.inputProcRefCon = NULL;
    AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallback, sizeof(renderCallback));
    
    // Initialize the AURemoteIO instance
    AudioUnitInitialize(_rioUnit);
}


void setupAudioSession()
{
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    
    // we are going to play and record so we pick that category
    NSError *error = nil;
    [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    NSLog(@"setupAudioSession.A %@",
          error);
    // set the buffer duration to 5 ms
    NSTimeInterval bufferDuration = .005;
    [sessionInstance setPreferredIOBufferDuration:bufferDuration error:&error];
    NSLog(@"setupAudioSession.B %@", error);
    
    // set the session's sample rate
    [sessionInstance setPreferredSampleRate:44100 error:&error];
    NSLog(@"setupAudioSession.C %@", error);
    
    // activate the audio session
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    NSLog(@"setupAudioSession.D %@", error);
}
