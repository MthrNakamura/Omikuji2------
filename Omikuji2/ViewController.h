//
//  ViewController.h
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/10/25.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#import <AVFoundation/AVFoundation.h>


@interface ViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate, UIWebViewDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) AppDelegate *delegate;


- (BOOL)startCamera;
- (NSMutableURLRequest *)createQRRequest:(NSString *)qrResult;
- (NSDictionary *)sendQRRequestSynchronously:(NSMutableURLRequest *)request;

- (BOOL)sendQRRequestAsyncronously:(NSMutableURLRequest *)request;
- (BOOL)checkStatusCode:(NSInteger)status;
- (BOOL)checkErrorCode:(NSString *)errorCode;
- (void)gobackToLoginView;
- (void)resumeQR;

@end
