jest.mock('jsonwebtoken', () => ({
    verify: jest.fn()
}))

const setupSocketHandlers = require('../../src/socket/handlers')

function createHarness(user = null) {
    const connectionHandlers = {}
    const socket = {
        id: 'socket-test',
        user,
        join: jest.fn(),
        leave: jest.fn(),
        emit: jest.fn(),
        on: jest.fn((event, handler) => {
            connectionHandlers[event] = handler
        })
    }
    const roomEmitter = { emit: jest.fn() }
    const io = {
        use: jest.fn(),
        on: jest.fn((event, handler) => {
            if (event === 'connection') handler(socket)
        }),
        emit: jest.fn(),
        to: jest.fn(() => roomEmitter)
    }

    setupSocketHandlers(io)
    return { io, socket, roomEmitter, handlers: connectionHandlers }
}

describe('Socket authorization boundaries', () => {
    test('anonymous clients cannot join privileged rooms', () => {
        const { socket, handlers } = createHarness()

        handlers['join:branch']('branch-a')
        handlers['join:kds']('branch-a')
        handlers['join:role']('admin')
        handlers['join:cashier']()

        expect(socket.join).not.toHaveBeenCalled()
    })

    test('anonymous clients cannot broadcast order state or rider locations', async () => {
        const { io, roomEmitter, handlers } = createHarness()

        await handlers['order:status']({ orderId: 'order-a', status: 'completed' })
        await handlers['rider:location']({ orderId: 'order-a', latitude: 30, longitude: 31 })

        expect(io.emit).not.toHaveBeenCalled()
        expect(roomEmitter.emit).not.toHaveBeenCalled()
    })

    test('authenticated users can only join their own role and branch', () => {
        const user = { userId: 'user-a', role: 'cashier', branchId: 'branch-a' }
        const { socket, handlers } = createHarness(user)

        handlers['join:role']({ role: 'admin' })
        handlers['join:branch']({ branchId: 'branch-b' })
        expect(socket.join).not.toHaveBeenCalledWith('admin')
        expect(socket.join).not.toHaveBeenCalledWith('branch:branch-b')

        handlers['join:role']({ role: 'cashier' })
        handlers['join:branch']({ branchId: 'branch-a' })
        expect(socket.join).toHaveBeenCalledWith('role:cashier')
        expect(socket.join).toHaveBeenCalledWith('branch:branch-a')
    })
})
