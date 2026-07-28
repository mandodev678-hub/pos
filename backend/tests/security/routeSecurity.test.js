const authRouter = require('../../src/routes/auth')
const devicesRouter = require('../../src/routes/devices')

function routePaths(router, method = null) {
    return router.stack
        .filter(layer => layer.route)
        .filter(layer => !method || layer.route.methods[method])
        .map(layer => layer.route.path)
}

describe('Critical route security invariants', () => {
    test('does not expose an HTTP admin reset backdoor', () => {
        expect(routePaths(authRouter)).not.toContain('/reset-admin')
    })

    test('constrains the dynamic device id route so it cannot shadow static routes', () => {
        const paths = routePaths(devicesRouter, 'get')
        const dynamicPath = paths.find(path => String(path).startsWith('/:id'))

        expect(dynamicPath).toBeDefined()
        expect(dynamicPath).not.toBe('/:id')
        for (const staticPath of ['/jobs/pending', '/jobs/history', '/templates/all']) {
            expect(paths.indexOf(staticPath)).toBeGreaterThan(-1)
        }
    })
})
