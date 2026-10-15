import '@/styles/globals.css'
const Layout = ({ children }) => {
  return (
    <html lang='en'>
      <body>
        <nav>
          <a href='/'>Home</a> | <a href='/posts'>Posts</a>
        </nav>

        <main>{children}</main>

        <footer>© 2026 Hello UI v 5</footer>
      </body>
    </html>
  )
}

export default Layout
