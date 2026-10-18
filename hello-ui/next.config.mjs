// next.config.mjs
const BACKEND = process.env.BACKEND_BASE_URL ?? 'http://hello-api-svc.backend.svc.cluster.local'

const nextConfig = {
  reactStrictMode: true,
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${BACKEND}/api/:path*`,
      },
    ]
  },
}

export default nextConfig