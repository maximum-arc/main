// maximum-arc.github.io/main/api/api.js
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

// Кэш для часто запрашиваемых статей (хранится 5 минут)
const CACHE_TTL = 300
const articleCache = new Map()

async function handleRequest(request) {
  const url = new URL(request.url)
  const path = url.pathname.split('/').filter(p => p)
  const action = path[1]
  const query = url.searchParams.get('q')

  // Разрешаем CORS и настраиваем заголовки
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Content-Type': 'application/json',
    'X-Content-Type-Options': 'nosniff'
  }

  // Проверка метода запроса
  if (request.method !== 'GET') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers
    })
  }

  // Проверка обязательных параметров
  if (!query || !action) {
    return new Response(JSON.stringify({ 
      error: 'Missing required parameters',
      usage: {
        search: '/api/search?q=query',
        article: '/api/article?q=pageid'
      }
    }), { 
      status: 400,
      headers
    })
  }

  try {
    // Обработка поиска
    if (action === 'search') {
      const cacheKey = `search:${query}`
      const cached = articleCache.get(cacheKey)
      
      if (cached && cached.expires > Date.now()) {
        return new Response(JSON.stringify(cached.data), { headers })
      }

      const wikiUrl = `https://en.wikipedia.org/w/api.php?action=opensearch&search=${encodeURIComponent(query)}&limit=5&namespace=0&format=json`
      const wikiResponse = await fetch(wikiUrl)
      
      if (!wikiResponse.ok) throw new Error('Wikipedia API error')
      
      const wikiData = await wikiResponse.json()
      
      // Форматируем ответ для ESP8266 (упрощаем структуру)
      const results = wikiData[1].map((title, i) => ({
        t: title, // Короткое название поля для экономии трафика
        i: wikiData[3][i].split('/').pop() // ID статьи
      }))

      // Кэшируем результат
      articleCache.set(cacheKey, {
        data: results,
        expires: Date.now() + CACHE_TTL * 1000
      })

      return new Response(JSON.stringify(results), { headers })
    }

    // Обработка запроса статьи
    if (action === 'article') {
      const cacheKey = `article:${query}`
      const cached = articleCache.get(cacheKey)
      
      if (cached && cached.expires > Date.now()) {
        return new Response(JSON.stringify(cached.data), { headers })
      }

      const wikiUrl = `https://en.wikipedia.org/w/api.php?action=query&prop=extracts&pageids=${query}&exintro=true&explaintext=true&format=json`
      const wikiResponse = await fetch(wikiUrl)
      
      if (!wikiResponse.ok) throw new Error('Wikipedia API error')
      
      const wikiData = await wikiResponse.json()
      const page = Object.values(wikiData.query.pages)[0]
      
      if (!page || page.missing) {
        return new Response(JSON.stringify({ error: 'Article not found' }), {
          status: 404,
          headers
        })
      }

      const responseData = {
        t: page.title, // Короткое название поля
        c: page.extract
          .replace(/\n\n/g, '\n') // Упрощаем переносы строк
          .substring(0, 2000) // Ограничиваем размер для ESP8266
      }

      // Кэшируем результат
      articleCache.set(cacheKey, {
        data: responseData,
        expires: Date.now() + CACHE_TTL * 1000
      })

      return new Response(JSON.stringify(responseData), { headers })
    }

    return new Response(JSON.stringify({ error: 'Invalid action' }), {
      status: 400,
      headers
    })

  } catch (error) {
    console.error('API Error:', error)
    return new Response(JSON.stringify({ 
      error: 'Internal server error',
      message: error.message
    }), {
      status: 500,
      headers
    })
  }
}
