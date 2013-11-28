//
//  PrinterErrorViewController.m
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/11/26.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import "PrinterErrorViewController.h"
#import "AppDelegate.h"
#import "TopViewController.h"
#import "AsyncURLConnection.h"
#import "AlertUtil.hpp"
#import "ConnectionUtils.hpp"
#import "LoginViewController.h"

AppDelegate *delegate;


// --- プリンタステータス ---
static NSString *const _PRINTER_STATUS[] =
{
    @"900",
    @"901",
    @"902",
    @"903",
    @"904",
    @"905",
    @"906",
    @"999"
};

enum PRINTER_STATUS : unsigned {
    STATUS_DRAWEROPEN = 0,
    STATUS_MISCUTTING,
    STATUS_HOVERHEAT,
    STATUS_PAPERJAMMED,
    STATUS_PAPEREMPTY,
    STATUS_UNUSUALDATA,
    STATUS_POWERERROR,
    STATUS_NOPAIRING
};

// --- ステータス ---
enum STATUS : unsigned {
    STATUS_PRINT = 0
};

// アラートタイトル
static NSString *const _ALERT_TITLE[] =
{
    @"印刷"
};

@interface PrinterErrorViewController ()

@end

@implementation PrinterErrorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.webView setDelegate:nil];
    [self.webView stopLoading];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    
    self.webView.delegate = self;
    NSURL *url = [NSURL URLWithString:delegate.printErrorUrl];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self miscomplete:delegate.qrErrorCode];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    NSString *url = [[request URL] absoluteString];
    if ([url isEqualToString:delegate.topURL]) {
        TopViewController *topView = [self.storyboard instantiateViewControllerWithIdentifier:@"TopView"];
        [self presentViewController:topView animated:YES completion:nil];
    }
    
    return YES;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSMutableURLRequest *)createCompleteRequest:(NSString *)qrData printResult:(NSInteger)printResult printErrorCode:(NSString *)printErrorCode
{
    //リクエストURLを設定
    NSURL *url = [[NSURL alloc]initWithString:COMPLETE_API];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    // [url release];
    //ヘッダーを設定
    [request setValue:APP_ID forHTTPHeaderField:@"ApplicationId"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:delegate.accessToken forHTTPHeaderField:@"Authorization"];
    
    
    //POSTに設定
    [request setHTTPMethod:@"POST"];
    
    NSLog(@"errorcode: %@", printErrorCode);
    
    //パラメータを設定
    NSArray *vals = [NSArray arrayWithObjects:delegate.qrResult, [NSNumber numberWithInteger:printResult], printErrorCode, nil];
    NSArray *keys = [NSArray arrayWithObjects:@"qrData", @"printResult", @"printErrorCode", nil];
    NSDictionary *param = [NSDictionary dictionaryWithObjects:vals forKeys:keys];
    NSError *error = [[NSError alloc]init];
    NSData *json = [NSJSONSerialization dataWithJSONObject:param options:0 error:&error];
    [request setHTTPBody:json];
    
    NSLog(@"sent: %@", (printErrorCode == 0)?@"正常":@"エラー");
    
    return request;
}

- (void)gobackToLoginView
{
    TopViewController *topView = [self.storyboard instantiateViewControllerWithIdentifier:@"TopView"];
    [self presentViewController:topView animated:YES completion:nil];
}

- (BOOL)checkStatusCode:(NSHTTPURLResponse *)response status:(STATUS)status
{
    // ステータスコードの取得
    auto code = static_cast< ConnectionUtil::HTTP_CODE >( response.statusCode );
    
    // *** 通信に成功したとき ***
    if ( code==ConnectionUtil::CODE_OK ) {
        
        return YES;
    }
    
    // *** 通信に失敗したとき ***
    // アラートの表示
    AlertUtil::showAlert( _ALERT_TITLE[ status ], code );
    
    
    // 認証エラー時はアクセストークンを無効にして、ログアウト
    if (code == ConnectionUtil::CODE_AUTHERROR) {
        
        delegate.accessToken = nil;
        delegate.loggedOut = YES;
        [self gobackToLoginView];
        
    }
    
    return NO;
}

// *** 印刷が正常に行われなかったことをサーバーに伝達 ***
- (void)miscomplete:(NSString *)errorCode
{
    if ([delegate checkNetworkStatus] == NO_NETWORK) {
        
        // *** ネットワーク接続がない
        // アラートの表示
        AlertUtil::showAlert( _ALERT_TITLE[STATUS_PRINT], AlertUtil::NETWORK_ERROR );
        
        //抽選結果を再度表示する
        //[timer invalidate];
        
        return ;
    }
    
    NSMutableURLRequest *request = [self createCompleteRequest:delegate.qrResult printResult:1 printErrorCode:errorCode];
    
    AsyncURLConnection *conn = [[AsyncURLConnection alloc]initWithRequest:request timeoutSec:TIMEOUT_INTERVAL completeBlock:^(AsyncURLConnection *conn, NSData *data) {

        NSLog(@"before");
        // ステータスコードの取得
        auto http_response = (NSHTTPURLResponse *)conn.response;
        [self checkStatusCode:http_response status:STATUS_PRINT];
        NSLog(@"after");
        
    } progressBlock:nil errorBlock:^(id conn, NSError *error) {
        if (error.code == NSURLErrorTimedOut) {
            
            //タイムアウト
            AlertUtil::showAlert(_ALERT_TITLE[STATUS_PRINT], AlertUtil::TIMEDOUT);
            //[timer invalidate];
            
        }
        else {
            //通信エラー
            AlertUtil::showAlert(_ALERT_TITLE[STATUS_PRINT], AlertUtil::NETWORK_ERROR);
            //[timer invalidate];
        }
    }];
    
    [conn performRequest];
    [conn join];
}


@end
