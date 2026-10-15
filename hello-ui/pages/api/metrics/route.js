import client from 'prom-client'

// Use a global to avoid re-registering metrics on every hot-reload / request in dev
const globalForMetrics = globalThis

if (!globalForMetrics.__prometheusRegister) {
  const register = new client.Registry()
  client.collectDefaultMetrics({ register, prefix: 'helloui_' })

  // Optional: custom counter for page/API requests
  const httpRequestCounter = new client.Counter({
    name: 'helloui_http_requests_total',
    help: 'Total HTTP requests to hello-ui',
    labelNames: ['route', 'method', 'status'],
    registers: [register],
  })

  globalForMetrics.__prometheusRegister = register
  globalForMetrics.__httpRequestCounter = httpRequestCounter
}

export async function GET() {
  const register = globalForMetrics.__prometheusRegister
  const metrics = await register.metrics()
  return new Response(metrics, {
    headers: { 'Content-Type': register.contentType },
  })
}
