request = require 'request'

module.exports = (app) ->
  class app.ApplicationController

    # GET /
    @index = (req, res) ->
      res.render 'index'

    @search = (req, res) ->
      q = req.param 'q'

      if q
        app.YouTube.search q, (error, results) ->
          if error
            res.render 'error',
              message: error
          else
            res.render 'search',
              q: q
              results: results
      else
        res.render 'index'

    @watch = (req, res) ->
      # get related
      # https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=10&relatedToVideoId=CGyEd0aKWZE&type=video&key=AIzaSyDVTGYt3PThnKmbhDQzccy0FcH5-Z-zkT8

      videoId = req.param 'id'
      app.YouTube.getVideoInfo videoId, (error, videoInfo) ->
        if error
          res.render 'error',
            message: error
        else
          res.render 'watch',
            videoInfo: videoInfo