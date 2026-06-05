// pages/user/UserDetailPage.ets
import { api } from '../../network/Api'
import router from '@ohos.router'

@Entry
@Component
struct UserDetailPage {
  @State user: object | null = null
  @State loading: boolean = false
  private userId: number = 0

  aboutToAppear() {
    const params = router.getParams() as { userId: number }
    this.userId = params.userId
    this.loadUserDetail()
  }

  async loadUserDetail() {
    this.loading = true
    try {
      const result = await api.user
        .getProfile(this.userId)
        .cache((cachedData) => {
          // 立即显示缓存
          this.user = cachedData
        })
        .execute()

      // 网络数据更新
      this.user = result
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

        Text(`用户名: ${this.user.name}`)
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