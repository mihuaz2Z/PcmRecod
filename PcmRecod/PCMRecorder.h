//
//  PCMRecorder.h
//  PcmRecod
//
//  Created by Ruiwen Feng on 2017/5/31.
//  Copyright © 2017年 Ruiwen Feng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>




@protocol PcmRecordProtocol <NSObject>

- (void)pcmDataCallback:(AudioBuffer)buffer;

@end


@interface PCMRecorder : NSObject

@property (assign,nonatomic) AudioComponentInstance audioUnit;

@property (weak,nonatomic)   id<PcmRecordProtocol>  delegate;


/* 8000 hz,16 bit,1 channel */
+ (void)defaultAudioFormat:(AudioStreamBasicDescription*)format;

- (void)createUnit:(AudioStreamBasicDescription)audioFormat;

- (void)startRecord;
- (void)stopRecord ;

@end
