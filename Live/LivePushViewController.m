//
//  LivePushViewController.m
//  WYTRTCDemo
//
//  Created by Weep Yan on 2021/3/16.
//

#import "LivePushViewController.h"
#import "WYTRTCDemo-Swift.h"// 引用默认Swift头文件调用swift代码
#import <TRTCCloud.h>
#import "GenerateTestUserSig.h"

static int MAX_REMOTE_USER_NUM = 6;

@interface LivePushViewController () <TRTCCloudDelegate>

@property (weak, nonatomic) IBOutlet NSMutableArray<LiveSubVideoView *> *remoteVideoViews;
@property (weak, nonatomic) IBOutlet UIImageView *videoMutedTipsView;
@property (weak, nonatomic) IBOutlet UIView *localVideoView;
@property (weak, nonatomic) IBOutlet UILabel *roomIdLabel;

@property (nonatomic, assign) BOOL isFrontCamera;
@property (nonatomic, strong) NSMutableOrderedSet *remoteUids;
@property (nonatomic, strong) TRTCVideoEncParam *videoEncParam;

@property (nonatomic, strong) LiveRoomManager *roomManager;
@property (nonatomic, strong) TRTCCloud *trtcCloud;

@end

@implementation LivePushViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.isFrontCamera = YES;
    self.roomManager = [LiveRoomManager sharedInstancee];
    
    self.roomIdLabel.text = [NSString stringWithFormat:@"%u", self.roomId];
    
    /**
     * 设置参数，进入视频通话房间
     * 房间号param.roomId，当前用户id param.userId
     * param.role 指定以什么角色进入房间（anchor主播，audience观众）
     */
    TRTCParams *params = [[TRTCParams alloc] init];
    params.sdkAppId = SDKAppID;
    params.roomId = self.roomId;
    params.userId = self.userId;
    params.role = TRTCRoleAnchor;
    
    /// userSig是进入房间的用户签名，相当于密码（这里生成的是测试签名，正确做法需要业务服务器来生成，然后下发给客户端）
    params.userSig = [GenerateTestUserSig genTestUserSig:params.userId];
    
    /// 指定以“在线直播场景”（TRTCAppScene.LIVE）进入房间
    [self.trtcCloud enterRoom:params appScene:TRTCAppSceneLIVE];
    
    // 创建房间
    [_roomManager createLiveRoomWithRoomId:[NSString stringWithFormat:@"%u", self.roomId]];
    
    /// 默认设置高清的直播画质（帧率 15fps, 码率 1200, 分辨率 540*960）
    TRTCVideoEncParam *videoEncParam = [[TRTCVideoEncParam alloc] init];
    videoEncParam.videoResolution = TRTCVideoResolution_960_540;
    videoEncParam.videoBitrate = 1200;
    videoEncParam.videoFps = 15;
    [self.trtcCloud setVideoEncoderParam:videoEncParam];
    
    /**
     * 设置默认美颜效果（美颜效果：自然，美颜级别：5, 美白级别：1）
     * 视频通话场景推荐使用“自然”美颜效果
     */
    TXBeautyManager *beautyManager = [self.trtcCloud getBeautyManager];
    [beautyManager setBeautyStyle:TXBeautyStyleNature];
    [beautyManager setBeautyLevel:5];
    [beautyManager setWhitenessLevel:1];
    
    /// 调整仪表盘显示位置
    [self.trtcCloud setDebugViewMargin:self.userId margin:UIEdgeInsetsMake(80, 0, 0, 0)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    /// 开启麦克风采集
    //[self.trtcCloud startLocalAudio];
    [self.trtcCloud startLocalAudio:TRTCAudioQualityDefault];
    
    /// 开启摄像头采集
    [self.trtcCloud startLocalPreview:self.isFrontCamera view:self.localVideoView];
}

/// 退出房间，结束视频直播
- (IBAction)onExitLiveClicked:(UIButton *)sender {
    
    [self.trtcCloud exitRoom];
    [_roomManager destroyLiveRoomWithRoomId:[NSString stringWithFormat:@"%u", self.roomId]];
    
    [self.navigationController popViewControllerAnimated:YES];
}

/// 切换前置与后置摄像头
- (IBAction)onSwitchCameraClicked:(UIButton *)sender {
    //[self.trtcCloud switchCamera];
    [[self.trtcCloud getDeviceManager] switchCamera:self.isFrontCamera];
    self.isFrontCamera = sender.isSelected;
    sender.selected = !sender.isSelected;
}

