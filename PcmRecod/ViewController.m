//
//  ViewController.m
//  PcmRecod
//
//  Created by Ruiwen Feng on 2017/5/31.
//  Copyright © 2017年 Ruiwen Feng. All rights reserved.
//

#import "ViewController.h"
#import "PCMRecorder.h"

@interface ViewController () <PcmRecordProtocol>
@property (strong,nonatomic) PCMRecorder *recorder;;
@property (strong,nonatomic) NSFileHandle * file;
@end

@implementation ViewController {
    long size_C;
    int num;
    long avage;

}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString * path = [NSString stringWithFormat:@"%@/8000hz16bit1channel.pcm",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    
    _file = [NSFileHandle fileHandleForWritingAtPath:path];
    
    
    self.recorder = [[PCMRecorder alloc]init];
    
    AudioStreamBasicDescription streamDes;
    [PCMRecorder defaultAudioFormat:&streamDes];
    [self.recorder createUnit:streamDes];
    
    self.recorder.delegate = self;
    
    [self.recorder startRecord];
    [self calcuteSize];

}


- (void)pcmDataCallback:(AudioBuffer)buffer {
    size_C += buffer.mDataByteSize;
    num += 1;
    [_file writeData:[NSData dataWithBytes:buffer.mData length:buffer.mDataByteSize]];
//    NSLog(@"caijidaole.%d",buffer.mDataByteSize);
}

- (void)calcuteSize {
    if (avage == 0) {
        avage = size_C;
    }
    avage = (avage+size_C)/2;
    NSLog(@"\nsize_C:%ld num:%d avage%ld sample:%f",size_C,num,avage,avage*1.0/num);
    size_C = 0;
    num = 0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self calcuteSize];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
