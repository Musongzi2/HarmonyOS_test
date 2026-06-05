// infrastructure/cache/impl/HybridCache.ets
import { ICache } from '../ICache'

export class HybridCache<K, V> implements ICache<K, V> {
  private memoryCache: ICache<K, V>
  private diskCache: ICache<K, V>

  constructor(memoryCache: ICache<K, V>, diskCache: ICache<K, V>) {
    this.memoryCache = memoryCache
    this.diskCache = diskCache
  }

  async get(key: K): Promise<V | null> {
    // 1. 查内存
    let value = await this.memoryCache.get(key)
    if (value !== null) {
      console.log('[HybridCache] Memory hit')
      return value
    }

    // 2. 查磁盘
    value = await this.diskCache.get(key)
    if (value !== null) {
      console.log('[HybridCache] Disk hit')
      // 回填内存
      await this.memoryCache.set(key, value)
      return value
    }

    return null
  }

  async set(key: K, value: V, options?: CacheOptions): Promise<void> {
    // 同时写入内存和磁盘
    await Promise.all([
      this.memoryCache.set(key, value, options),
      this.diskCache.set(key, value, options)
    ])
  }

  // ... 其他方法
}