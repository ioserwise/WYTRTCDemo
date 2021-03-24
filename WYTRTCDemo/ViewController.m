//
//  ViewController.m
//  WYTRTCDemo
//
//  Created by Weep Yan on 2021/3/15.
//

#import "ViewController.h"
#import "ScreenEntranceViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"TRTC示例教程";
}

// 视频通话
- (IBAction)onRTCClicked:(UIButton *)sender {
    [self presentStoryboard:@"RTC" isLocalVideo:NO];
}

// 视频直播
- (IBAction)onLiveClicked:(UIButton *)sender {
    [self presentStoryboard:@"Live" isLocalVideo:NO];
}

// 自定义采集
- (IBAction)onCustomCaptureClicked:(UIButton *)sender {
    NSLog(@"自定义采集适合比较有特性的某些场景..有兴趣的可以参考官方demo");
    [self presentStoryboard:@"CustomCapture" isLocalVideo:YES];
}

- (void)presentStoryboard:(NSString *)name isLocalVideo:(BOOL)isLocalVideo {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:name bundle:nil];
    UIViewController *vc = storyBoard.instantiateInitialViewController;
    if (!vc) {
        return;
    }
    [self.navigationController pushViewController:vc animated:YES];
}

// 屏幕录制
- (IBAction)onScreenClicked:(UIButton *)sender {
    [self presentStoryboard:@"Screen" isLocalVideo:NO];
}

@end
