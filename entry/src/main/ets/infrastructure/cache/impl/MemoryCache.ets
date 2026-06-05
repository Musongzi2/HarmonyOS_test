// infrastructure/cache/impl/MemoryCache.ets
import { ICache, CacheOptions } from '../ICache'

export class MemoryCache<K, V> implements ICache<K, V> {
  private cache = new Map<K, CacheEntry<V>>()
  private maxSize: number
  private usedSize = 0

  constructor(maxSizeInMB: number = 200) {
    this.maxSize = maxSizeInMB * 1024 * 1024
  }

  async get(key: K): Promise<V | null> {
    const entry = this.cache.get(key)
    if (!entry) return null

    // 检查是否过期
    if (entry.expiresAt && Date.now() > entry.expiresAt) {
      this.cache.delete(key)
      return null
    }

    // 更新访问时间（LRU）
    entry.lastAccessed = Date.now()
    return entry.value
  }

  async set(key: K, value: V, options?: CacheOptions): Promise<void> {
    const size: number = this.calculateSize(value)
    const ttl: number = options?.ttl || 0
    const expiresAt: number | undefined = ttl > 0 ? Date.now() + ttl : undefined

    // 确保有足够空间
    await this.evictIfNeeded(size)

    this.cache.set(key, {
      value,
      size,
      createdAt: Date.now(),
      lastAccessed: Date.now(),
      expiresAt
    })

    this.usedSize += size
  }

  async delete(key: K): Promise<boolean> {
    const existed: boolean = this.cache.has(key)
    this.cache.delete(key)
    return existed
  }

  async clear(): Promise<void> {
    this.cache.clear()
    this.usedSize = 0
  }

  async has(key: K): Promise<boolean> {
    const entry: CacheEntry<V> | undefined = this.cache.get(key)
    if (!entry) return false
    if (entry.expiresAt && Date.now() > entry.expiresAt) {
      this.cache.delete(key)
      return false
    }
    return true
  }

  async size(): Promise<number> {
    return this.cache.size
  }

  private calculateSize(value: V): number {
    return JSON.stringify(value).length * 2
  }

  private async evictIfNeeded(requiredSize: number): Promise<void> {
    if (this.usedSize + requiredSize <= this.maxSize) return
    const entries: Array<CacheEntryItem<K, V>> = []
    this.cache.forEach((entry: CacheEntry<V>, key: K) => {
      entries.push({ key, entry })
    })
    entries.sort((a: CacheEntryItem<K, V>, b: CacheEntryItem<K, V>) => a.entry.lastAccessed - b.entry.lastAccessed)
    for (const item of entries) {
      if (this.usedSize + requiredSize <= this.maxSize) break
      this.cache.delete(item.key)
      this.usedSize -= item.entry.size
    }
  }
}

interface CacheEntryItem<K, V> {
  key: K
  entry: CacheEntry<V>
}

interface CacheEntry<V> {
  value: V
  size: number
  createdAt: number
  lastAccessed: number
  expiresAt?: number
}