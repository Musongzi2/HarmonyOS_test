// infrastructure/cache/CacheFactory.ets
import { DiskCache } from "./impl/DiskCache"
import { FileStorageAdapter } from "./adapter/FileStorageAdapter"
import { HybridCache } from "./impl/HybridCache"
import { ICache } from "./ICache"
import { MemoryCache } from "./impl/MemoryCache"

export enum CacheType {
  MEMORY = 'MEMORY',
  DISK = 'DISK',
  HYBRID = 'HYBRID'
}

export class CacheFactory {
  /**
   * 创建缓存实例
   */
  static createCache<K, V>(
    type: CacheType,
    options?: {
      memoryMaxSizeMB?: number
      diskMaxSizeGB?: number
      baseDir?: string
    }
  ): ICache<K, V> {
    switch (type) {
      case CacheType.MEMORY:
        return new MemoryCache<K, V>(options?.memoryMaxSizeMB || 200)

      case CacheType.DISK:
        const adapter = new FileStorageAdapter<K, string>(options?.baseDir || '')
        return new DiskCache<K, V>(adapter, options?.diskMaxSizeGB || 1)

      case CacheType.HYBRID:
        const memoryCache = new MemoryCache<K, V>(options?.memoryMaxSizeMB || 200)
        const diskAdapter = new FileStorageAdapter<K, string>(options?.baseDir || '')
        const diskCache = new DiskCache<K, V>(diskAdapter, options?.diskMaxSizeGB || 1)
        return new HybridCache<K, V>(memoryCache, diskCache)

      default:
        throw new Error(`Unknown cache type: ${type}`)
    }
  }
}