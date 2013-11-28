//
//  VideoViewController.m
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/10/25.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import "VideoViewController.h"
#import "ResultViewController.h"
#import "RasterDocument.h"
#import "StarBitmap.h"
#import <ZXingObjC.h>
#import "AsyncURLConnection.h"

#import "TopViewController.h"


BOOL loading = YES;


int numDownloadingImg = 0;


@interface VideoViewController ()

@end

@implementation VideoViewController
@synthesize delegate;
@synthesize webView;
@synthesize offScreenWindow;

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

	delegate.receiptLoaded = NO;
    
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    
    
    offScreenWindow = [[UIWindow alloc]initWithFrame:CGRectMake(0.0, 0.0, RECEIPT_WIDTH1+10, RECEIPT_HEIGHT)];
    webView = [[UIWebView alloc]initWithFrame:CGRectMake(0.0, 0.0, RECEIPT_WIDTH1+10, RECEIPT_HEIGHT)];
    webView.delegate = self;
    [offScreenWindow addSubview:webView];
    
    //印刷する内容の画像をwebViewに表示
    NSString *htmlString = [self convertPrintInfo2Receipt:delegate.printInfo];
    [webView loadHTMLString:htmlString baseURL:nil];
    loading = YES;
    
//    NSURLCache *cache = [NSURLCache sharedURLCache];
//    [cache removeAllCachedResponses];
    
}


- (void)viewDidAppear:(BOOL)animated
{
    
    [super viewDidAppear:animated];
    
    [self playMovie];
    
    
    
    
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [webView setDelegate:nil];
    [webView stopLoading];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    //webViewがレシート画像の読み込みに失敗
    //AlertUtil::showAlert(@"レシート", @"レシートの取得に失敗しました");
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"レシート" message:@"レシートの取得に失敗しました" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alertView show];
    
    //Top画面に戻す
    TopViewController *topView = [self.storyboard instantiateViewControllerWithIdentifier:@"TopView"];
    [self presentViewController:topView animated:YES completion:nil];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    
    loading = NO;
}

- (void)playMovie
{
    //動画ファイルのパスを取得
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *videoName = [NSString stringWithFormat:@"%@.mp4", delegate.movieId];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:videoName];
    //プレイヤーに動画をセット
    moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:dataPath]];
    moviePlayer.moviePlayer.controlStyle = MPMovieControlStyleNone; //コントロールバーを非表示に
    //再生完了を検知する
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(MPMoviePlayerPlaybackDidFinishNotification) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    //画面いっぱいに動画を表示
    [moviePlayer.view setBounds:CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width)];
    [moviePlayer.view setCenter:CGPointMake(self.view.frame.size.height/2, self.view.frame.size.width/2)];
    [self.view addSubview:moviePlayer.view];
}

- (BOOL)prefersStatusBarHidden {return YES;}

- (void)MPMoviePlayerPlaybackDidFinishNotification
{
    //MoviePlayerを破棄
    [moviePlayer.view removeFromSuperview];
    
    while (loading) {
        usleep(100);
    }
    
    //レシート画像を作成
    delegate.receiptImage = [self imageFromWebView];
    delegate.receiptLoaded = YES;
    //[self.view addSubview:webView];
    
    
    //動画再生終了後画面に移動
    ResultViewController *resultView = [self.storyboard instantiateViewControllerWithIdentifier:@"ResultView"];
    [self presentViewController:resultView animated:YES completion:nil];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}


- (void)saveImage:(NSData *)imageData
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"icon.png"];
    //NSFileManager *fileManager = [NSFileManager defaultManager];
    [imageData writeToFile:dataPath atomically:YES];
    NSLog(@"saved!");
}

- (void)downloadImage:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *imageData = [[NSData alloc]initWithContentsOfURL:url];
    
    NSArray *dirs = [urlString componentsSeparatedByString:@"/"];
    //[self performSelectorOnMainThread:@selector(saveImage:) withObject:imageData waitUntilDone:NO];
    //保存
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[dirs objectAtIndex:dirs.count-1]];
    //NSFileManager *fileManager = [NSFileManager defaultManager];
    
    [imageData writeToFile:dataPath atomically:YES];
}

- (NSString *)convertPrintInfo2Receipt:(NSString *)printInfo
{
    //QRコード
    NSRegularExpression *regexQR = [[NSRegularExpression alloc]initWithPattern:@"(<qr src=\")(.*?)(\" size=\")(.*?)(\">)" options:0 error:nil];
    NSArray *result = [regexQR matchesInString:printInfo options:0 range:NSMakeRange(0, printInfo.length)];
    NSString *qrString = [[NSString alloc]init];
    int qrSize = 0;
    for (int i = 0; i < result.count; i++) {
        NSTextCheckingResult *res = [result objectAtIndex:i];
        qrString = [printInfo substringWithRange:[res rangeAtIndex:2]];
        qrSize = [[printInfo substringWithRange:[res rangeAtIndex:4]] intValue];
    }
    NSString *qrHtml = [NSString stringWithFormat:@"<img src=\"http://chart.apis.google.com/chart?chs=%dx%d&cht=qr&chl=%@\" width=\"%d\" height=\"%d\" style=\"margin-left: %dpx;\"><br>", qrSize, qrSize, qrString, qrSize, qrSize, (RECEIPT_WIDTH1-qrSize)/2];
    NSRegularExpression *regexQR2 = [[NSRegularExpression alloc]initWithPattern:@"(<qr src=\".*?\" size=\".*?\">)" options:0 error:nil];
    NSString *printInfo2 = [regexQR2 stringByReplacingMatchesInString:printInfo options:0 range:NSMakeRange(0, printInfo.length) withTemplate:qrHtml];

    //NSLog(@"print: %@", printInfo);
    //フォントサイズを変更
    NSRegularExpression *regex = [[NSRegularExpression alloc]initWithPattern:@"(<font size=\".*?\">)" options:0 error:nil];
    printInfo = [regex stringByReplacingMatchesInString:printInfo2 options:NSMatchingReportProgress range:NSMakeRange(0, printInfo.length) withTemplate:@"<font size=\"4\">"];
    //[regex release];
    //NSLog(@"info: %@", printInfo);
    //Image
    NSString *receiptString = [NSString stringWithFormat:@"<html><body style=\"width:%dpx\">%@</body></html>", RECEIPT_WIDTH1, printInfo];
    NSLog(@"print: %@", receiptString);
    return receiptString;
}


- (UIImage *)imageFromWebView
{
    CGRect screenRect = CGRectMake(0, 0, RECEIPT_WIDTH2, RECEIPT_HEIGHT); //webView.bounds;
    
    UIGraphicsBeginImageContext(screenRect.size);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor whiteColor]set];
    CGContextFillRect(ctx, screenRect);
    
    [webView.layer renderInContext:ctx];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}
@end
