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
#import "ConnectionUtils.hpp"

#import <sys/time.h>

// *** TOP画面に遷移するタイミング ***
#define RELOAD_INTERVAL 5



BOOL validRequest;

//NSTimer *timer;

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
    STATUS_COMPLETE = 0,
    STATUS_PRINT
};

// アラートタイトル
static NSString *const _ALERT_TITLE[] =
{
    @"抽選完了", @"印刷"
};

@interface ResultViewController () {
    BOOL isViewDidApper;
    BOOL wantGoToErrorPage;
}

@end

@implementation ResultViewController
@synthesize webView;
@synthesize delegate;
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
    
    isViewDidApper = FALSE;
    wantGoToErrorPage = FALSE;
    
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //RELOAD_INTERVAL秒後に自動的にTopViewに戻る
    //timer = [NSTimer scheduledTimerWithTimeInterval:RELOAD_INTERVAL target:self selector:@selector(gobackToTopView) userInfo:Nil repeats:YES];

    
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
    
    @synchronized ( self ) {
        isViewDidApper = YES;
        if ( wantGoToErrorPage ) {
            [self gotoErrorPage];
        }
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

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    NSString *url = [[request URL] absoluteString];
    if ([url hasPrefix:@"omikuji://"]) {
        url = [url stringByReplacingOccurrencesOfString:@"omikuji://" withString:@""];
        if ([url isEqualToString:@"print"]) {
            
            
            //プリンタの状態を確認
            delegate.pError = [self getPrinterStatus];
            
            
            //正常に印刷が行われた
            if ([delegate.pError isEqualToString:@""]) {
                
                //印刷終了まではアプリが強制終了しないようにする
                //delegate.networking = YES;

                //クーポンを印刷する
                [NSThread detachNewThreadSelector:@selector(PrintRasterSampleReceipt3InchWithPortname) toTarget:self withObject:nil];

                
                //印刷終了後は強制終了してもいい
            }
            //印刷にエラーがあった
            else {
                
                //印刷にエラーがあったことをサーバーに伝える
                [self miscomplete:delegate.pError];
                
                @synchronized ( self ) {
                    if ( isViewDidApper ) [self gotoErrorPage];
                    else wantGoToErrorPage = YES;
                }                
            }
        }
        return NO;
    }
   if ([url isEqualToString:delegate.topURL]) {
       //正常に行われたことをサーバーに伝える
       //サーバーからのレスポンスで、バーコードに問題があれば抽選結果画面を表示したままにする
       //[self complete];
       
       
        //待受け画面に戻る
        TopViewController *topView = [self.storyboard instantiateViewControllerWithIdentifier:@"TopView"];
        [self presentViewController:topView animated:YES completion:nil];
    }
    
    return YES;
}

- (void)gotoErrorPage {
    
    // 問題があればエラー画面に遷移する
    PrinterErrorViewController *perrorView = [self.storyboard instantiateViewControllerWithIdentifier:@"PrinterErrorView"];
    //[timer invalidate];
    [self presentViewController:perrorView animated:YES completion:nil];

}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300)
    {
        //コンテンツに問題があった場合には不正なリクエストとする
        [connection cancel];
        validRequest = NO;
        
        //コンテンツに問題があることをアラートで表示
        NSString *msg = [NSString stringWithFormat:@"ステータスコード: %d。管理者にご連絡ください。", httpResponse.statusCode];
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"コンテンツ取得" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        
        return ;
    }
    
    
    [connection cancel];
    
    [self.webView loadRequest:connection.originalRequest];

    [self.webView stringByEvaluatingJavaScriptFromString:
     /* ページのスタイルを透明に指定 */
     @"document.body.style.gackgroundColor = \"transparent\";"
     /* 印刷する関数を埋め込む */
     "var couponPrint = function() { window.location = \"omikuji://print\"; };"
     ];
}

