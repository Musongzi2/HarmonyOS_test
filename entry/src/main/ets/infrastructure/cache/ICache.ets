// infrastructure/cache/ICache.ets

/**
 * 缓存级别
 */
export enum CacheLevel {
  MEMORY = 'MEMORY',
  DISK = 'DISK'
}

/**
 * 通用缓存接口
 * 不关心具体存储方式，只定义行为
 */
export interface ICache<K, V> {
  /**
   * 获取缓存
   */
  get(key: K): Promise<V | null>

  /**
   * 设置缓存
   */
  set(key: K, value: V, options?: CacheOptions): Promise<void>

  /**
   * 删除缓存
   */
  delete(key: K): Promise<boolean>

  /**
   * 清空所有缓存
   */
  clear(): Promise<void>

  /**
   * 检查是否存在
   */
  has(key: K): Promise<boolean>

  /**
   * 获取缓存大小
   */
  size(): Promise<number>
}

/**
 * 缓存选项
 */
export interface CacheOptions {
  /** 存活时间（毫秒） */
  ttl?: number
  /** 最大大小（字节） */
  maxSize?: number
  /** 缓存级别 */
  level?: CacheLevel
}