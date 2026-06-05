// network/dsl/annotations.ets
import { RequestBuilder } from './RequestBuilder'

// 模块级暂存
let cacheTtlSnapshot: number | null = null
let cacheEnabled: boolean = false

// 缓存注解
interface CacheOptions {
  ttl?: number
}

export const Cache = (options?: CacheOptions): Function => {
  return (_target: Object, _prop: string, _descriptor: PropertyDescriptor): void => {
    cacheEnabled = true
    cacheTtlSnapshot = options?.ttl || null
  }
}

/**
 * GET 请求装饰器
 * @param url 请求路径，如 '/user/profile'
 * @param paramNames 可选，方法参数对应的 query 参数名数组，按顺序映射
 *   例：@GET('/user/profile', ['userId']) → getProfile(userId: number) → ?userId=xxx
 *   不传则不带 query 参数
 */
export const GET = (url: string, paramNames?: string[]): Function => {
  return (_target: Object, _prop: string, descriptor: PropertyDescriptor): void => {
    descriptor.value = (...args: Array<ESObject>): RequestBuilder => {
      const builder: RequestBuilder = new RequestBuilder()
      builder.method = 'GET'
      builder.path = url
      builder.args = args

      // 消费 @Cache 暂存的配置
      if (cacheEnabled) {
        builder.useCache = true
        builder.cacheTtl = cacheTtlSnapshot || 5 * 60 * 1000
        cacheEnabled = false
        cacheTtlSnapshot = null
      }

      // 自动映射参数名 → query params
      if (paramNames && paramNames.length > 0) {
        const params: Record<string, string> = {}
        for (let i: number = 0; i < paramNames.length && i < args.length; i++) {
          params[paramNames[i]] = String(args[i])
        }
        builder.query(params)
      }

      return builder
    }
  }
}

/**
 * POST 请求装饰器
 * @param url 请求路径，如 '/api/users'
 * @param bodyIndex 可选，方法参数中作为请求体的参数索引（默认 0），传 -1 表示不设置 body
 *   例：@POST('/api/users') → createUser(data: User) → body = JSON.stringify(data)
 */
export const POST = (url: string, bodyIndex?: number): Function => {
  return (_target: Object, _prop: string, descriptor: PropertyDescriptor): void => {
    const idx: number = bodyIndex !== undefined ? bodyIndex : 0
    descriptor.value = (...args: Array<ESObject>): RequestBuilder => {
      const builder: RequestBuilder = new RequestBuilder()
      builder.method = 'POST'
      builder.path = url
      builder.args = args

      // 消费 @Cache 暂存的配置
      if (cacheEnabled) {
        builder.useCache = true
        builder.cacheTtl = cacheTtlSnapshot || 5 * 60 * 1000
        cacheEnabled = false
        cacheTtlSnapshot = null
      }

      // 自动设置 body（默认第一个参数）
      if (idx >= 0 && idx < args.length) {
        builder.body(JSON.stringify(args[idx]))
      }

      return builder
    }
  }
}

// 保留 applyToBuilder 以便向后兼容和高级场景
let pendingBuilder: RequestBuilder | null = null

/**
 * 【已废弃】建议使用新的声明式参数映射方式。
 * 保留此方法用于需要链式配置 header/onCache/forceResponse 等高级场景。
 */
export function applyToBuilder(configure: (builder: RequestBuilder) => void): RequestBuilder {
  if (!pendingBuilder) {
    throw new Error('applyToBuilder() 只能在被 @GET/@POST 装饰的方法体内调用')
  }
  configure(pendingBuilder)
  return pendingBuilder
}
