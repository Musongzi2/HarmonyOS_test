// network/dsl/HttpDsl.ets
import { NetworkCache } from '../cache/NetworkCache'

export class RequestBuilder {
  private networkCache = new NetworkCache()

  async execute<T = ESObject>(): Promise<T> {
    // 1. 查缓存
    const cached = await this.networkCache.get(this.getCacheKey())
    if (cached && this.cacheCallback) {
      this.cacheCallback(cached)
    }

    // 2. 请求网络
    const remote = await this.executeRemote<T>()

    // 3. 更新缓存
    if (remote) {
      await this.networkCache.set(this.getCacheKey(), remote, 5 * 60 * 1000) // 5分钟
    }

    return remote
  }
}