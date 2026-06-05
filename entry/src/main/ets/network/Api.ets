// network/Api.ets
import { UserApi } from './service/UserApi'
import { ProductApi } from './service/ProductApi'
import { InterceptorChain } from './interceptor/Interceptor'
import { LoggingInterceptor } from './interceptor/LoggingInterceptor'
import { BusinessCodeInterceptor } from './interceptor/BusinessCodeInterceptor'
import { BizErrorInfo } from './interceptor/CallbackRegistry'
import { BusinessCode } from './model/ApiResponse'

/**
 * 网络配置
 */
export class NetworkConfig {
  /** 基础地址 - 修改为你的 Spring Boot 服务地址 */
  static readonly BASE_URL: string = 'http://192.168.213.176:8081'
  /** 请求超时时间（毫秒） */
  static readonly TIMEOUT: number = 30000
  /** 默认请求头 */
  static readonly DEFAULT_HEADERS: Record<string, string> = {
    'Content-Type': 'application/json'
  }
}

class ApiClient {
  user: UserApi = new UserApi()
  product: ProductApi = new ProductApi()
}

export const api: ApiClient = new ApiClient()

// ========== 注册全局拦截器 ==========

// 1. 日志拦截器 - 最高优先级（priority=0），无论正常/错误都会记录完整日志
InterceptorChain.register(new LoggingInterceptor())

// 2. 业务码拦截器（priority=10），处理业务错误码
InterceptorChain.register(new BusinessCodeInterceptor())

// 3. 原子参数拦截器 - 如需添加 token 等参数，取消注释并按需实现
// import { AtomicParamInterceptor, IAtomicParamProvider } from './interceptor/AtomicParamInterceptor'
// const atomicProvider: IAtomicParamProvider = {
//   async getParams(): Promise<Record<string, string>> {
//     return { token: 'your-token-here', platform: 'harmonyos' }
//   }
// }
// InterceptorChain.register(new AtomicParamInterceptor(atomicProvider))

// ========== 注册全局业务码处理器 ==========

// 异常登录 - 正在退出
BusinessCodeInterceptor.registerHandler(BusinessCode.ABNORMAL_LOGIN, (info: BizErrorInfo) => {
  console.warn('[Global] 异常登录, 即将退出:', info.message)
  // TODO: 跳转到登录页
  // router.pushUrl({ url: 'pages/LoginPage' })
}, 10)

// 未知错误
BusinessCodeInterceptor.registerHandler(BusinessCode.UNKNOWN_ERROR, (info: BizErrorInfo) => {
  console.error('[Global] 未知错误:', info.message)
  // TODO: 弹窗提示
  // promptAction.showToast({ message: info.message })
}, 10)