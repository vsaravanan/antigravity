const nextConfig = {
  reactStrictMode: true,
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: 'http://hello-api-svc/api/:path*',
      },
    ]
  },
}

export default nextConfig
