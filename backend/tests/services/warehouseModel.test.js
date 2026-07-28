const { Warehouse, Branch, sequelize } = require('../../src/models')

describe('Warehouse model', () => {
  beforeAll(async () => {
    await sequelize.sync({ force: true })
  })

  afterAll(async () => {
    await sequelize.close()
  })

  it('keeps only one default warehouse per branch', async () => {
    const branch = await Branch.create({
      name_ar: 'الفرع الرئيسي',
      name_en: 'Main Branch'
    })

    const firstWarehouse = await Warehouse.create({
      name_ar: 'المستودع 1',
      name_en: 'Warehouse 1',
      branch_id: branch.id,
      is_default: true
    })

    const secondWarehouse = await Warehouse.create({
      name_ar: 'المستودع 2',
      name_en: 'Warehouse 2',
      branch_id: branch.id,
      is_default: true
    })

    const [updatedFirst, updatedSecond] = await Promise.all([
      Warehouse.findByPk(firstWarehouse.id),
      Warehouse.findByPk(secondWarehouse.id)
    ])

    expect(updatedFirst.is_default).toBe(false)
    expect(updatedSecond.is_default).toBe(true)
  })
})
