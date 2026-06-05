// network/interceptor/Interceptor.ets

/**
 * 请求上下文 - 在拦截器链中传递
 */
export class RequestContext {
  method: string = ''
  path: string = ''
  url: string = ''
  queryParams: Record<string, string> = {}
  headers: Record<string, string> = {}
  body: string = ''
  /** 扩展数据，各拦截器可读写 */
  extras: Record<string, ESObject> = {}

  constructor() {
  }
}

/**
 * 响应上下文
 */
export class ResponseContext {
  statusCode: number = 0
  headers: Record<string, string> = {}
  body: string = ''
  /** 请求耗时（毫秒） */
  duration: number = 0
  /** 解析后的 ApiResponse 业务码，0 表示成功 */
  businessCode: number = 0
  /** 业务消息 */
  businessMsg: string = ''

  constructor() {
  }
}

/**
 * 拦截器接口
 * 每个拦截器在请求前/后执行，可以修改上下文
 */
export interface IInterceptor {
  /**
   * 拦截器名称
   */
  name: string

  /**
   * 请求前拦截
   * 可以修改 RequestContext，比如添加参数、修改请求头等
   * 返回 false 可以中断请求链
   */
  onRequest(context: RequestContext): Promise<boolean>

  /**
   * 响应后拦截
   * 可以读取/修改 ResponseContext
   */
  onResponse(context: RequestContext, response: ResponseContext): Promise<void>

  /**
   * 请求优先级，数字越小越先执行
   */
  priority: number
}

/**
 * 拦截器链管理器
 */
export class InterceptorChain {
  private static interceptors: Array<IInterceptor> = []

  /**
   * 注册拦截器
   */
  static register(interceptor: IInterceptor): void {
    // 检查是否已存在同名拦截器
    const existIndex: number = InterceptorChain.interceptors.findIndex((item: IInterceptor) => item.name === interceptor.name)
    if (existIndex >= 0) {
      InterceptorChain.interceptors[existIndex] = interceptor
    } else {
      InterceptorChain.interceptors.push(interceptor)
    }
    // 按优先级排序
    InterceptorChain.interceptors.sort((a: IInterceptor, b: IInterceptor) => a.priority - b.priority)
  }

  /**
   * 移除拦截器
   */
  static unregister(name: string): void {
    InterceptorChain.interceptors = InterceptorChain.interceptors.filter((item: IInterceptor) => item.name !== name)
  }

  /**
   * 执行所有拦截器的 onRequest
   * 返回 false 表示被中断
   */
  static async executeRequest(context: RequestContext): Promise<boolean> {
    for (let i: number = 0; i < InterceptorChain.interceptors.length; i++) {
      const interceptor: IInterceptor = InterceptorChain.interceptors[i]
      const shouldContinue: boolean = await interceptor.onRequest(context)
      if (!shouldContinue) {
        console.warn('[InterceptorChain] 请求被拦截器中断:', interceptor.name)
        return false
      }
    }
    return true
  }

  /**
   * 执行所有拦截器的 onResponse（倒序执行）
   */
  static async executeResponse(context: RequestContext, response: ResponseContext): Promise<void> {
    for (let i: number = InterceptorChain.interceptors.length - 1; i >= 0; i--) {
      const interceptor: IInterceptor = InterceptorChain.interceptors[i]
      await interceptor.onResponse(context, response)
    }
  }
}
