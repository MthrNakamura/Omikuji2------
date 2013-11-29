//
//  ViewController.h
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/10/25.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ZXingObjC.h>
#import "AppDelegate.h"



@interface ViewController : UIViewController <ZXCaptureDelegate, UIWebViewDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property AppDelegate *delegate;

- (void)readQR;
- (NSMutableURLRequest *)createQRRequest:(NSString *)qrResult;
- (NSDictionary *)sendQRRequestSynchronously:(NSMutableURLRequest *)request;

- (BOOL)sendQRRequestAsyncronously:(NSMutableURLRequest *)request;
- (BOOL)checkStatusCode:(NSInteger)status;
- (BOOL)checkErrorCode:(NSString *)errorCode;
- (void)gobackToLoginView;
- (void)resumeQR;

//ステータスコードを確認して適宜アラートを表示

//- (UIImage *)imageFromWebView:(UIWebView *)wView;
//- (UIWebView *)webViewFromString:(NSString *)receiptString;
@end
