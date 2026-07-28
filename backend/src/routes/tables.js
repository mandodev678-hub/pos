const express = require('express')
const router = express.Router()
const { body } = require('express-validator')
const { validate } = require('../middleware/validate')
const { authenticate, requirePermission, PERMISSIONS } = require('../middleware/auth')
const logger = require('../services/logger')
const { Order, Branch, Customer } = require('../models')
const { Op } = require('sequelize')
const path = require('path')
const fs = require('fs')

const TABLES_FILE = path.join(__dirname, '../../data/tables.json')

function loadTables() {
    try {
        if (fs.existsSync(TABLES_FILE)) {
            const raw = fs.readFileSync(TABLES_FILE, 'utf-8')
            return JSON.parse(raw)
        }
    } catch (err) {
        logger.error('Failed to load tables.json:', err.message)
    }
    return []
}

function saveTables(tables) {
    try {
        fs.writeFileSync(TABLES_FILE, JSON.stringify(tables, null, 2), 'utf-8')
    } catch (err) {
        logger.error('Failed to save tables.json:', err.message)
        throw new Error('فشل حفظ بيانات الطاولات')
    }
}

function generateId() {
    return 'tbl_' + Date.now() + '_' + Math.random().toString(36).substring(2, 8)
}

router.get('/', authenticate, requirePermission(PERMISSIONS.TABLES_VIEW), async (req, res) => {
    try {
        let tables = loadTables()
        const branchId = req.user.branchId

        if (branchId) {
            tables = tables.filter(t => t.branch_id === branchId || !t.branch_id)
        }

        const activeOrders = await Order.findAll({
            where: {
                table_number: { [Op.ne]: null, [Op.ne]: '' },
                status: { [Op.notIn]: ['completed', 'cancelled'] }
            },
            attributes: ['table_number', 'order_number', 'total', 'customer_id', 'status', 'id'],
            include: [{
                model: Customer,
                attributes: ['name']
            }]
        })

        const orderMap = {}
        for (const o of activeOrders) {
            const tn = o.table_number
            if (!orderMap[tn]) orderMap[tn] = []
            orderMap[tn].push(o)
        }

        tables = tables.map(t => {
            const orders = orderMap[t.table_number] || []
            const isOccupied = orders.length > 0
            return {
                ...t,
                status: isOccupied ? 'occupied' : (t.status === 'occupied' ? 'available' : t.status),
                currentOrders: orders.map(o => ({
                    id: o.id,
                    orderNumber: o.order_number,
                    total: parseFloat(o.total) || 0,
                    customerName: o.Customer ? o.Customer.name : null,
                    status: o.status
                })),
                currentOrderId: orders.length > 0 ? orders[0].id : null,
                currentOrderNumber: orders.length > 0 ? orders[0].order_number : null,
                customerName: orders.length > 0 ? (orders[0].Customer ? orders[0].Customer.name : null) : null,
                totalAmount: orders.length > 0 ? parseFloat(orders.reduce((sum, o) => sum + parseFloat(o.total || 0), 0)) : 0
            }
        })

        res.json({ data: tables })
    } catch (error) {
        logger.error('Error fetching tables:', error)
        res.status(500).json({ message: 'خطأ في جلب الطاولات' })
    }
})

router.post('/', authenticate, requirePermission(PERMISSIONS.TABLES_MANAGE), [
    body('table_number').notEmpty().withMessage('رقم الطاولة مطلوب'),
    body('capacity').optional().isInt({ min: 1 }).withMessage('السعة يجب أن تكون رقم صحيح')
], validate, async (req, res) => {
    try {
        const { table_number, capacity, area } = req.body
        const tables = loadTables()

        if (tables.find(t => t.table_number === table_number && t.branch_id === req.user.branchId)) {
            return res.status(409).json({ message: 'رقم الطاولة موجود مسبقاً' })
        }

        const newTable = {
            id: generateId(),
            table_number,
            capacity: capacity || 4,
            area: area || 'صالة',
            status: 'available',
            branch_id: req.user.branchId || null,
            created_at: new Date().toISOString()
        }

        tables.push(newTable)
        saveTables(tables)

        res.status(201).json({ data: newTable, message: 'تم إضافة الطاولة بنجاح' })
    } catch (error) {
        logger.error('Error creating table:', error)
        res.status(500).json({ message: 'خطأ في إضافة الطاولة' })
    }
})

