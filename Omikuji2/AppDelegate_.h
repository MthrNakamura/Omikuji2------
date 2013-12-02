//
//  AppDelegate.h
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/10/25.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import <UIKit/UIKit.h>

//#define PRODUCTION    // 本番環境?

#ifdef PRODUCTION
// 本番環境設定

#define APP_ID @"p7plrv4ithyh5387"

#define LOGIN_API @"http://mdh.fm/btapi/serial/auth/login"
#define LOGOUT_API @"http://mdh.fm/btapi/serial/auth/logout"
#define CHECK_API @"http://mdh.fm/btapi/serial/serial/auth/check"
#define LIST_API  @"http://mdh.fm/btapi/serial/contents/list"
#define DOWNLOAD_API @"http://mdh.fm/btapi/serial/contents/download"
#define LOT_API @"http://mdh.fm/btapi/serial/lot/action"
#define COMPLETE_API @"http://mdh.fm/btapi/serial/lot/complete"

#define VERSION_INFO @"1.0.6"

#else
// テスト環境設定

#define APP_ID @"2md0sy2sty2yjh79"

#define LOGIN_API @"http://dev02.betrend.com/btapi/serial/auth/login"
#define LOGOUT_API @"http://dev02.betrend.com/btapi/serial/auth/logout"
#define CHECK_API @"http://dev02.betrend.com/btapi/serial/serial/auth/check"
#define LIST_API  @"http://dev02.betrend.com/btapi/serial/contents/list"
#define DOWNLOAD_API @"http://dev02.betrend.com/btapi/serial/contents/download"
#define LOT_API @"http://dev02.betrend.com/btapi/serial/lot/action"
#define COMPLETE_API @"http://dev02.betrend.com/btapi/serial/lot/complete"

#define VERSION_INFO @"0.2.6"

#endif  // PRODUCTION

//#define LOGIN_STATUS 1

#define RECEIPT_WIDTH1 384
#define RECEIPT_WIDTH2 576
#define RECEIPT_HEIGHT 1512

#define TIME_TO_LONG_TAP 4

#define UPDATE_INTERVAL 3600

#define TIMEOUT_INTERVAL 20

#define TOP_FILENAME @"machiuke"
#define QR_FILENAME  @"qr_rayer"

#define CONTENTS_TOPURL    100
#define CONTENTS_QR_RAYER  101
#define CONTENTS_MOVIE     200
#define CONTENTS_SOUND     300

#define ERROR_DRAWEROPENED 900
#define ERROR_FAILEDTOCUT  901
#define ERROR_HEADERTEMP   902
#define ERROR_PAPERJAMMED  903
#define ERROR_PAPEREMPTY   904
#define ERROR_UNUSUALDATA  905
#define ERROR_POWERERROR   906
#define ERROR_PAIRING      999

#define NUM_LOOP 4

#define NO_NETWORK   0
#define NETWORK_3G   1
#define NETWORK_WIFI 2

#define CONTENTSLIST_KEY @"contents"

//レシートデータ用の構造体
//<font>データ
//typedef struct {
//    NSString *fontString;
//    int fontSize;
//}font_data;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    NSString *accessToken;
    BOOL singleAppMode;
    BOOL loggedOut;
    NSDictionary *contentsList;
    NSString *movieId;
    NSString *soundId;
    NSString *topURL;
    NSString *qrURL;
    NSString *resultURL;
    NSString *resultMovieId;
    NSString *afterMovieURL;
    NSString *printInfo;
    NSString *drawerOpenURL;
    NSString *failedCutURL;
    NSString *headerTempURL;
    NSString *paperEmptyURL;
    NSString *paperJammedURL;
    NSString *unusualDataURL;
    NSString *powerErrorURL;
    NSString *qrErrorMsg;
    NSString *qrResult;
    UIImage *receiptImage;
    NSString *printErrorUrl;
    NSString *pairingURL;
    BOOL receiptLoaded;
    NSString *qrErrorCode;
    NSString *pError;
    BOOL networking;
}
@property BOOL networking;
@property (strong, nonatomic) NSString *pError;
@property (strong, nonatomic) NSString *qrErrorCode;
@property (nonatomic) BOOL receiptLoaded;
@property (strong, nonatomic) NSString *pairingUrl;
@property (strong, nonatomic) NSString *printErrorUrl;
@property (strong, nonatomic) UIImage *receiptImage;
@property (strong, nonatomic) NSString *qrResult;
@property (strong, nonatomic) NSString *qrErrorMsg;
@property (strong, nonatomic) NSString *paperEmptyURL;
@property (strong, nonatomic) NSString *drawerOpenURL;
@property (strong, nonatomic) NSString *failedCutURL;
@property (strong, nonatomic) NSString *headerTempURL;
@property (strong, nonatomic) NSString *paperJammedURL;
@property (strong, nonatomic) NSString *unusualDataURL;
@property (strong, nonatomic) NSString *powerErrorURL;
@property (strong, nonatomic) NSString *soundId;
@property (strong, nonatomic) NSString *printInfo;
@property (strong, nonatomic) NSString *afterMovieURL;
@property (strong, nonatomic) NSString *resultMovieId;
@property (strong, nonatomic) NSString *resultURL;
@property (strong, nonatomic) NSString *topURL;
@property (strong, nonatomic) NSString *qrURL;
@property (strong, nonatomic) NSString *movieId;
@property (strong, nonatomic) NSDictionary *contentsList;
@property (nonatomic) BOOL singleAppMode;
@property (nonatomic) BOOL loggedOut;
@property (strong, nonatomic) NSString *accessToken;
@property (strong, nonatomic) UIWindow *window;


- (int)checkNetworkStatus;
@end
