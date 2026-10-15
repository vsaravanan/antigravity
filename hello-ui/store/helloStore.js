'use Server'

import { create } from 'zustand'
import { sleep } from 'lib/utils'

const getBaseUrl = () => {
  // Server-side: use internal service name
  if (typeof window === 'undefined') {
    console.log(' NEXT_PUBLIC_BACKEND_URL ' + process.env.NEXT_PUBLIC_BACKEND_URL)
    return process.env.NEXT_PUBLIC_BACKEND_URL
  }
  console.log(' NEXT_PUBLIC_LOCAL_URL ' + process.env.NEXT_PUBLIC_LOCAL_URL)

  // Client-side: use exposed NodePort
  return process.env.NEXT_PUBLIC_LOCAL_URL
}

const useHelloStore = create(set => ({
  message: '',
  loading: false,
  error: null,
  fetchHello: async () => {
    set({ loading: true, error: null })
    try {
      const path = `${process.env.NEXT_PUBLIC_BACKEND_URL}/api/hello`
      // const path =  '/api/hello'
      console.log('Fetching from:', path) // Log the URL being fetched
      const response = await fetch(path)
      //   {
      //   method: 'GET',
      //   // headers: {
      //   //   'Content-Type': 'application/json',
      //   // },
      //   // mode: 'cors',
      // })
      // await sleep(2) // Simulate a delay of 2 seconds
      const data = await response.json()
      console.log('Fetched data:', data) // Log the fetched data
      set({ message: data, loading: false })
    } catch (error) {
      set({ error: error.message, loading: false })
    }
  },
}))

export default useHelloStore
