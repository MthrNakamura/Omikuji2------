//
//  ZXingViewController.m
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/11/25.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import "ZXingViewController.h"
#import "OSSNaviViewController.h"

@interface ZXingViewController ()

@end

@implementation ZXingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL)prefersStatusBarHidden {return YES;}
- (IBAction)finishReading:(id)sender {
    OSSNaviViewController *naviView = [self.storyboard instantiateViewControllerWithIdentifier:@"OSSNavView"];
    [self presentViewController:naviView animated:YES completion:nil];
}
@end
