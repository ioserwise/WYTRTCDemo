//
//  RTCEntranceViewController.m
//  WYTRTCDemo
//
//  Created by Weep Yan on 2021/3/15.
//

#import "RTCEntranceViewController.h"
#import "RTCViewController.h"

@interface RTCEntranceViewController ()

@property (weak, nonatomic) IBOutlet UITextField *roomIdTextField;
@property (weak, nonatomic) IBOutlet UITextField *userIdTextField;

@end

@implementation RTCEntranceViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.roomIdTextField.text = @"1256732";
    self.userIdTextField.text = [NSString stringWithFormat:@"%u", (unsigned int)(CACurrentMediaTime() * 1000)];
    
    SEL sel = @selector(onTapGestureAction:);
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:sel];
    [self.view addGestureRecognizer:tapGesture];
}

- (IBAction)onEnterRoom:(UIButton *)sender {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"RTC" bundle:nil];
    RTCViewController *rtcVC = [storyBoard instantiateViewControllerWithIdentifier:@"RTCViewController"];
    if (!rtcVC) {
        return;
    }
    rtcVC.roomId = [self.roomIdTextField.text intValue] ?: 1256732;
    rtcVC.userId = self.userIdTextField.text ?: [NSString stringWithFormat:@"%u", (unsigned int)(CACurrentMediaTime() * 1000)];
    [self.navigationController pushViewController:rtcVC animated:YES];
}

- (void)onTapGestureAction:(UITapGestureRecognizer *)sender {
    [self.view endEditing:YES];
}

@end
