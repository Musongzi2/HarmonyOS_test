// infrastructure/cache/decorator/EncryptedCacheDecorator.ets
import { ICache, CacheOptions } from '../ICache'

export class EncryptedCacheDecorator<K, V> implements ICache<K, V> {
  constructor(
    private wrapped: ICache<K, V>,
    private secretKey: string
  ) {}

  async set(key: K, value: V, options?: CacheOptions): Promise<void> {
    const encrypted: string = await this.encrypt(JSON.stringify(value))
    await this.wrapped.set(key, encrypted as V, options)
  }

  async get(key: K): Promise<V | null> {
    const encrypted: V | null = await this.wrapped.get(key)
    if (!encrypted) return null
    const decrypted: string = await this.decrypt(encrypted as string)
    return JSON.parse(decrypted) as V
  }

  async delete(key: K): Promise<boolean> {
    return this.wrapped.delete(key)
  }

  async clear(): Promise<void> {
    await this.wrapped.clear()
  }

  async has(key: K): Promise<boolean> {
    return this.wrapped.has(key)
  }

  async size(): Promise<number> {
    return this.wrapped.size()
  }

  private async encrypt(data: string): Promise<string> {
    return data
  }

  private async decrypt(data: string): Promise<string> {
    return data
  }
}