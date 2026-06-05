// pages/user/UserListPage.ets
import { api } from '../../network/Api'
import router from '@ohos.router'

@Entry
@Component
struct UserListPage {
  @State users: Array<ESObject> = []
  @State loading: boolean = false

  aboutToAppear() {
    this.loadUsers()
  }

  async loadUsers() {
    this.loading = true
    try {
      const result = await api.user
        .getProfile(1001)
        .cache((cachedData) => {
          // 立即显示缓存
          console.log('使用缓存数据')
          this.users = [cachedData]
        })
        .execute()

      // 网络数据更新
      this.users = [result]
    } catch (err) {
      console.error('加载失败', err)
    } finally {
      this.loading = false
    }
  }

  build() {
    Column() {
      if (this.loading) {
        LoadingProgress()
      }

      List() {
        ForEach(this.users, (user: ESObject) => {
          ListItem() {
            Row() {
              Text(user.name)
                .fontSize(18)
                .onClick(() => {
                  // 跳转到详情页，并传递用户ID
                  router.pushUrl({
                    url: 'pages/user/UserDetailPage',
                    params: { userId: user.id }
                  })
                })
            }
            .padding(16)
          }
        }, (user: ESObject) => user.id.toString())
      }
    }
  }
}