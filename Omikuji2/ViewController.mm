//
//  ViewController.m
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/10/25.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import "ViewController.h"
#import "TopViewController.h"
#import "ResultViewController.h"
#import "VideoViewController.h"
#import "LaunchViewController.h"
#import "ManagementViewController.h"
#import "AsyncURLConnection.h"
#import "LoginViewController.h"
#import "PrinterErrorViewController.h"

#import "AlertUtil.hpp"


BOOL isFirstLoad;
BOOL playMovie = NO;


// --- ステータス ---
enum STATUS : unsigned {
    STATUS_ACTION = 0 //抽選
};

//アラートタイトル
static NSString *const _ALERT_TITLE[] =
{
    @"抽選"
};

@interface ViewController () {
    BOOL isViewDidAppeared;
}
@property (nonatomic, retain) ZXCapture *zxcapture;
@end

BOOL isFrontCamera = YES;

@implementation ViewController
@synthesize zxcapture;
@synthesize delegate;

- (BOOL)prefersStatusBarHidden {return YES;}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    isViewDidAppeared = NO;
    
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSLog(@"[QR]numLoop: %d", delegate.numLoop);
    delegate.numLoop++;
    
    self.webView.delegate = self;
    
    isFirstLoad = YES;
    
    NSString *urlString = delegate.qrURL;
    NSURL * url = [NSURL URLWithString:urlString];
    [self.webView setBackgroundColor:[UIColor clearColor]];
    [self.webView setOpaque:NO];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    [self.webView stringByEvaluatingJavaScriptFromString:
     /* ページのスタイルを透明に指定 */
     @"document.body.style.gackgroundColor = \"transparent\";"
     /* QRコード読み込みページに遷移する関数を定義する */
     "var cameraChange = function() { window.location = \"omikuji://cameraChange\"; };"
    ];
}

- (void)viewWillDisappear:(BOOL)animated
{
    isViewDidAppeared = NO;
    
    [super viewWillDisappear:animated];
    [self.webView setDelegate:nil];
    [self.webView stopLoading];
    
    [zxcapture.layer removeFromSuperlayer];
    [zxcapture setDelegate:nil];
    [zxcapture stop];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    isViewDidAppeared = NO;
    
    //QRコード読み取り画面を表示
    [self readQR];
    
    [self.view bringSubviewToFront:self.webView];
    
    //カメラ映像を自然にする
    CGAffineTransform transform = CGAffineTransformMakeRotation(-M_PI_2);
    [zxcapture setTransform:transform];
    CGRect f = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    self.view.layer.frame=f;
    zxcapture.layer.frame = f;
    
    [zxcapture start];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    isViewDidAppeared = YES;
}


- (void)captureResult:(ZXCapture *)capture result:(ZXResult *)result
{
    // ビューが表示されていなければ無視
    if ( !isViewDidAppeared ) return;
    
    
    //ネットワーク接続を確認
    if ([delegate checkNetworkStatus] == NO_NETWORK) {
        
        // *** ネットワーク接続がない ***
        //アラートの表示
        AlertUtil::showAlert( _ALERT_TITLE[ STATUS_ACTION ],
                             AlertUtil::NETWORK_ERROR );
        
        
        //スキャン再開
        [zxcapture start];
        return ;
    }
    
    //サーバーに結果を送信し確認
    NSMutableURLRequest *request = [self createQRRequest:result.text];
    
    if (![self sendQRRequestAsyncronously:request]) {
       return ; //QR読み込み再開
    }
    

    delegate.qrResult = result.text;
    
    
    if (![delegate.qrErrorCode isEqualToString:@"0000"]) {
        //QRコードエラーページに遷移
        delegate.printErrorUrl = delegate.afterMovieURL;
        PrinterErrorViewController *printErrorView = [self.storyboard instantiateViewControllerWithIdentifier:@"PrinterErrorView"];
        [self presentViewController:printErrorView animated:YES completion:nil];
        return ;
    }
    
        
    CFStringTransform((CFMutableStringRef)delegate.printInfo, NULL, CFSTR("Any-Hex/Java"), YES);
    
    //動画を再生
    //再生する動画のIDを取得
    VideoViewController *videoView = [self.storyboard instantiateViewControllerWithIdentifier:@"VideoView"];
    [self presentViewController:videoView animated:YES completion:nil];
    
    
    //次のアクションを決定
    if ([delegate.qrErrorCode isEqualToString:@"0000"]) {
        //動画を再生
        //再生する動画のIDを取得
        VideoViewController *videoView = [self.storyboard instantiateViewControllerWithIdentifier:@"VideoView"];
        [self presentViewController:videoView animated:YES completion:nil];
    }
}

