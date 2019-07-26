#import "JverifyPlugin.h"
#import "JVERIFICATIONService.h"
// 如果需要使用 idfa 功能所需要引入的头文件（可选）
#import <AdSupport/AdSupport.h>
#define UIColorFromRGB(rgbValue)  ([UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0])


#define JVLog(fmt, ...) NSLog((@"| JVER | iOS | " fmt), ##__VA_ARGS__)

/// 统一 key
static NSString *const j_result_key = @"result";
/// 错误码
static NSString *const j_code_key = @"code";
/// 回调的提示信息，统一返回 flutter 为 message
static NSString *const j_msg_key = @"message";
/// 运营商信息
static NSString *const j_opr_key = @"operator";
/// 默认超时时间
static long j_default_timeout = 5000;

@implementation JverifyPlugin

NSObject<FlutterPluginRegistrar>* _jv_registrar;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"jverify"
                                                              binaryMessenger:[registrar messenger]];
  _jv_registrar = registrar;
  JverifyPlugin* instance = [[JverifyPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    JVLog(@"Action - handleMethodCall: %@",call.method);
    
    NSString *methodName = call.method;
    if ([methodName isEqualToString:@"setup"]) {
        [self setup:call result:result];
    }else if([methodName isEqualToString:@"setDebugMode"]){
        [self setDebugMode:call result:result];
    }else if([methodName isEqualToString:@"isInitSuccess"]) {
        [self isSetupClient:result];
    }else if([methodName isEqualToString:@"checkVerifyEnable"]){
        [self checkVerifyEnable:call result:result];
    }else if([methodName isEqualToString:@"getToken"]){
        [self getToken:call result:result];
    }else if([methodName isEqualToString:@"verifyNumber"]){
        [self verifyNumber:call result:result];
    }else if([methodName isEqualToString:@"loginAuth"]){
        [self loginAuth:call result:result];
    }else if([methodName isEqualToString:@"preLogin"]){
        [self preLogin:call result:result];
    }else if([methodName isEqualToString:@"dismissLoginAuthView"]){
        [self dismissLoginController:call result:result];
    }else if([methodName isEqualToString:@"setCustomUI"]){
        [self setCustomUIWithConfig:call result:result];
    }else {
        result(FlutterMethodNotImplemented);
    }
}


#pragma mark - 设置日志 debug 模式
-(void)setDebugMode:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - setDebugMode::");
    
    NSDictionary *arguments = call.arguments;
    NSNumber *debug = arguments[@"debug"];
    [JVERIFICATIONService setDebug:[debug boolValue]];
}

#pragma mark - 初始化 SDK
- (void)setup:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - setup::");
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

#pragma mark - 获取初始化状态
-(BOOL)isSetupClient:(FlutterResult)result {
    JVLog(@"Action - isSetupClient:");
    BOOL isSetup = [JVERIFICATIONService isSetupClient];
    if (!isSetup) {
        JVLog(@"初始化未完成!");
    }
    result(@{j_result_key:[NSNumber numberWithBool:isSetup]});
    // 初始换成功
    //···
    return isSetup;
}

#pragma mark - 判断网络环境是否支持
-(BOOL)checkVerifyEnable:(FlutterMethodCall*)call result:(FlutterResult)result{
    JVLog(@"Action - checkVerifyEnable::");
    BOOL isEnable = [JVERIFICATIONService checkVerifyEnable];
    if(!isEnable) {
        JVLog(@"当前网络环境不支持认证！");
    }
    result(@{j_result_key:[NSNumber numberWithBool:isEnable]});
    //继续获取token操作
    //...
    return isEnable;
}

#pragma mark - 获取号码认证token
-(void)getToken:(FlutterMethodCall*)call result:(FlutterResult)result{
    JVLog(@"Action - getToken::%@",call.arguments);
    
    NSDictionary *arguments=  [call arguments];
    NSNumber *timeoutNum = arguments[@"timeout"];
    NSTimeInterval timeout = [timeoutNum longLongValue];
    if (timeout <= 0) {
        timeout = j_default_timeout;
    }
    
    /*
     参数说明
     timeout 超时时间。单位ms，合法范围3000~10000。
     completion 参数是字典 返回token 、错误码等相关信息，token有效期1分钟, 一次认证后失效
        res 字典
            获取到token时，key 有 code、token、operator 字段，
            获取不到token时，key 为 code 、content 字段
     
     */
    [JVERIFICATIONService getToken:timeout completion:^(NSDictionary *res) {
        JVLog(@"sdk getToken completion : %@",res);
        
        NSString *content = @"";
        if(res[@"token"]){
            content =res[@"token"];
        }else if(res[@"content"]){
            content = res[@"content"];
        }
        NSDictionary *dict = @{
                               j_code_key: res[@"code"],
                               j_msg_key : content,
                               j_opr_key : res[@"operator"] ? res[@"operator"] : @""
                               };
        
        dispatch_async(dispatch_get_main_queue(), ^{
            result(dict);
        });
    }];
}

