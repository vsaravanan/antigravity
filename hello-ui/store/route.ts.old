'use server'

import { NextResponse } from 'next/server'

export async function GET() {
  const res = await fetch(`${process.env.BACKEND_URL}/hello`, {
    cache: 'no-store',
  })
  const data = await res.json()
  return NextResponse.json(data)
}
