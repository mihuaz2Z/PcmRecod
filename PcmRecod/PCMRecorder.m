//
//  PCMRecorder.m
//  PcmRecod
//
//  Created by Ruiwen Feng on 2017/5/31.
//  Copyright © 2017年 Ruiwen Feng. All rights reserved.
//

#import "PCMRecorder.h"

PCMRecorder* recorder;

#define kOutputBus 0
#define kInputBus 1

void checkStatus(int status){
    if (status) {
        printf("Status not 0! %d\n", status);
        //exit(1);
    }
}

static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    //defaultformat：
    /*
     mono.
     16bits.
     
     */
    AudioBuffer buffer;
    buffer.mNumberChannels = 1;//mono
    buffer.mDataByteSize = inNumberFrames * 2;//16bits = 2Bytes.
    buffer.mData = malloc( inNumberFrames * 2 );
    
	// Put buffer in a AudioBufferList
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    // Then:
    // Obtain recorded samples
    OSStatus status;
    status = AudioUnitRender(recorder.audioUnit,
                             ioActionFlags,
                             inTimeStamp,
                             inBusNumber,
                             inNumberFrames,
                             &bufferList);
    checkStatus(status);
    
    //callback
    if ([recorder.delegate respondsToSelector:@selector(pcmDataCallback:)]) {
        [recorder.delegate pcmDataCallback:buffer];
    }
    
    free(bufferList.mBuffers[0].mData);


    return noErr;
}

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames, 
                                 AudioBufferList *ioData) {
    NSLog(@"play..");
    return noErr;
}

@interface PCMRecorder ()

@end


@implementation PCMRecorder

- (instancetype)init
{
    self = [super init];
    if (self) {
        recorder = self;
    }
    return self;
}


- (void)createUnit:(AudioStreamBasicDescription)audioFormat {
    
    OSStatus status;
    
    AudioComponentDescription desc = {0};
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;

    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    status = AudioComponentInstanceNew(inputComponent, &_audioUnit);
    checkStatus(status);

    // Enable IO for recording
    UInt32 flag = 1;
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &flag, 
                                  sizeof(flag));
    checkStatus(status);
    
    // Enable IO for playback
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  kOutputBus,
                                  &flag, 
                                  sizeof(flag));
    checkStatus(status);
    
    // Apply format
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    checkStatus(status);
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input, 
                                  kOutputBus, 
                                  &audioFormat, 
                                  sizeof(audioFormat));
    checkStatus(status);
    
    // Set input callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = recordingCallback;
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global,
                                  kInputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkStatus(status);
    
    // Set output callback
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global, 
                                  kOutputBus,
                                  &callbackStruct, 
                                  sizeof(callbackStruct));
    checkStatus(status);
    
    // Initialise
    status = AudioUnitInitialize(_audioUnit);
    checkStatus(status);
}

- (void)startRecord {
    
    OSStatus status = AudioOutputUnitStart(_audioUnit);
    checkStatus(status);

}

- (void)stopRecord {
    
    OSStatus status = AudioOutputUnitStop(_audioUnit);
    checkStatus(status);

}

+ (void)defaultAudioFormat:(AudioStreamBasicDescription*)format {
    format->mSampleRate         = 8000;
    format->mBitsPerChannel     = 16;
    format->mChannelsPerFrame   = 1;
    
    format->mFormatID           = kAudioFormatLinearPCM;
    format->mFormatFlags		= kAudioFormatFlagIsSignedInteger ;
    format->mFramesPerPacket	= 1;
    format->mBytesPerPacket		= 2;
    format->mBytesPerFrame		= 2;
}

- (void) dealloc {
    recorder = nil;
    AudioUnitUninitialize(_audioUnit);
}

@end
