//
//  ScreenViewController.m
//  WYTRTCDemo
//
//  Created by Weep Yan on 2021/3/18.
//

#import "ScreenViewController.h"
#import <TRTCCloud.h>
#import "GenerateTestUserSig.h"
#import "WYTRTCDemo-Swift.h"// 引用默认Swift头文件调用swift代码

enum State {
    StateWaiting,
    StateStarted,
    StateStoped
};

static NSString *APPGROUP = @"group.com.tencent.liteav.RPLiveStreamShare";

@interface ScreenViewController () <TRTCCloudDelegate>

@property (weak, nonatomic) IBOutlet UIButton *recordScreenButton;
@property (weak, nonatomic) IBOutlet UIButton *muteButton;
@property (weak, nonatomic) IBOutlet UILabel *recordStateLable;

@property (nonatomic, strong) TRTCParams *params;
@property (nonatomic, strong) TRTCVideoEncParam *videoEncParam;
@property (nonatomic, assign) enum State state;

@property (nonatomic, strong) TRTCCloud *trtcCloud;

@end

@implementation ScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _videoEncParam = [[TRTCVideoEncParam alloc] init];
    _videoEncParam.videoResolution = TRTCVideoResolution_1280_720;
    _videoEncParam.videoFps = 10;
    _videoEncParam.videoBitrate = 1500;
    
    self.state = StateStoped;
    _recordStateLable.text = @"进房中";
    
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
    
    [self.trtcCloud enterRoom:params appScene:TRTCAppSceneLIVE];
    [self.trtcCloud startScreenCaptureByReplaykit:self.videoEncParam appGroup:APPGROUP];
//    [self.trtcCloud startScreenCaptureInApp:self.videoEncParam];
}

- (void)setState:(enum State)state {
    NSDictionary *buttonTitleMap = @{
        [NSString stringWithFormat:@"%d", StateWaiting]:@"等待屏幕分享启动",
        [NSString stringWithFormat:@"%d", StateStarted]:@"停止屏幕分享",
        [NSString stringWithFormat:@"%d", StateStoped]:@"开始屏幕分享"
    };
    [_recordScreenButton setTitle:[buttonTitleMap objectForKey:[NSString stringWithFormat:@"%d", state]] forState:UIControlStateNormal];
    _recordStateLable.hidden = state != StateStoped;
    _state = state;
}

- (IBAction)onTapRecordButton:(id)sender {
    
    if (@available(iOS 11.0, *)) {
        switch (self.state) {
            case StateStarted:
                [self.trtcCloud stopScreenCapture];
                break;
                
            case StateStoped:
                self.state = StateWaiting;
                [self showPicker];
                [self.trtcCloud startScreenCaptureByReplaykit:self.videoEncParam appGroup:APPGROUP];
                break;
                
            case StateWaiting:
                [self showPicker];
                break;
                
            default:
                break;
        }
    }
}

- (void)showPicker {
    if (@available(iOS 12.0, *)) {
        [TRTCBroadcastExtensionLauncher launch];
    }
}

- (IBAction)onTapMuteButton:(UIButton *)sender {
    if (sender.tag == 1) {
        NSLog(@"开始静音");
        [sender setImage:[UIImage imageNamed:@"rtc_mic_off"] forState:UIControlStateNormal];
        sender.tag = 0;
        [self.trtcCloud stopLocalAudio];
    } else {
        NSLog(@"关闭静音");
        [sender setImage:[UIImage imageNamed:@"rtc_mic_on"] forState:UIControlStateNormal];
        sender.tag = 1;
        [self.trtcCloud startLocalAudio:TRTCAudioQualityDefault];
    }
}

#pragma mark - TRTCCloudDelegate
/**
 * 当前视频通话房间里的其他用户开启/关闭摄像头时会收到这个回调
 * 此时可以根据这个用户的视频available状态来 “显示或者关闭” Ta的视频画面
 */
- (void)onEnterRoom:(NSInteger)result {
    _recordStateLable.text = [NSString stringWithFormat:@""
                              @"房间号: %u\n"
                              @"用户名: %@\n"
                              @"分辨率: \"720 x 1280\"\n"
                              @"请在其他设备上使用不同用户名进入相同的房间进行观看",
                              self.roomId, self.userId];
    [self.trtcCloud startLocalAudio:TRTCAudioQualityDefault];
}

- (void)onScreenCaptureStarted {
    self.state = StateStarted;
}

- (void)onScreenCaptureStoped:(int)reason {
    self.state = StateStoped;
}

- (TRTCCloud *)trtcCloud {
    if (!_trtcCloud) {
        _trtcCloud = [TRTCCloud sharedInstance];
        ///设置TRTCCloud的回调接口
        _trtcCloud.delegate = self;
    }
    return _trtcCloud;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.trtcCloud exitRoom];
}

- (void)dealloc {
    [TRTCCloud destroySharedIntance];
}

@end
