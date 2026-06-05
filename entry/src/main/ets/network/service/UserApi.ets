// network/service/UserApi.ets
import { GET, POST, Cache } from '../dsl/annotations'
import { RequestBuilder } from '../dsl/RequestBuilder'

export class UserApi {
  @Cache({ ttl: 5 * 60 * 1000 }) // 缓存5分钟
  @GET('/user/profile')
  getProfile(userId: number): RequestBuilder {
    return null as any
  }

  @POST('/user/update')
  updateProfile(data: ESObject): RequestBuilder {
    return null as any
  }
}