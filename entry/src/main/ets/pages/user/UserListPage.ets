// pages/user/UserListPage.ets
import { api } from '../../network/Api'
import { BusinessCodeError } from '../../network/dsl/RequestBuilder'
import router from '@ohos.router'

interface UserItem {
  id: number
  name: string
  email?: string
}

@Entry
@Component
struct UserListPage {
  @State users: Array<UserItem> = []
  @State loading: boolean = false
  @State errorMessage: string = ''

  aboutToAppear() {
    this.loadUsers()
  }

  async loadUsers() {
    this.loading = true
    this.errorMessage = ''
    try {
      const result: Array<UserItem> = await api.user
        .getUsers()
        .onCache((cachedData: ESObject) => {
          console.info('UserListPage: 使用缓存数据')
          this.users = cachedData as Array<UserItem>
        })
        .execute<Array<UserItem>>()

      this.users = result
      console.info('UserListPage: 加载用户列表成功, 数量:', this.users.length)
    } catch (err) {
      if (err instanceof BusinessCodeError) {
        // 被业务码拦截器拦截（如异常登录），已被全局 handler 处理
        console.warn('UserListPage: 请求被业务拦截:', (err as BusinessCodeError).message)
        this.errorMessage = '操作被拦截: ' + (err as BusinessCodeError).message
      } else {
        console.error('UserListPage: 加载失败', JSON.stringify(err))
        this.errorMessage = '加载失败: ' + JSON.stringify(err)
      }
    } finally {
      this.loading = false
    }
  }

  build() {
    Column() {
      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor(Color.Red)
          .padding(12)
      }

      if (this.loading) {
        LoadingProgress()
      }

      List() {
        ForEach(this.users, (user: UserItem) => {
          ListItem() {
            Row() {
              Column() {
                Text(user.name)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                if (user.email) {
                  Text(user.email)
                    .fontSize(12)
                    .fontColor(Color.Gray)
                }
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text('查看 >')
                .fontSize(14)
                .fontColor('#007AFF')
            }
            .width('100%')
            .padding(16)
            .onClick(() => {
              router.pushUrl({
                url: 'pages/user/UserDetailPage',
                params: { id: user.id, name: user.name }
              })
            })
          }
          .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })
        }, (user: UserItem) => user.id.toString())
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}