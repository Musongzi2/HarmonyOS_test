// network/service/ProductApi.ets
import { GET, Cache } from '../dsl/annotations'
import { RequestBuilder } from '../dsl/RequestBuilder'

export class ProductApi {
  @Cache({ ttl: 30 * 60 * 1000 }) // 缓存30分钟
  @GET('/product/list')
  getProducts(category: string): RequestBuilder {
    return null as any
  }
}