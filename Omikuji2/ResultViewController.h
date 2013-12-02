//
//  ResultViewController.h
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/10/25.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StarIO/SMPort.h>
#import "AppDelegate.h"



#define TIMEOUT_TIME 10000
#define DEFAULT_PORTNAME @"BT:Star Micronics"




@interface ResultViewController : UIViewController <UIWebViewDelegate, NSURLConnectionDelegate> {
    NSString *result;
}
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) AppDelegate *delegate;

- (void)PrintRasterSampleReceipt3InchWithPortname;//:(NSString *)portName portSettings:(NSString *)portSettings;

- (void)complete;
- (void)miscomplete:(NSString *)errorCode;

- (NSMutableURLRequest *)createCompleteRequest:(NSString *)qrData printResult:(NSInteger)printResult printErrorCode:(NSString *)printErrorCode;
- (BOOL)sendCompleteRequest:(NSMutableURLRequest *)request;
- (BOOL)checkCompleteStatus:(NSHTTPURLResponse *)httpResponse;
- (BOOL)isFinishedPrintingSafely;
- (void)gobackToLoginView;
- (void)gobackToTopView;
- (UIImage *)imageRotatedByRadians:(CGFloat)radians image:(UIImage *)image width:(NSInteger)width height:(NSInteger)height;
@end
