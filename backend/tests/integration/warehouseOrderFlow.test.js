const { Branch, Warehouse, Menu, Stock, StockMovement, Order, OrderItem, User, sequelize } = require('../../src/models')
const { seedChartOfAccounts } = require('../../src/scripts/seed-chart-of-accounts')
const OrderFinalizationService = require('../../src/services/orderFinalizationService')

describe('Warehouse order flow', () => {
  beforeAll(async () => {
    await sequelize.sync({ force: true })
    await seedChartOfAccounts()
  })

  afterAll(async () => {
    await sequelize.close()
  })

  it('finalizes an order using the branch default warehouse', async () => {
    const branch = await Branch.create({ name_ar: 'فرع 1', name_en: 'Branch 1' })
    const user = await User.create({
      username: 'warehouse-test-user',
      password_hash: 'password123',
      name_ar: 'مستخدم اختبار',
      role: 'cashier',
      branch_id: branch.id
    })
    const warehouse = await Warehouse.create({
      name_ar: 'المستودع الافتراضي',
      name_en: 'Default Warehouse',
      branch_id: branch.id,
      is_default: true
    })

    const menu = await Menu.create({
      name_ar: 'شاورما',
      name_en: 'Shawarma',
      sku: 'SHA-1',
      branch_id: branch.id,
      category_id: null,
      track_stock: true,
      unit_of_measure: 'piece',
      cost: 10,
      price: 20
    })

    await Stock.create({
      menu_id: menu.id,
      warehouse_id: warehouse.id,
      quantity: 10,
      reserved_qty: 0,
      avg_cost: 10
    })

    const order = await Order.create({
      branch_id: branch.id,
      order_number: 'ORD-100',
      status: 'ready',
      order_type: 'walkin',
      total: 20,
      payment_method: 'cash',
      payment_status: 'pending',
      user_id: null,
      customer_id: null,
      delivery_status: 'pending'
    })

    await OrderItem.create({
      order_id: order.id,
      menu_id: menu.id,
      item_name_ar: 'شاورما',
      item_name_en: 'Shawarma',
      quantity: 2,
      unit_price: 20,
      total_price: 40,
      discount_amount: 0
    })

    const completed = await OrderFinalizationService.finalizeOrder(order.id, {
      paymentMethod: 'cash',
      warehouseId: warehouse.id,
      user: { userId: user.id }
    })

    expect(completed.status).toBe('completed')

    const stockAfter = await Stock.findOne({ where: { menu_id: menu.id, warehouse_id: warehouse.id } })
    expect(parseFloat(stockAfter.quantity)).toBe(8)
    expect(await StockMovement.count({ where: { source_type: 'order', source_id: order.id } })).toBeGreaterThan(0)
  })
})
