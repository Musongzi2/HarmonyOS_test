import { User } from '../model/User';
import { router } from '@kit.ArkUI';

interface UserParams {
  id: number
  name: string
  avatar?: string
}

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  aboutToAppear() {
    const params = router.getParams()
    if (params) {
      const raw = params as UserParams
      const user = new User()
      user.id = raw.id ?? 0
      user.name = raw.name ?? ''
      user.avatar = raw.avatar
      console.info('testTag:', '接收到的用户:id=' + user.id + ',name=' + user.name)
      this.message = '欢迎, ' + user.displayName
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
          router.back()
        })
    }
    .height('100%')
    .width('100%')
  }
}