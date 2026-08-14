import { AuthLoginCallBack } from '@jg/verify';

/** Controlled ArkUI style used by Flutter custom widgets. */
export class JverifyCustomViewStyle {
  id: string = '';
  type: string = 'button';
  text: string = '';
  textSize: number = 13;
  textColor: number = 0xFF000000;
  backgroundColor: number = 0x00000000;
  width: number = 0;
  height: number = 0;
  borderRadius: number = 0;
  marginTop: number = 0;
  marginRight: number = 0;
  marginBottom: number = 0;
  marginLeft: number = 0;
  textAlign: string = 'center';
  underline: boolean = false;
  imageSource: string = '';
  imageFit: string = 'contain';
  isClickEnabled: boolean = false;
  onClick: () => void = (): void => {};
}

let authCustomViewStyles: Array<JverifyCustomViewStyle> = new Array<JverifyCustomViewStyle>();
let checkDialogCustomViewStyles: Array<JverifyCustomViewStyle> = new Array<JverifyCustomViewStyle>();

export function configureHarmonyAuthCustomViews(styles: Array<JverifyCustomViewStyle>): void {
  authCustomViewStyles = styles;
}

export function configureHarmonyCheckDialogCustomViews(styles: Array<JverifyCustomViewStyle>): void {
  checkDialogCustomViewStyles = styles;
}

function resolveTextAlign(value: string): TextAlign {
  if (value === 'left' || value === 'start') {
    return TextAlign.Start;
  }
  if (value === 'right' || value === 'end') {
    return TextAlign.End;
  }
  return TextAlign.Center;
}

function resolveImageFit(value: string): ImageFit {
  if (value === 'fill') {
    return ImageFit.Fill;
  }
  if (value === 'cover') {
    return ImageFit.Cover;
  }
  return ImageFit.Contain;
}

@Builder
function buildHarmonyCustomView(style: JverifyCustomViewStyle) {
  if (style.type === 'image') {
    Image(style.imageSource)
      .id(style.id)
      .width(style.width)
      .height(style.height)
      .objectFit(resolveImageFit(style.imageFit))
      .backgroundColor(style.backgroundColor)
      .margin({
        top: style.marginTop,
        right: style.marginRight,
        bottom: style.marginBottom,
        left: style.marginLeft,
      })
      .onClick((): void => {
        if (style.isClickEnabled) {
          style.onClick();
        }
      })
  } else if (style.type === 'text' || style.type === 'textView') {
    Text(style.text)
      .id(style.id)
      .fontSize(style.textSize)
      .fontColor(style.textColor)
      .textAlign(resolveTextAlign(style.textAlign))
      .decoration({
        type: style.underline ? TextDecorationType.Underline : TextDecorationType.None,
      })
      .width(style.width)
      .height(style.height)
      .backgroundColor(style.backgroundColor)
      .margin({
        top: style.marginTop,
        right: style.marginRight,
        bottom: style.marginBottom,
        left: style.marginLeft,
      })
      .onClick((): void => {
        if (style.isClickEnabled) {
          style.onClick();
        }
      })
  } else {
    Button() {
      if (style.imageSource.length > 0) {
        Image(style.imageSource)
          .width('100%')
          .height('100%')
          .objectFit(resolveImageFit(style.imageFit))
      } else {
        Text(style.text)
          .fontSize(style.textSize)
          .fontColor(style.textColor)
          .textAlign(resolveTextAlign(style.textAlign))
      }
    }
    .id(style.id)
    .width(style.width)
    .height(style.height)
    .backgroundColor(style.backgroundColor === 0 ? Color.Transparent : style.backgroundColor)
    .borderRadius(style.borderRadius)
    .margin({
      top: style.marginTop,
      right: style.marginRight,
      bottom: style.marginBottom,
      left: style.marginLeft,
    })
    .onClick((): void => {
      if (style.isClickEnabled) {
        style.onClick();
      }
    })
  }
}

@Builder
export function buildHarmonyAuthCustomViews() {
  ForEach(authCustomViewStyles, (style: JverifyCustomViewStyle): void => {
    buildHarmonyCustomView(style);
  }, (style: JverifyCustomViewStyle): string => style.id)
}

@Builder
export function buildHarmonyCheckDialogCustomViews() {
  ForEach(checkDialogCustomViewStyles, (style: JverifyCustomViewStyle): void => {
    buildHarmonyCustomView(style);
  }, (style: JverifyCustomViewStyle): string => style.id)
}

export class JverifyCMLoginPageWidgetStyle {
  id: string = '';
  anchor: string = 'loginBtn';
  type: string = 'button';
  text: string = '';
  textSize: number = 16;
  textColor: number = 0xFFFFFFFF;
  backgroundColor: number = 0xFF359AF3;
  width: number = 180;
  height: number = 44;
  borderRadius: number = 22;
  imageSource: string = '';
  imageFit: string = 'contain';
  marginTop: number = 0;
  marginRight: number = 0;
  marginBottom: number = 0;
  marginLeft: number = 0;
  action: string = 'callback';
  toastText: string = '';
}

