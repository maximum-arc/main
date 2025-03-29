// maximum-arc.github.io/main/api/api.js
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  const url = new URL(request.url)
  const path = url.pathname.split('/').filter(p => p)
  const action = path[1]
  const query = url.searchParams.get('q')

  // Разрешаем CORS
  const headers = new Headers({
    'Access-Control-Allow-Origin': '*',
    'Content-Type': 'application/json'
  })

  try {
    if (action === 'search') {
      // Запрос к Wikipedia API
      const wikiUrl = `https://en.wikipedia.org/w/api.php?action=opensearch&search=${encodeURIComponent(query)}&limit=5&namespace=0&format=json`
      const wikiResponse = await fetch(wikiUrl)
      const wikiData = await wikiResponse.json()

      // Форматируем ответ для ESP8266
      const results = wikiData[1].map((title, i) => ({
        title,
        id: wikiData[3][i].split('/').pop() // Извлекаем ID статьи из URL
      }))

      return new Response(JSON.stringify(results), { headers })
    }

    if (action === 'article') {
      // Получаем статью из Wikipedia
      const wikiUrl = `https://en.wikipedia.org/w/api.php?action=query&prop=extracts&pageids=${query}&explaintext=true&format=json`
      const wikiResponse = await fetch(wikiUrl)
      const wikiData = await wikiResponse.json()
      const page = Object.values(wikiData.query.pages)[0]
      
      return new Response(JSON.stringify({
        title: page.title,
        content: page.extract
      }), { headers })
    }

    return new Response(JSON.stringify({ error: 'Invalid action' }), { status: 400, headers })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers })
  }
}
