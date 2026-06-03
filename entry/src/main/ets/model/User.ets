// 如果你想加方法/默认值/可观察，用 class
export class User {
  id: number = 0
  name: string = ''
  avatar?: string

  constructor(opts?: Partial<User>) {
    if (!opts) return
    this.id = opts.id ?? 0
    this.name = opts.name ?? ''
    this.avatar = opts.avatar
  }

  get displayName(): string {
    return this.name || '—'
  }
}