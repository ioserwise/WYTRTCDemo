//
//  LivePlayViewController.m
//  WYTRTCDemo
//
//  Created by Weep Yan on 2021/3/17.
//

#import "LivePlayViewController.h"
#import "WYTRTCDemo-Swift.h"// 引用默认Swift头文件调用swift代码
#import <TRTCCloud.h>
#import "GenerateTestUserSig.h"

static int MAX_REMOTE_USER_NUM = 6;

@interface LivePlayViewController () <TRTCCloudDelegate>

@property (weak, nonatomic) IBOutlet NSMutableArray<LiveSubVideoView *> *remoteVideoViews;
@property (weak, nonatomic) IBOutlet LiveSubVideoView *localVideoView;
@property (weak, nonatomic) IBOutlet UIButton *switchCameraButton;
@property (weak, nonatomic) IBOutlet UIView *roomOwnerVideoView;
@property (weak, nonatomic) IBOutlet UIView *videoMutedTipsView;
@property (weak, nonatomic) IBOutlet UILabel *roomIdLabel;

@property (nonatomic, strong) NSMutableOrderedSet *remoteUids;
@property (nonatomic, assign) BOOL isOwnerVideoStopped;
@property (nonatomic, assign) BOOL isFrontCamera;
@property (nonatomic, strong) TRTCVideoEncParam *videoEncParam;

@property (nonatomic, strong) LiveRoomManager *roomManager;
@property (nonatomic, strong) TRTCCloud *trtcCloud;

@end

@implementation LivePlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.roomOwner = [NSString stringWithFormat:@"%u", self.roomId];
    self.roomIdLabel.text = self.roomOwner;
    
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
    params.role = TRTCRoleAudience;// 观众身份
    
    /// userSig是进入房间的用户签名，相当于密码（这里生成的是测试签名，正确做法需要业务服务器来生成，然后下发给客户端）
    params.userSig = [GenerateTestUserSig genTestUserSig:params.userId];
    
    /// 指定以“在线直播场景”（TRTCAppScene.LIVE）进入房间
    [self.trtcCloud enterRoom:params appScene:TRTCAppSceneLIVE];
    
    /// 设置直播房间的画质（帧率 15fps，码率400, 分辨率 270*480）
    TRTCVideoEncParam *videoEncParam = [[TRTCVideoEncParam alloc] init];
    videoEncParam.videoResolution = TRTCVideoResolution_480_270;
    videoEncParam.videoBitrate = 400;
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
}

/// 退出视频直播房间
- (IBAction)onExitLiveClicked:(UIButton *)sender {
    
    [self.trtcCloud exitRoom];
    [self.navigationController popViewControllerAnimated:YES];
}

/// 与主播连麦
- (IBAction)onLinkMicClicked:(UIButton *)sender {
    if (sender.isSelected) {// 停止连麦
        [self.trtcCloud switchRole:TRTCRoleAudience];
        [self.trtcCloud stopLocalAudio];
        [self.trtcCloud stopLocalPreview];
        
        [self.localVideoView reset];
        self.localVideoView.hidden = YES;
        self.switchCameraButton.hidden = YES;
        
    } else {// 发起连麦
        self.localVideoView.hidden = NO;
        self.switchCameraButton.hidden = NO;
        
        [self.trtcCloud switchRole:TRTCRoleAnchor];
        //[self.trtcCloud startLocalAudio];
        [self.trtcCloud startLocalAudio:TRTCAudioQualityDefault];
        [self.trtcCloud startLocalPreview:self.isFrontCamera view:self.localVideoView];
    }
    sender.selected = !sender.isSelected;
}

/// 禁屏
- (IBAction)onMuteRoomOwnerVideoClicked:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    /// 打开/关闭当前房主的直播视频画面
    [self.trtcCloud muteRemoteVideoStream:self.roomOwner mute:!sender.isSelected];
    [self.roomManager muteRemoteVideoForUser:self.roomOwner muted:sender.isSelected];
    self.videoMutedTipsView.hidden = !(sender.isSelected || self.isOwnerVideoStopped);
}

