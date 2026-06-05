// infrastructure/cache/IStorageAdapter.ets

/**
 * 存储适配器接口
 * 负责具体的读写操作
 */
export interface IStorageAdapter<K, V> {
  /**
   * 读取原始数据
   */
  read(key: K): Promise<string | null>

  /**
   * 写入原始数据
   */
  write(key: K, data: string): Promise<void>

  /**
   * 删除原始数据
   */
  remove(key: K): Promise<boolean>

  /**
   * 清空所有数据
   */
  clear(): Promise<void>

  /**
   * 获取存储使用情况
   */
  getUsage(): Promise<StorageUsage>
}

export interface StorageUsage {
  used: number    // 已使用字节数
  total: number   // 总容量字节数
  available: number // 可用字节数
}