//
//  CustomCaptureViewController.h
//  WYTRTCDemo
//
//  Created by Weep Yan on 2021/3/17.
//

#import <UIKit/UIKit.h>

@class AVAsset;

NS_ASSUME_NONNULL_BEGIN

@interface CustomCaptureViewController : UIViewController

@property (nonatomic, assign) UInt32 roomId;
@property (nonatomic, copy) NSString *userId;

@property (nonatomic, strong) AVAsset *localVideoAsset;

@end

NS_ASSUME_NONNULL_END
