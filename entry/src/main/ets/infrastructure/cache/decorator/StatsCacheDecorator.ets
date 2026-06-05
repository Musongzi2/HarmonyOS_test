// infrastructure/cache/decorator/StatsCacheDecorator.ets
export class StatsCacheDecorator<K, V> implements ICache<K, V> {
  private hits = 0
  private misses = 0

  async get(key: K): Promise<V | null> {
    const value = await this.wrapped.get(key)
    if (value) {
      this.hits++
    } else {
      this.misses++
    }
    return value
  }

  getStats() {
    return {
      hits: this.hits,
      misses: this.misses,
      hitRate: this.hits / (this.hits + this.misses)
    }
  }
}