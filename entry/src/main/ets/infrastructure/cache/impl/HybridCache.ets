// infrastructure/cache/impl/HybridCache.ets
import { ICache, CacheOptions } from '../ICache'

export class HybridCache<K, V> implements ICache<K, V> {
  private memoryCache: ICache<K, V>
  private diskCache: ICache<K, V>

  constructor(memoryCache: ICache<K, V>, diskCache: ICache<K, V>) {
    this.memoryCache = memoryCache
    this.diskCache = diskCache
  }

  async get(key: K): Promise<V | null> {
    let value: V | null = await this.memoryCache.get(key)
    if (value !== null) {
      console.log('[HybridCache] Memory hit')
      return value
    }

    value = await this.diskCache.get(key)
    if (value !== null) {
      console.log('[HybridCache] Disk hit')
      await this.memoryCache.set(key, value)
      return value
    }

    return null
  }

  async set(key: K, value: V, options?: CacheOptions): Promise<void> {
    await Promise.all([
      this.memoryCache.set(key, value, options),
      this.diskCache.set(key, value, options)
    ])
  }

  async delete(key: K): Promise<boolean> {
    const memDeleted: boolean = await this.memoryCache.delete(key)
    const diskDeleted: boolean = await this.diskCache.delete(key)
    return memDeleted || diskDeleted
  }

  async clear(): Promise<void> {
    await Promise.all([
      this.memoryCache.clear(),
      this.diskCache.clear()
    ])
  }

  async has(key: K): Promise<boolean> {
    const inMemory: boolean = await this.memoryCache.has(key)
    if (inMemory) return true
    return this.diskCache.has(key)
  }

  async size(): Promise<number> {
    const memSize: number = await this.memoryCache.size()
    const diskSize: number = await this.diskCache.size()
    return memSize + diskSize
  }
}