//*** 印刷が正常に行われたことをサーバーに伝達 ***
- (void)complete
{
    
    if ([delegate checkNetworkStatus] == NO_NETWORK) {
        
        // *** ネットワーク接続がない
        // アラートの表示
        AlertUtil::showAlert( _ALERT_TITLE[ STATUS_COMPLETE ],
                             AlertUtil::NETWORK_ERROR );
        
        //抽選結果を再度表示する
        //[timer invalidate];
        
        return ;
    }
    
    NSMutableURLRequest *request = [self createCompleteRequest:delegate.qrResult printResult:0 printErrorCode:nil];
    
    AsyncURLConnection *conn = [[AsyncURLConnection alloc]initWithRequest:request timeoutSec:TIMEOUT_INTERVAL completeBlock:^(AsyncURLConnection *conn, NSData *data) {
        NSLog(@"成功");
        
        
        NSLog(@"status: %d", ((NSHTTPURLResponse *)conn.response).statusCode);
        NSLog(@"data: %@", [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
        
        
        // ステータスコードの取得
        auto http_response = (NSHTTPURLResponse *)conn.response;
        if (![self checkStatusCode:http_response status:STATUS_COMPLETE])
            ;//[timer invalidate];
        
        
    } progressBlock:nil errorBlock:^(id conn, NSError *error) {
        if (error.code == NSURLErrorTimedOut) {
            
            //タイムアウト
            AlertUtil::showAlert(_ALERT_TITLE[STATUS_COMPLETE], AlertUtil::TIMEDOUT);
            //[timer invalidate];
        }
        else {
//通信エラー
            AlertUtil::showAlert(_ALERT_TITLE[STATUS_COMPLETE], AlertUtil::NETWORK_ERROR);
            //[timer invalidate];
        }
    }];
    
    [conn performRequest];
    [conn join];
    
}

// *** 印刷が正常に行われなかったことをサーバーに伝達 ***
- (void)miscomplete:(NSString *)errorCode
{
    if ([delegate checkNetworkStatus] == NO_NETWORK) {
        
        // *** ネットワーク接続がない
        // アラートの表示
        AlertUtil::showAlert( _ALERT_TITLE[ STATUS_COMPLETE ],
                             AlertUtil::NETWORK_ERROR );
        
        //抽選結果を再度表示する
        //[timer invalidate];
        
        return ;
    }
    
    NSMutableURLRequest *request = [self createCompleteRequest:delegate.qrResult printResult:1 printErrorCode:errorCode];
    
    AsyncURLConnection *conn = [[AsyncURLConnection alloc]initWithRequest:request timeoutSec:TIMEOUT_INTERVAL completeBlock:^(AsyncURLConnection *conn, NSData *data) {
        
        
        // ステータスコードの取得
        auto http_response = (NSHTTPURLResponse *)conn.response;
        [self checkStatusCode:http_response status:STATUS_COMPLETE];
        
        
        
    } progressBlock:nil errorBlock:^(id conn, NSError *error) {
        if (error.code == NSURLErrorTimedOut) {
            
            
            //タイムアウト
            AlertUtil::showAlert(_ALERT_TITLE[STATUS_COMPLETE], AlertUtil::TIMEDOUT);
            
            
        }
        else {
            
            
            //通信エラー
            AlertUtil::showAlert(_ALERT_TITLE[STATUS_COMPLETE], AlertUtil::NETWORK_ERROR);
            
            
        }
    }];
    
    [conn performRequest];
    [conn join];
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

- (BOOL)checkCompleteStatus:(NSHTTPURLResponse *)httpResponse
{
    
    // ステータスコードの取得
    int code = httpResponse.statusCode;
    
    // *** 通信に成功したとき ***
    if ( code==ConnectionUtil::CODE_OK ) {
        
        return YES;
    }
    
    // *** 通信に失敗したとき ***
    // アラートの表示
    AlertUtil::showAlert( _ALERT_TITLE[ STATUS_COMPLETE ], AlertUtil::NETWORK_ERROR );
    
    
    // 認証エラー時はアクセストークンを無効にして、ログアウト
    if (code == ConnectionUtil::CODE_AUTHERROR) {
        
        
    
        [self gobackToLoginView];
        
    }
    
    
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
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:delegate.accessToken forHTTPHeaderField:@"Authorization"];

    
    //POSTに設定
    [request setHTTPMethod:@"POST"];

    
    //成功パラメーターを送信
    if (!printErrorCode) {
        //パラメータを設定
        NSArray *vals = [NSArray arrayWithObjects:delegate.qrResult, [NSNumber numberWithInteger:printResult], nil];
        NSArray *keys = [NSArray arrayWithObjects:@"qrData", @"printResult", nil];
        NSDictionary *param = [NSDictionary dictionaryWithObjects:vals forKeys:keys];
        NSError *error;
        NSData *json = [NSJSONSerialization dataWithJSONObject:param options:0 error:&error];
        [request setHTTPBody:json];
        
        return request;
    }
    //失敗パラメーターを送信
    //パラメータを設定
    NSArray *vals = [NSArray arrayWithObjects:delegate.qrResult, [NSNumber numberWithInteger:printResult], printErrorCode, nil];
    NSArray *keys = [NSArray arrayWithObjects:@"qrData", @"printResult", @"printErrorCode", nil];
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
- (NSString *)getPrinterStatus
{
    NSString *condition = [[NSString alloc]init];
    SMPort *starPort;
    @try {
        
        starPort = [SMPort getPort:DEFAULT_PORTNAME :@"" :TIMEOUT_TIME];
        if (starPort == nil) {
            delegate.printErrorUrl = delegate.pairingUrl;
            condition = _PRINTER_STATUS[STATUS_NOPAIRING];
            [SMPort releasePort:starPort];
            return condition;
        }
        
        StarPrinterStatus_2 status;
        [starPort getParsedStatus:&status :2];
        
        //カバーが開いている
        if (status.coverOpen == SM_TRUE) {
            delegate.printErrorUrl = delegate.drawerOpenURL;
            condition = _PRINTER_STATUS[STATUS_DRAWEROPEN];
        }
        //カッターエラー
        else if (status.cutterError == SM_TRUE) {
            delegate.printErrorUrl = delegate.failedCutURL;
            condition = _PRINTER_STATUS[STATUS_MISCUTTING];
        }
        //ヘッダーオーバーヒート
        else if (status.overTemp == SM_TRUE)
        {
            delegate.printErrorUrl = delegate.headerTempURL;
            condition = _PRINTER_STATUS[STATUS_HOVERHEAT];
        }
        //紙詰まり
        else if (status.presenterPaperJamError == SM_TRUE) {
            delegate.printErrorUrl = delegate.paperJammedURL;
            condition = _PRINTER_STATUS[STATUS_PAPERJAMMED];
        }
        //異常な量のデータをプリンタが受信
        else if (status.receiveBufferOverflow  == SM_TRUE) {
            delegate.printErrorUrl = delegate.unusualDataURL;
            condition = _PRINTER_STATUS[STATUS_UNUSUALDATA];
        }
        //電源異常
        else if (status.voltageError  == SM_TRUE) {
            delegate.printErrorUrl = delegate.powerErrorURL;
            condition = _PRINTER_STATUS[STATUS_POWERERROR];
        }
        //紙切れ
        else if (status.receiptPaperEmpty == SM_TRUE ) {
            delegate.printErrorUrl = delegate.paperEmptyURL;
            condition = _PRINTER_STATUS[STATUS_PAPEREMPTY];
        }
        //紙が入っていない
//        else if (status.presenterState == '\0') {
//            delegate.printErrorUrl = delegate.paperEmptyURL;
//            condition = _PRINTER_STATUS[STATUS_PAPEREMPTY];
//        }
        
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
- (BOOL)sendCommand:(NSData *)commandToPrint portName:(NSString *)portName portSettings:(NSString *)portSettings timeoutMillis:(u_int32_t)timeoutMillis
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
            AlertUtil::showAlert(_ALERT_TITLE[STATUS_PRINT], @"プリンタに接続できませんでした。管理者にご連絡ください。");
            
            return NO;
        }
        
        StarPrinterStatus_2 status;
        [starPort beginCheckedBlock:&status :2];
        
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
            
            AlertUtil::showAlert(_ALERT_TITLE[STATUS_PRINT], @"タイムアウトです。再度お試しください。");

            return NO;
        }
        
        [starPort endCheckedBlock:&status :2];
        if (status.offline == SM_TRUE) {
            AlertUtil::showAlert(_ALERT_TITLE[STATUS_PRINT], @"プリンタに接続できませんでした。管理者にご連絡ください。");
            
            return NO;
        }
    }
    @catch (PortException *exception)
    {
        
        AlertUtil::showAlert(_ALERT_TITLE[STATUS_PRINT], @"タイムアウトです。再度お試しください。");
        
        return NO;
    }
    @finally
    {
        free(dataToSentToPrinter);
        [SMPort releasePort:starPort];
    }
    return YES;
}

- (BOOL)PrintImageWithPortname:(NSString *)portName portSettings:(NSString*)portSettings imageToPrint:(UIImage*)imageToPrint maxWidth:(int)maxWidth compressionEnable:(BOOL)compressionEnable withDrawerKick:(BOOL)drawerKick
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
    
   
    return [self sendCommand:commandsToPrint portName:portName portSettings:portSettings timeoutMillis:10000];
    
}

