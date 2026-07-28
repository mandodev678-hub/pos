require('dotenv').config({ path: require('path').join(__dirname, '../../.env') })
const { sequelize } = require('../config/database')

async function migrate() {
    console.log('🔄 Running migration: add_delivery_role_and_user_id\n')
    const qi = sequelize.getQueryInterface()
    const tables = (await qi.showAllTables()).map(t => typeof t === 'string' ? t : (t.tableName || t.TABLE_NAME || ''))

    // 1. Modify users.role ENUM to include 'delivery'
    if (tables.includes('users')) {
        const desc = await qi.describeTable('users')
        if (desc.role) {
            const colType = String(desc.role.type || '').toLowerCase()
            if (colType.includes('enum')) {
                await sequelize.query(
                    "ALTER TABLE users MODIFY COLUMN role ENUM('admin','manager','cashier','chef','supervisor','accountant','delivery') NOT NULL DEFAULT 'cashier'",
                    { type: sequelize.QueryTypes.RAW }
                )
                console.log('✅ Added delivery role to users.role ENUM')
            }
        }

        // Ensure ENUM expansion via the model helper in index.js
        try {
            await sequelize.query(
                "ALTER TABLE users MODIFY COLUMN role ENUM('admin','manager','cashier','chef','supervisor','accountant','delivery') NOT NULL DEFAULT 'cashier'",
                { type: sequelize.QueryTypes.RAW }
            )
        } catch (_) {}
    }

    // 2. Add user_id column to delivery_personnel (SQLite-safe: no inline UNIQUE)
    if (tables.includes('delivery_personnel')) {
        const desc = await qi.describeTable('delivery_personnel')
        if (!desc.user_id) {
            // Add column without UNIQUE (SQLite doesn't support ADD UNIQUE column)
            await sequelize.query(
                'ALTER TABLE `delivery_personnel` ADD COLUMN `user_id` TEXT',
                { type: sequelize.QueryTypes.RAW }
            )
            // Create a unique index separately
            try {
                await sequelize.query(
                    'CREATE UNIQUE INDEX IF NOT EXISTS idx_delivery_personnel_user_id ON `delivery_personnel` (`user_id`)',
                    { type: sequelize.QueryTypes.RAW }
                )
            } catch (_) {}
            console.log('✅ Added user_id column to delivery_personnel')
        } else {
            console.log('ℹ️  user_id column already exists in delivery_personnel')
        }
    }

    console.log('\n✅ Migration completed successfully!')
}

module.exports = migrate

if (require.main === module) {
    migrate()
        .then(() => sequelize.close())
        .catch(async err => {
            console.error('❌ Migration failed:', err.message)
            await sequelize.close().catch(() => {})
            process.exitCode = 1
        })
}
