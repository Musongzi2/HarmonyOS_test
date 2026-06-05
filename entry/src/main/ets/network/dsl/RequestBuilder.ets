// network/dsl/RequestBuilder.ets
import { HybridCache } from '../../infrastructure/cache/impl/HybridCache'

export class RequestBuilder {
  method!: string
  path!: string
  args!: Array<ESObject>
  useCache: boolean = false
  cacheTtl: number = 5 * 60 * 1000
  private cacheCallback?: (data: ESObject) => void
  private cache = new HybridCache<string, ESObject>(200, 1, 'network_cache')

  // DSL 方法
  query(params: Record<string, ESObject>) {
    // 拼接查询参数
    return this
  }

  body(data: ESObject) {
    // 设置请求体
    return this
  }

  cache(callback: (data: ESObject) => void) {
    this.cacheCallback = callback
    return this
  }

  // 执行请求
  async execute<T = ESObject>(): Promise<T> {
    const cacheKey = this.buildCacheKey()

    // 1. 尝试从缓存获取
    if (this.useCache) {
      const cached = await this.cache.get(cacheKey)
      if (cached && this.cacheCallback) {
        this.cacheCallback(cached)
      }
    }

    // 2. 发起网络请求
    const response = await this.executeNetwork<T>()

    // 3. 更新缓存
    if (this.useCache && response) {
      await this.cache.set(cacheKey, response, { ttl: this.cacheTtl })
    }

    return response
  }

  private buildCacheKey(): string {
    return `${this.method}:${this.path}:${JSON.stringify(this.args)}`
  }

  private async executeNetwork<T>(): Promise<T> {
    // 这里调用实际的网络请求
    // 为了示例，我们模拟一个异步请求
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve({ data: 'mock data' } as T)
      }, 1000)
    })
  }
}