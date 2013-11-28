//
//  ResultViewController.m
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/10/25.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import "LoginViewController.h"
#import "ResultViewController.h"
#import "TopViewController.h"
#import "LastViewController.h"
#import "RasterDocument.h"
#import "StarBitmap.h"
#import "LaunchViewController.h"
#import "PrinterErrorViewController.h"
#import "AsyncURLConnection.h"

#import "AlertUtil.hpp"

#import <sys/time.h>

// --- 抽選結果画面のアラートタイトル ---
static NSString *const ALERT_TITLE = @"抽選結果";

BOOL validRequest;

@interface ResultViewController () {
    AppDelegate *delegate;
}
@end

@implementation ResultViewController
@synthesize webView;
//@synthesize result;


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
    
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    //透明のwebViewを表示
    //まずはHTMLをダウンロード
    self.webView.delegate = self;
    validRequest = YES;
    NSURL * url = [[NSURL alloc] initWithString:delegate.afterMovieURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection connectionWithRequest:request delegate:self];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.webView setDelegate:nil];
    [self.webView stopLoading];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!validRequest) {
        [self gobackToLoginView];
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"start loading");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"finish loading");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"fail to load: %@", error);
    [self gobackToLoginView];
}

// **************************************************************
// * Web画面遷移のフック
// **************************************************************
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *url = [[request URL] absoluteString];
    if ([url hasPrefix:@"omikuji://"]) {
        url = [url stringByReplacingOccurrencesOfString:@"omikuji://" withString:@""];
        if ([url isEqualToString:@"print"]) {
            if (![self getPrinterStatus]) {
                PrinterErrorViewController *perrorView = [self.storyboard instantiateViewControllerWithIdentifier:@"PrinterErrorView"];
                [self presentViewController:perrorView animated:YES completion:nil];
                return NO;
            }
            //クーポンを印刷する
            
            [NSThread detachNewThreadSelector:@selector(PrintRasterSampleReceipt3InchWithPortname) toTarget:self withObject:nil];
            //[self PrintRasterSampleReceipt3InchWithPortname];
            //正常に印刷されたかどうかを確認
            if (![self isFinishedPrintingSafely]) {
                return NO;
            }
            else {
                //サーバーに印刷結果を送信
                [self complete];
                
            }
            //TOP画面に戻る
            TopViewController *topView = [self.storyboard instantiateViewControllerWithIdentifier:@"TopView"];
            [self presentViewController:topView animated:YES completion:nil];
        }
        
        return NO;
    }
   if ([url isEqualToString:delegate.topURL] || [url isEqualToString:@"http://t.bemss.jp/appsdev01/html/index.html"]) {
        //待受け画面に戻る
        TopViewController *topView = [self.storyboard instantiateViewControllerWithIdentifier:@"TopView"];
        [self presentViewController:topView animated:YES completion:nil];
    }
    
    return YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300)
    {
        [connection cancel];
        NSLog(@"status: %d", httpResponse.statusCode);
        validRequest = NO;
        return ;
    }
    
    
    //[connection cancel];
    
    NSLog(@"status: %d", httpResponse.statusCode);
    
    [self.webView loadRequest:connection.originalRequest];
        
    [self.webView stringByEvaluatingJavaScriptFromString:
     /* ページのスタイルを透明に指定 */
     @"document.body.style.gackgroundColor = \"transparent\";"
     /* 印刷する関数を埋め込む */
     "var couponPrint = function() { window.location = \"omikuji://print\"; };"
     ];
}

- (void)complete
{
    __block BOOL finishedSafely = YES;
    
    if ([delegate checkNetworkStatus] == NO_NETWORK) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"ネットワーク" message:@"ネットワークに接続されていません。ネットワーク状態をお確かめください。" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        return ;
    }
    
    NSMutableURLRequest *request = [self createCompleteRequest:delegate.qrResult printResult:0 printErrorCode:nil];
    
    AsyncURLConnection *conn = [[AsyncURLConnection alloc]initWithRequest:request timeoutSec:TIMEOUT_INTERVAL completeBlock:^(AsyncURLConnection *conn, NSData *data) {
        UIAlertView *alertView;
        switch (conn.response.statusCode) {
            case 400:
                alertView = [[UIAlertView alloc]initWithTitle:@"抽選結果" message:@"致命的なエラーです。管理者にご連絡ください。" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alertView show];
                finishedSafely = NO;
                break;
            case 401:
                alertView = [[UIAlertView alloc]initWithTitle:@"抽選結果" message:@"認証に失敗しました。再度ログインしてください。" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alertView show];
                finishedSafely = NO;
                break;
            case 500:
                alertView = [[UIAlertView alloc]initWithTitle:@"抽選結果" message:@"サーバーエラーです。管理者にご連絡ください。" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alertView show];
                finishedSafely = NO;
                break;
            default:
                break;
        }
        
    } progressBlock:nil errorBlock:^(id conn, NSError *error) {
        if (error.code == NSURLErrorTimedOut) {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"抽選結果" message:@"タイムアウトです。再度お試しください。" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
            finishedSafely = NO;
        }
        else {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"コンテンツリスト" message:@"ネットワークに接続されていません。接続状況をご確認ください。" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
            finishedSafely = NO;
        }
    }];
    
    [conn performRequest];
    
}