- (void)readQR
{
    zxcapture = [[ZXCapture alloc] init];
    zxcapture.delegate = self;
    
    //正面カメラを使う
    zxcapture.camera = (isFrontCamera)? zxcapture.front:zxcapture.back;
    zxcapture.layer.frame = self.view.bounds;
    [self.view.layer addSublayer:zxcapture.layer];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    if (isFirstLoad) {
        isFirstLoad = NO;
        return YES;
    }
    
    NSString *url = [[request URL] absoluteString];
    if ([url isEqualToString:delegate.qrURL]) {
//        [zxcapture.layer removeFromSuperlayer];
//        [zxcapture stop];
        //[self dismissViewControllerAnimated:YES completion:nil];
        TopViewController *topView = [self.storyboard instantiateViewControllerWithIdentifier:@"TopView"];
        [self presentViewController:topView animated:YES completion:nil];
    }
    else if ([url hasPrefix:@"omikuji://"]) {
        url = [url stringByReplacingOccurrencesOfString:@"omikuji://" withString:@""];
        if ([url isEqualToString:@"cameraChange"]) {
            //カメラを切り替える
            isFrontCamera = !isFrontCamera;
            zxcapture.camera = (isFrontCamera)? zxcapture.front:zxcapture.back;
        }
        return NO;
    }
    
    
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    //ロードインジケータを表示
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    //ロードインジケータを非表示に
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if ([error code] != NSURLErrorCancelled) {
        NSString *message = [error localizedDescription];
        NSLog(@"error: %@", message);
    }
}


- (NSMutableURLRequest *)createQRRequest:(NSString *)qrResult
{    NSURL *url = [[NSURL alloc]initWithString:LOT_API];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    //[url release];
    
    //ヘッダーを設定
    [request setValue:APP_ID forHTTPHeaderField:@"ApplicationId"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:delegate.accessToken forHTTPHeaderField:@"Authorization"];
    
    //POSTに設定
    [request setHTTPMethod:@"POST"];
    
    //パラメータを設定
    NSDictionary *param = [NSDictionary dictionaryWithObjectsAndKeys:qrResult, @"qrData", nil];
    NSError *error;
    NSData *json = [NSJSONSerialization dataWithJSONObject:param options:0 error:&error];
    
    [request setHTTPBody:json];
    
    return request;
}

