// network/interceptor/LoggingInterceptor.ets
import { IInterceptor, RequestContext, ResponseContext } from './Interceptor'

/**
 * 日志拦截器
 *
 * 职责：在请求前输出所有请求参数，在响应后输出回调信息
 *
 * 使用方式：
 * ```
 * InterceptorChain.register(new LoggingInterceptor())
 * ```
 */
export class LoggingInterceptor implements IInterceptor {
  readonly name: string = 'Logging'
  /** 最高优先级：onRequest 最先执行，onResponse 最后执行（倒序），保证无论正常还是错误都能记录完整日志 */
  readonly priority: number = 0

  async onRequest(context: RequestContext): Promise<boolean> {
    console.info('═══════════════════════════════════════')
    console.info('[LoggingInterceptor] >>> 请求开始 <<<')
    console.info(`[LoggingInterceptor] Method : ${context.method}`)
    console.info(`[LoggingInterceptor] Path   : ${context.path}`)
    console.info(`[LoggingInterceptor] URL    : ${context.url}`)

    // 输出请求头
    const headerKeys: string[] = Object.keys(context.headers)
    if (headerKeys.length > 0) {
      const headerOutput: string[] = []
      for (let i: number = 0; i < headerKeys.length; i++) {
        const key: string = headerKeys[i]
        // 敏感字段脱敏
        const sensitiveKeys: string[] = ['Authorization', 'Cookie', 'token']
        const isSensitive: boolean = sensitiveKeys.some((s: string) => key.toLowerCase().includes(s.toLowerCase()))
        const value: string = isSensitive ? '***' : context.headers[key]
        headerOutput.push(`  ${key}: ${value}`)
      }
      console.info(`[LoggingInterceptor] Headers:\n${headerOutput.join('\n')}`)
    }

    // 输出查询参数
    const queryKeys: string[] = Object.keys(context.queryParams)
    if (queryKeys.length > 0) {
      const queryOutput: string[] = []
      for (let i: number = 0; i < queryKeys.length; i++) {
        const key: string = queryKeys[i]
        queryOutput.push(`  ${key}=${context.queryParams[key]}`)
      }
      console.info(`[LoggingInterceptor] QueryParams:\n${queryOutput.join('\n')}`)
    }

    // 输出请求体
    if (context.body.length > 0) {
      const bodyPreview: string = context.body.length > 500 ? context.body.substring(0, 500) + '...' : context.body
      console.info(`[LoggingInterceptor] Body: ${bodyPreview}`)
    }

    // 输出扩展数据
    const extraKeys: string[] = Object.keys(context.extras)
    if (extraKeys.length > 0) {
      const extraOutput: string[] = []
      for (let i: number = 0; i < extraKeys.length; i++) {
        const key: string = extraKeys[i]
        extraOutput.push(`  ${key}: ${JSON.stringify(context.extras[key])}`)
      }
      console.info(`[LoggingInterceptor] Extras:\n${extraOutput.join('\n')}`)
    }

    return true
  }

  async onResponse(_context: RequestContext, response: ResponseContext): Promise<void> {
    console.info('[LoggingInterceptor] >>> 请求响应 <<<')
    console.info(`[LoggingInterceptor] Status  : ${response.statusCode}`)
    console.info(`[LoggingInterceptor] Duration: ${response.duration}ms`)

    // 输出响应头
    const headerKeys: string[] = Object.keys(response.headers)
    if (headerKeys.length > 0) {
      const headerOutput: string[] = []
      for (let i: number = 0; i < headerKeys.length; i++) {
        const key: string = headerKeys[i]
        headerOutput.push(`  ${key}: ${response.headers[key]}`)
      }
      console.info(`[LoggingInterceptor] Response Headers:\n${headerOutput.join('\n')}`)
    }

    // 输出响应体预览
    const bodyPreview: string = response.body.length > 1000 ? response.body.substring(0, 1000) + '...' : response.body
    console.info(`[LoggingInterceptor] Response Body: ${bodyPreview}`)
    console.info('═══════════════════════════════════════')
  }
}
