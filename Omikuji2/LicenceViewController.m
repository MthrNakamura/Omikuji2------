//
//  LicenceViewController.m
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/11/04.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import "LicenceViewController.h"

@interface LicenceViewController ()

@end

@implementation LicenceViewController

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
    
    //Apache Licence v2.0のページを表示
    self.webView.delegate = self;
    
    NSURL *url = [NSURL URLWithString:@"http://www.apache.org/licenses/LICENSE-2.0.html"];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:req];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)finishReading:(id)sender {
    //画面を閉じる
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
