// network/interceptor/AtomicParamInterceptor.ets
import { IInterceptor, RequestContext, ResponseContext } from './Interceptor'

/**
 * 原子参数提供者接口
 * 业务方实现此接口来提供动态参数（如 token、userId、设备信息等）
 */
export interface IAtomicParamProvider {
  /**
   * 获取原子参数
   * 返回的参数会自动拼接到请求 URL 上
   */
  getParams(): Promise<Record<string, string>>
}

/**
 * 原子参数拦截器
 *
 * 职责：在请求发起前，从 IAtomicParamProvider 获取原子参数并拼接到 URL
 *
 * 使用方式：
 * ```
 * const provider: IAtomicParamProvider = {
 *   async getParams() {
 *     return { token: 'xxx', deviceId: 'yyy' }
 *   }
 * }
 * InterceptorChain.register(new AtomicParamInterceptor(provider))
 * ```
 */
export class AtomicParamInterceptor implements IInterceptor {
  readonly name: string = 'AtomicParam'
  readonly priority: number = 5

  private provider: IAtomicParamProvider
  /** 标记是否正在获取参数，避免递归轮询 */
  private fetching: boolean = false

  constructor(provider: IAtomicParamProvider) {
    this.provider = provider
  }

  async onRequest(context: RequestContext): Promise<boolean> {
    // 防止递归轮询：如果当前请求本身就是获取原子参数的请求，则跳过
    if (this.fetching) {
      console.info('[AtomicParamInterceptor] 跳过: 当前正在获取原子参数')
      return true
    }

    try {
      this.fetching = true
      const atomicParams: Record<string, string> = await this.provider.getParams()
      console.info('[AtomicParamInterceptor] 获取原子参数:', JSON.stringify(atomicParams))

      // 合并到 queryParams，原子参数优先级低于已有参数（不覆盖）
      const keys: string[] = Object.keys(atomicParams)
      for (let i: number = 0; i < keys.length; i++) {
        const key: string = keys[i]
        if (!(key in context.queryParams)) {
          context.queryParams[key] = atomicParams[key]
        }
      }
    } catch (err) {
      console.warn('[AtomicParamInterceptor] 获取原子参数失败:', JSON.stringify(err))
    } finally {
      this.fetching = false
    }

    return true
  }

  async onResponse(_context: RequestContext, _response: ResponseContext): Promise<void> {
    // 原子参数拦截器不需要处理响应
  }
}
