const request = require('supertest')
const express = require('express')
const notificationRoutes = require('../../src/routes/notifications')
const { Notification } = require('../../src/models')

jest.mock('../../src/models', () => ({
    Notification: {
        findAll: jest.fn(),
        findOne: jest.fn(),
        count: jest.fn(),
        update: jest.fn(),
        destroy: jest.fn(),
    },
}))

jest.mock('../../src/middleware/auth', () => ({
    authenticate: (req, res, next) => {
        req.user = {
            userId: 'user-123',
            role: 'admin',
            branchId: 'branch-1',
            permissions: [],
        }
        next()
    },
    authorize: (...roles) => (req, res, next) => next(),
}))

const app = express()
app.use(express.json())
app.use('/api/notifications', notificationRoutes)

describe('Notification Routes Integration', () => {
    beforeEach(() => {
        jest.clearAllMocks()
    })

    describe('GET /api/notifications', () => {
        test('should return notifications list with unread count', async () => {
            const mockNotifs = [
                { id: 'n1', title: 'Notif 1', is_read: false, toJSON: () => ({ id: 'n1' }) },
                { id: 'n2', title: 'Notif 2', is_read: true, toJSON: () => ({ id: 'n2' }) },
            ]
            Notification.findAll.mockResolvedValue(mockNotifs)
            Notification.count.mockResolvedValue(1)

            const res = await request(app).get('/api/notifications')

            expect(res.status).toBe(200)
            expect(res.body.data).toHaveLength(2)
            expect(res.body.unread_count).toBe(1)
        })

        test('should filter to unread only when param is true', async () => {
            Notification.findAll.mockResolvedValue([])
            Notification.count.mockResolvedValue(0)

            await request(app).get('/api/notifications?unread_only=true')

            expect(Notification.findAll).toHaveBeenCalledWith(expect.objectContaining({
                where: expect.objectContaining({ is_read: false }),
            }))
        })

        test('should return empty list when no notifications exist', async () => {
            Notification.findAll.mockResolvedValue([])
            Notification.count.mockResolvedValue(0)

            const res = await request(app).get('/api/notifications')

            expect(res.status).toBe(200)
            expect(res.body.data).toEqual([])
            expect(res.body.unread_count).toBe(0)
        })

        test('should handle error and return 500', async () => {
            Notification.findAll.mockRejectedValue(new Error('DB Error'))

            const res = await request(app).get('/api/notifications')

            expect(res.status).toBe(500)
            expect(res.body.message).toBe('Failed to load notifications')
        })
    })

    describe('PUT /api/notifications/:id/read', () => {
        test('should mark a notification as read', async () => {
            const mockNotif = {
                id: 'n1',
                is_read: false,
                update: jest.fn().mockResolvedValue(true),
                toJSON: () => ({ id: 'n1', is_read: true }),
            }
            Notification.findOne.mockResolvedValue(mockNotif)

            const res = await request(app).put('/api/notifications/n1/read')

            expect(res.status).toBe(200)
            expect(mockNotif.update).toHaveBeenCalledWith({
                is_read: true,
                read_at: expect.any(Date),
            })
        })

        test('should return 404 when notification not found', async () => {
            Notification.findOne.mockResolvedValue(null)

            const res = await request(app).put('/api/notifications/nonexistent/read')

            expect(res.status).toBe(404)
            expect(res.body.message).toBe('Notification not found')
        })
    })

    describe('PUT /api/notifications/read-all', () => {
        test('should mark all visible notifications as read', async () => {
            Notification.update.mockResolvedValue([5])

            const res = await request(app).put('/api/notifications/read-all')

            expect(res.status).toBe(200)
            expect(Notification.update).toHaveBeenCalledWith(
                { is_read: true, read_at: expect.any(Date) },
                expect.objectContaining({
                    where: expect.objectContaining({ is_read: false }),
                })
            )
        })
    })

    describe('DELETE /api/notifications/cleanup', () => {
        test('should delete old read notifications', async () => {
            Notification.destroy.mockResolvedValue(10)

            const res = await request(app).delete('/api/notifications/cleanup')

            expect(res.status).toBe(200)
            expect(res.body.message).toContain('10')
            const arg = Notification.destroy.mock.calls[0][0]
            expect(arg.where.is_read).toBe(true)
            expect(arg.where.created_at).toBeDefined()
        })
    })
})
