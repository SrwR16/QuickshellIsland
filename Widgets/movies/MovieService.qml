pragma Singleton
import QtQuick

Item {
  id: movieSvc

  property ListModel trendingMovies: ListModel {}

  property bool isFetchingMovies: false

  function fetchMovies() {
    isFetchingMovies = true
    var xhr = new XMLHttpRequest()
    xhr.open("GET", "https://v3-cinemeta.strem.io/catalog/movie/top.json")
    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        isFetchingMovies = false
        if (xhr.status === 200) {
          try {
            let res = JSON.parse(xhr.responseText)
            if (res && res.metas) {
              trendingMovies.clear()
              for (let i = 0; i < Math.min(20, res.metas.length); i++) {
                let m = res.metas[i]
                if (m.poster) trendingMovies.append({ 
                  id: m.id, 
                  title: m.name, 
                  poster: m.poster, 
                  rating: m.imdbRating || 0, 
                  year: m.releaseInfo || "" 
                })
              }
            }
          } catch(e) {}
        }
      }
    }
    xhr.send()
  }

  Component.onCompleted: {
    fetchMovies()
  }
}
