//
//  ScreenEntranceViewController.m
//  WYTRTCDemo
//
//  Created by Weep Yan on 2021/3/18.
//

#import "ScreenEntranceViewController.h"
#import "ScreenViewController.h"

@interface ScreenEntranceViewController ()

@property (weak, nonatomic) IBOutlet UITextField *roomIdTextField;
@property (weak, nonatomic) IBOutlet UITextField *userIdTextField;

@end

@implementation ScreenEntranceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"屏幕分享";
    self.roomIdTextField.text = @"1256732";
    self.userIdTextField.text = [NSString stringWithFormat:@"%u", (unsigned int)(CACurrentMediaTime() * 1000)];
    
    SEL sel = @selector(onTapGestureAction:);
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:sel];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *segueId = segue.identifier;
    if (!segueId) {
        return;
    }
    if ([@"beginScreen" isEqualToString: segueId]) {
        ScreenViewController *screenVC = [segue destinationViewController];
        screenVC.roomId = (UInt32)[self.roomIdTextField.text integerValue];
        screenVC.userId = self.userIdTextField.text;
    }
}

- (IBAction)onEnterRoom:(UIButton *)sender {
    
}

- (void)onTapGestureAction:(UITapGestureRecognizer *)sender {
    [self.view endEditing:YES];
}

@end
