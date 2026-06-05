// feature/user/config/UserConfigCache.ets
import { CacheFactory, CacheType } from '../../../infrastructure/cache/CacheFactory'

export class UserConfigCache {
  private cache = CacheFactory.createCache<string, ESObject>(CacheType.MEMORY, {
    memoryMaxSizeMB: 50 // 只占用50MB
  })

  async saveTheme(theme: string): Promise<void> {
    await this.cache.set('theme', theme, { ttl: 30 * 24 * 60 * 60 * 1000 }) // 30天
  }

  async getTheme(): Promise<string | null> {
    return this.cache.get('theme')
  }
}