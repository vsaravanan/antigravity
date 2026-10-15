'use client'

import { useEffect } from 'react'
import useHelloStore from '@/store/helloStore'

const Hello2 = () => {
  const { message, loading, error, fetchHello } = useHelloStore()

  useEffect(() => {
    fetchHello()
  }, [fetchHello])

  const messageDetails = message?.details ? `Message: ${message.details}` : 'No message available'

  return (
    <main style={{ padding: '2rem', fontFamily: 'Arial, sans-serif' }}>
      <h1>API Fetch Example</h1>
      <div style={{ marginTop: '1rem' }}>
        {loading && <p>Loading...</p>}
        {error && <p style={{ color: 'red' }}>Error: {error}</p>}
        {message && (
          <div>
            <h2>Response:</h2>
            <p style={{ fontSize: '1.5rem', fontWeight: 'bold' }}>{messageDetails}</p>
          </div>
        )}
        <button
          onClick={fetchHello}
          disabled={loading}
          style={{
            marginTop: '1rem',
            padding: '0.5rem 1rem',
            backgroundColor: loading ? '#ccc' : '#0070f3',
            color: 'white',
            border: 'none',
            borderRadius: '4px',
            cursor: loading ? 'not-allowed' : 'pointer',
          }}
        >
          Refresh
        </button>
      </div>
    </main>
  )
}

export default Hello2
