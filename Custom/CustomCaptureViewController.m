//
//  CustomCaptureViewController.m
//  WYTRTCDemo
//
//  Created by Weep Yan on 2021/3/17.
//

#import "CustomCaptureViewController.h"
#import <TRTCCloud.h>
#import "GenerateTestUserSig.h"
#import "TestSendCustomVideoData.h"
#import "TestRenderVideoFrame.h"

static int MAX_REMOTE_USER_NUM = 6;

@interface CustomCaptureViewController () <TRTCCloudDelegate>

@property (weak, nonatomic) IBOutlet NSMutableArray<UIView *> *remoteVideoViews;
@property (weak, nonatomic) IBOutlet UIImageView *localVideoView;
@property (weak, nonatomic) IBOutlet UILabel *roomIdLabel;

@property (nonatomic, strong) NSMutableOrderedSet *remoteUids;
@property (nonatomic, strong) TRTCCloud *trtcCloud;
@property (nonatomic, strong) TestSendCustomVideoData *videoCaptureTester;
@property (nonatomic, strong) TestRenderVideoFrame *renderTester;

@end

@implementation CustomCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
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
    
    /// 指定以“视频通话场景”（TRTCAppScene.videoCall）进入房间
    [self.trtcCloud enterRoom:params appScene:TRTCAppSceneVideoCall];
    
    /// 设置视频通话的画质（帧率 15fps，码率550, 分辨率 360*640）
    TRTCVideoEncParam *videoEncParam = [[TRTCVideoEncParam alloc] init];
    videoEncParam.videoResolution = TRTCVideoResolution_640_360;
    videoEncParam.videoBitrate = 550;
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
    
    if (self.localVideoAsset) {
        /// 设置使用自定义视频
        [self videoCaptureTester];
        
        [self.trtcCloud enableCustomAudioCapture:YES];
        [self.trtcCloud enableCustomVideoCapture:YES];
        [self.trtcCloud setLocalVideoRenderDelegate:self.renderTester pixelFormat:TRTCVideoPixelFormat_NV12 bufferType:TRTCVideoBufferType_PixelBuffer];
        [self.renderTester addUser:nil videoView:self.localVideoView];
        [self.videoCaptureTester start];
    }
}

- (IBAction)onExitRoomClicked:(UIButton *)sender {
    /// 退出视频通话房间
    [self.trtcCloud exitRoom];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - TRTCCloudDelegate
/**
 * 当前视频通话房间里的其他用户开启/关闭摄像头时会收到这个回调
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
            self.remoteVideoViews[i].hidden = YES;
        }
    }
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

- (TestSendCustomVideoData *)videoCaptureTester {
    if (!_videoCaptureTester) {
        _videoCaptureTester = [[TestSendCustomVideoData alloc] initWithTRTCCloud:self.trtcCloud mediaAsset:self.localVideoAsset ?: [[AVAsset alloc] init]];
    }
    return _videoCaptureTester;
}

- (TestRenderVideoFrame *)renderTester {
    if (!_renderTester) {
        _renderTester = [[TestRenderVideoFrame alloc] init];
    }
    return _renderTester;
}

- (void)dealloc {
    [TRTCCloud destroySharedIntance];
}

@end
