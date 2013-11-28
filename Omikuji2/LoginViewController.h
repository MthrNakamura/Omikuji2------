//
//  LoginViewController.h
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/11/11.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface LoginViewController : UIViewController<MBProgressHUDDelegate>

@property (strong, nonatomic) IBOutlet UITextField *userNameField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;

- (IBAction)doLogin:(id)sender;
- (IBAction)finishEnteringUserName:(id)sender;
- (IBAction)finishEnteringPassword:(id)sender;

@end
