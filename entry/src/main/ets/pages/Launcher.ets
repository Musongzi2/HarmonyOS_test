import { User } from "../model/User"
import router from '@ohos.router'; // 1. 引入路由模块

@Entry
@Component
struct Launcher {
  @State message: string = '爱你'
  // ====== ViewModel 的“状态” ======
  @State account: string = 'linhui'
  @State pwd: string = '123123'
  @State loading: boolean = false
  @State user: User = new User()

  // ====== ViewModel 的“命令/事件逻辑” ======
  private async login() {
    this.loading = true
    try {
      // 假装请求
      const u = new User()
      u.id = 1
      u.name = this.account
      this.user = u
    } finally {
      this.loading = false
    }
  }

  build() {
    Column({ space: 12 }) {
      TextInput({ placeholder: '账号' })
        .onChange(v => this.account = v)

      TextInput({ placeholder: '密码' })
        .type(InputType.Password)
        .onChange(v => this.pwd = v)

      Button(this.loading ? '登录中...' : '登录')
        .enabled(!this.loading)
        .onClick(() => this.login())

      Text(this.user.displayName)
      Button("其他登陆").enabled(this.user.id == 1).onClick(() => {
        router.pushUrl({ url: 'pages/Index', params: this.user })
          .then(() => {
            console.info('页面跳转成功');
          })
          .catch((err: Error) => {
            console.error('页面跳转失败', err.message);
          });
      })
    }
    .padding(16)
  }
}