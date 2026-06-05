// infrastructure/cache/adapter/FileStorageAdapter.ets
import fileIo from '@ohos.fileio'
import { IStorageAdapter, StorageUsage } from '../IStorageAdapter'

export class FileStorageAdapter<K, V> implements IStorageAdapter<K, V> {
  private baseDir: string

  constructor(baseDir: string) {
    this.baseDir = baseDir
  }

  async read(key: K): Promise<string | null> {
    const path: string = this.getKeyPath(key)
    try {
      const fd: number = await fileIo.open(path, 0o0)
      const stat: fileIo.Stat = await fileIo.stat(path)
      const buffer: ArrayBuffer = new ArrayBuffer(stat.size)
      await fileIo.read(fd, buffer)
      await fileIo.close(fd)
      return buffer.toString()
    } catch {
      return null
    }
  }

  async write(key: K, data: string): Promise<void> {
    const path: string = this.getKeyPath(key)
    const fd: number = await fileIo.open(path, 0o102)
    await fileIo.write(fd, data)
    await fileIo.close(fd)
  }

  async remove(key: K): Promise<boolean> {
    const path: string = this.getKeyPath(key)
    try {
      await fileIo.unlink(path)
      return true
    } catch {
      return false
    }
  }

  async clear(): Promise<void> {
    // 简化实现：不递归删除目录
    console.log('FileStorageAdapter: clear called on', this.baseDir)
  }

  async getUsage(): Promise<StorageUsage> {
    return { used: 0, total: 1024 * 1024 * 1024, available: 1024 * 1024 * 1024 }
  }

  private getKeyPath(key: K): string {
    const hash: string = this.hashKey(String(key))
    return `${this.baseDir}/${hash}`
  }

  private hashKey(key: string): string {
    let hash: number = 0
    for (let i: number = 0; i < key.length; i++) {
      const char: number = key.charCodeAt(i)
      hash = ((hash << 5) - hash) + char
      hash = hash & hash
    }
    return Math.abs(hash).toString(16)
  }
}