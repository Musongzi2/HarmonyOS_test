import { User } from "../model/User"

@Entry
@Component
struct Launcher {
  @State message: string = '爱你'

  // ====== ViewModel 的“状态” ======
  @State account: string = ''
  @State pwd: string = ''
  @State loading: boolean = false
  @State user?: User

  // ====== ViewModel 的“命令/事件逻辑” ======
  private async login() {
    this.loading = true
    try {
      // 假装请求
      const u = new User({ id: 1, name: this.account })
      this.user = u
    } finally {
      this.loading = false
    }
  }

  build() {
    Column({ space: 12 }) {
      TextInput({ placeholder: '账号' })
        .onChange(v => this.account = v)

      TextInput({ placeholder: '密码', type: InputType.Password })
        .onChange(v => this.pwd = v)

      Button(this.loading ? '登录中...' : '登录')
        .enabled(!this.loading)
        .onClick(() => this.login())

      Text(this.user?.displayName ?? '')
    }
    .padding(16)
  }
}