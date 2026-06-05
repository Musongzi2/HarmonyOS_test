// network/dsl/annotations.ets

export const GET = (url: string) => createMethodDecorator('GET', url)
export const POST = (url: string) => createMethodDecorator('POST', url)

function createMethodDecorator(method: string, url: string) {
  return (_target: Object, _prop: string, descriptor: PropertyDescriptor) => {
    const fn = descriptor.value
    descriptor.value = function (...args: Array<ESObject>) {
      const builder = new RequestBuilder()
      builder.method = method
      builder.path = url
      builder.args = args
      return builder
    }
  }
}

// 缓存注解
export const Cache = (options?: { ttl?: number }) => {
  return (_target: Object, _prop: string, descriptor: PropertyDescriptor) => {
    const fn = descriptor.value
    descriptor.value = function (...args: Array<ESObject>) {
      const builder = new RequestBuilder()
      builder.useCache = true
      builder.cacheTtl = options?.ttl || 5 * 60 * 1000 // 默认5分钟
      builder.args = args
      return builder
    }
  }
}