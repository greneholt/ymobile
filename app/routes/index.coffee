module.exports = (app) ->
  # Index
  app.get '/', app.ApplicationController.index

  app.get '/watch/:id', app.ApplicationController.watch
  app.get '/search', app.ApplicationController.search

  # Error handling (No previous route found. Assuming it’s a 404)
  app.get '/*', (req, res) ->
    NotFound res

  NotFound = (res) ->
    res.render '404', status: 404, view: 'four-o-four'
