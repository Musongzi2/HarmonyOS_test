// network/service/UserApi.ets
import { GET, POST, Cache } from '../dsl/annotations'
import { RequestBuilder } from '../dsl/RequestBuilder'

export class UserApi {
  @Cache({ ttl: 5 * 60 * 1000 }) // 缓存5分钟
  @GET('/user/profile', ['userId'])
  getProfile(userId: number): RequestBuilder { return undefined! }

  @GET('/api/users')
  getUsers(): RequestBuilder { return undefined! }

  @POST('/api/users')
  createUser(data: ESObject): RequestBuilder { return undefined! }
}