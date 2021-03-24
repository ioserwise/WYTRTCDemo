//
//  CustomEntranceViewController.m
//  WYTRTCDemo
//
//  Created by Weep Yan on 2021/3/17.
//

#import "CustomEntranceViewController.h"
#import "CustomCaptureViewController.h"
#import <QBImagePickerController/QBImagePickerController.h>
#import <Photos/Photos.h>

@interface CustomEntranceViewController () <QBImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *roomIdTextField;
@property (weak, nonatomic) IBOutlet UITextField *userIdTextField;

@property (nonatomic, strong) AVAsset *localVideoAsset;

@end

@implementation CustomEntranceViewController

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
    QBImagePickerController *picker = [[QBImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    picker.showsNumberOfSelectedAssets = YES;
    picker.minimumNumberOfSelection = 1;
    picker.maximumNumberOfSelection = 1;
    picker.mediaType = QBImagePickerMediaTypeVideo;
    picker.title = @"请选择视频";
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController pushViewController:picker animated:YES];
}

- (void)enterCustomCaptureRoom:(AVAsset *)sender {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"CustomCapture" bundle:nil];
    CustomCaptureViewController *ccVC = [storyBoard instantiateViewControllerWithIdentifier:@"CustomCaptureViewController"];
    if (!ccVC) {
        return;
    }
    ccVC.roomId = [self.roomIdTextField.text intValue] ?: 1256732;
    ccVC.userId = self.userIdTextField.text ?: [NSString stringWithFormat:@"%u", (unsigned int)(CACurrentMediaTime() * 1000)];
    ccVC.localVideoAsset = self.localVideoAsset;
    [self.navigationController pushViewController:ccVC animated:YES];
}

- (void)onTapGestureAction:(UITapGestureRecognizer *)sender {
    [self.view endEditing:YES];
}

#pragma - QBImagePickerControllerDelegate
- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets {
    [self.navigationController popViewControllerAnimated:NO];
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = YES;
    
    __weak typeof(self) wself = self;
    [[PHImageManager defaultManager] requestAVAssetForVideo:[assets firstObject] options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(wself) sself = wself;
            [sself enterCustomCaptureRoom:asset];
        });
    }];
    
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
