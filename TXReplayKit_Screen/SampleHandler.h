//
//  SampleHandler.h
//  TXReplayKit_Screen
//
//  Created by Weep Yan on 2021/3/18.
//

#import <ReplayKit/ReplayKit.h>
#import <TXLiteAVSDK_ReplayKitExt/TXLiteAVSDK_ReplayKitExt.h>

static NSString *APPGROUP = @"group.com.tencent.liteav.RPLiveStreamShare";

@interface SampleHandler : RPBroadcastSampleHandler<TXReplayKitExtDelegate>

@end
