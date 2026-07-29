/**
 * Seed Initial Data Script
 *
 * Seeds admin user, default branch, and sample notifications.
 * IDEMPOTENT — safe to run multiple times.
 */

const bcrypt = require('bcryptjs')
const { v4: uuidv4 } = require('uuid')
const { sequelize, User, Branch, Notification } = require('../models')
const logger = require('../services/logger')

const BRANCH_ID = '62133736-991f-4d28-ba76-5d7352dfc216'
const ADMIN_ID = 'a0000000-0000-0000-0000-000000000001'

async function seed() {
  logger.info('=== Seeding initial data ===')

  // 1. Default Branch
  const [branch] = await Branch.findOrCreate({
    where: { id: BRANCH_ID },
    defaults: {
      id: BRANCH_ID,
      name_ar: 'الفرع الرئيسي',
      name_en: 'Main Branch',
      is_active: true,
    },
  })
  logger.info(`Branch: ${branch.name_ar}`)

  // 2. Admin User
  const passwordHash = await bcrypt.hash('admin123', 10)
  const [admin] = await User.findOrCreate({
    where: { username: 'admin' },
    defaults: {
      id: ADMIN_ID,
      branch_id: BRANCH_ID,
      username: 'admin',
      password_hash: passwordHash,
      role: 'admin',
      name_ar: 'مدير النظام',
      name_en: 'System Admin',
      is_active: true,
    },
  })
  if (!admin) {
    // Update password hash if user exists but password changed
    await User.update({ password_hash: passwordHash }, { where: { username: 'admin' } })
  }
  logger.info(`Admin user: ${admin?.username || 'admin'}`)

  // 3. Seed Notifications — clear and recreate so seed is idempotent
  await sequelize.query('DELETE FROM notifications')
  const notifications = [
    {
      type: 'order_new',
      title: 'طلب جديد للمطبخ',
      message: 'طلب #1001 - dine_in',
      target_role: 'chef',
      entity_type: 'order',
      entity_id: 'ord-1001',
      is_read: 0,
      icon: '🛒',
      priority: 'high',
      play_sound: 1,
      branch_id: BRANCH_ID,
    },
    {
      type: 'order_ready',
      title: 'الطلب جاهز!',
      message: 'طلب #1002 جاهز للتسليم',
      target_role: 'cashier',
      entity_type: 'order',
      entity_id: 'ord-1002',
      is_read: 0,
      icon: '🔔',
      priority: 'high',
      play_sound: 1,
      branch_id: BRANCH_ID,
    },
    {
      type: 'low_stock',
      title: 'تنبيه مخزون منخفض',
      message: 'آيس كريم - الكمية 3 (الحد الأدنى 10)',
      target_role: 'all',
      entity_type: 'stock',
      entity_id: 'menu-ice',
      is_read: 0,
      icon: '📦',
      priority: 'high',
      play_sound: 1,
      branch_id: BRANCH_ID,
    },
    {
      type: 'order_cancelled',
      title: 'تم إلغاء الطلب',
      message: 'طلب #999 - العميل ألغى الطلب',
      target_role: 'all',
      entity_type: 'order',
      entity_id: 'ord-999',
      is_read: 0,
      icon: '❌',
      priority: 'urgent',
      play_sound: 1,
      branch_id: BRANCH_ID,
    },
    {
      type: 'shift_alert',
      title: 'تذكير بالوردية',
      message: 'وردية اليوم تنتهي خلال ساعة',
      target_role: 'admin',
      entity_type: 'shift',
      entity_id: 'shift-001',
      is_read: 0,
      icon: '⏰',
      priority: 'normal',
      play_sound: 0,
      branch_id: BRANCH_ID,
    },
    {
      type: 'order_preparing',
      title: 'بدأ تحضير الطلب',
      message: 'طلب #1003 قيد التحضير',
      target_role: 'cashier',
      entity_type: 'order',
      entity_id: 'ord-1003',
      is_read: 1,
      icon: '🍳',
      priority: 'normal',
      play_sound: 0,
      branch_id: BRANCH_ID,
    },
    {
      type: 'system',
      title: 'تحديث النظام',
      message: 'تم تحديث النظام إلى الإصدار 1.0.0',
      target_role: 'all',
      entity_type: 'system',
      entity_id: '',
      is_read: 0,
      icon: 'ℹ️',
      priority: 'low',
      play_sound: 0,
      branch_id: null,
    },
  ]

  for (const n of notifications) {
    await Notification.create(n)
  }
  logger.info(`Notifications: ${notifications.length} seeded`)

  logger.info('=== Seed complete ===')
}

module.exports = { seed }

// Run directly: node src/scripts/seed-initial-data.js
if (require.main === module) {
  (async () => {
    try {
      await require('../models').sequelize.sync()
      await seed()
      process.exit(0)
    } catch (err) {
      console.error('Seed failed:', err)
      process.exit(1)
    }
  })()
}
