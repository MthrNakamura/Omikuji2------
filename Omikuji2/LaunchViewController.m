//
//  LaunchViewController.m
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/10/31.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import "LaunchViewController.h"

@interface LaunchViewController ()

@end

@implementation LaunchViewController
@synthesize delegate;

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
    if ([self startUpAsSingleAppMode]) {
        //SingleAppモードとして起動
        
    }
    else {
        //通常のアプリモードとして起動
        
    }
    //コンテンツチェックリストをチェック
    if ([self checkContentsList]) {
        //アップデートが必要
    }
    //アップデート不要なので通常起動
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//コンテンツチェックリストをダウンロードし、
//コンテンツのアップデートが必要かを確認
// YES : コンテンツのアップデートが必要
// NO  : コンテンツはすべて最新
- (BOOL)checkContentsList
{
    //コンテンツチェックリストをダウンロード
    
    
    
    
    
    
    return NO;
}



//SingleAppモードとして立ち上がるかをサーバーに問い合わせる
//YES : SingleAppモードとして立ち上がる
//NO  : 通常のアプリとして立ち上がる
- (BOOL)startUpAsSingleAppMode
{
    NSURL * url = [NSURL URLWithString:@"http://MMacbookPro.local/~motohiro/fotuneteller/single.php?single='no'"];
    NSURLRequest * request = [NSURLRequest requestWithURL:url];
    NSError *error;
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    
    NSString * responseString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"singleApp? %@", responseString);
    if ([responseString isEqualToString:@"yes"]) {
        return YES; //SingleAppモードとして立ち上げる
    }
    return NO; //普通のアプリとして立ち上げる
}

@end
