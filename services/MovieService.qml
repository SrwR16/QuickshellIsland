import "../overlay"
import "../widgets"
import "../services"
import "../theme"
pragma Singleton
import QtQuick

Item {
  id: movieSvc

  property ListModel trendingMovies: ListModel {}

  property bool isFetchingMovies: false

  property ListModel searchResults: ListModel {}
  property bool isSearching: false

  function fetchMovies(category) {
    if (!category) category = "top";
    isFetchingMovies = true
    var xhr = new XMLHttpRequest()
    xhr.open("GET", "https://v3-cinemeta.strem.io/catalog/movie/" + category + ".json")
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
                  rating: String(m.imdbRating || 0), 
                  year: m.releaseInfo || "",
                  description: m.description || "No description available."
                })
              }
            }
          } catch(e) {}
        }
      }
    }
    xhr.send()
  }

  function searchMovies(query) {
    if (query.trim() === "") {
        searchResults.clear();
        return;
    }
    isSearching = true
    var xhr = new XMLHttpRequest()
    xhr.open("GET", "https://v3-cinemeta.strem.io/catalog/movie/top/search=" + encodeURIComponent(query) + ".json")
    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        isSearching = false
        if (xhr.status === 200) {
          try {
            let res = JSON.parse(xhr.responseText)
            if (res && res.metas) {
              searchResults.clear()
              for (let i = 0; i < Math.min(20, res.metas.length); i++) {
                let m = res.metas[i]
                if (m.poster) searchResults.append({ 
                  id: m.id, 
                  title: m.name, 
                  poster: m.poster, 
                  rating: String(m.imdbRating || 0), 
                  year: m.releaseInfo || "",
                  description: m.description || "No description available."
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
