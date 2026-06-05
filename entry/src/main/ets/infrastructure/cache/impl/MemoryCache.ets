// infrastructure/cache/impl/MemoryCache.ets
import { ICache } from '../ICache'

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
    const size = this.calculateSize(value)
    const ttl = options?.ttl || 0
    const expiresAt = ttl > 0 ? Date.now() + ttl : undefined

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

  // ... 其他方法省略
}

interface CacheEntry<V> {
  value: V
  size: number
  createdAt: number
  lastAccessed: number
  expiresAt?: number
}