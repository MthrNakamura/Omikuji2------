//
//  LaunchViewController.h
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/10/31.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface LaunchViewController : UIViewController {
    AppDelegate *delegate;
}
@property (strong, nonatomic)AppDelegate *delegate;

- (BOOL)startUpAsSingleAppMode;
- (BOOL)checkContentsList;

@end

