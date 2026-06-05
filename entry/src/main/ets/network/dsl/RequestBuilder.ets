// network/dsl/RequestBuilder.ets
import { http } from '@kit.NetworkKit'
import { HybridCache } from '../../infrastructure/cache/impl/HybridCache'
import { MemoryCache } from '../../infrastructure/cache/impl/MemoryCache'
import { DiskCache } from '../../infrastructure/cache/impl/DiskCache'
import { FileStorageAdapter } from '../../infrastructure/cache/adapter/FileStorageAdapter'
import { NetworkConfig } from '../Api'
import { RequestContext, ResponseContext, InterceptorChain } from '../interceptor/Interceptor'
import { ApiResponse } from '../model/ApiResponse'

interface CacheEntry {
  data: ESObject
  expireAt: number
}

interface BizResult<T> {
  data: T | null
  isIntercepted: boolean
  bizMsg: string
}

/**
 * 网络请求构建器
 * 支持 DSL 链式调用，集成缓存层、拦截器链、统一响应体解析
 */
export class RequestBuilder {
  method!: string
  path!: string
  args!: Array<ESObject>
  useCache: boolean = false
  cacheTtl: number = 5 * 60 * 1000
  /** 强制下发回调 - 即使业务码拦截也返回数据 */
  forceReceive: boolean = false
  private cacheCallback?: (data: ESObject) => void
  private hybridCache: HybridCache<string, ESObject>
  private queryParams: Record<string, string> = {}
  private requestBody: string = ''
  private customHeaders: Record<string, string> = {}

  constructor() {
    const memCache: MemoryCache<string, ESObject> = new MemoryCache<string, ESObject>(200)
    const diskAdapter: FileStorageAdapter<string, string> = new FileStorageAdapter<string, string>('/data/storage/el2/base/haps/entry/cache/network')
    const diskCache: DiskCache<string, ESObject> = new DiskCache<string, ESObject>(diskAdapter, 1)
    this.hybridCache = new HybridCache<string, ESObject>(memCache, diskCache)
  }

  // DSL 方法
  query(params: Record<string, string>): RequestBuilder {
    this.queryParams = params
    return this
  }

  body(data: string): RequestBuilder {
    this.requestBody = data
    return this
  }

  header(headers: Record<string, string>): RequestBuilder {
    const keys: string[] = Object.keys(headers)
    for (let i: number = 0; i < keys.length; i++) {
      const key: string = keys[i]
      this.customHeaders[key] = headers[key]
    }
    return this
  }

  onCache(callback: (data: ESObject) => void): RequestBuilder {
    this.cacheCallback = callback
    return this
  }

  /**
   * 强制下发回调，忽略业务码拦截
   * 用于必须获取数据的场景，如异常登录拦截后仍然需要拿到错误详情
   */
  forceResponse(): RequestBuilder {
    this.forceReceive = true
    return this
  }

  /**
   * 执行请求并自动解析 ApiResponse，返回解包后的 data
   */
  async execute<T = ESObject>(): Promise<T> {
    const cacheKey: string = this.buildCacheKey()

    // 1. 尝试从缓存获取
    if (this.useCache) {
      const cached: ESObject | null = await this.hybridCache.get(cacheKey)
      if (cached && this.cacheCallback) {
        this.cacheCallback(cached)
      }
      if (cached) {
        console.info('[RequestBuilder] 命中缓存:', this.path)
        return cached as T
      }
    }

    // 2. 发起真实网络请求
    const result: BizResult<T> =
      await this.executeNetworkWithBiz<T>()

    // 3. 业务码被拦截且未设置 forceReceive，抛出异常
    if (result.isIntercepted && !this.forceReceive) {
      throw new BusinessCodeError(result.bizMsg)
    }

    // 4. 更新缓存
    if (this.useCache && result.data) {
      await this.hybridCache.set(cacheKey, result.data as ESObject)
    }

    return result.data as T
  }

  private buildCacheKey(): string {
    return `${this.method}:${this.path}:${JSON.stringify(this.args)}:${JSON.stringify(this.queryParams)}`
  }

  /**
   * 构建拦截器用的 RequestContext
   */
  private buildRequestContext(): RequestContext {
    const ctx: RequestContext = new RequestContext()
    ctx.method = this.method
    ctx.path = this.path
    ctx.queryParams = this.queryParams
    ctx.body = this.requestBody

    // 合并请求头
    const headers: Record<string, string> = {}
    const defaultKeys: string[] = Object.keys(NetworkConfig.DEFAULT_HEADERS)
    for (let i: number = 0; i < defaultKeys.length; i++) {
      const key: string = defaultKeys[i]
      headers[key] = NetworkConfig.DEFAULT_HEADERS[key]
    }
    const customKeys: string[] = Object.keys(this.customHeaders)
    for (let i: number = 0; i < customKeys.length; i++) {
      const key: string = customKeys[i]
      headers[key] = this.customHeaders[key]
    }
    ctx.headers = headers

    ctx.url = this.buildUrlFromContext(ctx)
    return ctx
  }