- (BOOL)sendQRRequestAsyncronously:(NSMutableURLRequest *)request
{
    __block BOOL validQR = YES;
    
    AsyncURLConnection *conn = [[AsyncURLConnection alloc] initWithRequest:request timeoutSec:TIMEOUT_INTERVAL completeBlock:^(AsyncURLConnection *conn, NSData *data) {
        
        NSError *error = [[NSError alloc]init];
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
        //QRコードにエラーがないか
        delegate.qrErrorCode = [jsonData objectForKey:@"errorCode"];
        
        
        delegate.movieId = [jsonData objectForKey:@"contentsId"];
        delegate.afterMovieURL = [jsonData objectForKey:@"nextUrl"];
        if ([jsonData objectForKey:@"printInfo"] == [NSNull null]) {
            delegate.printInfo = nil;
        }
        else {
            delegate.printInfo = [jsonData objectForKey:@"printInfo"];
        }
        if ([[jsonData objectForKey:@"type"]intValue] == 0) {
            playMovie = YES;
            delegate.resultMovieId = [jsonData objectForKey:@"contentsId"];
        }
        else {
            playMovie = NO;
        }
        
       
        // ステータスコードの取得
        auto http_response = (NSHTTPURLResponse *)conn.response;
        if (![self checkStatusCode:http_response status:STATUS_ACTION])
            validQR = NO;
        
        
    } progressBlock:nil errorBlock:^(id conn, NSError *error) {
        if (error.code == NSURLErrorTimedOut) {
            //タイムアウト
            AlertUtil::showAlert(_ALERT_TITLE[STATUS_ACTION], AlertUtil::TIMEDOUT);
        }
        else {
            //通信エラー
            AlertUtil::showAlert(_ALERT_TITLE[STATUS_ACTION], AlertUtil::NETWORK_ERROR);
            validQR = NO;
        }
    }];
    [conn performRequest];
    
    [conn join];
    
    return validQR;
}

- (NSDictionary *)sendQRRequestSynchronously:(NSMutableURLRequest *)request
{
    NSError *error;
    NSURLResponse *response;
    NSData *responseData =  [NSURLConnection sendSynchronousRequest:request
                                                  returningResponse:&response error:&error];
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (![self checkStatusCode:httpResponse.statusCode])
        return nil;
    
    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
    NSLog(@"jsondata: %@", jsonData);
    return jsonData;
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


- (BOOL)checkErrorCode:(NSString *)errorCode
{
    if ([errorCode isEqualToString:@"0000"]) {
        return YES;
    }
    if ([errorCode isEqualToString:@"0001"]) {
        delegate.qrErrorMsg = (@"QRエラー: 不正なシリアルナンバー");
    }
    else if ([errorCode isEqualToString:@"0002"]) {
        NSLog(@"QRエラー: 有効期限前");
        return YES;
    }
    else if ([errorCode isEqualToString:@"0003"]) {
        delegate.qrErrorMsg = (@"QRエラー: 有効期限切れ");
    }
    else if ([errorCode isEqualToString:@"0004"]) {
        delegate.qrErrorMsg = (@"QRエラー: 回数上限オーバー");
    }
    else if ([errorCode isEqualToString:@"0005"]) {
        delegate.qrErrorMsg = (@"QRエラー: 1ユーザーでのトータル回数制限オーバー");
    }
    else if ([errorCode isEqualToString:@"0006"]) {
        delegate.qrErrorMsg = (@"QRエラー: 1日あたりの全ユーザーの回数制限オーバー");
    }
    else if ([errorCode isEqualToString:@"0007"]) {
        delegate.qrErrorMsg = (@"QRエラー: 1日あたりの1ユーザ（1シリアル）の回数制限オーバー");
    }
    else if ([errorCode isEqualToString:@"0008"]) {
        NSLog(@"QRエラー: 時間帯制限前");
        return YES;
    }
    else if ([errorCode isEqualToString:@"0009"]) {
        delegate.qrErrorMsg = (@"QRエラー: 時間帯制限後");
    }
    else if ([errorCode isEqualToString:@"0010"]) {
        delegate.qrErrorMsg = (@"QRエラー: 連続利用制限エラー");
    }
    else if ([errorCode isEqualToString:@"0008"]) {
        delegate.qrErrorMsg = (@"QRエラー: 利用可能店舗外エラー");
    }
    else if ([errorCode isEqualToString:@"0009"]) {
        delegate.qrErrorMsg = (@"QRエラー: 当選最大数エラー");
    }
    
    return NO;
}

- (void)gobackToLoginView
{
    LoginViewController *loginView = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginView"];
    [self presentViewController:loginView animated:YES completion:nil];
}

- (void)resumeQR
{
    
}

@end
