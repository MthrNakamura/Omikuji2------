//
//  MBProgressViewController.h
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/11/25.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MBProgressViewController : UIViewController
@property (strong, nonatomic) IBOutlet UINavigationBar *navBar;
@property (strong, nonatomic) IBOutlet UITextView *textView;
- (IBAction)finishReading:(id)sender;

@end