#pragma mark - SDK 发起号码认证
-(void)verifyNumber:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - verifyNumber::%@",call.arguments);

    NSDictionary *arguments=  [call arguments];
    NSString *phone = arguments[@"phone"];
    NSString *token = arguments[@"token"];
    
    JVAuthEntity *entity = [[JVAuthEntity alloc] init];
    entity.number = phone;
    entity.token = token;
    [JVERIFICATIONService verifyNumber:entity result:^(NSDictionary *res) {
        JVLog(@"sdk verifyNumber completion : %@",res);
        
        NSDictionary *dict = @{
                               j_code_key:res[@"code"],
                               j_msg_key :res[@"content"] ? res[@"content"] : @""
                               };
        dispatch_async(dispatch_get_main_queue(), ^{
            result(dict);
        });
    }];
}
#pragma mark - SDK 登录预取号
- (void)preLogin:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - preLogin::%@",call.arguments);
    
    NSDictionary *arguments=  [call arguments];
    NSNumber *timeoutNum = arguments[@"timeout"];
    NSTimeInterval timeout = [timeoutNum longLongValue];
    if (timeout <= 0) {
        timeout = j_default_timeout;
    }
    
    /*
     参数说明:
        completion 预取号结果
            result 字典 key为code和message两个字段
            timeout 超时时间。单位ms，合法范围3000~10000。
     */
    [JVERIFICATIONService preLogin:timeout completion:^(NSDictionary *res) {
        JVLog(@"sdk preLogin completion :%@",res);
        
        NSDictionary *dict = @{
                               j_code_key:res[@"code"],
                               j_msg_key :res[@"message"] ? res[@"message"] : @""
                               };
        dispatch_async(dispatch_get_main_queue(), ^{
            result(dict);
        });
    }];
}
#pragma mark - SDK 请求授权一键登录
-(void)loginAuth:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - loginAuth::%@",call.arguments);

    NSDictionary *arguments = [call arguments];
    NSNumber *hide = arguments[@"autoDismiss"];
    
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    /*
     参数说明:
     vc 当前控制器
     hide 完成后是否自动隐藏授权页，默认YES。若此字段设置为NO，请在收到一键登录回调后调用SDK提供的关闭授权页面方法。
     completion 登录结果
        result 字典
            获取到时， token 时 key 有 code、operator、loginToken字段，
            获取不到时，token 是 key 为 code 和 content 字段
     */
    [JVERIFICATIONService getAuthorizationWithController:vc hide:[hide boolValue] completion:^(NSDictionary *res) {
        JVLog(@"loginAuth result = %@",res);
        
        NSString *content = @"";
        if(res[@"loginToken"]){
            content =res[@"loginToken"];
        }else if(res[@"content"]){
            content = res[@"content"];
        }
        
        NSDictionary *dict = @{
                               j_code_key:res[@"code"],
                               j_msg_key :content,
                               j_opr_key :res[@"operator"]?:@""
                               };
        dispatch_async(dispatch_get_main_queue(), ^{
            result(dict);
        });
    }];
}
#pragma mark - SDK关闭授权页面
-(void)dismissLoginController:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - dismissLoginController::");
    [JVERIFICATIONService dismissLoginController];
}

