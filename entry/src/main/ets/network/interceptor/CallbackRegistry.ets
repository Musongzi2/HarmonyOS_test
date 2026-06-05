// network/interceptor/CallbackRegistry.ets

/**
 * 带权重的回调条目
 */
class CallbackEntry<T> {
  callback: (data: T) => void
  /** 权重，数字越小越先执行 */
  weight: number

  constructor(callback: (data: T) => void, weight: number) {
    this.callback = callback
    this.weight = weight
  }
}

/**
 * 通用回调注册表
 *
 * 支持按 key（如业务错误码）注册多个回调，按权重排序执行。
 * 抽象设计，可用于任意 key → callbacks 场景。
 *
 * 使用示例：
 * ```
 * const registry = new CallbackRegistry<BizErrorInfo>()
 * registry.register(20000, (info) => { logout() }, 10)
 * registry.register(20000, (info) => { showToast() }, 20)
 * registry.dispatch(20000, { code: 20000, msg: '异常登录' })
 * ```
 */
export class CallbackRegistry<T> {
  private callbacks: Map<number, Array<CallbackEntry<T>>> = new Map()

  /**
   * 注册回调
   * @param key 业务码
   * @param callback 回调函数
   * @param weight 权重，数字越小越先执行，默认 100
   */
  register(key: number, callback: (data: T) => void, weight: number = 100): void {
    let entries: Array<CallbackEntry<T>> | undefined = this.callbacks.get(key)
    if (!entries) {
      entries = new Array<CallbackEntry<T>>()
      this.callbacks.set(key, entries)
    }
    entries.push(new CallbackEntry<T>(callback, weight))
    // 按权重排序
    entries.sort((a: CallbackEntry<T>, b: CallbackEntry<T>) => a.weight - b.weight)
  }

  /**
   * 取消注册
   * @param key 业务码
   * @param callback 要移除的回调（引用相等判断）
   */
  unregister(key: number, callback: (data: T) => void): void {
    const entries: Array<CallbackEntry<T>> | undefined = this.callbacks.get(key)
    if (entries) {
      const filtered: Array<CallbackEntry<T>> = entries.filter((e: CallbackEntry<T>) => e.callback !== callback)
      if (filtered.length === 0) {
        this.callbacks.delete(key)
      } else {
        this.callbacks.set(key, filtered)
      }
    }
  }

  /**
   * 清除指定 key 的所有回调
   */
  clearKey(key: number): void {
    this.callbacks.delete(key)
  }

  /**
   * 清除所有回调
   */
  clearAll(): void {
    this.callbacks.clear()
  }

  /**
   * 分发回调
   * 按权重顺序依次执行所有注册在 key 下的 callback
   * @returns 是否有回调被执行
   */
  dispatch(key: number, data: T): boolean {
    const entries: Array<CallbackEntry<T>> | undefined = this.callbacks.get(key)
    if (!entries || entries.length === 0) {
      return false
    }
    for (let i: number = 0; i < entries.length; i++) {
      const entry: CallbackEntry<T> = entries[i]
      try {
        entry.callback(data)
      } catch (err) {
        console.error(`[CallbackRegistry] key=${key} callback[${i}] 执行异常:`, JSON.stringify(err))
      }
    }
    return true
  }
}

/**
 * 业务错误信息，分发给 callback 的数据结构
 */
export class BizErrorInfo {
  /** 业务错误码 */
  code: number
  /** 错误消息 */
  message: string
  /** 请求路径（便于判断来源） */
  path: string
  /** 原始响应体 */
  rawBody: string

  constructor(code: number, message: string, path: string, rawBody: string) {
    this.code = code
    this.message = message
    this.path = path
    this.rawBody = rawBody
  }
}
