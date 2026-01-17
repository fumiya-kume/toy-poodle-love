export const metadata = {
  title: 'AI テキスト生成',
  description: 'QwenとGeminiを使ったシンプルなテキスト生成UI',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ja">
      <body suppressHydrationWarning>{children}</body>
    </html>
  )
}
