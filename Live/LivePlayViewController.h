//
//  LivePlayViewController.h
//  WYTRTCDemo
//
//  Created by Weep Yan on 2021/3/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LivePlayViewController : UIViewController

@property (nonatomic, assign) UInt32 roomId;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *roomOwner;

@end

NS_ASSUME_NONNULL_END
