// network/cache/NetworkCache.ets
import { ICache } from '../../infrastructure/cache/ICache'
import { CacheFactory, CacheType } from '../../infrastructure/cache/CacheFactory'

export class NetworkCache {
  private cache: ICache<string, ESObject>

  constructor() {
    // 使用混合缓存（内存200MB + 磁盘1GB）
    this.cache = CacheFactory.createCache<string, ESObject>(CacheType.HYBRID, {
      memoryMaxSizeMB: 200,
      diskMaxSizeGB: 1,
      baseDir: '/data/storage/el2/base/haps/entry/cache/network'
    })
  }

  async get(url: string): Promise<ESObject> {
    return this.cache.get(url)
  }

  async set(url: string, data: ESObject, ttl?: number): Promise<void> {
    await this.cache.set(url, data, { ttl })
  }
}