export class JverifyCMLoginPageStyle {
  showTitle: boolean = false;
  title: string = '极光认证';
  titleSize: number = 24;
  titleColor: number = 0xFF17233D;
  // setLoginPageComponent is an overlay. Keep the SDK's native page visible
  // unless Flutter explicitly requests a custom background.
  backgroundColor: number = 0x00000000;
  backgroundImage: string = '';
  widgets: Array<JverifyCMLoginPageWidgetStyle> = new Array<JverifyCMLoginPageWidgetStyle>();
  onWidgetClick: (id: string, action: string, toastText: string) => void =
    (_id: string, _action: string, _toastText: string): void => {};
}

let cmLoginPageStyle: JverifyCMLoginPageStyle = new JverifyCMLoginPageStyle();

export function configureHarmonyCMLoginPage(style: JverifyCMLoginPageStyle): void {
  cmLoginPageStyle = style;
}

@Builder
function buildHarmonyCMLoginPageWidget(style: JverifyCMLoginPageWidgetStyle) {
  if (style.type === 'image') {
    Image(style.imageSource)
      .id(style.id)
      .width(style.width)
      .height(style.height)
      .objectFit(resolveImageFit(style.imageFit))
      .backgroundColor(style.backgroundColor)
      .alignRules({
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        top: { anchor: style.anchor, align: VerticalAlign.Bottom },
      })
      .margin({
        top: style.marginTop,
        right: style.marginRight,
        bottom: style.marginBottom,
        left: style.marginLeft,
      })
      .onClick((): void => {
        cmLoginPageStyle.onWidgetClick(style.id, style.action, style.toastText);
      })
  } else if (style.type === 'text' || style.type === 'textView') {
    Text(style.text)
      .id(style.id)
      .fontSize(style.textSize)
      .fontColor(style.textColor)
      .width(style.width)
      .height(style.height)
      .alignRules({
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        top: { anchor: style.anchor, align: VerticalAlign.Bottom },
      })
      .margin({
        top: style.marginTop,
        right: style.marginRight,
        bottom: style.marginBottom,
        left: style.marginLeft,
      })
      .onClick((): void => {
        cmLoginPageStyle.onWidgetClick(style.id, style.action, style.toastText);
      })
  } else {
    Button() {
      if (style.imageSource.length > 0) {
        Image(style.imageSource)
          .width('100%')
          .height('100%')
          .objectFit(resolveImageFit(style.imageFit))
      } else {
        Text(style.text)
          .fontSize(style.textSize)
          .fontColor(style.textColor)
      }
    }
    .id(style.id)
    .width(style.width)
    .height(style.height)
    .backgroundColor(style.backgroundColor === 0 ? Color.Transparent : style.backgroundColor)
    .borderRadius(style.borderRadius)
    .alignRules({
      middle: { anchor: '__container__', align: HorizontalAlign.Center },
      top: { anchor: style.anchor, align: VerticalAlign.Bottom },
    })
    .margin({
      top: style.marginTop,
      right: style.marginRight,
      bottom: style.marginBottom,
      left: style.marginLeft,
    })
    .onClick((): void => {
      cmLoginPageStyle.onWidgetClick(style.id, style.action, style.toastText);
    })
  }
}

@Builder
export function buildHarmonyCMLoginPage(_obj?: object) {
  if (cmLoginPageStyle.backgroundImage.length > 0) {
    Image(cmLoginPageStyle.backgroundImage)
      .width('100%')
      .height('100%')
      .objectFit(ImageFit.Cover)
      .backgroundColor(cmLoginPageStyle.backgroundColor)
      .hitTestBehavior(HitTestMode.None)
  } else if (cmLoginPageStyle.backgroundColor !== 0) {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor(cmLoginPageStyle.backgroundColor)
      .hitTestBehavior(HitTestMode.None)
  }
  if (cmLoginPageStyle.showTitle && cmLoginPageStyle.title.length > 0) {
    Text(cmLoginPageStyle.title)
      .id('jverify-cm-login-page-title')
      .fontSize(cmLoginPageStyle.titleSize)
      .fontColor(cmLoginPageStyle.titleColor)
      .fontWeight(FontWeight.Bold)
      .alignRules({
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        top: { anchor: '__container__', align: VerticalAlign.Top },
      })
      .margin({ top: 80 })
  }
  ForEach(cmLoginPageStyle.widgets, (style: JverifyCMLoginPageWidgetStyle): void => {
    buildHarmonyCMLoginPageWidget(style);
  }, (style: JverifyCMLoginPageWidgetStyle): string => style.id)
}

class JverifyCMAuthLoginListenerContext {}

export class JverifyCMAuthLoginListener {
  obj: object = new JverifyCMAuthLoginListenerContext();
  private message: string;
  private confirmText: string;
  private cancelText: string;
  private confirmColor: string;
  private cancelColor: string;

  constructor(message: string, confirmText: string, cancelText: string,
    confirmColor: string, cancelColor: string) {
    this.message = message;
    this.confirmText = confirmText;
    this.cancelText = cancelText;
    this.confirmColor = confirmColor;
    this.cancelColor = cancelColor;
  }

  onAuthLoginListener(context: UIContext, callBack: AuthLoginCallBack): void {
    context.getPromptAction().showDialog({
      message: this.message,
      buttons: [{
        text: this.confirmText,
        color: this.confirmColor,
      }, {
        text: this.cancelText,
        color: this.cancelColor,
      }],
    }).then((data): void => {
      callBack.onAuthLoginCallBack(data.index === 0);
    }).catch((): void => {
      callBack.onAuthLoginCallBack(false);
    });
  }
}
