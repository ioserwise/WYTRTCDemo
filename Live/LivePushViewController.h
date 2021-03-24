//
//  LivePushViewController.h
//  WYTRTCDemo
//
//  Created by Weep Yan on 2021/3/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LivePushViewController : UIViewController

@property (nonatomic, assign) UInt32 roomId;
@property (nonatomic, copy) NSString *userId;

@end

NS_ASSUME_NONNULL_END
