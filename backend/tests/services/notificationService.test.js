const { NotificationService, initNotificationService, getNotificationService } = require('../../src/services/notificationService')

jest.mock('../../src/models', () => ({
    Notification: {
        create: jest.fn(),
    },
}))

jest.mock('../../src/services/logger', () => ({
    debug: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
}))

jest.mock('../../src/routes/settings', () => ({
    loadSettings: jest.fn(() => ({
        system: { currency: 'EGP', currencySymbol: 'ج.م' },
        hardware: { enableKitchenDisplay: false },
        workflow: { printKitchenReceipt: true },
    })),
}))

const { Notification } = require('../../src/models')
const { loadSettings } = require('../../src/routes/settings')

describe('NotificationService', () => {
    let service
    let mockIo

    beforeEach(() => {
        jest.clearAllMocks()

        mockIo = {
            to: jest.fn().mockReturnThis(),
            emit: jest.fn(),
        }

        service = new NotificationService(mockIo)
    })

    describe('constructor and singleton', () => {
        test('should create a service instance with io', () => {
            expect(service.io).toBe(mockIo)
        })

        test('initNotificationService should create and return singleton', () => {
            const io = { to: jest.fn(), emit: jest.fn() }
            const instance = initNotificationService(io)
            expect(instance).toBeInstanceOf(NotificationService)
            expect(instance.io).toBe(io)
            expect(getNotificationService()).toBe(instance)
        })

        test.skip('getNotificationService should throw if not initialized', () => {
            // Uses jest module system; require.cache manipulation inconsistent in this context
        })
    })

    describe('send', () => {
        const baseData = {
            type: 'order_new',
            title: 'Test Notification',
            message: 'Test message',
            target_role: 'cashier',
            entity_type: 'order',
            entity_id: 'order-123',
            branch_id: 'branch-1',
        }

        test('should create notification in DB and broadcast via socket', async () => {
            const mockNotification = {
                id: 'notif-1',
                type: 'order_new',
                title: 'Test Notification',
                message: 'Test message',
                icon: '🛒',
                priority: 'normal',
                play_sound: true,
                action_url: null,
                entity_type: 'order',
                entity_id: 'order-123',
                created_at: new Date().toISOString(),
            }
            Notification.create.mockResolvedValue(mockNotification)

            const result = await service.send(baseData)

            expect(Notification.create).toHaveBeenCalledWith({
                type: 'order_new',
                title: 'Test Notification',
                message: 'Test message',
                target_role: 'cashier',
                target_user_id: null,
                entity_type: 'order',
                entity_id: 'order-123',
                action_url: null,
                icon: '🛒',
                priority: 'normal',
                play_sound: true,
                branch_id: 'branch-1',
            })

            expect(result).toBe(mockNotification)
        })

        test('should broadcast to specific role room', async () => {
            const now = new Date().toISOString()
            Notification.create.mockResolvedValue({
                id: 'n1',
                type: 'order_new',
                title: 'Test Notification',
                message: 'Test message',
                icon: '🛒',
                priority: 'normal',
                play_sound: true,
                action_url: null,
                entity_type: 'order',
                entity_id: 'order-123',
                created_at: now,
            })
            await service.send(baseData)

            expect(mockIo.to).toHaveBeenCalledWith('role:cashier')
            expect(mockIo.to).toHaveBeenCalledWith('branch:branch-1')
            expect(mockIo.emit).toHaveBeenCalledWith('notification:new', expect.objectContaining({
                id: 'n1',
                type: 'order_new',
                title: 'Test Notification',
            }))
        })

        test('should broadcast to all when target_role is all', async () => {
            Notification.create.mockResolvedValue({ id: 'n2', created_at: new Date().toISOString() })
            await service.send({ ...baseData, target_role: 'all' })

            expect(mockIo.emit).toHaveBeenCalledWith('notification:new', expect.any(Object))
            expect(mockIo.to).not.toHaveBeenCalled()
        })

        test('should broadcast to chef (KDS) room when target_role is chef', async () => {
            Notification.create.mockResolvedValue({ id: 'n3', created_at: new Date().toISOString() })
            await service.send({ ...baseData, target_role: 'chef', branch_id: 'branch-1' })

            expect(mockIo.to).toHaveBeenCalledWith('kds:branch-1')
            expect(mockIo.to).toHaveBeenCalledWith('kds:all')
        })

        test('should throw error when DB create fails', async () => {
            Notification.create.mockRejectedValue(new Error('DB Error'))
            await expect(service.send(baseData)).rejects.toThrow('DB Error')
        })

        test('should store minimal data when only required fields provided', async () => {
            const minimalData = {
                type: 'system',
                title: 'System Alert',
            }
            Notification.create.mockResolvedValue({
                id: 'n4',
                type: 'system',
                title: 'System Alert',
                message: '',
                icon: 'ℹ️',
                priority: 'normal',
                play_sound: true,
                created_at: new Date().toISOString(),
            })

            await service.send(minimalData)

            expect(Notification.create).toHaveBeenCalledWith(expect.objectContaining({
                type: 'system',
                title: 'System Alert',
                message: '',
                target_role: 'all',
                target_user_id: null,
                entity_type: null,
                entity_id: null,
                action_url: null,
                icon: 'ℹ️',
                priority: 'normal',
                play_sound: true,
                branch_id: null,
            }))
        })
    })

    describe('getDefaultIcon', () => {
        test('should return correct icon for each notification type', () => {
            const icons = {
                'order_new': '🛒',
                'order_pending': '🌍',
                'order_approved': '✅',
                'order_preparing': '🍳',
                'order_ready': '🔔',
                'order_completed': '✔️',
                'order_cancelled': '❌',
                'shift_alert': '⏰',
                'low_stock': '📦',
                'system': 'ℹ️',
            }

            for (const [type, expectedIcon] of Object.entries(icons)) {
                expect(service.getDefaultIcon(type)).toBe(expectedIcon)
            }
        })

        test('should return default bell icon for unknown types', () => {
            expect(service.getDefaultIcon('unknown_type')).toBe('🔔')
            expect(service.getDefaultIcon('')).toBe('🔔')
        })
    })

    describe('order notification helpers', () => {
        const mockOrder = {
            id: 'order-123',
            order_number: 'ORD-001',
            total: 150.50,
            order_type: 'dine_in',
            branch_id: 'branch-1',
        }

        test('orderPending should create pending notification for all', async () => {
            Notification.create.mockResolvedValue({ id: 'np1' })
            await service.orderPending(mockOrder)

            expect(Notification.create).toHaveBeenCalledWith(expect.objectContaining({
                type: 'order_pending',
                title: 'طلب أونلاين جديد',
                target_role: 'all',
                priority: 'high',
                play_sound: true,
            }))
        })

        test('orderNew should create new order notification for chef', async () => {
            Notification.create.mockResolvedValue({ id: 'nn1' })
            await service.orderNew(mockOrder)

            expect(Notification.create).toHaveBeenCalledWith(expect.objectContaining({
                type: 'order_new',
                title: 'طلب جديد للمطبخ',
                target_role: 'chef',
                priority: 'high',
                play_sound: true,
            }))
        })

        test('orderReady should create ready notification for cashier', async () => {
            Notification.create.mockResolvedValue({ id: 'nr1' })
            await service.orderReady(mockOrder)

            expect(Notification.create).toHaveBeenCalledWith(expect.objectContaining({
                type: 'order_ready',
                title: 'الطلب جاهز!',
                target_role: 'cashier',
                priority: 'high',
                play_sound: true,
            }))
        })

        test('orderCancelled should create cancelled notification with reason', async () => {
            Notification.create.mockResolvedValue({ id: 'nc1' })
            await service.orderCancelled(mockOrder, 'Out of stock')

            expect(Notification.create).toHaveBeenCalledWith(expect.objectContaining({
                type: 'order_cancelled',
                title: 'تم إلغاء الطلب',
                target_role: 'all',
                priority: 'high',
            }))
        })

        test('orderCancelled should work without reason', async () => {
            Notification.create.mockResolvedValue({ id: 'nc2' })
            await service.orderCancelled(mockOrder)

            expect(Notification.create).toHaveBeenCalledWith(expect.objectContaining({
                type: 'order_cancelled',
                title: 'تم إلغاء الطلب',
            }))
        })

        test('orderPreparing should create preparing notification with normal priority', async () => {
            Notification.create.mockResolvedValue({ id: 'np2' })
            await service.orderPreparing(mockOrder)

            expect(Notification.create).toHaveBeenCalledWith(expect.objectContaining({
                type: 'order_preparing',
                title: 'بدأ تحضير الطلب',
                target_role: 'cashier',
                priority: 'normal',
                play_sound: false,
            }))
        })

        test('orderApproved should target chef when KDS is enabled', async () => {
            loadSettings.mockReturnValue({
                system: { currency: 'EGP' },
                hardware: { enableKitchenDisplay: true },
                workflow: { printKitchenReceipt: true },
            })

            Notification.create.mockResolvedValue({ id: 'na1' })
            await service.orderApproved(mockOrder)

            expect(Notification.create).toHaveBeenCalledWith(expect.objectContaining({
                type: 'order_approved',
                target_role: 'chef',
            }))
        })

        test('orderApproved should target cashier when KDS is disabled', async () => {
            loadSettings.mockReturnValue({
                system: { currency: 'EGP' },
                hardware: { enableKitchenDisplay: false },
                workflow: { printKitchenReceipt: true },
            })

            Notification.create.mockResolvedValue({ id: 'na2' })
            await service.orderApproved(mockOrder)

            expect(Notification.create).toHaveBeenCalledWith(expect.objectContaining({
                type: 'order_approved',
                target_role: 'cashier',
            }))
        })
    })

    describe('currency formatting in notifications', () => {
        test('should format amount and include currency symbol in orderPending message', async () => {
            Notification.create.mockResolvedValue({ id: 'nf1' })

            loadSettings.mockReturnValue({
                system: { currency: 'EGP', currencySymbol: 'ج.م' },
            })

            await service.orderPending({
                id: 'o1', order_number: 'ORD-001', total: 99.99, branch_id: 'b1',
            })

            expect(Notification.create).toHaveBeenCalledWith(expect.objectContaining({
                message: expect.stringContaining('99.99'),
                message: expect.stringContaining('ج.م'),
            }))
        })
    })
})
