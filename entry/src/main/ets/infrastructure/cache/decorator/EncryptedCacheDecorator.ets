// infrastructure/cache/decorator/EncryptedCacheDecorator.ets
import { ICache } from '../ICache'
import cryptoFramework from '@ohos.security.cryptoFramework'

export class EncryptedCacheDecorator<K, V> implements ICache<K, V> {
  constructor(
    private wrapped: ICache<K, V>,
    private secretKey: string
  ) {}

  async set(key: K, value: V, options?: ESObject): Promise<void> {
    const encrypted = await this.encrypt(JSON.stringify(value))
    await this.wrapped.set(key, encrypted, options)
  }

  async get(key: K): Promise<V | null> {
    const encrypted = await this.wrapped.get(key)
    if (!encrypted) return null
    const decrypted = await this.decrypt(encrypted)
    return JSON.parse(decrypted)
  }

  // ... 其他方法委托给 wrapped
}