#pragma mark - SDK自定义授权页面UI样式
-(void)setCustomUIWithConfig:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - setCustomUIWithConfig::");
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
        mobileUIConfig.navColor  = UIColorFromRGB([navColor intValue]);
        unicomUIConfig.navColor  = UIColorFromRGB([navColor intValue]);
        telecomUIConfig.navColor = UIColorFromRGB([navColor intValue]);
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
        mobileUIConfig.navReturnImg  = [UIImage imageNamed:imageName];
        unicomUIConfig.navReturnImg  = [UIImage imageNamed:imageName];
        telecomUIConfig.navReturnImg = [UIImage imageNamed:imageName];
    }
    
    NSString *logoImgPath =[self getValue:call key:@"logoImgPath"];
    if(logoImgPath){
        mobileUIConfig.logoImg  = [UIImage imageNamed:logoImgPath];
        unicomUIConfig.logoImg  = [UIImage imageNamed:logoImgPath];
        telecomUIConfig.logoImg = [UIImage imageNamed:logoImgPath];
    }
    
    NSNumber *logoHidden = [self getValue:call key:@"logoHidden"];
    if(logoHidden){
        mobileUIConfig.logoHidden  = [logoHidden boolValue];
        unicomUIConfig.logoHidden  = [logoHidden boolValue];
        telecomUIConfig.logoHidden = [logoHidden boolValue];
    }
    
    NSNumber *logoWidth = [self getValue:call key:@"logoWidth"];
    if(logoWidth){
        mobileUIConfig.logoWidth  = [logoWidth intValue];
        unicomUIConfig.logoWidth  = [logoWidth intValue];
        telecomUIConfig.logoWidth = [logoWidth intValue];
    }
    
    NSNumber *logoHeight = [self getValue:call key:@"logoHeight"];
    if(logoHeight){
        mobileUIConfig.logoHeight  = [logoHeight intValue];
        unicomUIConfig.logoHeight  = [logoHeight intValue];
        telecomUIConfig.logoHeight = [logoHeight intValue];
    }
    
    NSNumber *logoOffsetY = [self getValue:call key:@"logoOffsetY"];
    if(logoOffsetY){
        mobileUIConfig.logoOffsetY  = [logoOffsetY integerValue];
        unicomUIConfig.logoOffsetY  = [logoOffsetY integerValue];
        telecomUIConfig.logoOffsetY = [logoOffsetY integerValue];
    }
    
    NSNumber *numberColor = [self getValue:call key:@"numberColor"];
    if(numberColor){
        mobileUIConfig.numberColor  = UIColorFromRGB([numberColor intValue]);
        unicomUIConfig.numberColor  = UIColorFromRGB([numberColor intValue]);
        telecomUIConfig.numberColor = UIColorFromRGB([numberColor intValue]);
    }
    
    NSNumber *numFieldOffsetY = [self getValue:call key:@"numFieldOffsetY"];
    if(numFieldOffsetY){
        mobileUIConfig.numFieldOffsetY  = [numFieldOffsetY integerValue];
        unicomUIConfig.numFieldOffsetY  = [numFieldOffsetY integerValue];
        telecomUIConfig.numFieldOffsetY = [numFieldOffsetY integerValue];
    }
    
    NSString *logBtnText = [self getValue:call key:@"logBtnText"];
    if(logBtnText){
        mobileUIConfig.logBtnText  = logBtnText;
        unicomUIConfig.logBtnText  = logBtnText;
        telecomUIConfig.logBtnText = logBtnText;
    }
    
    NSNumber *logBtnTextColor = [self getValue:call key:@"logBtnTextColor"];
    if(logBtnTextColor){
        mobileUIConfig.logBtnTextColor  = UIColorFromRGB([logBtnTextColor integerValue]);
        unicomUIConfig.logBtnTextColor  = UIColorFromRGB([logBtnTextColor integerValue]);
        telecomUIConfig.logBtnTextColor = UIColorFromRGB([logBtnTextColor integerValue]);
    }
    
    NSNumber *logBtnOffsetY = [self getValue:call key:@"logBtnOffsetY"];
    if(logBtnOffsetY){
        mobileUIConfig.logBtnOffsetY  = [logBtnOffsetY integerValue];
        unicomUIConfig.logBtnOffsetY  = [logBtnOffsetY integerValue];
        telecomUIConfig.logBtnOffsetY = [logBtnOffsetY integerValue];
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
        mobileUIConfig.uncheckedImg  = [UIImage imageNamed:uncheckedImgPath];
        unicomUIConfig.uncheckedImg  = [UIImage imageNamed:uncheckedImgPath];
        telecomUIConfig.uncheckedImg = [UIImage imageNamed:uncheckedImgPath];
    }
    
    NSString *checkedImgPath =[self getValue:call key:@"checkedImgPath"];
    if (checkedImgPath) {
        mobileUIConfig.checkedImg  = [UIImage imageNamed:checkedImgPath];
        unicomUIConfig.checkedImg  = [UIImage imageNamed:checkedImgPath];
        telecomUIConfig.checkedImg = [UIImage imageNamed:checkedImgPath];
    }

    NSNumber *privacyOffsetY = [self getValue:call key:@"privacyOffsetY"];
    if(privacyOffsetY){
        mobileUIConfig.privacyOffsetY  = [privacyOffsetY integerValue];
        unicomUIConfig.privacyOffsetY  = [privacyOffsetY integerValue];
        telecomUIConfig.privacyOffsetY = [privacyOffsetY integerValue];
    }
    
    NSString *clauseName = [self getValue:call key:@"clauseName"];
    NSString *clauseUrl = [self getValue:call key:@"clauseUrl"];
    if (clauseName && clauseUrl) {
        mobileUIConfig.appPrivacyOne  = @[clauseName,clauseUrl];
        unicomUIConfig.appPrivacyOne  = @[clauseName,clauseUrl];
        telecomUIConfig.appPrivacyOne = @[clauseName,clauseUrl];
    }
    
    NSString *clauseNameTwo = [self getValue:call key:@"clauseNameTwo"];
    NSString *clauseUrlTwo = [self getValue:call key:@"clauseUrlTwo"];
    if (clauseNameTwo && clauseUrlTwo) {
        mobileUIConfig.appPrivacyTwo  = @[clauseNameTwo,clauseUrlTwo];
        unicomUIConfig.appPrivacyTwo  = @[clauseNameTwo,clauseUrlTwo];
        telecomUIConfig.appPrivacyTwo = @[clauseNameTwo,clauseUrlTwo];
    }
    
    NSNumber *clauseBaseColor = [self getValue:call key:@"clauseBaseColor"];
    UIColor *privacyBasicColor =[UIColor grayColor];
    if(clauseBaseColor){
        privacyBasicColor =  UIColorFromRGB([clauseBaseColor integerValue]);
    }
    NSNumber *clauseColor = [self getValue:call key:@"clauseColor"];
    UIColor *privacyColor = UIColorFromRGB(-16007674);
    if(clauseColor){
        privacyColor =UIColorFromRGB([clauseColor integerValue]);
    }
    mobileUIConfig.appPrivacyColor  = @[privacyBasicColor,privacyColor];
    unicomUIConfig.appPrivacyColor  = @[privacyBasicColor,privacyColor];
    telecomUIConfig.appPrivacyColor = @[privacyBasicColor,privacyColor];
    
    NSNumber *sloganTextColor = [self getValue:call key:@"sloganTextColor"];
    if(sloganTextColor){
        mobileUIConfig.sloganTextColor  = UIColorFromRGB([sloganTextColor integerValue]);
        unicomUIConfig.sloganTextColor  = UIColorFromRGB([sloganTextColor integerValue]);
        telecomUIConfig.sloganTextColor = UIColorFromRGB([sloganTextColor integerValue]);
    }
    
    NSNumber *sloganOffsetY = [self getValue:call key:@"sloganOffsetY"];
    if(sloganOffsetY){
        mobileUIConfig.sloganOffsetY  = [sloganOffsetY integerValue];
        unicomUIConfig.sloganOffsetY  = [sloganOffsetY integerValue];
        telecomUIConfig.sloganOffsetY = [sloganOffsetY integerValue];
    }
    
    [JVERIFICATIONService customUIWithConfig:mobileUIConfig];
    [JVERIFICATIONService customUIWithConfig:unicomUIConfig];
    [JVERIFICATIONService customUIWithConfig:telecomUIConfig];
}

#pragma mark - SDK授权页面添加自定义控件

- (void)setCustomWidgetWithConfig:(FlutterMethodCall*) call result:(FlutterResult)result {
    
}


#pragma mark - 其他
-(id) getValue:(FlutterMethodCall*) caller key:(NSString*) key{
    if (caller && ![caller.arguments[key] isKindOfClass:[NSNull class]]) {
        return caller.arguments[key]?:0;
    }else{
        return 0;
    }
}

//- (id)object:(FlutterMethodCall*)caller forKey:(NSString *)key {
//    if (caller && ![caller.arguments[key] isKindOfClass:[NSNull class]]) {
//        return caller.arguments[key]?:nil;
//    }
//    return nil;
//}

@end
