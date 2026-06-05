// infrastructure/cache/impl/DiskCache.ets
import { ICache } from '../ICache'
import { IStorageAdapter } from '../IStorageAdapter'
import { FileStorageAdapter } from '../adapter/FileStorageAdapter'
import { CacheOptions } from '../ICache'

export class DiskCache<K, V> implements ICache<K, V> {
  private adapter: IStorageAdapter<K, string>
  private maxSize: number
  private usedSize = 0

  constructor(
    adapter: IStorageAdapter<K, string>,
    maxSizeInGB: number = 1
  ) {
    this.adapter = adapter
    this.maxSize = maxSizeInGB * 1024 * 1024 * 1024
  }

  async get(key: K): Promise<V | null> {
    const data = await this.adapter.read(key)
    if (!data) return null

    try {
      return JSON.parse(data) as V
    } catch {
      return null
    }
  }

  async set(key: K, value: V, options?: CacheOptions): Promise<void> {
    const data = JSON.stringify(value)
    const size = data.length * 2

    // 检查容量
    const usage = await this.adapter.getUsage()
    if (usage.available < size) {
      await this.evictOldest(size)
    }

    await this.adapter.write(key, data)
  }

  // ... 其他方法
}