// feature/offline/OfflineDataCache.ets
import { CacheFactory, CacheType } from '../../infrastructure/cache/CacheFactory'

export class OfflineDataCache {
  private cache = CacheFactory.createCache<string, ESObject>(CacheType.DISK, {
    diskMaxSizeGB: 2 // 离线数据用2GB
  })

  async saveOfflineData(key: string, data: ESObject): Promise<void> {
    await this.cache.set(key, data, { ttl: 7 * 24 * 60 * 60 * 1000 }) // 7天
  }
}