// network/Api.ets
import { UserApi } from './service/UserApi'
import { ProductApi } from './service/ProductApi'

export const api = {
  user: new UserApi(),
  product: new ProductApi()
}