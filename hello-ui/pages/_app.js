// pages/_app.js
import '@/styles/globals.css'

import Layout from '../app/layout'

const MyApp = ({ Component, pageProps }) => {
  return (
    <Layout>
      <Component {...pageProps} />
    </Layout>
  )
}

export default MyApp