router.put('/:id', authenticate, requirePermission(PERMISSIONS.TABLES_MANAGE), async (req, res) => {
    try {
        const tables = loadTables()
        const index = tables.findIndex(t => t.id === req.params.id)

        if (index === -1) {
            return res.status(404).json({ message: 'الطاولة غير موجودة' })
        }

        const allowedFields = ['table_number', 'capacity', 'area', 'status']
        for (const field of allowedFields) {
            if (req.body[field] !== undefined) {
                tables[index][field] = req.body[field]
            }
        }

        saveTables(tables)

        res.json({ data: tables[index], message: 'تم تحديث الطاولة بنجاح' })
    } catch (error) {
        logger.error('Error updating table:', error)
        res.status(500).json({ message: 'خطأ في تحديث الطاولة' })
    }
})

router.delete('/:id', authenticate, requirePermission(PERMISSIONS.TABLES_MANAGE), async (req, res) => {
    try {
        const tables = loadTables()
        const index = tables.findIndex(t => t.id === req.params.id)

        if (index === -1) {
            return res.status(404).json({ message: 'الطاولة غير موجودة' })
        }

        const activeOrder = await Order.findOne({
            where: {
                table_number: tables[index].table_number,
                status: { [Op.notIn]: ['completed', 'cancelled'] }
            }
        })

        if (activeOrder) {
            return res.status(400).json({ message: 'لا يمكن حذف طاولة عليها طلبات نشطة' })
        }

        tables.splice(index, 1)
        saveTables(tables)

        res.json({ message: 'تم حذف الطاولة بنجاح' })
    } catch (error) {
        logger.error('Error deleting table:', error)
        res.status(500).json({ message: 'خطأ في حذف الطاولة' })
    }
})

router.post('/:id/transfer', authenticate, requirePermission(PERMISSIONS.TABLES_TRANSFER), [
    body('target_table').notEmpty().withMessage('الطاولة المستهدفة مطلوبة')
], validate, async (req, res) => {
    try {
        const tables = loadTables()
        const sourceTable = tables.find(t => t.id === req.params.id)
        if (!sourceTable) {
            return res.status(404).json({ message: 'الطاولة المصدر غير موجودة' })
        }

        const targetTable = tables.find(t => t.table_number === req.body.target_table)
        if (!targetTable) {
            return res.status(404).json({ message: 'الطاولة المستهدفة غير موجودة' })
        }

        const activeOrders = await Order.findAll({
            where: {
                table_number: sourceTable.table_number,
                status: { [Op.notIn]: ['completed', 'cancelled'] }
            }
        })

        if (activeOrders.length === 0) {
            return res.status(400).json({ message: 'لا يوجد طلبات نشطة على هذه الطاولة' })
        }

        const ordersOnTarget = await Order.findOne({
            where: {
                table_number: targetTable.table_number,
                status: { [Op.notIn]: ['completed', 'cancelled'] }
            }
        })

        if (ordersOnTarget) {
            return res.status(400).json({ message: 'الطاولة المستهدفة مشغولة، قم باختيار طاولة فارغة' })
        }

        const orderIds = activeOrders.map(o => o.id)
        await Order.update(
            { table_number: targetTable.table_number },
            { where: { id: orderIds } }
        )

        const updatedOrders = await Order.findAll({
            where: { id: orderIds },
            attributes: ['id', 'order_number', 'table_number']
        })

        res.json({
            message: `تم نقل الطلب إلى طاولة رقم ${targetTable.table_number}`,
            data: { sourceTable: sourceTable.table_number, targetTable: targetTable.table_number, orders: updatedOrders }
        })
    } catch (error) {
        logger.error('Error transferring table:', error)
        res.status(500).json({ message: 'خطأ في نقل الطلب بين الطاولات' })
    }
})

router.delete('/:id/clear', authenticate, requirePermission(PERMISSIONS.TABLES_MANAGE), async (req, res) => {
    try {
        const tables = loadTables()
        const index = tables.findIndex(t => t.id === req.params.id)
        if (index === -1) {
            return res.status(404).json({ message: 'الطاولة غير موجودة' })
        }
        tables[index].status = 'available'
        saveTables(tables)
        res.json({ message: 'تم تفريغ الطاولة', data: tables[index] })
    } catch (error) {
        logger.error('Error clearing table:', error)
        res.status(500).json({ message: 'خطأ في تفريغ الطاولة' })
    }
})

module.exports = router
