#import "JverifyPlugin.h"
#import "JVERIFICATIONService.h"
// 如果需要使用 idfa 功能所需要引入的头文件（可选）
#import <AdSupport/AdSupport.h>
#define UIColorFromRGB(rgbValue)  ([UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0])

@implementation JverifyPlugin

NSObject<FlutterPluginRegistrar>* _registrar;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"jverify"
            binaryMessenger:[registrar messenger]];
    _registrar = registrar;
  JverifyPlugin* instance = [[JverifyPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"setup" isEqualToString:call.method]) {
      [self setup:call result:result];
  }else if([@"setDebugMode" isEqualToString:call.method]){
      [self setDebugMode:call result:result];
  }else if([@"checkVerifyEnable" isEqualToString:call.method]){
      [self checkVerifyEnable:call result:result];
  }else if([@"getToken" isEqualToString:call.method]){
      [self getToken:call result:result];
  }else if([@"verifyNumber" isEqualToString:call.method]){
      [self verifyNumber:call result:result];
  }else if([@"loginAuth" isEqualToString:call.method]){
      [self loginAuth:call result:result];
  }else if([@"setCustomUI" isEqualToString:call.method]){
      [self setCustomUIWithConfig:call result:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)setup:(FlutterMethodCall*) call result:(FlutterResult)result{
    NSDictionary *arguments = [call arguments];
    NSString *appKey = arguments[@"appKey"];
    NSString *channel = arguments[@"channel"];
    NSNumber *useIDFA = arguments[@"useIDFA"];
    
    JVAuthConfig *config = [[JVAuthConfig alloc] init];
    if (![appKey isKindOfClass:[NSNull class]]) {
        config.appKey = appKey;
    }
    config.appKey =appKey;
    if (![channel isKindOfClass:[NSNull class]]) {
        config.channel = channel;
    }
    NSString *idfaStr = NULL;
    if(![useIDFA isKindOfClass:[NSNull class]]){
        if([useIDFA boolValue]){
            idfaStr = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
            config.advertisingId = idfaStr;
        }
    }
    [JVERIFICATIONService setupWithConfig:config];
    
}

-(void)setDebugMode:(FlutterMethodCall*) call result:(FlutterResult)result{
    NSDictionary *arguments = call.arguments;
    NSNumber *debug = arguments[@"debug"];
    [JVERIFICATIONService setDebug:[debug boolValue]];
}

-(void)checkVerifyEnable:(FlutterMethodCall*) call result:(FlutterResult)result{
    BOOL verifyEnable = [JVERIFICATIONService checkVerifyEnable];
    result(@{@"result":[NSNumber numberWithBool:verifyEnable]});
}

-(void)getToken:(FlutterMethodCall*) call result:(FlutterResult)result{
    [JVERIFICATIONService getToken:^(NSDictionary *res) {
        NSString *content = @"";
        if(res[@"token"]){
            content =res[@"token"];
        }else if(res[@"content"]){
            content = res[@"content"];
        }
        result(@{@"code":res[@"code"],@"content":content,@"operator":res[@"operator"]?:@""});
    }];
}

-(void)verifyNumber:(FlutterMethodCall*) call result:(FlutterResult)result{
    NSDictionary *arguments=  [call arguments];
    NSString *phone = arguments[@"phone"];
    NSString *token = arguments[@"token"];
    
    JVAuthEntity *entity = [[JVAuthEntity alloc] init];
    entity.number = phone;
    entity.token = token;
    [JVERIFICATIONService verifyNumber:entity result:^(NSDictionary *res) {
        result(@{@"code":res[@"code"],@"content":res[@"content"]?:@""});
    }];
}

-(void)loginAuth:(FlutterMethodCall*) call result:(FlutterResult)result{
    [JVERIFICATIONService getAuthorizationWithController:[UIApplication sharedApplication].keyWindow.rootViewController completion:^(NSDictionary *res) {
        NSLog(@"一键登录 result:%@", res);
        NSString *content = @"";
        if(res[@"loginToken"]){
            content =res[@"loginToken"];
        }else if(res[@"content"]){
            content = res[@"content"];
        }
        result(@{@"code":res[@"code"],@"content":content,@"operator":res[@"operator"]?:@""});
    }];
}

-(void)setCustomUIWithConfig:(FlutterMethodCall*) call result:(FlutterResult)result{
    /*移动*/
    JVMobileUIConfig *mobileUIConfig = [[JVMobileUIConfig alloc] init];
    /*联通*/
    JVUnicomUIConfig *unicomUIConfig = [[JVUnicomUIConfig alloc] init];
    /*电信*/
    JVTelecomUIConfig *telecomUIConfig = [[JVTelecomUIConfig alloc] init];
    
    mobileUIConfig.barStyle = 0;
    unicomUIConfig.barStyle = 0;
    telecomUIConfig.barStyle = 0;

    NSNumber *navColor = [self getValue:call key:@"navColor"];
    if (navColor) {
        mobileUIConfig.navColor = unicomUIConfig.navColor = telecomUIConfig.navColor = UIColorFromRGB([navColor intValue]);
    }
    NSString *navText = [self getValue:call key:@"navText"];
    if (!navText) {
        navText = @"登录";
    }
    UIColor *navTextColor = UIColorFromRGB(-1);
    if ([self getValue:call key:@"navTextColor"]) {
        navTextColor = UIColorFromRGB([[self getValue:call key:@"navTextColor"] intValue]);
    }
    NSDictionary *navTextAttr = @{NSForegroundColorAttributeName:navTextColor};
    NSAttributedString *attr = [[NSAttributedString alloc]initWithString:navText attributes:navTextAttr];
    mobileUIConfig.navText = attr;
    unicomUIConfig.navText = attr;
    telecomUIConfig.navText = attr;
    
    NSString *imageName =[self getValue:call key:@"navReturnImgPath"];
    if(imageName){
        mobileUIConfig.navReturnImg
        = unicomUIConfig.navReturnImg
        = telecomUIConfig.navReturnImg = [UIImage imageNamed:imageName];
    }
    
    
    NSString *logoImgPath =[self getValue:call key:@"logoImgPath"];
    if(logoImgPath){
        mobileUIConfig.logoImg
        = unicomUIConfig.logoImg
        = telecomUIConfig.logoImg = [UIImage imageNamed:logoImgPath];
    }
    
    NSNumber *logoHidden = [self getValue:call key:@"logoHidden"];
    if(logoHidden){
        BOOL hiden = [logoHidden boolValue];
        mobileUIConfig.logoHidden
        = unicomUIConfig.logoHidden
        = telecomUIConfig.logoHidden = hiden;
    }
    NSNumber *logoWidth = [self getValue:call key:@"logoWidth"];
    if(logoWidth){
        mobileUIConfig.logoWidth = unicomUIConfig.logoWidth = telecomUIConfig.logoWidth =  [logoWidth intValue];
    }
    
    NSNumber *logoHeight = [self getValue:call key:@"logoHeight"];
    if(logoHeight){
        mobileUIConfig.logoHeight = unicomUIConfig.logoHeight = telecomUIConfig.logoHeight =  [logoHeight intValue];
    }
    
    NSNumber *logoOffsetY = [self getValue:call key:@"logoOffsetY"];
    if(logoOffsetY){
        mobileUIConfig.logoOffsetY = unicomUIConfig.logoOffsetY = telecomUIConfig.logoOffsetY = [logoOffsetY integerValue];
    }
    
    NSNumber *numberColor = [self getValue:call key:@"numberColor"];
    if(numberColor){
        mobileUIConfig.numberColor = unicomUIConfig.numberColor = telecomUIConfig.numberColor = UIColorFromRGB([numberColor intValue]);
    }
    
    NSNumber *numFieldOffsetY = [self getValue:call key:@"numFieldOffsetY"];
    if(numFieldOffsetY){
        mobileUIConfig.numFieldOffsetY = unicomUIConfig.numFieldOffsetY = telecomUIConfig.numFieldOffsetY = [numFieldOffsetY integerValue];
    }
    
    NSString *logBtnText = [self getValue:call key:@"logBtnText"];
    if(logBtnText){
        mobileUIConfig.logBtnText = unicomUIConfig.logBtnText = telecomUIConfig.logBtnText = logBtnText;
    }
    
    NSNumber *logBtnTextColor = [self getValue:call key:@"logBtnTextColor"];
    if(logBtnTextColor){
        mobileUIConfig.logBtnTextColor = unicomUIConfig.logBtnTextColor = telecomUIConfig.logBtnTextColor = UIColorFromRGB([logBtnTextColor integerValue]);
    }
    
    NSNumber *logBtnOffsetY = [self getValue:call key:@"logBtnOffsetY"];
    if(logBtnOffsetY){
        mobileUIConfig.logBtnOffsetY = unicomUIConfig.logBtnOffsetY = telecomUIConfig.logBtnOffsetY = [logBtnOffsetY integerValue];
    }
    
    NSString *loginBtnNormalImage =[self getValue:call key:@"loginBtnNormalImage"];
    loginBtnNormalImage = loginBtnNormalImage?:nil;
    NSString *loginBtnPressedImage =[self getValue:call key:@"loginBtnPressedImage"];
    loginBtnPressedImage = loginBtnPressedImage?:nil;
    NSString *loginBtnUnableImage =[self getValue:call key:@"loginBtnUnableImage"];
    loginBtnUnableImage = loginBtnUnableImage?:nil;
    NSArray * images =[[NSArray alloc]initWithObjects:[UIImage imageNamed:loginBtnNormalImage],[UIImage imageNamed:loginBtnPressedImage],[UIImage imageNamed:loginBtnUnableImage],nil];
    mobileUIConfig.logBtnImgs = images;
    unicomUIConfig.logBtnImgs = images;
    telecomUIConfig.logBtnImgs = images;
    
    NSString *uncheckedImgPath =[self getValue:call key:@"uncheckedImgPath"];
    if (uncheckedImgPath) {
        mobileUIConfig.uncheckedImg = unicomUIConfig.uncheckedImg = telecomUIConfig.uncheckedImg = [UIImage imageNamed:uncheckedImgPath];
    }
    
    NSString *checkedImgPath =[self getValue:call key:@"checkedImgPath"];
    if (checkedImgPath) {
        mobileUIConfig.checkedImg = unicomUIConfig.checkedImg = telecomUIConfig.checkedImg = [UIImage imageNamed:checkedImgPath];
    }

    NSNumber *privacyOffsetY = [self getValue:call key:@"privacyOffsetY"];
    if(privacyOffsetY){
        mobileUIConfig.privacyOffsetY = unicomUIConfig.privacyOffsetY = telecomUIConfig.privacyOffsetY = [privacyOffsetY integerValue];
    }
    
    NSString *clauseName = [self getValue:call key:@"clauseName"];
    NSString *clauseUrl = [self getValue:call key:@"clauseUrl"];
    
    if (clauseName && clauseUrl) {
        mobileUIConfig.appPrivacyOne = unicomUIConfig.appPrivacyOne = telecomUIConfig.appPrivacyOne = @[clauseName,clauseUrl];
    }
    
    
    NSString *clauseNameTwo = [self getValue:call key:@"clauseNameTwo"];
    NSString *clauseUrlTwo = [self getValue:call key:@"clauseUrlTwo"];
    if (clauseNameTwo && clauseUrlTwo) {
        mobileUIConfig.appPrivacyTwo = unicomUIConfig.appPrivacyTwo = telecomUIConfig.appPrivacyTwo = @[clauseNameTwo,clauseUrlTwo];
    }
    
    
    NSNumber *clauseBaseColor = [self getValue:call key:@"clauseBaseColor"];
    UIColor *privacyBasicColor =[UIColor grayColor];
    if(clauseBaseColor){
        privacyBasicColor =  UIColorFromRGB([clauseBaseColor integerValue]);
    }
    NSNumber *clauseColor = [self getValue:call key:@"clauseColor"];
    UIColor *privacyColor =UIColorFromRGB(-16007674);
    if(clauseColor){
        privacyColor =UIColorFromRGB([clauseColor integerValue]);
    }
    mobileUIConfig.appPrivacyColor = unicomUIConfig.appPrivacyColor = telecomUIConfig.appPrivacyColor = @[privacyBasicColor,privacyColor];
    
    NSNumber *sloganTextColor = [self getValue:call key:@"sloganTextColor"];
    if(sloganTextColor){
        mobileUIConfig.sloganTextColor = unicomUIConfig.sloganTextColor = telecomUIConfig.sloganTextColor = UIColorFromRGB([sloganTextColor integerValue]);
    }
    
    NSNumber *sloganOffsetY = [self getValue:call key:@"sloganOffsetY"];
    if(sloganOffsetY){
        mobileUIConfig.sloganOffsetY = unicomUIConfig.sloganOffsetY = telecomUIConfig.sloganOffsetY = [sloganOffsetY integerValue];
    }
    
    
    [JVERIFICATIONService customUIWithConfig:mobileUIConfig];
    [JVERIFICATIONService customUIWithConfig:unicomUIConfig];
    [JVERIFICATIONService customUIWithConfig:telecomUIConfig];


}

-(id) getValue:(FlutterMethodCall*) caller key:(NSString*) key{
    if (caller && ![caller.arguments[key] isKindOfClass:[NSNull class]]) {
        return caller.arguments[key]?:0;
    }else{
        return 0;
    }
}

@end