  /**
   * 从 context 构建完整 URL
   */
  private buildUrlFromContext(ctx: RequestContext): string {
    let url: string = NetworkConfig.BASE_URL + ctx.path

    const keys: string[] = Object.keys(ctx.queryParams)
    if (keys.length > 0) {
      const queryParts: string[] = []
      for (let i: number = 0; i < keys.length; i++) {
        const key: string = keys[i]
        queryParts.push(`${encodeURIComponent(key)}=${encodeURIComponent(ctx.queryParams[key])}`)
      }
      url += '?' + queryParts.join('&')
    }

    return url
  }

  /**
   * 网络请求 + 统一响应体解析 + 业务码判断
   */
  private async executeNetworkWithBiz<T>(): Promise<BizResult<T>> {
    const requestCtx: RequestContext = this.buildRequestContext()

    // 执行拦截器链 - onRequest
    const shouldContinue: boolean = await InterceptorChain.executeRequest(requestCtx)
    if (!shouldContinue) {
      throw new Error('请求被拦截器中断')
    }

    const url: string = this.buildUrlFromContext(requestCtx)
    const httpRequest: http.HttpRequest = http.createHttp()
    const startTime: number = Date.now()

    try {
      const requestOptions: http.HttpRequestOptions = {
        method: this.parseMethod(),
        header: requestCtx.headers,
        connectTimeout: NetworkConfig.TIMEOUT,
        readTimeout: NetworkConfig.TIMEOUT
      }

      if (requestCtx.body.length > 0) {
        requestOptions.extraData = requestCtx.body
      }

      const response: http.HttpResponse = await httpRequest.request(url, requestOptions)
      const responseData: string = response.result as string

      // 构建响应上下文
      const responseCtx: ResponseContext = new ResponseContext()
      responseCtx.statusCode = response.responseCode
      responseCtx.body = responseData
      responseCtx.duration = Date.now() - startTime

      // 执行拦截器链 - onResponse（含 BusinessCodeInterceptor）
      await InterceptorChain.executeResponse(requestCtx, responseCtx)

      // HTTP 非 200/201，直接抛异常
      if (response.responseCode !== 200 && response.responseCode !== 201) {
        throw new Error(`HTTP ${response.responseCode}: ${responseData}`)
      }

      // 解析统一响应体 ApiResponse<T>
      const apiResp: ApiResponse<T> = JSON.parse(responseData) as ApiResponse<T>

      // 从 context.extras 读取业务码拦截标记
      const isIntercepted: boolean = requestCtx.extras['businessCodeIntercepted'] === true
      const bizMsg: string = apiResp.rpMsg || ''

      // 如果被拦截且未设置 forceReceive，不下发 data
      if (isIntercepted && !this.forceReceive) {
        const interceptedResult: BizResult<T> = { data: null, isIntercepted: true, bizMsg: bizMsg }
        return interceptedResult
      }

      // 正常返回：即使 rpCode !== 0，只要没被拦截器处理或设置了 forceReceive，就返回 data
      const successResult: BizResult<T> = { data: apiResp.data, isIntercepted: false, bizMsg: bizMsg }
      return successResult

    } catch (err) {
      const errorCtx: ResponseContext = new ResponseContext()
      errorCtx.statusCode = 0
      errorCtx.body = JSON.stringify(err)
      errorCtx.duration = Date.now() - startTime

      await InterceptorChain.executeResponse(requestCtx, errorCtx)
      const errMsg: string = (err as Error).message || '网络请求失败'
      throw new Error(errMsg)
    } finally {
      httpRequest.destroy()
    }
  }

  /**
   * 解析 HTTP 方法
   */
  private parseMethod(): http.RequestMethod {
    switch (this.method.toUpperCase()) {
      case 'POST':
        return http.RequestMethod.POST
      case 'PUT':
        return http.RequestMethod.PUT
      case 'DELETE':
        return http.RequestMethod.DELETE
      case 'GET':
      default:
        return http.RequestMethod.GET
    }
  }
}

/**
 * 业务码错误 - 当请求被业务码拦截器拦截时抛出
 */
export class BusinessCodeError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'BusinessCodeError'
  }
}