// network/interceptor/BusinessCodeInterceptor.ets
import { IInterceptor, RequestContext, ResponseContext } from './Interceptor'
import { CallbackRegistry, BizErrorInfo } from './CallbackRegistry'
import { ApiResponse } from '../model/ApiResponse'

/**
 * 业务码拦截器
 *
 * 职责：
 * 1. 解析后端返回的 ApiResponse<ESObject> 统一响应体
 * 2. 如果 rpCode 为特殊错误码（如 20000 异常登录），拦截响应：
 *    - 调用 CallbackRegistry 中注册的回调（按权重顺序）
 *    - 阻止响应数据下发给页面层
 * 3. 如果请求设置了 forceReceive=true，则即使业务错误也下发回调
 *
 * 注册方式：
 * ```
 * BusinessCodeInterceptor.registerHandler(20000, (info) => { logout() }, 10)
 * BusinessCodeInterceptor.registerHandler(20001, (info) => { showError() }, 20)
 * InterceptorChain.register(new BusinessCodeInterceptor())
 * ```
 */
export class BusinessCodeInterceptor implements IInterceptor {
  readonly name: string = 'BusinessCode'
  readonly priority: number = 10

  /** 全局业务码回调注册表 */
  static readonly handlers: CallbackRegistry<BizErrorInfo> = new CallbackRegistry<BizErrorInfo>()

  /**
   * 注册业务码处理器（快捷方法）
   * @param code 业务错误码
   * @param handler 处理函数
   * @param weight 权重，越小越先执行，默认 100
   */
  static registerHandler(code: number, handler: (info: BizErrorInfo) => void, weight: number = 100): void {
    BusinessCodeInterceptor.handlers.register(code, handler, weight)
  }

  /**
   * 取消注册业务码处理器
   */
  static unregisterHandler(code: number, handler: (info: BizErrorInfo) => void): void {
    BusinessCodeInterceptor.handlers.unregister(code, handler)
  }

  async onRequest(_context: RequestContext): Promise<boolean> {
    return true
  }

  async onResponse(context: RequestContext, response: ResponseContext): Promise<void> {
    // 只处理 HTTP 成功的响应
    if (response.statusCode !== 200 && response.statusCode !== 201) {
      return
    }

    // 尝试解析统一响应体
    let apiResp: ApiResponse<ESObject> | null = null
    try {
      apiResp = JSON.parse(response.body) as ApiResponse<ESObject>
    } catch {
      // 不是标准 JSON 格式，跳过
      return
    }

    if (!apiResp || apiResp.rpCode === undefined) {
      return
    }

    const rpCode: number = apiResp.rpCode

    // 将业务码存入 context.extras，供 RequestBuilder 使用
    context.extras['businessCode'] = rpCode
    context.extras['businessMsg'] = apiResp.rpMsg

    // 成功码，不拦截
    if (rpCode === 0) {
      return
    }

    // 检查是否有注册的处理器
    const hasHandlers: boolean = BusinessCodeInterceptor.handlers.dispatch(rpCode,
      new BizErrorInfo(rpCode, apiResp.rpMsg, context.path, response.body))

    if (hasHandlers) {
      console.info(`[BusinessCodeInterceptor] 业务码 ${rpCode} 已被拦截, msg: ${apiResp.rpMsg}`)
      // 标记该请求被拦截，RequestBuilder 将据此决定是否下发
      context.extras['businessCodeIntercepted'] = true
    }
  }
}
