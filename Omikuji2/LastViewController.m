//
//  LastViewController.m
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/11/04.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import "LastViewController.h"
#import "TopViewController.h"
#import "LaunchViewController.h"

@interface LastViewController ()

@end

@implementation LastViewController

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
    
    self.webView.delegate = self;
    //印刷終了ページをロードし表示する
    NSURL *url = [NSURL URLWithString:@"http://MMacbookPro.local/~motohiro/fotuneteller/last.html"];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:req];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *url = [[request URL]absoluteString];
    if ([url isEqualToString:@"http://mmacbookpro.local/~motohiro/fotuneteller/index.html"]) {
        TopViewController *topViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TopView"];
        [self presentViewController:topViewController animated:YES completion:nil];
    }
    else if ([url isEqualToString:@"http://mmacbookpro.local/~motohiro/fotuneteller/gotoTop.html"]) {
        LaunchViewController *topViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"LaunchView"];
        [self presentViewController:topViewController animated:YES completion:nil];
    }
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
