import Router from '@system.router';
import { User } from '../model/User';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>
    console.info('接收到的参数:', JSON.stringify(params))
    if (params && params['name']) {
      this.message = '欢迎, ' + params['name']
    }
  }

  build() {

    RelativeContainer() {
      Text(this.message)
        .id('HelloWorld')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          // this.message = 'Welcome';
          Router.back()
        })
    }
    .height('100%')
    .width('100%')
  }
}