// infrastructure/cache/adapter/FileStorageAdapter.ets
import fileIo from '@ohos.fileio'
import { IStorageAdapter } from '../IStorageAdapter'

export class FileStorageAdapter<K, string> implements IStorageAdapter<K, string> {
  private baseDir: string

  constructor(baseDir: string) {
    this.baseDir = baseDir
  }

  async read(key: K): Promise<string | null> {
    const path = this.getKeyPath(key)
    try {
      const fd = await fileIo.open(path, fileIo.OpenMode.READ_ONLY)
      const stat = await fileIo.stat(path)
      const buffer = new ArrayBuffer(stat.size)
      await fileIo.read(fd, buffer)
      await fileIo.close(fd)
      return buffer.toString()
    } catch {
      return null
    }
  }

  async write(key: K, data: string): Promise<void> {
    const path = this.getKeyPath(key)
    const fd = await fileIo.open(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
    await fileIo.write(fd, data)
    await fileIo.close(fd)
  }

  private getKeyPath(key: K): string {
    const hash = this.hashKey(String(key))
    return `${this.baseDir}/${hash}`
  }

  // ... 其他方法
}