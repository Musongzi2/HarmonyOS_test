// pages/user/UserDetailPage.ets
import { api } from '../../network/Api'
import router from '@ohos.router'

interface UserInfo {
  id: number
  nickname: string
  email?: string
}

@Entry
@Component
struct UserDetailPage {
  @State user: UserInfo = { id: 0, nickname: '' }
  @State loading: boolean = false
  private userId: number = 0

  aboutToAppear() {
    const params: ESObject = router.getParams()
    // if (params) {
    //   const typed = params as UserInfo
    //   this.userId = typed.id
      this.loadUserDetail()
    // }
  }

  async loadUserDetail() {
    this.loading = true
    try {
      const result: ESObject = await api.user
        .getProfile(this.userId)
        .onCache((cachedData: ESObject) => {
          this.user = cachedData as UserInfo
        })
        .execute()

      this.user = result as UserInfo
    } catch (err) {
      console.error('加载详情失败', err)
    } finally {
      this.loading = false
    }
  }

  build() {
    Column() {
      if (this.loading) {
        LoadingProgress()
      }

      if (this.user) {
        Text(`用户ID: ${this.user.id}`)
          .fontSize(20)
          .margin(10)

        Text(`用户名: ${this.user.nickname}`)
          .fontSize(18)
          .margin(10)

        Text(`邮箱: ${this.user.email}`)
          .fontSize(16)
          .margin(10)
      }
    }
    .padding(20)
  }
}