- (BOOL)prefersStatusBarHidden {return YES;}

//ラスター形式の幅3インチのレシートを印刷する
- (void)PrintRasterSampleReceipt3InchWithPortname//:(NSString *)portName portSettings:(NSString *)portSettings
{
    
    BOOL success = YES;
    
    if (!delegate.receiptImage) {
        AlertUtil::showAlert(_ALERT_TITLE[STATUS_PRINT], @"レシートの取得に失敗したました。再度お試しください。");
        success = NO;
    }
    
    if (success) {
        
    // レシートイメージを180度回転させる
    UIImage *rotImage = [self imageRotatedByRadians:M_PI image:delegate.receiptImage width:delegate.receiptImage.size.width height:delegate.receiptImage.size.height];
        delegate.receiptImage = [UIImage imageWithCGImage:delegate.receiptImage.CGImage scale:delegate.receiptImage.scale orientation:UIImageOrientationRight];

    //印刷を実行
        success = [self PrintImageWithPortname:DEFAULT_PORTNAME portSettings:@"" imageToPrint:rotImage maxWidth:RECEIPT_WIDTH2 compressionEnable:YES withDrawerKick:YES];
    }
    
    if (success ) {
        [self complete];
    }
    else {
        [self miscomplete:@"999"];
    }
    
    //印刷が終了したらアプリを強制終了してもいい
    //delegate.networking = NO;
}


- (void)gobackToLoginView
{
    // アクセストークンを無効にする
    delegate.accessToken = nil;
    delegate.loggedOut = YES;
    
    LoginViewController *loginView = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginView"];
    [self presentViewController:loginView animated:YES completion:nil];
}

- (void)gobackToTopView
{
    TopViewController *topView = [self.storyboard instantiateViewControllerWithIdentifier:@"TopView"];
    [self presentViewController:topView animated:YES completion:nil];
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