/// 禁言
- (IBAction)onMuteRoomOwnerAudioClicked:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    /// 打开/关闭当前房主的声音
    [self.trtcCloud muteRemoteAudio:self.roomOwner mute:sender.isSelected];
    [self.roomManager muteRemoteAudioForUser:self.roomOwner muted:sender.isSelected];
}

/// 显示调试信息
- (IBAction)onDashboardClicked:(UIButton *)sender {
    sender.tag += 1;
    if (sender.tag > 2) {
        sender.tag = 0;
    }
    [self.trtcCloud showDebugView:sender.tag];
}

/// 连麦之后，切换自己的前置/后置摄像头
- (IBAction)onSwitchCameraClicked:(UIButton *)sender {
    //[self.trtcCloud switchCamera];
    [[self.trtcCloud getDeviceManager] switchCamera:self.isFrontCamera];
    self.isFrontCamera = sender.isSelected;
    sender.selected = !sender.isSelected;
}

/// 麦克风开启与关闭
- (IBAction)onMuteRemoteAudioClicked:(UIButton *)sender {
    if (self.localVideoView == sender.superview) {
        /// 连麦之后，打开/关闭自己的麦克风
        if (sender.isSelected) {
                [self.trtcCloud startLocalAudio:TRTCAudioQualityDefault];
        } else {
            [self.trtcCloud stopLocalAudio];
        }
        [self.localVideoView muteAudio:!sender.isSelected];
    } else {
        NSUInteger index = sender.superview.tag;
        if (index < self.remoteUids.count) {
            /// 打开/关闭指定uid的远程用户的声音
            NSString *remoteUid = self.remoteUids[index];
            [self.trtcCloud muteRemoteAudio:remoteUid mute:!sender.isSelected];
            [(LiveSubVideoView *)sender.superview muteAudio:!sender.isSelected];
        }
    }
}

/// 摄像头开启与关闭
- (IBAction)onMuteRemoteVideoClicked:(UIButton *)sender {
    if (self.localVideoView == sender.superview) {
        if (sender.isSelected) {
            /// 连麦之后，打开/关闭自己的摄像头
            [self.trtcCloud startLocalPreview:self.isFrontCamera view:self.localVideoView];
        } else {
            [self.trtcCloud stopLocalPreview];
        }
        
        [self.localVideoView muteVideo:!sender.isSelected];
    } else {
        NSUInteger index = sender.superview.tag;
        if (index < self.remoteUids.count) {
            /// 打开/关闭指定uid的远程用户的视频画面
            NSString *remoteUid = self.remoteUids[index];
            [self.trtcCloud muteRemoteVideoStream:remoteUid mute:!sender.isSelected];
            [(LiveSubVideoView *)sender.superview muteVideo:!sender.isSelected];
        }
    }
}

#pragma mark - TRTCCloudDelegate
/**
 * 当前视频直播房间里的其他用户开启/关闭摄像头时会收到这个回调
 * 此时可以根据这个用户的视频available状态来 “显示或者关闭” Ta的视频画面
 */
- (void)onUserVideoAvailable:(NSString *)userId available:(BOOL)available {
    if ([userId isEqualToString:self.roomOwner]) {
        [self refreshRoomOwnerVideoView:available];
        return;
    }
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
            self.remoteVideoViews[i].hidden = YES;
        }
    }
}

- (void)refreshRoomOwnerVideoView:(BOOL)available {
    if (available) {
        [self.trtcCloud startRemoteView:self.roomOwner streamType:TRTCVideoStreamTypeSmall view:self.roomOwnerVideoView];
    } else {
        [self.trtcCloud startPublishing:self.roomOwner type:TRTCVideoStreamTypeSmall];
    }
    self.isOwnerVideoStopped = !available;
    self.videoMutedTipsView.hidden = !([self.roomManager isVideoMutedForUser:self.roomOwner] || self.isOwnerVideoStopped);
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