- (BOOL)checkCompleteStatus:(NSHTTPURLResponse *)httpResponse
{
    switch (httpResponse.statusCode) {
        case 200:
            NSLog(@"通知成功");
            return YES;
        case 400:
            AlertUtil::showAlert( ALERT_TITLE, AlertUtil::INVALID_PARAM );
            break;
        case 401:
            AlertUtil::showAlert( ALERT_TITLE, AlertUtil::AUTH_ERROR );
            break;
        case 403:
            AlertUtil::showAlert( ALERT_TITLE, AlertUtil::STATUS_ERROR );
            break;
        case 500:
            AlertUtil::showAlert( ALERT_TITLE, AlertUtil::SERVER_ERROR );
            break;
        default:
            break;
    }
 
    auto defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:@"uname"];
    [defaults setObject:nil forKey:@"passwd"];
    delegate.accessToken = nil;
    delegate.loggedOut = YES;
    [self gobackToLoginView];
    
    return NO;
}

- (BOOL)sendCompleteRequest:(NSMutableURLRequest *)request
{
    NSError *error;
    NSURLResponse *response;
    NSData *responseData =  [NSURLConnection sendSynchronousRequest:request
                                                  returningResponse:&response error:&error];
    
    //NSLog(@"response: %@", [[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding]);
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (![self checkCompleteStatus:httpResponse])
        return NO;
    
    NSDictionary *jsonResponse =  [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
    
    NSLog(@"errorCode: complete: %@", [jsonResponse objectForKey:@"errorCode"]);
    
    return YES;
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
    [request setValue:delegate.accessToken forHTTPHeaderField:@"Authorization"];

    
    //POSTに設定
    [request setHTTPMethod:@"POST"];
    
    
    //パラメータを設定
    NSArray *vals = [NSArray arrayWithObjects:delegate.qrResult, [NSNumber numberWithInteger:printResult], nil];
    NSArray *keys = [NSArray arrayWithObjects:@"qrData", @"printResult", nil];
    NSDictionary *param = [NSDictionary dictionaryWithObjects:vals forKeys:keys];
    NSError *error;
    NSData *json = [NSJSONSerialization dataWithJSONObject:param options:0 error:&error];
    [request setHTTPBody:json];

    
    return request;
}

- (BOOL)isFinishedPrintingSafely
{
    //プリンタの状態を取得
    
    return YES;
}

//Bluetoothプリンタの状態を確認する
- (BOOL)getPrinterStatus
{
    BOOL condition = YES;
    SMPort *starPort;
    @try {
        starPort = [SMPort getPort:DEFAULT_PORTNAME :@"" :TIMEOUT_TIME];
        if (starPort == nil) {
//            alertView = [[UIAlertView alloc]initWithTitle:@"通信エラー" message:@"プリンタに接続できませんでした。管理者にご連絡ください。" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//            [alertView show];
            delegate.printErrorUrl = delegate.pairingUrl;
            return NO;
        }
        
        StarPrinterStatus_2 status;
        [starPort getParsedStatus:&status :2];
        
        //カバーが開いている
        if ( status.coverOpen ) {
            delegate.printErrorUrl = delegate.drawerOpenURL;
            condition = NO;
        }
        else if ( status.cutterError ) {
            delegate.printErrorUrl = delegate.failedCutURL;
            condition = NO;
        }
        else if ( status.overTemp )
        {
            delegate.printErrorUrl = delegate.headerTempURL;
            condition = NO;
        }
        else if ( status.presenterPaperJamError ) {
            delegate.printErrorUrl = delegate.paperJammedURL;
            condition = NO;
        }
        else if ( status.receiveBufferOverflow ) {
            delegate.printErrorUrl = delegate.unusualDataURL;
            condition = NO;
        }
        else if ( status.voltageError ) {
            delegate.printErrorUrl = delegate.powerErrorURL;
            condition = NO;
        }
    }
    @catch (PortException *e) {
        
    }
    @finally
    {
        [SMPort releasePort:starPort];
    }
    return condition;
}

//Bluetoothプリンタに印刷用コマンドを送信する
- (void)sendCommand:(NSData *)commandToPrint portName:(NSString *)portName portSettings:(NSString *)portSettings timeoutMillis:(u_int32_t)timeoutMillis
{
    int commandSize = [commandToPrint length];
    unsigned char *dataToSentToPrinter = (unsigned char *)malloc(commandSize);
    [commandToPrint getBytes:dataToSentToPrinter];
    SMPort *starPort;
    @try
    {
        starPort = [SMPort getPort:DEFAULT_PORTNAME :@"" :TIMEOUT_TIME];
        if (starPort == nil)
        {
            AlertUtil::showAlert( @"通信エラー", @"プリンタに接続できませんでした。管理者にご連絡ください。" );
            return;
        }
        
        StarPrinterStatus_2 status;
        [starPort beginCheckedBlock:&status :2];
        if ( status.offline ) {
            
            AlertUtil::showAlert( @"通信エラー", @"プリンタに接続できませんでした。管理者にご連絡ください。" );
            return;
        }
        
        struct timeval endTime;
        gettimeofday(&endTime, NULL);
        endTime.tv_sec += 30;
        
        int totalAmountWritten = 0;
        while (totalAmountWritten < commandSize)
        {
            int remaining = commandSize - totalAmountWritten;
            int amountWritten = [starPort writePort:dataToSentToPrinter :totalAmountWritten :remaining];
            totalAmountWritten += amountWritten;
            
            struct timeval now;
            gettimeofday(&now, NULL);
            if (now.tv_sec > endTime.tv_sec)
            {
                break;
            }
        }
        
        if (totalAmountWritten < commandSize)
        {
            AlertUtil::showAlert( @"印刷エラー", AlertUtil::getMsg( AlertUtil::TIMEDOUT ) );
            return;
        }
        
        [starPort endCheckedBlock:&status :2];
        if ( status.offline ) {
            AlertUtil::showAlert( @"印刷エラー", @"プリンタに接続できませんでした。管理者にご連絡ください。" );
            return;
        }
    }
    @catch (PortException *exception)
    {
        AlertUtil::showAlert( @"印刷エラー", AlertUtil::getMsg( AlertUtil::TIMEDOUT )  );
    }
    @finally
    {
        free(dataToSentToPrinter);
        [SMPort releasePort:starPort];
    }
}

- (void)PrintImageWithPortname:(NSString *)portName portSettings:(NSString*)portSettings imageToPrint:(UIImage*)imageToPrint maxWidth:(int)maxWidth compressionEnable:(BOOL)compressionEnable withDrawerKick:(BOOL)drawerKick
{
    RasterDocument *rasterDoc = [[RasterDocument alloc] initWithDefaults:RasSpeed_Medium endOfPageBehaviour:RasPageEndMode_FeedAndFullCut endOfDocumentBahaviour:RasPageEndMode_FeedAndFullCut topMargin:RasTopMargin_Standard pageLength:0 leftMargin:0 rightMargin:0];
    StarBitmap *starbitmap = [[StarBitmap alloc] initWithUIImage:imageToPrint :maxWidth :false];
    
    NSMutableData *commandsToPrint = [[NSMutableData alloc] init];
    NSData *shortcommand = [rasterDoc BeginDocumentCommandData];
    [commandsToPrint appendData:shortcommand];
    
    shortcommand = [starbitmap getImageDataForPrinting:compressionEnable];
    [commandsToPrint appendData:shortcommand];
    
    shortcommand = [rasterDoc EndDocumentCommandData];
    [commandsToPrint appendData:shortcommand];
    
    if (drawerKick == YES) {
        [commandsToPrint appendBytes:"\x07"
                              length:sizeof("\x07") - 1];    // KickCashDrawer
    }
    
   
    [self sendCommand:commandsToPrint portName:portName portSettings:portSettings timeoutMillis:10000];
}

- (BOOL)prefersStatusBarHidden {return YES;}

//ラスター形式の幅3インチのレシートを印刷する
- (void)PrintRasterSampleReceipt3InchWithPortname//:(NSString *)portName portSettings:(NSString *)portSettings
{
    UIImage *rotImage = [self imageRotatedByRadians:M_PI image:delegate.receiptImage width:delegate.receiptImage.size.width height:delegate.receiptImage.size.height];
        delegate.receiptImage = [UIImage imageWithCGImage:delegate.receiptImage.CGImage scale:delegate.receiptImage.scale orientation:UIImageOrientationRight];
        delegate.receiptImage = [UIImage imageWithCGImage:delegate.receiptImage.CGImage scale:delegate.receiptImage.scale orientation:UIImageOrientationRight];

    
    [self PrintImageWithPortname:DEFAULT_PORTNAME portSettings:@"" imageToPrint:rotImage maxWidth:RECEIPT_WIDTH2 compressionEnable:YES withDrawerKick:YES];
    
    
//    [self PrintImageWithPortname:portName  portSettings:portSettings imageToPrint:delegate.receiptImage maxWidth:RECEIPT_WIDTH1 compressionEnable:YES withDrawerKick:YES];
//
    //プリンタの状態を確認
}


- (void)gobackToLoginView
{
    delegate.loggedOut = YES;
    LoginViewController *loginView = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginView"];
    [self presentViewController:loginView animated:YES completion:nil];
}

- (UIImage *)imageRotatedByRadians:(CGFloat)radians image:(UIImage *)image width:(NSInteger)width height:(NSInteger)height
{
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,width, height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(radians);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //Rotate the image context
    CGContextRotateCTM(bitmap, radians);
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-width / 2, -height / 2, width, height), [image CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
