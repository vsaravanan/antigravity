import { NextResponse } from 'next/server'

const proxy = async request => {
  const { pathname } = request.nextUrl
  console.log('🔵 Middleware running for:', pathname)

  if (pathname.startsWith('/api')) {
    // Rewrite to internal service

    //NEXT_PUBLIC_BACKEND_BASE_URL
    const backendUrl = process.env.NEXT_PUBLIC_BACKEND_BASE_URL || 'http://hello-api-svc'

    const url = new URL(pathname, backendUrl)
    console.log(`🔄 Rewriting ${pathname} to ${url.toString()}`)

    // const url = request.nextUrl.clone()
    // url.hostname = 'hello-api-svc'
    // url.protocol = 'http'
    return NextResponse.rewrite(url)
  }

  console.log('🟢 Passing through:', pathname)
  return NextResponse.next()
}

export const config = {
  matcher: ['/api/:path*'], // Run on all paths
}

export default proxy