/// 切换画质
- (IBAction)onResolutionClicked:(UIButton *)sender {
    /// 实际中请放在外部，这里为了方便每次都新建
    NSArray *videoConfigs =
    @[
        @{@"bitrate": @"900", @"resolutionName": @"标", @"resolutionDesc": @"标清：360*640", @"resolution": @(TRTCVideoResolution_640_360)},
        @{@"bitrate": @"1200", @"resolutionName": @"高", @"resolutionDesc": @"高清：540*960", @"resolution": @(TRTCVideoResolution_960_540)},
        @{@"bitrate": @"1500", @"resolutionName": @"超", @"resolutionDesc": @"超清：720*1280", @"resolution": @(TRTCVideoResolution_1280_720)}
    ];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"分辨率" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSDictionary *config in videoConfigs) {
        [alert addAction:[UIAlertAction actionWithTitle:config[@"resolutionDesc"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [sender setTitle:config[@"resolutionName"] forState:UIControlStateNormal];
            /// 切换视频直播的画质（标清、高清、超清）
            self.videoEncParam.videoResolution = [config[@"resolution"] intValue];
            self.videoEncParam.videoBitrate = [config[@"bitrate"] intValue];
            [self.trtcCloud setVideoEncoderParam:self.videoEncParam];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

/// 麦克风开启与关闭
- (IBAction)onMicCaptureClicked:(UIButton *)sender {
    if (sender.isSelected) {// 开启采集
        [self.trtcCloud startLocalAudio:TRTCAudioQualityDefault];
    } else {// 关闭采集
        [self.trtcCloud stopLocalAudio];
    }
    sender.selected = !sender.isSelected;
}

/// 摄像头开启与关闭
- (IBAction)onVideoCaptureClicked:(UIButton *)sender {
    if (sender.isSelected) {// 开启采集
        [self.trtcCloud startLocalPreview:self.isFrontCamera view:self.localVideoView];
    } else {// 关闭采集
        [self.trtcCloud stopLocalPreview];
    }
    _videoMutedTipsView.hidden = sender.isSelected;/// 
    sender.selected = !sender.isSelected;
}

/// 禁屏
- (IBAction)onMuteRemoteVideoClicked:(UIButton *)sender {
    NSInteger index = sender.superview.tag;
    if (index < self.remoteUids.count) {
        NSString *remoteUid = self.remoteUids[index];
        [self.trtcCloud muteRemoteVideoStream:remoteUid mute:!sender.isSelected];
        [(LiveSubVideoView *)(sender.superview) muteVideo:!sender.isSelected];
    }
}

/// 禁言
- (IBAction)onMuteRemoteAudioClicked:(UIButton *)sender {
    NSInteger index = sender.superview.tag;
    if (index < self.remoteUids.count) {
        NSString *remoteUid = self.remoteUids[index];
        [self.trtcCloud muteRemoteAudio:remoteUid mute:!sender.isSelected];
        [(LiveSubVideoView *)(sender.superview) muteAudio:!sender.isSelected];
    }
}

/// 显示调试信息
- (IBAction)onDashboardClicked:(UIButton *)sender {
    sender.tag += 1;
    if (sender.tag > 2) {
        sender.tag = 0;
    }
    [self.trtcCloud showDebugView:sender.tag];
}

#pragma mark - TRTCCloudDelegate
/**
 * 当前视频直播房间里的其他用户开启/关闭摄像头时会收到这个回调
 * 此时可以根据这个用户的视频available状态来 “显示或者关闭” Ta的视频画面
 */
- (void)onUserVideoAvailable:(NSString *)userId available:(BOOL)available {
    NSUInteger index = [self.remoteUids indexOfObject:userId];
    if (available) {
        if (index == NSNotFound) {
            return;
        }
        // 添加
        [self.remoteUids addObject:userId];
        [self refreshRemoteVideoViews:self.remoteUids.count-1];
    } else {
        if (index == NSNotFound) {
            return;
        }
        /// 关闭用户userId的视频画面
        //[self.trtcCloud stopRemoteView:userId];
        [self.trtcCloud stopRemoteView:userId streamType:TRTCVideoStreamTypeSmall];
        [self.remoteUids removeObjectAtIndex:index];
        [self refreshRemoteVideoViews:index];
    }
}

- (void)refreshRemoteVideoViews:(NSUInteger)from {
    for (NSUInteger i=from; i<[self.remoteVideoViews count]; i++) {
        if (i<self.remoteUids.count) {
            NSString *remotrUid = self.remoteUids[i];
            self.remoteVideoViews[i].hidden = NO;
            /// 开始显示用户remoteUid的视频画面
            //[self.trtcCloud startRemoteView:remotrUid view:self.remoteVideoViews[i]];
            [self.trtcCloud startRemoteView:remotrUid streamType:TRTCVideoStreamTypeSmall view:self.remoteVideoViews[i]];
        } else {
            [self.remoteVideoViews[i] reset];
            self.remoteVideoViews[i].hidden = YES;
        }
    }
}

/// 有用户进入当前视频直播房间
- (void)onRemoteUserEnterRoom:(NSString *)userId {
    [_roomManager onRemoteUserEnterRoomWithUserId:userId];
}

/// 有用户离开当前视频直播房间
- (void)onRemoteUserLeaveRoom:(NSString *)userId reason:(NSInteger)reason {
    [_roomManager onRemoteUserLeaveRoomWithUserId:userId];
}

/// Lazy
- (NSMutableOrderedSet *)remoteUids {
    if (!_remoteUids) {
        _remoteUids = [[NSMutableOrderedSet alloc] initWithCapacity:MAX_REMOTE_USER_NUM];
    }
    return _remoteUids;
}

- (TRTCCloud *)trtcCloud {
    if (!_trtcCloud) {
        _trtcCloud = [TRTCCloud sharedInstance];
        ///设置TRTCCloud的回调接口
        _trtcCloud.delegate = self;
    }
    return _trtcCloud;
}

- (void)dealloc {
    NSLog(@"---------------------------------------------dealloc: %@", self);
    [TRTCCloud destroySharedIntance];
}

@end
