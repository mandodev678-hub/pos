#!/usr/bin/env node
/**
 * Script to reset admin user password in the POS database
 * Run from /home/elwens/Desktop/POS: node reset-admin.js
 */

const bcrypt = require('./node_modules/bcryptjs')
const { Sequelize } = require('./node_modules/sequelize')
const path = require('path')

const dbPath = path.join(__dirname, 'backend/data/restaurant.db')
console.log('📁 Using database:', dbPath)

const sequelize = new Sequelize({
    dialect: 'sqlite',
    storage: dbPath,
    logging: false
})

async function resetAdmin() {
    try {
        await sequelize.authenticate()
        console.log('✅ Connected to database')

        const newPassword = process.env.INITIAL_ADMIN_PASSWORD
        if (!newPassword || newPassword.length < 12) {
            throw new Error('INITIAL_ADMIN_PASSWORD of at least 12 characters is required')
        }
        const hashedPassword = await bcrypt.hash(newPassword, 10)
        console.log('🔐 Password hash generated')

        // Check if admin exists
        const [users] = await sequelize.query(
            `SELECT id, username, role, is_active FROM users WHERE username = 'admin'`
        )

        if (users.length === 0) {
            await sequelize.query(
                `INSERT INTO users (id, username, password_hash, name_ar, name_en, role, is_active, created_at, updated_at)
                 VALUES (lower(hex(randomblob(16))), 'admin', '${hashedPassword}', 'مدير النظام', 'Admin', 'admin', 1, datetime('now'), datetime('now'))`
            )
            console.log('✅ Admin user CREATED')
        } else {
            await sequelize.query(
                `UPDATE users SET password_hash = '${hashedPassword}', is_active = 1 WHERE username = 'admin'`
            )
            console.log('✅ Admin password UPDATED')
        }

        const [verifyUsers] = await sequelize.query(
            `SELECT id, username, role, is_active FROM users WHERE username = 'admin'`
        )
        const admin = verifyUsers[0]
        const isValid = await bcrypt.compare(newPassword, hashedPassword)

        console.log('')
        console.log('══════════════════════════════════════════')
        console.log('  ✅ تم إعادة تعيين كلمة المرور بنجاح!')
        console.log('══════════════════════════════════════════')
        console.log('  المستخدم:      admin')
        console.log('  كلمة المرور:   تم تعيينها من INITIAL_ADMIN_PASSWORD')
        console.log('  الدور:         ' + (admin?.role || 'admin'))
        console.log('  مفعّل:         ' + (admin?.is_active ? 'نعم ✅' : 'لا ❌'))
        console.log('  اختبار الهاش:  ' + (isValid ? '✅ صح' : '❌ خطأ'))
        console.log('══════════════════════════════════════════')

        await sequelize.close()
        process.exit(0)
    } catch (error) {
        console.error('❌ Error:', error.message)
        console.error(error)
        process.exit(1)
    }
}

resetAdmin()
