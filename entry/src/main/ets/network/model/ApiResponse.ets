// network/model/ApiResponse.ets

/**
 * 统一后端响应体结构
 * { "rpCode": 0, "rpMsg": "", "data": T }
 */
export class ApiResponse<T> {
  /** 业务状态码，0 表示成功 */
  rpCode: number = 0
  /** 业务提示消息 */
  rpMsg: string = ''
  /** 响应数据 */
  data: T | null = null

  constructor() {
  }

  /** 判断是否业务成功 */
  isSuccess(): boolean {
    return this.rpCode === 0
  }
}

/**
 * 业务错误码定义
 */
export class BusinessCode {
  /** 成功 */
  static readonly SUCCESS: number = 0
  /** 异常登录 - 正在退出 */
  static readonly ABNORMAL_LOGIN: number = 20000
  /** 未知错误 */
  static readonly UNKNOWN_ERROR: number = 20001
  /** 参数错误 */
  static readonly PARAM_ERROR: number = 20002
  /** Token 过期 */
  static readonly TOKEN_EXPIRED: number = 20003
}
