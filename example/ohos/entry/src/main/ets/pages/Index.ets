import common from '@ohos.app.ability.common';
import { FlutterPage } from '@ohos/flutter_ohos';
import { JverifyNavigation } from 'jverify';

let storage = LocalStorage.getShared();
const EVENT_BACK_PRESS: string = 'EVENT_BACK_PRESS';

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext;
  @LocalStorageLink('viewId') viewId: string = '';
  @Provide('jverifyNavPathStack') navPathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    JverifyNavigation.attachNavPathStack(this.navPathStack, this);
  }

  aboutToDisappear(): void {
    JverifyNavigation.detachNavPathStack(this.navPathStack);
  }

  build() {
    Navigation(this.navPathStack) {
      Column() {
        FlutterPage({ viewId: this.viewId });
      }
      .width('100%')
      .height('100%');
    }
    .hideTitleBar(true)
    .width('100%')
    .height('100%');
  }

  onBackPress(): boolean {
    this.context.eventHub.emit(EVENT_BACK_PRESS);
    return true;
  }
}
